import 'package:shared_preferences/shared_preferences.dart';

/// Manages user login session: tokens and user data.
/// Use [saveSession] after successful OTP verification.
/// Use [clearSession] for logout (to be integrated).
class SessionManager {
  SessionManager._();
  static final SessionManager _instance = SessionManager._();
  factory SessionManager() => _instance;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserPhone = 'user_phone';
  static const _keyUserRole = 'user_role';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String? _accessToken;
  String? _refreshToken;

  /// Cached access token. Prefer [getAccessToken] for fresh read.
  String? get accessToken => _accessToken;

  /// Cached refresh token. Prefer [getRefreshToken] for fresh read.
  String? get refreshToken => _refreshToken;

  /// Whether the user has a valid session (has access token).
  Future<bool> get isLoggedIn async => (await getAccessToken())?.isNotEmpty == true;

  /// Reads access token from storage (or cache).
  Future<String?> getAccessToken() async {
    final prefs = await _storage;
    _accessToken ??= prefs.getString(_keyAccessToken);
    return _accessToken;
  }

  /// Reads refresh token from storage (or cache).
  Future<String?> getRefreshToken() async {
    final prefs = await _storage;
    _refreshToken ??= prefs.getString(_keyRefreshToken);
    return _refreshToken;
  }

  /// Saves session after successful OTP verification.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    int? userId,
    String? phone,
    String? role,
  }) async {
    final prefs = await _storage;
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    if (userId != null) {
      await prefs.setString(_keyUserId, userId.toString());
    }
    if (phone != null) {
      await prefs.setString(_keyUserPhone, phone);
    }
    if (role != null) {
      await prefs.setString(_keyUserRole, role);
    }
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Updates only the access token (e.g. after refresh).
  Future<void> updateAccessToken(String accessToken) async {
    final prefs = await _storage;
    await prefs.setString(_keyAccessToken, accessToken);
    _accessToken = accessToken;
  }

  /// Clears all session data. Use for logout.
  Future<void> clearSession() async {
    final prefs = await _storage;
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserRole);
    _accessToken = null;
    _refreshToken = null;
  }

  /// User id from stored session.
  Future<int?> getUserId() async {
    final prefs = await _storage;
    final s = prefs.getString(_keyUserId);
    return s != null ? int.tryParse(s) : null;
  }

  /// User phone from stored session.
  Future<String?> getUserPhone() async {
    final prefs = await _storage;
    return prefs.getString(_keyUserPhone);
  }

  /// User role from stored session.
  Future<String?> getUserRole() async {
    final prefs = await _storage;
    return prefs.getString(_keyUserRole);
  }
}
