import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../network/api_endpoint.dart';
import '../models/login_response.dart';
import '../models/verify_response.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository([ApiClient? client]) : _client = client ?? apiClient;

  String _extractErrorMessage(
    Object error, {
    String fallback = 'Request failed',
  }) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final dynamic message =
            data['message'] ?? data['error'] ?? data['detail'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      } else if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
    }
    final text = error.toString();
    return text.isNotEmpty ? text : fallback;
  }

  String _normalizeToLocal10(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  List<String> _phoneVariants(
    String phone, {
    required bool preferInternational,
  }) {
    final raw = phone.trim();
    final local = _normalizeToLocal10(raw);
    final international = local.length == 10 ? '+91$local' : raw;
    final ordered = preferInternational
        ? <String>[international, local, raw]
        : <String>[local, international, raw];

    final seen = <String>{};
    final variants = <String>[];
    for (final value in ordered) {
      final v = value.trim();
      if (v.isEmpty || seen.contains(v)) continue;
      seen.add(v);
      variants.add(v);
    }
    return variants;
  }

  Future<Map<String, dynamic>?> _postAuthWithPhoneVariants(
    String path, {
    required String phone,
    String? otp,
    required bool preferInternational,
  }) async {
    final variants = _phoneVariants(
      phone,
      preferInternational: preferInternational,
    );
    DioException? last400;

    for (int i = 0; i < variants.length; i++) {
      final candidate = variants[i];
      try {
        final body = <String, dynamic>{'phone': candidate};
        if (otp != null) body['otp'] = otp;

        final response = await _client.post(
          path,
          data: body,
          options: Options(extra: {'skipAuth': true}),
        );
        return response.data as Map<String, dynamic>?;
      } on DioException catch (e) {
        final isLastAttempt = i == variants.length - 1;
        final shouldRetryForBadRequest =
            e.response?.statusCode == 400 && !isLastAttempt;
        if (shouldRetryForBadRequest) {
          last400 = e;
          continue;
        }
        rethrow;
      }
    }

    if (last400 != null) {
      throw last400;
    }
    return null;
  }

  /// Request OTP for login. Expects 10-digit phone string (without +91)
  Future<LoginResponse> requestLoginOtp(String phone) async {
    try {
      final data = await _postAuthWithPhoneVariants(
        AuthApiEndpoint.login,
        phone: phone,
        preferInternational: false,
      );
      if (data != null) {
        return LoginResponse.fromJson(data);
      }
      return LoginResponse(success: false, message: 'Invalid response');
    } on DioException catch (e) {
      return LoginResponse(
        success: false,
        message: _extractErrorMessage(e, fallback: 'Failed to request OTP'),
      );
    } catch (e) {
      return LoginResponse(success: false, message: _extractErrorMessage(e));
    }
  }

  /// Request OTP for signup. Expects 10-digit phone string (without +91)
  Future<LoginResponse> requestSignupOtp(String phone) async {
    try {
      final data = await _postAuthWithPhoneVariants(
        AuthApiEndpoint.signup,
        phone: phone,
        preferInternational: false,
      );
      if (data != null) {
        return LoginResponse.fromJson(data);
      }
      return LoginResponse(success: false, message: 'Invalid response');
    } on DioException catch (e) {
      return LoginResponse(
        success: false,
        message: _extractErrorMessage(e, fallback: 'Failed to request OTP'),
      );
    } catch (e) {
      return LoginResponse(success: false, message: _extractErrorMessage(e));
    }
  }

  /// If [helper] is true, hits `auth/helper/verify-otp`, otherwise `auth/verify-otp`.
  /// [phone] can be 10 digits; it is sent as +91{phone} to match API spec.
  Future<VerifyResponse> verifyOtp(
    String phone,
    String otp, {
    bool helper = false,
  }) async {
    try {
      final path = helper
          ? AuthApiEndpoint.helperVerifyOtp
          : AuthApiEndpoint.verifyOtp;
      final data = await _postAuthWithPhoneVariants(
        path,
        phone: phone,
        otp: otp,
        preferInternational: true,
      );
      if (data != null) {
        return VerifyResponse.fromJson(data);
      }
      return VerifyResponse(success: false, message: 'Invalid response');
    } on DioException catch (e) {
      return VerifyResponse(
        success: false,
        message: _extractErrorMessage(e, fallback: 'OTP verification failed'),
      );
    } catch (e) {
      return VerifyResponse(success: false, message: _extractErrorMessage(e));
    }
  }

  /// Logout and invalidate refresh token. Requires JWT.
  Future<bool> logout() async {
    try {
      await _client.post(AuthApiEndpoint.logout);
      return true;
    } catch (_) {
      return false;
    }
  }
}
