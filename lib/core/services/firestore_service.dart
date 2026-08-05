import 'package:cloud_firestore/cloud_firestore.dart';
import '../exceptions/app_exception.dart';
import '../logger/app_logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data, SetOptions(merge: true));
      AppLogger.sync('Document set: $collection/$docId');
    } catch (e) {
      AppLogger.error('Failed to set document: $collection/$docId', e, null, 'FIRESTORE');
      throw FirestoreException('Failed to set document in Firestore', details: e);
    }
  }

  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      AppLogger.sync('Document deleted: $collection/$docId');
    } catch (e) {
      AppLogger.error('Failed to delete document: $collection/$docId', e, null, 'FIRESTORE');
      throw FirestoreException('Failed to delete document from Firestore', details: e);
    }
  }

  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      final snapshot = await _firestore.collection(collection).doc(docId).get();
      return snapshot.data();
    } catch (e) {
      AppLogger.error('Failed to get document: $collection/$docId', e, null, 'FIRESTORE');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCollection({
    required String collection,
  }) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch collection: $collection', e, null, 'FIRESTORE');
      return [];
    }
  }
}
