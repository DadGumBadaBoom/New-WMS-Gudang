import 'package:dio/dio.dart';

// Service HTTP menggunakan Dio dengan header token
class ApiService {
  ApiService({Dio? dio, String? baseUrl, String? token})
    : _dio = dio ?? Dio(),
      _baseUrl = baseUrl ?? 'http://192.168.78.2:8080/api', //IP Komputer
      _token = token ?? 'RAHASIA123' {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );
  }

  final Dio _dio;
  final String _baseUrl;
  final String _token;

  // GET dengan query
  Future<Response<T>> getRequest<T>(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _dio.get(path, queryParameters: query);
  }

  // POST JSON
  Future<Response<T>> postRequest<T>(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _dio.post(path, data: body);
  }

  // PUT JSON
  Future<Response<T>> putRequest<T>(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _dio.put(path, data: body);
  }

  // DELETE
  Future<Response<T>> deleteRequest<T>(String path) async {
    return _dio.delete(path);
  }

  // Push sinkronisasi batch
  Future<Response<T>> syncPush<T>(Map<String, dynamic> payload) async {
    return _dio.post('/sync/push', data: payload);
  }

  // Pull sinkronisasi batch
  Future<Response<T>> syncPull<T>({
    String? updatedAfter,
    int perPage = 200,
    int page = 1,
  }) async {
    return _dio.get(
      '/sync/pull',
      queryParameters: {
        if (updatedAfter != null) 'updated_after': updatedAfter,
        'per_page': perPage,
        'page': page,
      },
    );
  }

  // Health check endpoint sederhana
  Future<Response<T>> healthCheck<T>() async {
    return _dio.get('/health');
  }
}
