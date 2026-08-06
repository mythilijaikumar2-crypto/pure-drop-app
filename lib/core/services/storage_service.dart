import 'dart:io';
import '../logger/app_logger.dart';

/// Pure Local StorageService stub.
class StorageService {
  Future<String?> uploadFile({
    required String path,
    required File file,
  }) async {
    AppLogger.info('Local file upload: $path -> ${file.path}', 'STORAGE');
    return file.path;
  }

  Future<void> deleteFile(String path) async {
    AppLogger.info('Local file deleted: $path', 'STORAGE');
  }
}
