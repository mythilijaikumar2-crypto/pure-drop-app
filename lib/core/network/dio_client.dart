import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../storage/hive_service.dart';

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
          // Remove authorization headers to prevent Google Apps Script 401 redirect errors
          options.headers.remove('Authorization');
          options.headers.remove('authorization');

          if (kDebugMode) {
            debugPrint('==================================================');
            debugPrint('🚀 [API REQUEST] METHOD: ${options.method}');
            debugPrint('🌐 [API URL]: ${options.uri}');
            debugPrint('📋 [HEADERS]: ${options.headers}');
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
            debugPrint('📄 [ERROR BODY]: ${error.response?.data}');
            debugPrint('==================================================');
          }
          return handler.next(error);
        },
      ),
    );
  }

  static void resetAppsScriptUrl() {
    HiveService.saveData(
      AppConstants.settingsBoxName,
      'apps_script_url',
      AppConstants.defaultAppsScriptUrl,
    );
    if (kDebugMode) {
      debugPrint('🔄 [DioClient]: Restored default Google Apps Script Web App URL: ${AppConstants.defaultAppsScriptUrl}');
    }
  }

  String get _baseUrl {
    final defaultUrl = AppConstants.defaultAppsScriptUrl;
    var customUrl = HiveService.getData(
      AppConstants.settingsBoxName,
      'apps_script_url',
      defaultValue: defaultUrl,
    ).toString().trim();

    if (kDebugMode) {
      debugPrint('🔍 [URL DIAGNOSTICS] Saved Hive URL: "$customUrl"');
      debugPrint('🔍 [URL DIAGNOSTICS] Default URL: "$defaultUrl"');
    }

    // Auto-fix Hive saved URL if missing, placeholder, or invalid
    if (customUrl.isEmpty || customUrl.contains('placeholder') || !customUrl.endsWith('/exec')) {
      if (kDebugMode) {
        debugPrint('⚠️ [URL AUTO-FIX] Stale/invalid URL detected in Hive. Auto-replacing with default Apps Script URL!');
      }
      customUrl = defaultUrl;
      HiveService.saveData(AppConstants.settingsBoxName, 'apps_script_url', customUrl);
    } else if (customUrl != defaultUrl) {
      if (kDebugMode) {
        debugPrint('ℹ️ [URL INFO] Using custom deployed Apps Script URL: $customUrl');
      }
    }

    return customUrl;
  }

  Future<Response> postAction(String action, Map<String, dynamic> data) async {
    try {
      final cleanAction = action.startsWith('/') ? action.substring(1) : action;

      // Construct JSON payload containing action and payload fields as expected by Google Apps Script doPost(e)
      final Map<String, dynamic> bodyPayload = {
        'action': cleanAction,
        'payload': data,
      };

      // Target MUST strictly be the base URL (/exec) without query parameters
      final targetUrl = _baseUrl;

      if (kDebugMode) {
        debugPrint('==================================================');
        debugPrint('🚀 [POST ACTION TARGET]: $targetUrl');
        debugPrint('🎯 [ACTION]: $cleanAction');
        debugPrint('📋 [CONTENT-TYPE]: ${Headers.jsonContentType}');
        debugPrint('📝 [EXACT JSON BODY]: ${jsonEncode(bodyPayload)}');
        debugPrint('==================================================');
      }

      final String postContentType = kIsWeb ? 'text/plain;charset=utf-8' : Headers.jsonContentType;

      // Step 1: Initial POST request with followRedirects: false to catch 302 without converting POST to GET
      Response response = await _dio.post(
        targetUrl,
        data: jsonEncode(bodyPayload),
        options: Options(
          contentType: postContentType,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (kDebugMode) {
        debugPrint('📡 [INITIAL POST RESPONSE CODE]: ${response.statusCode}');
      }

      // Step 2: Handle 302/301/303/307/308 redirects manually preserving POST method & JSON payload
      if (response.statusCode != null && response.statusCode! >= 300 && response.statusCode! < 400) {
        final redirectLocation = response.headers.value('location');
        if (redirectLocation != null && redirectLocation.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('🔄 [POST REDIRECT DETECTED]: Following 302 redirect to $redirectLocation preserving POST method & JSON payload...');
          }
          response = await _dio.post(
            redirectLocation,
            data: jsonEncode(bodyPayload),
            options: Options(
              contentType: postContentType,
              followRedirects: true,
              maxRedirects: 5,
              validateStatus: (status) => status != null && status < 500,
            ),
          );
        }
      }

      if (kDebugMode) {
        debugPrint('==================================================');
        debugPrint('✅ [POST RESPONSE STATUS]: ${response.statusCode}');
        debugPrint('📄 [POST RESPONSE BODY]: ${response.data}');
        debugPrint('==================================================');
      }

      // Parse JSON string response if needed
      if (response.data is String) {
        try {
          response.data = jsonDecode(response.data as String);
        } catch (_) {}
      }

      return response;
    } on DioException catch (e) {
      debugPrint('DioException in postAction [$action]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Exception in postAction [$action]: $e');
      rethrow;
    }
  }

  Future<Response> getAction(String action, {Map<String, dynamic>? queryParams}) async {
    try {
      final cleanAction = action.startsWith('/') ? action.substring(1) : action;
      final params = {'action': cleanAction, ...?queryParams};

      final response = await _dio.get(
        _baseUrl,
        queryParameters: params,
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
      debugPrint('DioException in getAction [$action]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Exception in getAction [$action]: $e');
      rethrow;
    }
  }
}
