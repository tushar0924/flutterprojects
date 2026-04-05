class BookingAcceptResponseModel {
  final bool success;
  final String message;
  final int? bookingId;
  final String? responseMessage;

  BookingAcceptResponseModel({
    required this.success,
    required this.message,
    this.bookingId,
    this.responseMessage,
  });

  factory BookingAcceptResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return BookingAcceptResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      bookingId: data?['bookingId'] as int?,
      responseMessage: data?['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {'bookingId': bookingId, 'message': responseMessage},
    };
  }
}
