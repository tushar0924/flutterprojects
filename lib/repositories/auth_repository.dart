import '../network/api_client.dart';
import '../models/login_response.dart';
import '../models/verify_response.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository([ApiClient? client]) : _client = client ?? apiClient;

  /// Request OTP for login. Expects 10-digit phone string (without +91)
  Future<LoginResponse> requestLoginOtp(String phone) async {
    final response = await _client.post('auth/login', data: {'phone': phone});
    if (response.data is Map<String, dynamic>) {
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    }
    // Fallback: create a generic failure response
    return LoginResponse(success: false, message: 'Invalid response', phone: null, expiresIn: null);
  }

  /// Request OTP for signup. Expects 10-digit phone string (without +91)
  Future<LoginResponse> requestSignupOtp(String phone) async {
    final response = await _client.post('auth/signup', data: {'phone': phone});
    if (response.data is Map<String, dynamic>) {
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    }
    // Fallback: create a generic failure response
    return LoginResponse(success: false, message: 'Invalid response', phone: null, expiresIn: null);
  }

  /// If [helper] is true, hits `auth/helper/verify-otp`, otherwise `auth/verify-otp`.
  /// [phone] can be 10 digits; it is sent as +91<phone> to match API spec.
  Future<VerifyResponse> verifyOtp(String phone, String otp, {bool helper = false}) async {
    final path = helper ? 'auth/helper/verify-otp' : 'auth/verify-otp';
    final phoneFormatted = phone.startsWith('+') ? phone : '+91$phone';
    final response = await _client.post(path, data: {'phone': phoneFormatted, 'otp': otp});
    if (response.data is Map<String, dynamic>) {
      return VerifyResponse.fromJson(response.data as Map<String, dynamic>);
    }
    return VerifyResponse(success: false, message: 'Invalid response');
  }
}
