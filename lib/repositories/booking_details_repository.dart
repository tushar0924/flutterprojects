import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/booking_details_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoint.dart';
import '../utils/toast_helper.dart';

final bookingDetailsRepositoryProvider = Provider((ref) {
  return BookingDetailsRepository();
});

class BookingDetailsRepository {
  final ApiClient _client = apiClient;

  BookingDetailsRepository();

  Future<BookingDetailsModel?> getBookingDetails(int bookingId) async {
    try {
      final endpoint = PartnerApiEndpoint.bookingDetail(bookingId);
      final response = await _client.get(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final bookingJson = data['data'] ?? data;
          return BookingDetailsModel.fromJson(bookingJson);
        }
      }
      return null;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      AppToast.showError(message);
      return null;
    } catch (e) {
      AppToast.showError('Failed to load booking details');
      return null;
    }
  }

  String _extractErrorMessage(DioException error) {
    try {
      if (error.response?.data is Map<String, dynamic>) {
        final data = error.response!.data as Map<String, dynamic>;
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}

    return error.message ?? 'An error occurred';
  }
}
