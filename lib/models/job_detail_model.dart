class JobDetailResponse {
  final bool success;
  final JobDetailModel? data;
  final String? message;

  JobDetailResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory JobDetailResponse.fromJson(Map<String, dynamic> json) {
    return JobDetailResponse(
      success: json['success'] == true,
      data: json['data'] != null ? JobDetailModel.fromJson(json['data']) : null,
      message: json['message'] as String?,
    );
  }
}

class JobDetailModel {
  final int id;
  final String status;
  final String jobState;
  final String date;
  final String time;
  final String duration;
  final JobCategory category;
  final List<JobService> services;
  final JobCustomer customer;
  final JobHelper helper;
  final JobLocation location;
  final JobPayment payment;
  final JobPayout payout;
  final JobTimeline timeline;
  final dynamic arrival;

  JobDetailModel({
    required this.id,
    required this.status,
    required this.jobState,
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
    this.arrival,
  });

  factory JobDetailModel.fromJson(Map<String, dynamic> json) {
    return JobDetailModel(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      jobState: json['jobState'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      category: JobCategory.fromJson(json['category'] as Map<String, dynamic>? ?? {}),
      services: _parseServices(json['services']),
      customer: JobCustomer.fromJson(json['customer'] as Map<String, dynamic>? ?? {}),
      helper: JobHelper.fromJson(json['helper'] as Map<String, dynamic>? ?? {}),
      location: JobLocation.fromJson(json['location'] as Map<String, dynamic>? ?? {}),
      payment: JobPayment.fromJson(json['payment'] as Map<String, dynamic>? ?? {}),
      payout: JobPayout.fromJson(json['payout'] as Map<String, dynamic>? ?? {}),
      timeline: JobTimeline.fromJson(json['timeline'] as Map<String, dynamic>? ?? {}),
      arrival: json['arrival'],
    );
  }

  static List<JobService> _parseServices(dynamic servicesData) {
    if (servicesData is List) {
      return servicesData
          .whereType<Map<String, dynamic>>()
          .map(JobService.fromJson)
          .toList();
    }
    return [];
  }
}

class JobCategory {
  final int id;
  final String name;

  JobCategory({required this.id, required this.name});

  factory JobCategory.fromJson(Map<String, dynamic> json) {
    return JobCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class JobService {
  final int id;
  final String name;
  final int price;
  final int duration;
  final int totalDuration;
  final int quantity;
  final List<String> included;
  final List<String> notIncluded;
  final List<String> requirements;

  JobService({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.totalDuration,
    required this.quantity,
    required this.included,
    required this.notIncluded,
    required this.requirements,
  });

  factory JobService.fromJson(Map<String, dynamic> json) {
    return JobService(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      duration: json['unitDurationMinutes'] as int? ?? json['duration'] as int? ?? 0,
      totalDuration: json['totalDuration'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      included: _parseStringList(json['included']),
      notIncluded: _parseStringList(json['notIncluded']),
      requirements: _parseStringList(json['requirements']),
    );
  }

  static List<String> _parseStringList(dynamic data) {
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    return [];
  }
}

class JobCustomer {
  final int id;
  final String name;
  final String phone;

  JobCustomer({required this.id, required this.name, required this.phone});

  factory JobCustomer.fromJson(Map<String, dynamic> json) {
    return JobCustomer(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class JobHelper {
  final int id;
  final String name;
  final double rating;

  JobHelper({required this.id, required this.name, required this.rating});

  factory JobHelper.fromJson(Map<String, dynamic> json) {
    return JobHelper(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class JobLocation {
  final String short;
  final String full;
  final double latitude;
  final double longitude;

  JobLocation({
    required this.short,
    required this.full,
    required this.latitude,
    required this.longitude,
  });

  factory JobLocation.fromJson(Map<String, dynamic> json) {
    return JobLocation(
      short: json['short'] as String? ?? '',
      full: json['full'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class JobPayment {
  final int amount;
  final String status;
  final String? method;
  final String? paymentId;
  final String? orderId;
  final bool isPaid;

  JobPayment({
    required this.amount,
    required this.status,
    this.method,
    this.paymentId,
    this.orderId,
    required this.isPaid,
  });

  factory JobPayment.fromJson(Map<String, dynamic> json) {
    return JobPayment(
      amount: json['amount'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      method: json['method'] as String?,
      paymentId: json['paymentId'] as String?,
      orderId: json['orderId'] as String?,
      isPaid: json['isPaid'] == true,
    );
  }
}

class JobPayout {
  final String status;
  final double amount;
  final double commission;

  JobPayout({
    required this.status,
    required this.amount,
    required this.commission,
  });

  factory JobPayout.fromJson(Map<String, dynamic> json) {
    return JobPayout(
      status: json['status'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class JobTimeline {
  final String createdAt;
  final String scheduledAt;
  final String? startedAt;
  final String? completedAt;
  final String? cancelledAt;

  JobTimeline({
    required this.createdAt,
    required this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory JobTimeline.fromJson(Map<String, dynamic> json) {
    return JobTimeline(
      createdAt: json['createdAt'] as String? ?? '',
      scheduledAt: json['scheduledAt'] as String? ?? '',
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
    );
  }
}
