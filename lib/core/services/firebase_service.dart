import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'sync_queue_manager.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication status
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Synchronize document to Firestore safely.
  // - If Firebase session is active: writes directly to Firestore.
  // - If Firebase session is missing: enqueues to SyncQueueManager for auto-retry.
  Future<void> syncDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final currentUser = _auth.currentUser;

    if (kDebugMode) {
      debugPrint('─── Firestore Write: $collection/$docId ───');
      debugPrint('🔐 Auth: ${currentUser == null ? "NULL ❌" : "uid=${currentUser.uid} ✅"}');
    }

    if (currentUser == null) {
      // No Firebase session — enqueue for retry when session is restored
      if (kDebugMode) {
        debugPrint('📥 No Firebase session — enqueuing $collection/$docId for sync retry.');
      }
      await SyncQueueManager().enqueue(
        collection: collection,
        docId: docId,
        action: 'set',
        data: data,
      );
      return;
    }

    try {
      await _db.collection(collection).doc(docId).set(data, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('✅ Firestore synced: $collection/$docId (uid=${currentUser.uid})');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Firestore write failed: $collection/$docId');
        debugPrint('   Error : $e');
        debugPrint('   UID   : ${currentUser.uid}');
        debugPrint('   Email : ${currentUser.email}');
        debugPrint('   Stack : $stackTrace');
      }
      // Enqueue for retry on transient errors
      await SyncQueueManager().enqueue(
        collection: collection,
        docId: docId,
        action: 'set',
        data: data,
      );
    }
  }


  // Delete document from Firestore safely
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _db.collection(collection).doc(docId).delete();
      if (kDebugMode) {
        debugPrint('🔥 Firebase deleted: $collection/$docId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Firebase delete pending (offline/error): $collection/$docId -> $e');
      }
    }
  }

  // Stream Collection from Firestore (For real-time cloud listener if enabled)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(String collection) {
    return _db.collection(collection).snapshots();
  }

  // Execute Atomic Firestore WriteBatch Transaction for Delivery Status Updates (Reschedule, Cancel, Not Available, Skip)
  Future<void> executeDeliveryActionTransaction({
    required String deliveryId,
    required String customerId,
    required Map<String, dynamic> deliveryData,
    required Map<String, dynamic> customerHistoryData,
    required Map<String, dynamic> auditLogData,
  }) async {
    try {
      final batch = _db.batch();

      // 1. Update Deliveries document
      final deliveryRef = _db.collection('deliveries').doc(deliveryId);
      batch.set(deliveryRef, deliveryData, SetOptions(merge: true));

      // 2. Write entry to customers/{customerId}/history subcollection
      if (customerId.isNotEmpty) {
        final historyId = 'HIST-${DateTime.now().millisecondsSinceEpoch}';
        final historyRef = _db.collection('customers').doc(customerId).collection('history').doc(historyId);
        batch.set(historyRef, customerHistoryData);
      }

      // 3. Write entry to audit_logs collection
      final auditId = 'AUD-${DateTime.now().millisecondsSinceEpoch}';
      final auditRef = _db.collection('audit_logs').doc(auditId);
      batch.set(auditRef, auditLogData);

      await batch.commit();
      if (kDebugMode) {
        debugPrint('🔥 Firestore WriteBatch Committed: $deliveryId (${deliveryData['deliveryStatus']})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error in executeDeliveryActionTransaction: $e');
      }
    }
  }

  /// Execute Atomic Firestore WriteBatch Transaction for Order Cancellation
  Future<void> executeOrderCancellationTransaction({
    required String orderId,
    required String deliveryId,
    required String customerId,
    required Map<String, dynamic> orderData,
    required Map<String, dynamic> deliveryData,
    required Map<String, dynamic> customerHistoryData,
    required Map<String, dynamic> timelineData,
    required Map<String, dynamic> auditLogData,
  }) async {
    try {
      debugPrint('ℹ️ [CANCELLATION LOG 1/8] Order Cancellation Started: orderId=$orderId, deliveryId=$deliveryId');

      // Pre-validation: Check latest Firestore document state to prevent race conditions or stale updates
      if (orderId.isNotEmpty) {
        final orderDoc = await _db.collection('orders').doc(orderId).get();
        if (orderDoc.exists) {
          final currentStatus = (orderDoc.data()?['status'] ?? '').toString().toLowerCase();
          if (currentStatus == 'cancelled' || currentStatus == 'delivered') {
            debugPrint('⚠️ [CANCELLATION CANCELLED] Order $orderId is already $currentStatus. Aborting transaction.');
            throw Exception('Order $orderId is already $currentStatus');
          }
        }
      }

      final batch = _db.batch();

      // 1. Update Orders document
      if (orderId.isNotEmpty) {
        debugPrint('ℹ️ [CANCELLATION LOG 2/8] Updating Orders Collection: orders/$orderId');
        final orderRef = _db.collection('orders').doc(orderId);
        batch.set(orderRef, orderData, SetOptions(merge: true));

        // Write to orders/{orderId}/timeline subcollection
        final timelineId = 'TL-${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('ℹ️ [CANCELLATION LOG 3/8] Writing Order Timeline: orders/$orderId/timeline/$timelineId');
        final timelineRef = orderRef.collection('timeline').doc(timelineId);
        batch.set(timelineRef, timelineData);
      }

      // 2. Update Deliveries document
      if (deliveryId.isNotEmpty) {
        debugPrint('ℹ️ [CANCELLATION LOG 4/8] Updating Deliveries Collection: deliveries/$deliveryId');
        final deliveryRef = _db.collection('deliveries').doc(deliveryId);
        batch.set(deliveryRef, deliveryData, SetOptions(merge: true));
      }

      // 3. Write entry to customers/{customerId}/history subcollection
      if (customerId.isNotEmpty) {
        final historyId = 'HIST-${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('ℹ️ [CANCELLATION LOG 5/8] Writing Customer History: customers/$customerId/history/$historyId');
        final historyRef = _db.collection('customers').doc(customerId).collection('history').doc(historyId);
        batch.set(historyRef, customerHistoryData);
      }

      // 4. Write entry to audit_logs collection
      final auditId = 'AUD-${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('ℹ️ [CANCELLATION LOG 6/8] Writing Audit Log: audit_logs/$auditId');
      final auditRef = _db.collection('audit_logs').doc(auditId);
      batch.set(auditRef, auditLogData);

      await batch.commit();
      debugPrint('🔥 [CANCELLATION LOG 7/8] Firestore Batch Commit Success for Order: $orderId');
    } catch (e) {
      debugPrint('❌ Error in executeOrderCancellationTransaction: $e');
      rethrow;
    }
  }

  // Execute Atomic Firestore WriteBatch Transaction for Completed Delivery (Delivered action)
  Future<void> executeDeliveredTransaction({
    required String deliveryId,
    required String customerId,
    required Map<String, dynamic> deliveryData,
    required Map<String, dynamic> customerData,
    required Map<String, dynamic> inventoryData,
    required Map<String, dynamic> customerHistoryData,
    required Map<String, dynamic> auditLogData,
  }) async {
    try {
      final batch = _db.batch();

      // 1. Update Deliveries document
      final deliveryRef = _db.collection('deliveries').doc(deliveryId);
      batch.set(deliveryRef, deliveryData, SetOptions(merge: true));

      // 2. Update Customer profile
      if (customerId.isNotEmpty) {
        final customerRef = _db.collection('customers').doc(customerId);
        batch.set(customerRef, customerData, SetOptions(merge: true));

        // 3. Write entry to customers/{customerId}/history subcollection
        final historyId = 'HIST-${DateTime.now().millisecondsSinceEpoch}';
        final historyRef = customerRef.collection('history').doc(historyId);
        batch.set(historyRef, customerHistoryData);
      }

      // 4. Update Inventory
      final inventoryRef = _db.collection('inventory').doc('current');
      batch.set(inventoryRef, inventoryData, SetOptions(merge: true));

      // 5. Write entry to audit_logs collection
      final auditId = 'AUD-${DateTime.now().millisecondsSinceEpoch}';
      final auditRef = _db.collection('audit_logs').doc(auditId);
      batch.set(auditRef, auditLogData);

      await batch.commit();
      if (kDebugMode) {
        debugPrint('🔥 Firestore Delivered Atomic WriteBatch Committed: $deliveryId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error in executeDeliveredTransaction: $e');
      }
    }
  }
}
