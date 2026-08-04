import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint('==================================================');
            debugPrint('🚀 [API REQUEST] METHOD: ${options.method}');
            debugPrint('🌐 [API URL]: ${options.uri}');
            debugPrint('📦 [QUERY PARAMS]: ${options.queryParameters}');
            debugPrint('📝 [PAYLOAD]: ${options.data}');
            debugPrint('==================================================');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('==================================================');
            debugPrint('✅ [API RESPONSE] STATUS CODE: ${response.statusCode}');
            debugPrint('🌐 [API URL]: ${response.requestOptions.uri}');
            debugPrint('📄 [RESPONSE BODY]: ${response.data}');
            debugPrint('==================================================');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            debugPrint('==================================================');
            debugPrint('❌ [API ERROR] CODE: ${error.response?.statusCode}');
            debugPrint('🌐 [URL]: ${error.requestOptions.uri}');
            debugPrint('⚠️ [TYPE]: ${error.type}');
            debugPrint('⚠️ [MESSAGE]: ${error.message}');
            debugPrint('==================================================');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> postAction(String url, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        url,
        data: jsonEncode(data),
        options: Options(
          contentType: Headers.jsonContentType,
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.data is String) {
        try {
          response.data = jsonDecode(response.data as String);
        } catch (_) {}
      }

      return response;
    } on DioException catch (e) {
      debugPrint('DioException in postAction: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Exception in postAction: $e');
      rethrow;
    }
  }

  Future<Response> getAction(String url, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.data is String) {
        try {
          response.data = jsonDecode(response.data as String);
        } catch (_) {}
      }

      return response;
    } on DioException catch (e) {
      debugPrint('DioException in getAction: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Exception in getAction: $e');
      rethrow;
    }
  }
}
