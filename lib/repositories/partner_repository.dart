import 'dart:io';

import 'package:dio/dio.dart';

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
      print('[submitOnboardingProfile] RESPONSE (${res.statusCode}): $responseData');
      return responseData;
    } on DioException catch (e) {
      print('[submitOnboardingProfile] ERROR (${e.response?.statusCode}): ${e.response?.data}');
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

  /// GET /api/partner/bookings/:bookingId
  Future<Map<String, dynamic>> getBookingDetail(int bookingId) async {
    final res = await _client.get(PartnerApiEndpoint.bookingDetail(bookingId));
    return (res.data as Map<String, dynamic>?) ?? {};
  }
}
