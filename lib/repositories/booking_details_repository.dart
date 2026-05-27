import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<bool> startBookingWithOtp(int bookingId, String otp) async {
    try {
      final response = await _client.post(
        'partner/bookings/$bookingId/start',
        data: {'otp': otp},
      );

      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data is Map<String, dynamic>) {
          return data['success'] != false;
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      AppToast.showError(message);
      return false;
    } catch (_) {
      AppToast.showError('Failed to verify OTP');
      return false;
    }
  }

  Future<bool> uploadBeforePhotos(int bookingId, List<XFile> photos) async {
    try {
      final formData = FormData();
      for (final photo in photos) {
        formData.files.add(
          MapEntry(
            'photos',
            await MultipartFile.fromFile(photo.path, filename: photo.name),
          ),
        );
      }

      final response = await _client.post(
        'partner/bookings/$bookingId/before-photos',
        data: formData,
      );

      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data is Map<String, dynamic>) {
          return data['success'] != false;
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      AppToast.showError(message);
      return false;
    } catch (_) {
      AppToast.showError('Failed to upload before work photos');
      return false;
    }
  }

  Future<bool> startBookingTimer(int bookingId) async {
    try {
      final response = await _client.post(
        'partner/bookings/$bookingId/start-timer',
      );

      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data is Map<String, dynamic>) {
          return data['success'] != false;
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      AppToast.showError(message);
      return false;
    } catch (_) {
      AppToast.showError('Failed to start timer');
      return false;
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
