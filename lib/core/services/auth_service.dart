import '../exceptions/app_exception.dart';
import '../logger/app_logger.dart';
import '../storage/hive_service.dart';

/// Pure Local AuthService implementation (No Firebase Dependency).
///
/// Handles local user authentication and session caching using Hive.
class AuthService {
  // Current active user ID in local session
  String? _currentUserId;

  String? get currentUserId {
    if (_currentUserId != null) return _currentUserId;
    final box = HiveService.getBoxSafe('auth_box');
    final cachedStr = box?.get('active_user_session');
    if (cachedStr != null && cachedStr.isNotEmpty) {
      _currentUserId = cachedStr;
    }
    return _currentUserId;
  }

  static String syntheticEmail(String identifier) {
    final clean = identifier.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    return '$clean@puredropaqua.com';
  }

  /// Local sign-in using synthetic email / username and password.
  Future<Map<String, dynamic>> signIn(String identifier, String password) async {
    final cleanId = identifier.trim().toLowerCase();
    AppLogger.info('🔐 LOCAL AUTH: signIn → identifier=$cleanId', 'AUTH');

    await Future.delayed(const Duration(milliseconds: 300)); // Simulate async auth

    final box = HiveService.getBoxSafe('auth_box');
    
    // Default system credentials for testing
    if ((cleanId == 'admin' || cleanId == 'admin@puredropaqua.com') && password == 'admin123') {
      final adminUser = {
        'id': 'ADM-001',
        'uid': 'ADM-001',
        'employeeId': 'PDAEMP-000',
        'name': 'Pure Drop Admin',
        'username': 'admin',
        'firebaseEmail': 'admin@puredropaqua.com',
        'role': 'admin',
        'employeeType': 'Admin',
        'phone': '9876543210',
        'address': 'HQ Chennai',
        'status': 'Active',
        'firstLogin': false,
      };
      _currentUserId = 'ADM-001';
      if (box != null) {
        await box.put('active_user_session', 'ADM-001');
        await box.put('user_profile_ADM-001', adminUser);
      }
      return adminUser;
    }

    if ((cleanId == 'driver1' || cleanId == 'driver1@puredropaqua.com' || cleanId == 'pdaemp-001') && password == 'driver123') {
      final driverUser = {
        'id': 'PDAEMP-001',
        'uid': 'PDAEMP-001',
        'employeeId': 'PDAEMP-001',
        'name': 'Ramesh Kumar',
        'username': 'driver1',
        'firebaseEmail': 'driver1@puredropaqua.com',
        'role': 'deliveryBoy',
        'employeeType': 'Delivery Staff',
        'phone': '9123456789',
        'address': 'Route A, T.Nagar',
        'status': 'Active',
        'firstLogin': false,
      };
      _currentUserId = 'PDAEMP-001';
      if (box != null) {
        await box.put('active_user_session', 'PDAEMP-001');
        await box.put('user_profile_PDAEMP-001', driverUser);
      }
      return driverUser;
    }

    // Check custom saved employee/user profiles in Hive
    if (box != null) {
      final cachedProfile = box.get('user_profile_$cleanId');
      if (cachedProfile != null && cachedProfile is Map) {
        _currentUserId = cleanId;
        await box.put('active_user_session', cleanId);
        return Map<String, dynamic>.from(cachedProfile);
      }
    }

    // Throw readable AuthException if not matched
    throw const AuthException(
      'Invalid credentials. Please check your username/email and password.',
      code: 'invalid-credential',
    );
  }

  /// Create local user account for staff
  Future<Map<String, dynamic>> createLocalAccount(String identifier, String password, Map<String, dynamic> profile) async {
    final cleanId = identifier.trim().toLowerCase();
    AppLogger.info('🆕 LOCAL AUTH: createLocalAccount → identifier=$cleanId', 'AUTH');

    final box = HiveService.getBoxSafe('auth_box');
    final uid = profile['id'] ?? profile['employeeId'] ?? 'EMP-${DateTime.now().millisecondsSinceEpoch}';
    final userMap = {
      ...profile,
      'id': uid,
      'uid': uid,
      'firebaseEmail': syntheticEmail(identifier),
    };

    if (box != null) {
      await box.put('user_profile_$uid', userMap);
      await box.put('user_profile_$cleanId', userMap);
    }
    return userMap;
  }

  Future<Map<String, dynamic>?> fetchUserProfileByUid(String uid) async {
    final box = HiveService.getBoxSafe('auth_box');
    if (box != null) {
      final data = box.get('user_profile_$uid');
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    }
    return null;
  }

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    final box = HiveService.getBoxSafe('auth_box');
    if (box != null) {
      await box.put('user_profile_$uid', data);
    }
  }

  Future<void> bootstrapAdminIfNeeded() async {
    AppLogger.info('⚡ LOCAL AUTH: Local admin profile ready.', 'AUTH');
  }

  Future<void> signOut() async {
    AppLogger.info('🔓 LOCAL AUTH: signOut', 'AUTH');
    _currentUserId = null;
    final box = HiveService.getBoxSafe('auth_box');
    if (box != null) {
      await box.delete('active_user_session');
    }
  }
}
