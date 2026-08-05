import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../exceptions/app_exception.dart';
import '../logger/app_logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile({
    required String path,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      AppLogger.info('Uploaded file: $path -> $downloadUrl', 'STORAGE');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Failed to upload file to path: $path', e, null, 'STORAGE');
      throw StorageException('Failed to upload file to storage: $e');
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
      AppLogger.info('Deleted file: $path', 'STORAGE');
    } catch (e) {
      AppLogger.error('Failed to delete file at path: $path', e, null, 'STORAGE');
    }
  }
}
