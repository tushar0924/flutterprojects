import 'package:dio/dio.dart';

import '../../network/api_client.dart';
import '../../network/api_endpoint.dart';

class BookingRequestActionsRepository {
  BookingRequestActionsRepository([ApiClient? client])
    : _client = client ?? apiClient;

  final ApiClient _client;

  String _extractErrorMessage(
    DioException e, {
    String fallback = 'Request failed',
  }) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['error'] ?? data['detail'];
      if (msg is String && msg.trim().isNotEmpty) {
        return msg.trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return e.message ?? fallback;
  }

  /// POST /api/booking-requests/:requestId/accept
  Future<Map<String, dynamic>> acceptByRequestId(int requestId) async {
    try {
      final res = await _client.post(
        BookingRequestApiEndpoint.accept(requestId),
      );
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to accept booking request',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }

  /// POST /api/booking-requests/:requestId/reject
  Future<Map<String, dynamic>> rejectByRequestId(int requestId) async {
    try {
      final res = await _client.post(
        BookingRequestApiEndpoint.reject(requestId),
      );
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to reject booking request',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }
}
