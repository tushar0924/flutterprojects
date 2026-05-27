import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoint.dart';
import '../session/session_manager.dart';
import '../utils/toast_helper.dart';
import '../utils/session_expired_dialog.dart';
import '../utils/navigator_service.dart' as nav;

class ApiClient {
  late final Dio dio;
  final SessionManager _session = SessionManager();

  bool _isPutMethod(String method) => method.toUpperCase() == 'PUT';

  String? _extractSuccessMessage(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data as Map);
    final candidate =
        map['message'] ?? map['msg'] ?? map['detail'] ?? map['statusMessage'];
    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
    return null;
  }

  bool _isSuccessPayload(dynamic data, int? statusCode) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data as Map);
      final success = map['success'];
      if (success is bool) return success;
    }

    // If API does not include explicit success flag, treat 2xx as success.
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }

  void _showPutSuccessToast(Response<dynamic> resp) {
    final options = resp.requestOptions;
    if (!_isPutMethod(options.method)) return;
    if (options.extra['showSuccessToast'] == false) return;

    final statusCode = resp.statusCode;
    final data = resp.data;
    if (!_isSuccessPayload(data, statusCode)) return;

    final customMessage = options.extra['successToastMessage'];
    if (customMessage is String && customMessage.trim().isNotEmpty) {
      AppToast.showSuccess(customMessage.trim());
      return;
    }

    final responseMessage = _extractSuccessMessage(data);
    if (responseMessage != null) {
      AppToast.showSuccess(responseMessage);
      return;
    }

    AppToast.showSuccess('Updated successfully');
  }

  String _maskSensitiveValue(String key, dynamic value) {
    final lower = key.toLowerCase();
    if (value == null) return 'null';
    if (lower.contains('authorization')) {
      final text = value.toString();
      if (text.startsWith('Bearer ') && text.length > 16) {
        return 'Bearer ${text.substring(7, 13)}...';
      }
      return '***';
    }
    if (lower.contains('refresh') || lower.contains('access')) {
      return '***';
    }
    return value.toString();
  }

  dynamic _describeData(dynamic data) {
    if (data == null) return null;
    if (data is FormData) {
      return <String, dynamic>{
        'fields': <Map<String, dynamic>>[
          for (final field in data.fields)
            <String, dynamic>{'key': field.key, 'value': field.value},
        ],
        'files': <Map<String, dynamic>>[
          for (final entry in data.files)
            <String, dynamic>{
              'field': entry.key,
              'filename': entry.value.filename,
              'length': entry.value.length,
              'contentType': entry.value.contentType?.toString(),
            },
        ],
      };
    }
    if (data is Map) {
      return data.map<String, dynamic>(
        (dynamic key, dynamic value) => MapEntry<String, dynamic>(
          key.toString(),
          key is String ? _maskSensitiveValue(key, value) : value,
        ),
      );
    }
    if (data is List) {
      return data;
    }
    return data.toString();
  }

  Map<String, dynamic> _describeHeaders(Map<String, dynamic> headers) {
    return headers.map<String, dynamic>(
      (String key, dynamic value) =>
          MapEntry<String, dynamic>(key, _maskSensitiveValue(key, value)),
    );
  }

  String _pretty(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  void _logBlock(String title, Map<String, dynamic> payload) {
    if (!kDebugMode) return;

    debugPrint('========== $title ==========');
    debugPrint(_pretty(payload));
    debugPrint('============================');
  }

  bool _shouldLogRequest(RequestOptions opts) {
    if (!kDebugMode) return false;
    if (opts.extra['skipLog'] == true) return false;
    return true;
  }
  void _showSessionExpiredDialog() {
    try {
      // Get the current context from the navigator
      final context = nav.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        showSessionExpiredDialog(context);
      }
    } catch (_) {
      // Fallback: just log if we can't show the dialog
    }
  }
  void _logRequest(RequestOptions opts) {
    if (!_shouldLogRequest(opts)) return;

    _logBlock('API REQUEST', <String, dynamic>{
      'method': opts.method,
      'url': opts.uri.toString(),
      'headers': _describeHeaders(opts.headers),
      'queryParameters': opts.queryParameters,
      'data': _describeData(opts.data),
    });
  }

  void _logResponse(Response<dynamic> resp) {
    if (!kDebugMode) return;
    if (resp.requestOptions.extra['skipLog'] == true) return;

    final startedAt = resp.requestOptions.extra['requestStartedAt'];
    final durationMs = startedAt is DateTime
        ? DateTime.now().difference(startedAt).inMilliseconds
        : null;

    _logBlock('API RESPONSE', <String, dynamic>{
      'method': resp.requestOptions.method,
      'url': resp.requestOptions.uri.toString(),
      'statusCode': resp.statusCode,
      'durationMs': durationMs,
      'data': resp.data,
    });
  }

  void _logError(DioException err) {
    if (!kDebugMode) return;
    if (err.requestOptions.extra['skipLog'] == true) return;

    final startedAt = err.requestOptions.extra['requestStartedAt'];
    final durationMs = startedAt is DateTime
        ? DateTime.now().difference(startedAt).inMilliseconds
        : null;

    _logBlock('API ERROR', <String, dynamic>{
      'method': err.requestOptions.method,
      'url': err.requestOptions.uri.toString(),
      'statusCode': err.response?.statusCode,
      'durationMs': durationMs,
      'type': err.type.toString(),
      'message': err.message,
      'requestData': _describeData(err.requestOptions.data),
      'responseData': err.response?.data,
    });
  }

  ApiClient({BaseOptions? options}) {
    final baseOptions =
        options ??
        BaseOptions(
          baseUrl: ApiEndpoint.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        );

    dio = Dio(baseOptions);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opts, handler) async {
          final skipAuth = opts.extra['skipAuth'] == true;
          if (!skipAuth) {
            try {
              final token = await _session.getAccessToken();
              if (token != null && token.isNotEmpty) {
                opts.headers['Authorization'] = 'Bearer $token';
              }
            } catch (_) {
              // Continue request without auth header if session read fails.
            }
          }
          opts.extra['requestStartedAt'] = DateTime.now();
          opts.extra['shouldLogRequest'] = _shouldLogRequest(opts);
          _logRequest(opts);
          return handler.next(opts);
        },
        onResponse: (resp, handler) {
          _logResponse(resp);
          _showPutSuccessToast(resp);
          return handler.next(resp);
        },
        onError: (err, handler) async {
          _logError(err);
          if (err.response?.statusCode == 401) {
            String? refreshToken;
            try {
              refreshToken = await _session.getRefreshToken();
            } catch (_) {
              refreshToken = null;
            }
            if (refreshToken == null || refreshToken.isEmpty) {
              try {
                await _session.clearSession();
              } catch (_) {}
              // Session expired - show dialog and redirect to login
              _showSessionExpiredDialog();
              return handler.next(err);
            }
            try {
              final response = await dio.post<Map<String, dynamic>>(
                AuthApiEndpoint.refreshToken,
                data: {'refreshToken': refreshToken},
                options: Options(extra: {'skipAuth': true, 'skipLog': true}),
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
            try {
              await _session.clearSession();
            } catch (_) {}
            // Token refresh failed - show dialog and redirect
            _showSessionExpiredDialog();
          }
          return handler.next(err);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

final apiClient = ApiClient();
