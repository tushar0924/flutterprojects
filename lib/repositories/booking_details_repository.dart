import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  /// POST /api/partner/bookings/:bookingId/start-selfie
  Future<bool> uploadStartSelfie(int bookingId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _client.post(
        'partner/bookings/$bookingId/start-selfie',
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
      AppToast.showError('Failed to upload selfie');
      return false;
    }
  }

  /// Compresses [photo] to ≤80% quality and ≤1920 px on the long side.
  /// Returns the compressed [XFile], or the original if compression fails.
  Future<XFile> _compressPhoto(XFile photo) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final ext = p.extension(photo.name).toLowerCase();
      final outPath = p.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '.jpg' : ext}',
      );

      final CompressFormat format =
          ext == '.png' ? CompressFormat.png : CompressFormat.jpeg;

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        photo.path,
        outPath,
        quality: 80,
        minWidth: 1920,
        minHeight: 1920,
        format: format,
      );

      return result ?? photo;
    } catch (_) {
      // If compression fails for any reason, fall back to the original file.
      return photo;
    }
  }

  Future<bool> uploadBeforePhotos(int bookingId, List<XFile> photos) async {
    try {
      final formData = FormData();
      for (final photo in photos) {
        final compressed = await _compressPhoto(photo);
        formData.files.add(
          MapEntry(
            'photos',
            await MultipartFile.fromFile(
              compressed.path,
              filename: p.basename(compressed.path),
            ),
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

  Future<bool> uploadAfterPhotos(int bookingId, List<XFile> photos) async {
    try {
      final formData = FormData();
      for (final photo in photos) {
        final compressed = await _compressPhoto(photo);
        formData.files.add(
          MapEntry(
            'photos',
            await MultipartFile.fromFile(
              compressed.path,
              filename: p.basename(compressed.path),
            ),
          ),
        );
      }

      final response = await _client.post(
        'partner/bookings/$bookingId/after-photos',
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
      AppToast.showError('Failed to upload after work photos');
      return false;
    }
  }

  Future<bool> completeBooking(int bookingId) async {
    try {
      final response = await _client.post('partner/bookings/$bookingId/complete');
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
      AppToast.showError('Failed to complete booking');
      return false;
    }
  }

  Future<bool> submitRating({
    required int bookingId,
    required int serviceRating,
    required int partnerRating,
    String? review,
  }) async {
    try {
      final response = await _client.post(
        'ratings',
        data: {
          'bookingId': bookingId,
          'serviceRating': serviceRating,
          'partnerRating': partnerRating,
          if (review != null && review.isNotEmpty) 'review': review,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      AppToast.showError(message);
      return false;
    } catch (_) {
      AppToast.showError('Failed to submit rating');
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
