class UpcomingJobModel {
  const UpcomingJobModel({
    required this.id,
    required this.status,
    required this.workflowState,
    required this.jobState,
    required this.displayState,
    required this.date,
    required this.time,
    required this.duration,
    required this.category,
    required this.services,
    required this.customer,
    required this.helper,
    required this.location,
    required this.payment,
    required this.payout,
    required this.timeline,
  });

  final int id;
  final String status; // CONFIRMED, PENDING, etc.
  final String workflowState;
  final String jobState; // UPCOMING, ACTIVE, COMPLETED, etc.
  final String
  displayState; // Presentation state from API (e.g. TODAY, TOMORROW)
  final String date; // "Friday, May 29, 2026"
  final String time; // "04:00 PM"
  final String duration; // "2 hours"
  final JobCategory category;
  final List<JobService> services;
  final JobCustomer customer;
  final JobHelper helper;
  final JobLocation location;
  final JobPayment payment;
  final JobPayout payout;
  final JobTimeline timeline;

  factory UpcomingJobModel.fromJson(Map<String, dynamic> json) {
    return UpcomingJobModel(
      id: _toInt(json['id']),
      status: _toString(json['status'], fallback: 'PENDING'),
      workflowState: _toString(json['workflowState']),
      jobState: _toString(json['jobState'], fallback: 'UPCOMING'),
      displayState: _toString(
        json['displayState'] ?? json['jobState'],
        fallback: '',
      ),
      date: _toString(json['date']),
      time: _toString(json['time']),
      // API may return `durationLabel`; prefer it when available for UI display.
      duration: _toString(json['durationLabel'] ?? json['duration']),
      category: JobCategory.fromJson(
        json['category'] as Map<String, dynamic>? ?? {},
      ),
      services: _parseServices(json['services']),
      customer: JobCustomer.fromJson(
        json['customer'] as Map<String, dynamic>? ?? {},
      ),
      helper: JobHelper.fromJson(json['helper'] as Map<String, dynamic>? ?? {}),
      location: JobLocation.fromJson(
        json['location'] as Map<String, dynamic>? ?? {},
      ),
      payment: JobPayment.fromJson(
        json['payment'] as Map<String, dynamic>? ?? {},
      ),
      payout: JobPayout.fromJson(json['payout'] as Map<String, dynamic>? ?? {}),
      timeline: JobTimeline.fromJson(
        json['timeline'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  // Compatibility getters for existing UI
  int get bookingId => id;
  String get customerName => customer.name;
  String get serviceName => services.isNotEmpty ? services.first.name : '—';
  String get serviceType => category.name;
  String get helperName => helper.name;
  double get helperRating => helper.rating;
  String get dayLabel => date;
  String get timeLabel => time;
  String get durationLabel => duration;
  String get address => location.full;
  double? get latitude => location.latitude;
  double? get longitude => location.longitude;
  num get finalAmount => payment.amount;
  String get amountLabel => '₹${payment.amount.toInt()}';
  String get jobStatus => status;

  String get displaySchedule {
    return '$date • $time';
  }

  String get displayDuration => duration;

  String get displayAddress => location.full.isNotEmpty ? location.full : location.short;

  String get displayAmount => amountLabel;

  String get displayRating {
    return helperRating % 1 == 0
        ? helperRating.toStringAsFixed(0)
        : helperRating.toStringAsFixed(1);
  }
}

class JobCategory {
  const JobCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory JobCategory.fromJson(Map<String, dynamic> json) {
    return JobCategory(
      id: _toInt(json['id']),
      name: _toString(json['name'], fallback: 'Service'),
    );
  }
}

class JobService {
  const JobService({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  final int id;
  final String name;
  final num price;
  final int quantity;

  factory JobService.fromJson(Map<String, dynamic> json) {
    return JobService(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      price: _toNum(json['price']),
      quantity: _toInt(json['quantity']),
    );
  }
}

class JobCustomer {
  const JobCustomer({
    required this.id,
    required this.name,
    required this.phone,
  });

  final int id;
  final String name;
  final String phone;

  factory JobCustomer.fromJson(Map<String, dynamic> json) {
    return JobCustomer(
      id: _toInt(json['id']),
      name: _toString(json['name'], fallback: 'Customer'),
      phone: _toString(json['phone']),
    );
  }
}

class JobHelper {
  const JobHelper({required this.id, required this.name, required this.rating});

  final int id;
  final String name;
  final double rating;

  factory JobHelper.fromJson(Map<String, dynamic> json) {
    return JobHelper(
      id: _toInt(json['id']),
      name: _toString(json['name'], fallback: 'Helper Assigned'),
      rating: _toDouble(json['rating']),
    );
  }
}

class JobLocation {
  const JobLocation({
    required this.full,
    required this.short,
    required this.latitude,
    required this.longitude,
  });

  final String full;
  final String short;
  final double? latitude;
  final double? longitude;

  factory JobLocation.fromJson(Map<String, dynamic> json) {
    return JobLocation(
      full: _toString(json['full'], fallback: '—'),
      short: _toString(json['short'], fallback: '—'),
      latitude: _toNullableDouble(json['latitude']),
      longitude: _toNullableDouble(json['longitude']),
    );
  }
}

class JobPayment {
  const JobPayment({
    required this.amount,
    required this.status,
    required this.method,
    required this.paymentId,
    required this.orderId,
    required this.isPaid,
  });

  final num amount;
  final String status;
  final String method;
  final String? paymentId;
  final String orderId;
  final bool isPaid;

  factory JobPayment.fromJson(Map<String, dynamic> json) {
    return JobPayment(
      amount: _toNum(json['amount']),
      status: _toString(json['status'], fallback: 'PENDING'),
      method: _toString(json['method']),
      paymentId: json['paymentId']?.toString(),
      orderId: _toString(json['orderId']),
      isPaid: json['isPaid'] == true,
    );
  }
}

class JobPayout {
  const JobPayout({
    required this.status,
    required this.amount,
    required this.commission,
  });

  final String status;
  final num amount;
  final num commission;

  factory JobPayout.fromJson(Map<String, dynamic> json) {
    return JobPayout(
      status: _toString(json['status'], fallback: 'PENDING'),
      amount: _toNum(json['amount']),
      commission: _toNum(json['commission']),
    );
  }
}

class JobTimeline {
  const JobTimeline({
    required this.createdAt,
    required this.scheduledAt,
    required this.startedAt,
    required this.completedAt,
    required this.cancelledAt,
  });

  final String? createdAt;
  final String? scheduledAt;
  final String? startedAt;
  final String? completedAt;
  final String? cancelledAt;

  factory JobTimeline.fromJson(Map<String, dynamic> json) {
    return JobTimeline(
      createdAt: json['createdAt']?.toString(),
      scheduledAt: json['scheduledAt']?.toString(),
      startedAt: json['startedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      cancelledAt: json['cancelledAt']?.toString(),
    );
  }
}

class UpcomingJobsApiResponse {
  const UpcomingJobsApiResponse({
    required this.success,
    required this.jobs,
    required this.pagination,
    required this.message,
  });

  final bool success;
  final List<UpcomingJobModel> jobs;
  final PaginationInfo pagination;
  final String? message;

  // Compatibility getters
  int get totalUpcomingJobs => pagination.total;
  int get todayJobsCount => 0; // Not in new API, can be added if needed

  factory UpcomingJobsApiResponse.fromJson(Map<String, dynamic> json) {
    final rawList = (json['data'] as List<dynamic>?) ?? const <dynamic>[];
    final parsedJobs = rawList
        .whereType<Map<String, dynamic>>()
        .map(UpcomingJobModel.fromJson)
        .toList();

    final paginationData = json['pagination'] as Map<String, dynamic>? ?? {};

    return UpcomingJobsApiResponse(
      success: json['success'] == true,
      jobs: parsedJobs,
      pagination: PaginationInfo.fromJson(paginationData),
      message: json['message']?.toString(),
    );
  }
}

class PaginationInfo {
  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: _toInt(json['page']),
      limit: _toInt(json['limit']),
      total: _toInt(json['total']),
      totalPages: _toInt(json['totalPages']),
    );
  }
}

String _toString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.trim().isEmpty ? fallback : text;
}

List<JobService> _parseServices(dynamic value) {
  if (value is! List<dynamic>) return const <JobService>[];
  return value
      .whereType<Map<String, dynamic>>()
      .map(JobService.fromJson)
      .toList();
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
