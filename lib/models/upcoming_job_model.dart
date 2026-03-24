class UpcomingJobModel {
  const UpcomingJobModel({
    required this.bookingId,
    required this.customerName,
    required this.serviceName,
    required this.serviceType,
    required this.helperName,
    required this.helperRating,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.dayLabel,
    required this.timeLabel,
    required this.duration,
    required this.durationLabel,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.finalAmount,
    required this.amountLabel,
    required this.jobStatus,
  });

  final int bookingId;
  final String customerName;
  final String serviceName;
  final String serviceType;
  final String helperName;
  final double helperRating;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String dayLabel;
  final String timeLabel;
  final int duration;
  final String durationLabel;
  final String address;
  final double? latitude;
  final double? longitude;
  final num finalAmount;
  final String amountLabel;
  final String jobStatus;

  factory UpcomingJobModel.fromJson(Map<String, dynamic> json) {
    return UpcomingJobModel(
      bookingId: _toInt(json['bookingId']),
      customerName: _toString(json['customerName'], fallback: 'Customer'),
      serviceName: _toString(
        json['serviceName'],
        fallback: _toString(json['serviceType'], fallback: 'Service'),
      ),
      serviceType: _toString(json['serviceType'], fallback: 'Service'),
      helperName: _toString(json['helperName'], fallback: 'Helper Assigned'),
      helperRating: _toDouble(json['helperRating']),
      bookingDate: _toString(json['bookingDate']),
      startTime: _toString(json['startTime']),
      endTime: _toString(json['endTime']),
      dayLabel: _toString(json['dayLabel']),
      timeLabel: _toString(json['timeLabel']),
      duration: _toInt(json['duration']),
      durationLabel: _toString(json['durationLabel']),
      address: _toString(json['address'], fallback: '—'),
      latitude: _toNullableDouble(json['latitude']),
      longitude: _toNullableDouble(json['longitude']),
      finalAmount: _toNum(json['finalAmount']),
      amountLabel: _toString(json['amountLabel']),
      jobStatus: _toString(json['jobStatus']),
    );
  }

  String get displaySchedule {
    final parts = <String>[];
    if (dayLabel.trim().isNotEmpty) parts.add(dayLabel.trim());
    if (timeLabel.trim().isNotEmpty) parts.add(timeLabel.trim());
    return parts.isEmpty ? '—' : parts.join(' • ');
  }

  String get displayDuration {
    if (durationLabel.trim().isNotEmpty) return durationLabel;
    return duration > 0 ? '$duration hours' : '—';
  }

  String get displayAmount {
    if (amountLabel.trim().isNotEmpty) return amountLabel;
    if (finalAmount % 1 == 0) return '₹${finalAmount.toInt()}';
    return '₹${finalAmount.toStringAsFixed(2)}';
  }

  String get displayRating {
    return helperRating % 1 == 0
        ? helperRating.toStringAsFixed(0)
        : helperRating.toStringAsFixed(1);
  }
}

class UpcomingJobsApiResponse {
  const UpcomingJobsApiResponse({
    required this.success,
    required this.jobs,
    required this.totalUpcomingJobs,
    required this.todayJobsCount,
    required this.message,
  });

  final bool success;
  final List<UpcomingJobModel> jobs;
  final int totalUpcomingJobs;
  final int todayJobsCount;
  final String? message;

  factory UpcomingJobsApiResponse.fromJson(Map<String, dynamic> json) {
    final rawList =
        (json['data'] as List<dynamic>?) ??
        (json['bookings'] as List<dynamic>?) ??
        const <dynamic>[];
    final parsedJobs = rawList
        .whereType<Map<String, dynamic>>()
        .map(UpcomingJobModel.fromJson)
        .toList();

    return UpcomingJobsApiResponse(
      success: json['success'] == true,
      jobs: parsedJobs,
      totalUpcomingJobs: _toInt(json['totalUpcomingJobs']) > 0
          ? _toInt(json['totalUpcomingJobs'])
          : parsedJobs.length,
      todayJobsCount: _toInt(json['todayJobsCount']),
      message: json['message']?.toString(),
    );
  }
}

String _toString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.trim().isEmpty ? fallback : text;
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

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
