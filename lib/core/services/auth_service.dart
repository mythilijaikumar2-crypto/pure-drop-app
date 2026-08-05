import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../exceptions/app_exception.dart';
import '../logger/app_logger.dart';
import '../storage/hive_service.dart';

/// Firebase-first AuthService.
///
/// All authentication goes through FirebaseAuth.
/// Hive is ONLY used as a session cache — never as the auth source.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─────────────────────────────────────────────────────────────────────────
  // SYNTHETIC EMAIL HELPER
  // Converts a username or employee ID into a consistent Firebase-safe email.
  // e.g. "admin" → "admin@puredropaqua.com"
  //      "PDAEMP-001" → "pdaemp-001@puredropaqua.com"
  // ─────────────────────────────────────────────────────────────────────────
  static String syntheticEmail(String identifier) {
    final clean = identifier.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    return '$clean@puredropaqua.com';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN IN
  // Firebase Auth sign-in using synthetic email derived from username/employeeId.
  // Does NOT auto-create accounts — if user not found, throws AuthException
  // with code 'user-not-found' so the caller can show "Contact Administrator".
  // ─────────────────────────────────────────────────────────────────────────
  Future<UserCredential> signIn(String identifier, String password) async {
    final email = syntheticEmail(identifier);
    AppLogger.info('🔐 AUTH: signIn → email=$email', 'AUTH');

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password.trim(),
      );
      AppLogger.audit(
        '✅ AUTH: Firebase Auth success — uid=${credential.user?.uid} email=${credential.user?.email}',
        'AUTH',
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('⚠️ AUTH: Sign-in failed (${e.code}): ${e.message}', 'AUTH');
      // Map Firebase error codes to human-readable messages
      switch (e.code) {
        case 'user-not-found':
          throw const AuthException(
            'Account not found. Please contact Administrator.',
            code: 'user-not-found',
          );
        case 'wrong-password':
        case 'invalid-credential':
          throw const AuthException(
            'Incorrect password. Please try again.',
            code: 'wrong-password',
          );
        case 'user-disabled':
          throw const AuthException(
            'This account has been disabled. Contact Administrator.',
            code: 'user-disabled',
          );
        case 'too-many-requests':
          throw const AuthException(
            'Too many failed attempts. Try again later.',
            code: 'too-many-requests',
          );
        default:
          throw AuthException(
            e.message ?? 'Authentication failed.',
            code: e.code,
          );
      }
    } catch (e) {
      AppLogger.error('❌ AUTH: Unexpected sign-in error', e, null, 'AUTH');
      throw AuthException('Sign-in failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE FIREBASE AUTH ACCOUNT
  // Used ONLY by: (a) Admin bootstrap, (b) Admin creating a new employee.
  // Never called during user login.
  // ─────────────────────────────────────────────────────────────────────────
  Future<UserCredential> createFirebaseAccount(String identifier, String password) async {
    final email = syntheticEmail(identifier);
    AppLogger.info('🆕 AUTH: createFirebaseAccount → email=$email', 'AUTH');

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password.trim(),
      );
      AppLogger.audit(
        '✅ AUTH: Firebase account created — uid=${credential.user?.uid} email=${credential.user?.email}',
        'AUTH',
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Account exists — sign in instead
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password.trim(),
        );
      }
      AppLogger.error('❌ AUTH: createFirebaseAccount failed (${e.code}): ${e.message}', e, null, 'AUTH');
      throw AuthException(e.message ?? 'Failed to create account', code: e.code);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH USER PROFILE BY UID
  // Loads user document from Firestore users/{uid}.
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchUserProfileByUid(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        AppLogger.info('✅ AUTH: Fetched users/$uid from Firestore', 'AUTH');
        return doc.data();
      }
      AppLogger.warning('⚠️ AUTH: users/$uid not found in Firestore', 'AUTH');
      return null;
    } catch (e) {
      AppLogger.error('❌ AUTH: fetchUserProfileByUid failed for uid=$uid', e, null, 'AUTH');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SAVE USER PROFILE TO FIRESTORE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
      AppLogger.audit('✅ AUTH: User profile saved to users/$uid', 'AUTH');
    } catch (e) {
      AppLogger.error('❌ AUTH: saveUserProfile failed for uid=$uid', e, null, 'AUTH');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN OUT
  // Clears Firebase Auth session.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.audit('🔓 AUTH: Firebase session cleared (signed out)', 'AUTH');
    } catch (e) {
      AppLogger.error('❌ AUTH: Sign out error', e, null, 'AUTH');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOOTSTRAP ADMIN (One-Time Setup)
  //
  // Called once from SplashScreen on the very first app launch.
  // Creates the default admin Firebase Auth account and Firestore user document
  // so the admin can log in without any manual Firebase Console setup.
  //
  // Safe to call on every launch — checks `hasBootstrapped` in Hive first.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> bootstrapAdminIfNeeded() async {
    try {
      final alreadyDone = HiveService.getData(
        AppConstants.authBoxName,
        'hasBootstrapped',
        defaultValue: false,
      );
      if (alreadyDone == true) {
        AppLogger.info('ℹ️ AUTH: Bootstrap already completed. Skipping.', 'AUTH');
        return;
      }

      AppLogger.info('🚀 AUTH: Running first-time admin bootstrap...', 'AUTH');

      // Create Firebase Auth account for admin (or sign in if already exists)
      const adminIdentifier = 'admin';
      const adminPassword = 'admin123';
      final email = syntheticEmail(adminIdentifier);

      UserCredential credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: adminPassword,
        );
        AppLogger.audit('✅ AUTH: Bootstrap — Admin Firebase account created: uid=${credential.user?.uid}', 'AUTH');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Account already exists — just sign in to get the UID
          credential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: adminPassword,
          );
          AppLogger.info('ℹ️ AUTH: Bootstrap — Admin account already exists: uid=${credential.user?.uid}', 'AUTH');
        } else {
          AppLogger.error('❌ AUTH: Bootstrap failed (${e.code}): ${e.message}', e, null, 'AUTH');
          return; // Bootstrap failed — app will still work, admin must use Firebase Console
        }
      }

      final uid = credential.user?.uid;
      if (uid == null) return;

      // Create admin Firestore users/{uid} document
      final adminDoc = {
        'uid': uid,
        'id': uid,
        'employeeId': 'PDAEMP-000',
        'name': 'Pure Drop Admin',
        'username': 'admin',
        'firebaseEmail': email,
        'role': 'admin',
        'employeeType': 'Admin',
        'phone': '',
        'address': '',
        'status': 'Active',
        'firstLogin': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _db.collection('users').doc(uid).set(adminDoc, SetOptions(merge: true));
      AppLogger.audit('✅ AUTH: Bootstrap — Admin Firestore document created: users/$uid', 'AUTH');

      // Sign out after bootstrap so the login screen is shown normally
      await _auth.signOut();

      // Mark bootstrap complete
      await HiveService.saveData(AppConstants.authBoxName, 'hasBootstrapped', true);
      AppLogger.audit('✅ AUTH: Bootstrap complete. Admin account ready.', 'AUTH');
    } catch (e) {
      AppLogger.error('❌ AUTH: Bootstrap unexpected error', e, null, 'AUTH');
      // Non-fatal: bootstrap failure should not crash the app
    }
  }
}
