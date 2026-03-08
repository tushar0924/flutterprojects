import 'package:dio/dio.dart';
import 'api_endpoint.dart';
import '../session/session_manager.dart';

class ApiClient {
  late final Dio dio;
  final SessionManager _session = SessionManager();

  ApiClient({BaseOptions? options}) {
    final baseOptions = options ?? BaseOptions(
      baseUrl: ApiEndpoint.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    dio = Dio(baseOptions);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) async {
        final skipAuth = opts.extra['skipAuth'] == true;
        if (!skipAuth) {
          final token = await _session.getAccessToken();
          if (token != null && token.isNotEmpty) {
            opts.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(opts);
      },
      onResponse: (resp, handler) => handler.next(resp),
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          final refreshToken = await _session.getRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            await _session.clearSession();
            return handler.next(err);
          }
          try {
            final response = await dio.post<Map<String, dynamic>>(
              'auth/refresh-token',
              data: {'refreshToken': refreshToken},
              options: Options(extra: {'skipAuth': true}),
            );
            final data = response.data;
            if (data != null && data['success'] == true) {
              final newToken = data['accessToken'] as String?;
              if (newToken != null && newToken.isNotEmpty) {
                await _session.updateAccessToken(newToken);
                final opts = err.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final res = await dio.fetch(opts);
                return handler.resolve(res);
              }
            }
          } catch (_) {}
          await _session.clearSession();
        }
        return handler.next(err);
      },
    ));
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}

final apiClient = ApiClient();
