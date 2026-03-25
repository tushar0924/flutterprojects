class JobHistoryModel {
  const JobHistoryModel({
    required this.bookingId,
    required this.customerName,
    required this.serviceType,
    required this.status,
    required this.rating,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.address,
    required this.amount,
  });

  final int bookingId;
  final String customerName;
  final String serviceType;
  final String status;
  final double rating;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String address;
  final num amount;

  factory JobHistoryModel.fromJson(Map<String, dynamic> json) {
    return JobHistoryModel(
      bookingId: _toInt(json['bookingId'] ?? json['id']),
      customerName: _toString(
        json['customerName'] ?? json['name'] ?? json['userName'],
        fallback: 'Customer',
      ),
      serviceType: _toString(
        json['serviceType'] ?? json['serviceName'] ?? json['workType'],
        fallback: 'Service',
      ),
      status: _toString(json['status'] ?? json['jobStatus']),
      rating: _toDouble(json['helperRating'] ?? json['rating']),
      bookingDate: _toString(
        json['dateLabel'] ?? json['bookingDate'] ?? json['date'],
      ),
      startTime: _toString(json['timeLabel'] ?? json['startTime']),
      endTime: _toString(json['endTime']),
      address: _toString(json['address']),
      amount: _toNum(
        json['finalAmount'] ?? json['amount'] ?? json['price'] ?? json['fee'],
      ),
    );
  }

  bool get hasRating => rating > 0;

  bool get hasAddress => address.trim().isNotEmpty;

  String get displayStatus {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'COMPLETED') return 'Delivered';
    if (normalized == 'CANCELLED' || normalized == 'CANCELED') {
      return 'Cancelled';
    }
    if (normalized.isEmpty) return 'Delivered';
    return _toTitleCase(normalized.toLowerCase());
  }

  String get displayRating {
    return rating % 1 == 0 ? rating.toStringAsFixed(0) : rating.toStringAsFixed(1);
  }

  String get displaySchedule {
    final date = bookingDate.trim();
    final start = startTime.trim();
    final end = endTime.trim();

    if (date.isNotEmpty && start.isNotEmpty && start.contains(' - ')) {
      return '$date · $start';
    }

    if (date.isNotEmpty && start.isNotEmpty && end.isNotEmpty) {
      return '$date · $start - $end';
    }
    if (date.isNotEmpty && start.isNotEmpty) {
      return '$date · $start';
    }
    if (date.isNotEmpty) return date;
    if (start.isNotEmpty && end.isNotEmpty) return '$start - $end';
    if (start.isNotEmpty) return start;
    return '-';
  }

  String get displayAmount {
    if (amount % 1 == 0) {
      return '₹${amount.toInt()}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }
}

class JobHistoryApiResponse {
  const JobHistoryApiResponse({
    required this.success,
    required this.jobs,
    required this.message,
  });

  final bool success;
  final List<JobHistoryModel> jobs;
  final String? message;

  factory JobHistoryApiResponse.fromJson(Map<String, dynamic> json) {
    final rawList =
        (json['data'] as List<dynamic>?) ??
        (json['bookings'] as List<dynamic>?) ??
        (json['history'] as List<dynamic>?) ??
        const <dynamic>[];

    return JobHistoryApiResponse(
      success: json['success'] == true,
      jobs: rawList
          .whereType<Map<String, dynamic>>()
          .map(JobHistoryModel.fromJson)
          .toList(),
      message: json['message']?.toString(),
    );
  }
}

String _toString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

String _toTitleCase(String text) {
  if (text.trim().isEmpty) return text;
  return text
      .split(' ')
      .where((word) => word.trim().isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}
