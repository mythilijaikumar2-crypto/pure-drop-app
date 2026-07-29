import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/hive_service.dart';
import '../constants/app_constants.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        followRedirects: true,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  String get _baseUrl {
    final customUrl = HiveService.getData(
      AppConstants.settingsBoxName,
      'apps_script_url',
      defaultValue: AppConstants.defaultAppsScriptUrl,
    );
    return customUrl as String;
  }

  Future<Response> postAction(String action, Map<String, dynamic> data) async {
    try {
      final payload = {
        'action': action,
        'payload': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      return await _dio.post(_baseUrl, data: payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getAction(String action, {Map<String, dynamic>? queryParams}) async {
    try {
      final params = {'action': action, ...?queryParams};
      return await _dio.get(_baseUrl, queryParameters: params);
    } catch (e) {
      rethrow;
    }
  }
}
