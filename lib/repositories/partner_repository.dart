import 'dart:io';

import 'package:dio/dio.dart';

import '../models/partner_address_model.dart';
import '../models/helper_bank_model.dart';
import '../models/helper_earnings_history_model.dart';
import '../models/helper_earnings_transaction_model.dart';
import '../models/job_history_model.dart';
import '../models/partner_review_model.dart';
import '../models/upcoming_job_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class PartnerRepository {
  final ApiClient _client;

  PartnerRepository([ApiClient? client]) : _client = client ?? apiClient;

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? 'upload_file' : parts.last;
  }

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

  Future<Map<String, dynamic>> _postFileWithFieldFallback(
    String path,
    File file, {
    required List<String> fieldNames,
    required String fallbackMessage,
  }) async {
    DioException? lastError;

    for (int i = 0; i < fieldNames.length; i++) {
      final field = fieldNames[i];
      try {
        final formData = FormData.fromMap({
          field: await MultipartFile.fromFile(
            file.path,
            filename: _fileNameFromPath(file.path),
          ),
        });
        final res = await _client.post(path, data: formData);
        return (res.data as Map<String, dynamic>?) ?? {};
      } on DioException catch (e) {
        lastError = e;
        final status = e.response?.statusCode;
        final isLast = i == fieldNames.length - 1;
        // Retry only for validation-style errors with alternate field names.
        if ((status == 400 || status == 422) && !isLast) {
          continue;
        }
        return <String, dynamic>{
          'success': false,
          'message': _extractErrorMessage(e, fallback: fallbackMessage),
          'statusCode': status,
        };
      }
    }

    if (lastError != null) {
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(lastError, fallback: fallbackMessage),
        'statusCode': lastError.response?.statusCode,
      };
    }

    return <String, dynamic>{'success': false, 'message': fallbackMessage};
  }

  // ── Onboarding ───────────────────────────────────────────────────────────

  /// GET /api/partner/onboarding/status
  Future<Map<String, dynamic>> getOnboardingStatus() async {
    try {
      final res = await _client.get(PartnerApiEndpoint.onboardingStatus);
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to load onboarding status',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }

  /// POST /api/partner/onboarding/profile
  Future<Map<String, dynamic>> submitOnboardingProfile({
    required String fullName,
    String city = '',
    required String serviceArea,
    required List<int> serviceIds,
    String gender = '',
    List<String> workTypes = const [],
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{
      'fullName': fullName,
      'address': serviceArea,
      'serviceIds': serviceIds,
    };
    if (gender.isNotEmpty) payload['gender'] = gender;
    if (city.isNotEmpty) payload['city'] = city;
    if (workTypes.isNotEmpty) payload['workTypes'] = workTypes;
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;

    print('[submitOnboardingProfile] REQUEST payload: $payload');

    try {
      final res = await _client.post(
        PartnerApiEndpoint.onboardingProfile,
        data: payload,
      );
      final responseData = (res.data as Map<String, dynamic>?) ?? {};
      print(
        '[submitOnboardingProfile] RESPONSE (${res.statusCode}): $responseData',
      );
      return responseData;
    } on DioException catch (e) {
      print(
        '[submitOnboardingProfile] ERROR (${e.response?.statusCode}): ${e.response?.data}',
      );
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to submit profile',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }

  /// POST /api/partner/onboarding/bank
  Future<Map<String, dynamic>> submitOnboardingBank({
    required String accountName,
    required String accountNumber,
    required String ifsc,
    required String bankName,
  }) async {
    try {
      final res = await _client.post(
        PartnerApiEndpoint.onboardingBank,
        data: {
          'accountName': accountName,
          'accountNumber': accountNumber,
          'ifsc': ifsc,
          'bankName': bankName,
        },
      );
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to submit bank details',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }

  // ── KYC (Image-based) ────────────────────────────────────────────────────

  /// POST /api/partner/kyc/upload-selfie — Step 1
  Future<Map<String, dynamic>> uploadKycSelfie(File file) async {
    return _postFileWithFieldFallback(
      PartnerApiEndpoint.uploadSelfie,
      file,
      fieldNames: const ['file', 'image', 'selfie'],
      fallbackMessage: 'Failed to upload selfie',
    );
  }

  /// POST /api/partner/kyc/upload-pan — Step 2
  Future<Map<String, dynamic>> verifyKycPan(File file) async {
    return _postFileWithFieldFallback(
      PartnerApiEndpoint.uploadPan,
      file,
      fieldNames: const ['file', 'pan', 'panCard', 'document', 'image'],
      fallbackMessage: 'Failed to verify PAN',
    );
  }

  /// POST /api/partner/kyc/upload-police — Step 3
  Future<Map<String, dynamic>> uploadKycPolice(File file) async {
    return _postFileWithFieldFallback(
      PartnerApiEndpoint.uploadPolice,
      file,
      fieldNames: const [
        'file',
        'document',
        'policeCertificate',
        'certificate',
      ],
      fallbackMessage: 'Failed to upload police certificate',
    );
  }

  // ── Earnings ─────────────────────────────────────────────────────────────

  /// GET /api/partner/earnings/summary
  Future<Map<String, dynamic>> getEarningsSummary() async {
    final res = await _client.get(PartnerApiEndpoint.earningsSummary);
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  /// GET /api/partner/earnings/history
  Future<Map<String, dynamic>> getEarningsHistory({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await _client.get(
      PartnerApiEndpoint.earningsHistory,
      queryParameters: {'page': page, 'limit': limit},
    );
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  /// GET /api/helper/earnings/dashboard
  Future<Map<String, dynamic>> getHelperEarningsDashboard() async {
    try {
      final res = await _client.get(PartnerApiEndpoint.helperEarningsDashboard);
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to load earnings dashboard',
        ),
      };
    }
  }

  /// GET /api/helper/earnings/history
  Future<HelperEarningsHistoryResponse> getHelperEarningsHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _client.get(
        PartnerApiEndpoint.helperEarningsHistory,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = (res.data as Map<String, dynamic>?) ?? {};
      return HelperEarningsHistoryResponse.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return HelperEarningsHistoryResponse.fromJson(data);
      }
      return HelperEarningsHistoryResponse.fromJson(<String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to load earnings history',
        ),
      });
    }
  }

  /// GET /api/helper/bank
  Future<HelperBankResponse> getHelperBank() async {
    try {
      final res = await _client.get(PartnerApiEndpoint.helperBank);
      final data = (res.data as Map<String, dynamic>?) ?? {};
      return HelperBankResponse.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return HelperBankResponse.fromJson(data);
      }
      return HelperBankResponse.fromJson(<String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to load bank details',
        ),
      });
    }
  }

  /// PUT /api/helper/bank
  Future<Map<String, dynamic>> updateHelperBank(HelperBankAccount account) async {
    try {
      final res = await _client.put(
        PartnerApiEndpoint.helperBank,
        data: account.toPutPayload(),
      );
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to update bank details',
        ),
      };
    }
  }

  /// GET /api/helper/earnings/transaction/:id
  Future<HelperEarningsTransactionResponse> getHelperEarningsTransactionDetail(
    String id,
  ) async {
    try {
      final res = await _client.get(PartnerApiEndpoint.helperEarningsTransaction(id));
      final data = (res.data as Map<String, dynamic>?) ?? {};
      return HelperEarningsTransactionResponse.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return HelperEarningsTransactionResponse.fromJson(data);
      }
      return HelperEarningsTransactionResponse.fromJson(<String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to load transaction detail',
        ),
      });
    }
  }

  // ── Ops (Dashboard, Status) ──────────────────────────────────────────────

  /// GET /api/partner/ops/dashboard — Approved helper only
  Future<Map<String, dynamic>> getOpsDashboard() async {
    try {
      final res = await _client.get(PartnerApiEndpoint.opsDashboard);
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to load dashboard',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }

  /// GET /api/partner/profile
  Future<Map<String, dynamic>> getPartnerProfile() async {
    try {
      final res = await _client.get(PartnerApiEndpoint.profile);
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to load partner profile',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }

  /// PUT /api/partner/profile
  Future<Map<String, dynamic>> updatePartnerProfile({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (phone != null) {
      data['phone'] = phone;
      data['phoneNumber'] = phone;
    }
    if (address != null) data['address'] = address;

    try {
      final res = await _client.put(PartnerApiEndpoint.profile, data: data);
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to update partner profile',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }

  /// GET /api/partner/address
  Future<PartnerAddressModel> getPartnerAddress() async {
    try {
      final res = await _client.get(PartnerApiEndpoint.address);
      final data = (res.data as Map<String, dynamic>?) ?? {};
      return PartnerAddressModel.fromPayload(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return PartnerAddressModel.fromPayload(data);
      }
      return PartnerAddressModel.empty();
    }
  }

  /// PUT /api/partner/address
  Future<Map<String, dynamic>> updatePartnerAddress(
    PartnerAddressModel address,
  ) async {
    try {
      final res = await _client.put(
        PartnerApiEndpoint.address,
        data: address.toPutPayload(),
      );
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to update address',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }

  /// GET /api/partner/reviews
  Future<PartnerReviewsResponse> getPartnerReviews() async {
    try {
      final res = await _client.get(PartnerApiEndpoint.reviews);
      final data = (res.data as Map<String, dynamic>?) ?? {};
      return PartnerReviewsResponse.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return PartnerReviewsResponse.fromJson(data);
      }
      return PartnerReviewsResponse.empty(
        message: _extractErrorMessage(e, fallback: 'Failed to load reviews'),
      );
    }
  }

  /// GET /api/partner/services
  Future<Map<String, dynamic>> getPartnerServices() async {
    try {
      final res = await _client.get(PartnerApiEndpoint.services);
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to load partner services',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }

  /// PUT /api/partner/services
  Future<Map<String, dynamic>> updatePartnerServices({
    required List<int> serviceIds,
  }) async {
    final payload = <String, dynamic>{
      'serviceIds': serviceIds,
      // Keep compatibility with APIs using `services` key.
      'services': serviceIds,
    };

    try {
      final res = await _client.put(PartnerApiEndpoint.services, data: payload);
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return <String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to update partner services',
        ),
        'statusCode': e.response?.statusCode,
      };
    }
  }

  /// GET /api/partner/jobs — Public job listings.
  /// Falls back to API error payload when Dio throws for non-2xx status.
  Future<Map<String, dynamic>> getPublicJobs({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _client.get(
        PartnerApiEndpoint.publicJobs,
        queryParameters: {'page': page, 'limit': limit},
        options: Options(extra: {'skipAuth': true}),
      );
      return (res.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return <String, dynamic>{
        'success': false,
        'message': e.message ?? 'Failed to load jobs',
        'statusCode': e.response?.statusCode,
      };
    }
  }

  /// PATCH /api/partner/ops/status — Toggle online/offline
  Future<Map<String, dynamic>> updateOpsStatus({
    required bool isOnline,
    bool force = false,
  }) async {
    final res = await _client.patch(
      PartnerApiEndpoint.opsStatus,
      data: {'isOnline': isOnline, 'force': force},
    );
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  // ── Bookings ─────────────────────────────────────────────────────────────

  /// GET /api/partner/bookings
  Future<Map<String, dynamic>> getBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await _client.get(
      PartnerApiEndpoint.bookings,
      queryParameters: params,
    );
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  /// GET /api/partner/bookings/upcoming
  Future<UpcomingJobsApiResponse> getUpcomingBookings({
    int page = 1,
    int limit = 20,
    String? day,
    String? serviceType,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (day != null && day.trim().isNotEmpty) {
      params['day'] = day.trim();
    }
    if (serviceType != null && serviceType.trim().isNotEmpty) {
      params['serviceType'] = serviceType.trim();
    }

    try {
      final res = await _client.get(
        PartnerApiEndpoint.upcomingBookings,
        queryParameters: params,
      );
      final data = (res.data as Map<String, dynamic>?) ?? {};
      return UpcomingJobsApiResponse.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return UpcomingJobsApiResponse.fromJson(data);
      }
      return UpcomingJobsApiResponse.fromJson(<String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to load upcoming bookings',
        ),
        'statusCode': e.response?.statusCode,
      });
    }
  }

  /// GET /api/partner/bookings/history
  Future<JobHistoryApiResponse> getBookingHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};

    try {
      final res = await _client.get(
        PartnerApiEndpoint.bookingsHistory,
        queryParameters: params,
      );
      final data = (res.data as Map<String, dynamic>?) ?? {};
      return JobHistoryApiResponse.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return JobHistoryApiResponse.fromJson(data);
      }
      return JobHistoryApiResponse.fromJson(<String, dynamic>{
        'success': false,
        'message': _extractErrorMessage(
          e,
          fallback: 'Failed to load booking history',
        ),
      });
    }
  }

  /// GET /api/partner/bookings/:bookingId
  Future<Map<String, dynamic>> getBookingDetail(int bookingId) async {
    final res = await _client.get(PartnerApiEndpoint.bookingDetail(bookingId));
    return (res.data as Map<String, dynamic>?) ?? {};
  }
}
