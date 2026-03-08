import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/login_response.dart';
import '../repositories/auth_repository.dart';
import '../models/verify_response.dart';
import '../session/session_manager.dart';

class AuthState {
  final bool isLoading;
  final String? message;
  final bool? success;

  AuthState({this.isLoading = false, this.message, this.success});

  AuthState copyWith({bool? isLoading, String? message, bool? success}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final SessionManager _session = SessionManager();

  AuthNotifier(this._repo) : super(AuthState());

  Future<LoginResponse> sendSignupOtp(String phone) async {
    state = state.copyWith(isLoading: true, message: null, success: null);
    try {
      final resp = await _repo.requestSignupOtp(phone);
      state = state.copyWith(isLoading: false, message: resp.message, success: resp.success);
      return resp;
    } catch (e) {
      state = state.copyWith(isLoading: false, message: e.toString(), success: false);
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<LoginResponse> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, message: null, success: null);
    try {
      final resp = await _repo.requestLoginOtp(phone);
      state = state.copyWith(isLoading: false, message: resp.message, success: resp.success);
      return resp;
    } catch (e) {
      state = state.copyWith(isLoading: false, message: e.toString(), success: false);
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<VerifyResponse> verifyOtp(String phone, String otp, {bool helper = false}) async {
    state = state.copyWith(isLoading: true, message: null, success: null);
    try {
      final resp = await _repo.verifyOtp(phone, otp, helper: helper);
      state = state.copyWith(isLoading: false, message: resp.message, success: resp.success);
      if (resp.success && resp.accessToken != null && resp.refreshToken != null) {
        final user = resp.user;
        await _session.saveSession(
          accessToken: resp.accessToken!,
          refreshToken: resp.refreshToken!,
          userId: user != null ? user['id'] as int? : null,
          phone: user != null ? user['phone'] as String? : null,
          role: user != null ? user['role'] as String? : null,
        );
      }
      return resp;
    } catch (e) {
      state = state.copyWith(isLoading: false, message: e.toString(), success: false);
      return VerifyResponse(success: false, message: e.toString());
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo);
});
