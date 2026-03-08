class LoginResponse {
  final bool success;
  final String message;
  final String? phone;
  final int? expiresIn;

  LoginResponse({
    required this.success,
    required this.message,
    this.phone,
    this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true,
      message: json['message'] ?? '',
      phone: json['phone'] as String?,
      expiresIn: json['expiresIn'] is int ? json['expiresIn'] as int : (json['expiresIn'] is String ? int.tryParse(json['expiresIn']) : null),
    );
  }
}
