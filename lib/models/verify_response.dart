class VerifyResponse {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;

  VerifyResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory VerifyResponse.fromJson(Map<String, dynamic> json) {
    // Tokens and user at top level: { success, accessToken, refreshToken, user }
    final user = json['user'] as Map<String, dynamic>?;
    return VerifyResponse(
      success: json['success'] == true,
      message: json['message'] ?? '',
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      user: user,
    );
  }
}
