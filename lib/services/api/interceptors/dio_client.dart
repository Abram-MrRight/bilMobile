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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return _dio;
  }
}
