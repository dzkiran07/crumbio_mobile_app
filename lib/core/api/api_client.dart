import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../services/storage/user_session_service.dart';
import 'api_endpoint.dart';

class ApiClient {
  final Dio _dio;
  final UserSessionService _userSessionService;
  final void Function()? onUnauthorized;

  ApiClient({
    required UserSessionService userSessionService,
    this.onUnauthorized,
  }) : _userSessionService = userSessionService,
       _dio = Dio(
         BaseOptions(
           baseUrl: ApiEndpoints.baseUrl,
           connectTimeout: ApiEndpoints.connectionTimeout,
           receiveTimeout: ApiEndpoints.receiveTimeout,
           headers: {
             'Content-Type': 'application/json',
             'Accept': 'application/json',
           },
         ),
       ) {
    // Add Auth Interceptor
    _dio.interceptors.add(
      _AuthInterceptor(
        userSessionService: _userSessionService,
        onUnauthorized: onUnauthorized,
      ),
    );

    // Retry interceptor with exponential backoff
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
        ],
        retryEvaluator: (error, attempt) {
          final path = error.requestOptions.path;
          final isAuthRequest =
              path.contains(ApiEndpoints.login) ||
              path.contains(ApiEndpoints.register);
          if (isAuthRequest) {
            // Fail fast for login/register so UI doesn't hang for retry cycles.
            return false;
          }
          return error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError;
        },
      ),
    );

    // Add logger in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }
  }

  Dio get dio => _dio;

  void _syncBaseUrlIfNeeded() {
    final resolvedBaseUrl = ApiEndpoints.baseUrl;
    if (_dio.options.baseUrl != resolvedBaseUrl) {
      _dio.options.baseUrl = resolvedBaseUrl;
    }
  }

  // HTTP Methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    _syncBaseUrlIfNeeded();
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    _syncBaseUrlIfNeeded();
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    _syncBaseUrlIfNeeded();
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    _syncBaseUrlIfNeeded();
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> uploadFile(
    String path, {
    required FormData formData,
    Options? options,
    ProgressCallback? onSendProgress,
  }) {
    _syncBaseUrlIfNeeded();
    return _dio.post(
      path,
      data: formData,
      options: options,
      onSendProgress: onSendProgress,
    );
  }
}

// Auth Interceptor
class _AuthInterceptor extends Interceptor {
  final UserSessionService _userSessionService;
  final void Function()? onUnauthorized;

  _AuthInterceptor({
    required UserSessionService userSessionService,
    this.onUnauthorized,
  }) : _userSessionService = userSessionService;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // List of public endpoints
    final publicEndpoints = {
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.forgotPasswordSendOtp,
      ApiEndpoints.forgotPasswordVerifyOtp,
      ApiEndpoints.forgotPasswordReset,
    };

    // Check if this is a POST to login/register/forgot-password
    final isPublic = publicEndpoints.any(
      (endpoint) =>
          options.path.contains(endpoint) && (options.method == 'POST'),
    );

    // Skip adding token only for public endpoints
    if (!isPublic) {
      try {
        final token = await _userSessionService.getToken();
        if (token != null) {
          debugPrint('Adding Bearer token to request: ${options.path}');
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          debugPrint('No token found for request: ${options.path}');
        }
      } catch (e) {
        debugPrint('Error getting token: $e');
      }
    } else {
      debugPrint('Skipping auth for public endpoint: ${options.path}');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      // Clear session and trigger callback
      await _userSessionService.clearSession();
      if (onUnauthorized != null) onUnauthorized!();
    }

    handler.next(err);
  }
}
