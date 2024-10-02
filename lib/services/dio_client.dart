import 'package:dio/dio.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:5000',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
      },
      extra: {
        'withCredentials': true, // Enable cookies
      },
    ),
  );

  static Dio get dio => _dio;
}
