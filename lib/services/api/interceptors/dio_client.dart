import 'package:bilSend/services/api/api_constants.dart';
import 'package:bilSend/services/api/interceptors/dio_interceptors.dart';
import 'package:dio/dio.dart';
import 'package:bilSend/services/storage/storage_service.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),   // 30 sec to connect
      receiveTimeout: const Duration(minutes: 2),    // 2 minutes to wait for data
      sendTimeout: const Duration(seconds: 30),      // optional: 30 sec to send
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static Dio get client {
    _dio.interceptors.clear();
    _dio.interceptors.add(DioInterceptors());
    _dio.interceptors.add(_authInterceptor);
    return _dio;
  }
  static final InterceptorsWrapper _authInterceptor = InterceptorsWrapper(
    onRequest: (options, handler) async {
      // List of public endpoints that don't require authentication
      final publicEndpoints = [
        ApiConstants.register,
        ApiConstants.login,
        ApiConstants.otp_generate,
        ApiConstants.otp_validate,
        ApiConstants.password_reset_request,
        ApiConstants.password_reset_confirm,
      ];

      // Also add individual path patterns for flexibility
      final isPublicEndpoint = publicEndpoints.any((endpoint) =>
      options.path == endpoint || options.path.contains(endpoint)
      );

      // Check for specific path patterns
      final isAuthPath = options.path.contains('/auth/') &&
          (options.path.contains('/register') ||
              options.path.contains('/login'));
      final isOtpPath = options.path.contains('/otp_');
      final isPasswordResetPath = options.path.contains('/password-reset/');

      // Only add token for non-public endpoints
      if (!isPublicEndpoint && !isAuthPath && !isOtpPath && !isPasswordResetPath) {
        final token = await StorageService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }

      handler.next(options);
    },
  );
}
