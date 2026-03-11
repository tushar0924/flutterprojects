import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class ServicesRepository {
  final ApiClient _client;

  ServicesRepository([ApiClient? client]) : _client = client ?? apiClient;

  Map<String, dynamic> _errorPayload(
    Object error, {
    String fallback = 'Request failed',
  }) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is String && data.trim().isNotEmpty) {
        return <String, dynamic>{'success': false, 'message': data.trim()};
      }
      return <String, dynamic>{
        'success': false,
        'message': error.message ?? fallback,
        'statusCode': error.response?.statusCode,
      };
    }
    return <String, dynamic>{'success': false, 'message': fallback};
  }

  /// GET /api/services — Public, list all available services
  Future<Map<String, dynamic>> getServices() async {
    try {
      final res = await _client.get(
        ServicesApiEndpoint.list,
        options: Options(extra: {'skipAuth': true}),
      );
      return (res.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      return _errorPayload(e, fallback: 'Failed to load services');
    }
  }

  /// GET /api/services/:serviceId — Public, service detail with plans
  Future<Map<String, dynamic>> getServiceDetail(int serviceId) async {
    try {
      final res = await _client.get(
        ServicesApiEndpoint.detail(serviceId),
        options: Options(extra: {'skipAuth': true}),
      );
      return (res.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      return _errorPayload(e, fallback: 'Failed to load service detail');
    }
  }
}
