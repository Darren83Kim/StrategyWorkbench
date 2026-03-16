import 'package:dio/dio.dart';
import 'dart:developer' as developer;

/// HTTP 클라이언트 예외
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalException;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalException,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Dio HTTP 클라이언트 싱글톤
class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        validateStatus: (status) {
          // 모든 상태코드를 수락하고 에러 처리는 수동으로
          return status != null && status < 500;
        },
      ),
    );

    // 인터셉터 추가
    _dio.interceptors.add(_LoggingInterceptor());
  }

  /// GET 요청
  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      developer.log('GET: $url', name: 'DioClient');
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: options,
      );
      _checkResponse(response);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
        originalException: e,
      );
    }
  }

  /// POST 요청
  Future<dynamic> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      developer.log('POST: $url', name: 'DioClient');
      final response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _checkResponse(response);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
        originalException: e,
      );
    }
  }

  /// PUT 요청
  Future<dynamic> put(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      developer.log('PUT: $url', name: 'DioClient');
      final response = await _dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _checkResponse(response);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
        originalException: e,
      );
    }
  }

  /// DELETE 요청
  Future<dynamic> delete(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      developer.log('DELETE: $url', name: 'DioClient');
      final response = await _dio.delete(
        url,
        queryParameters: queryParameters,
        options: options,
      );
      _checkResponse(response);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
        originalException: e,
      );
    }
  }

  /// 응답 상태 확인
  void _checkResponse(Response response) {
    final statusCode = response.statusCode ?? 500;

    if (statusCode >= 400) {
      throw ApiException(
        'HTTP Error: ${response.statusMessage ?? 'Unknown error'}',
        statusCode: statusCode,
      );
    }

    // JSON 응답 검증
    if (response.data is! Map && response.data is! List) {
      throw ApiException(
        'Invalid response format: ${response.data.runtimeType}',
        statusCode: statusCode,
      );
    }
  }
}

/// 로깅 인터셉터
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      'Request: ${options.method} ${options.path}\n'
      'Headers: ${options.headers}\n'
      'Query: ${options.queryParameters}',
      name: 'DioClient.Request',
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      'Response: ${response.statusCode} ${response.statusMessage}\n'
      'Data: ${response.data.toString().substring(0, 200)}...',
      name: 'DioClient.Response',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      'Error: ${err.message}\n'
      'Type: ${err.type}',
      name: 'DioClient.Error',
    );
    super.onError(err, handler);
  }
}
