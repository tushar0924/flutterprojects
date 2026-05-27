class JobHistoryModel {
  const JobHistoryModel({
    required this.bookingId,
    required this.customerName,
    required this.serviceType,
    required this.status,
    required this.jobState,
    required this.displayState,
    required this.rating,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.durationLabel,
    required this.address,
    required this.fullAddress,
    required this.amount,
    required this.earnings,
    required this.customerPhone,
    required this.helperName,
    required this.serviceNames,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.isPaid,
    required this.hasServiceDetails,
  });

  final int bookingId;
  final String customerName;
  final String serviceType;
  final String status;
  final String jobState;
  final String displayState;
  final double rating;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String durationLabel;
  final String address;
  final String fullAddress;
  final num amount;
  final num earnings;
  final String customerPhone;
  final String helperName;
  final List<String> serviceNames;
  final String paymentStatus;
  final String paymentMethod;
  final bool isPaid;
  final bool hasServiceDetails;

  factory JobHistoryModel.fromJson(Map<String, dynamic> json) {
    final customer = _toMap(json['customer']);
    final helper = _toMap(json['helper']);
    final category = _toMap(json['category']);
    final location = _toMap(json['location']);
    final payment = _toMap(json['payment']);
    final paymentBreakdown = _toMap(json['paymentBreakdown']);
    final serviceNames = _toListOfMaps(json['services'])
        .map((item) => _toString(item['name']))
        .where((name) => name.isNotEmpty)
        .toList();

    return JobHistoryModel(
      bookingId: _toInt(json['bookingId'] ?? json['id']),
      customerName: _toString(
        customer['name'] ?? json['customerName'] ?? json['name'] ?? json['userName'],
        fallback: 'Customer',
      ),
      serviceType: _toString(
        category['name'] ??
            json['serviceType'] ??
            json['serviceName'] ??
            json['workType'] ??
            (serviceNames.isNotEmpty ? serviceNames.first : null),
        fallback: '',
      ),
      status: _toString(
        json['displayState'] ?? json['status'] ?? json['jobStatus'] ?? json['jobState'],
      ),
      jobState: _toString(json['jobState']),
      displayState: _toString(json['displayState']),
      rating: _toDouble(
        helper['rating'] ?? json['helperRating'] ?? json['rating'],
      ),
      bookingDate: _toString(
        json['dateLabel'] ?? json['bookingDate'] ?? json['date'],
      ),
      startTime: _toString(
        json['timeLabel'] ?? json['startTime'] ?? json['time'],
      ),
      endTime: _toString(json['endTime']),
      durationLabel: _toString(json['durationLabel']),
      address: _toString(
        location['short'] ?? location['full'] ?? json['address'],
      ),
      fullAddress: _toString(location['full']),
      amount: _toNum(
        payment['amount'] ??
            paymentBreakdown['finalPayable'] ??
            json['finalAmount'] ??
            json['amount'] ??
            json['price'] ??
            json['fee'],
      ),
      earnings: _toNum(json['earnings']),
      customerPhone: _toString(customer['phone']),
      helperName: _toString(helper['name']),
      serviceNames: serviceNames,
      paymentStatus: _toString(payment['status']),
      paymentMethod: _toString(payment['method']),
      isPaid: payment['isPaid'] == true,
      hasServiceDetails: json['hasServiceDetails'] == true,
    );
  }

  bool get hasRating => rating > 0;

  bool get hasAddress => address.trim().isNotEmpty;

  String get displayStatus {
    final source = displayState.trim().isNotEmpty
        ? displayState
        : (status.trim().isNotEmpty ? status : jobState);
    return source;
  }

  String get displayRating {
    return rating % 1 == 0 ? rating.toStringAsFixed(0) : rating.toStringAsFixed(1);
  }

  String get displaySchedule {
    final date = bookingDate.trim();
    final start = startTime.trim();
    final end = endTime.trim();
    final duration = durationLabel.trim();

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
    if (start.isNotEmpty && duration.isNotEmpty) {
      return '$start · $duration';
    }
    if (start.isNotEmpty) return start;
    if (duration.isNotEmpty) return duration;
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
    required this.pagination,
    required this.message,
  });

  final bool success;
  final List<JobHistoryModel> jobs;
  final JobHistoryPagination pagination;
  final String? message;

  factory JobHistoryApiResponse.fromJson(Map<String, dynamic> json) {
    final payload = _toMap(json['data']).isNotEmpty ? _toMap(json['data']) : json;
    final rawList =
        (payload['data'] as List<dynamic>?) ??
        (payload['bookings'] as List<dynamic>?) ??
        (payload['history'] as List<dynamic>?) ??
        const <dynamic>[];
    final pagination = JobHistoryPagination.fromJson(
      _toMap(payload['pagination']).isNotEmpty
          ? _toMap(payload['pagination'])
          : _toMap(json['pagination']),
    );

    return JobHistoryApiResponse(
      success: payload['success'] == true || json['success'] == true,
      jobs: rawList
          .whereType<Map<String, dynamic>>()
          .map(JobHistoryModel.fromJson)
          .toList(),
      pagination: pagination,
      message: (payload['message'] ?? json['message'])?.toString(),
    );
  }
}

class JobHistoryPagination {
  const JobHistoryPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory JobHistoryPagination.fromJson(Map<String, dynamic> json) {
    return JobHistoryPagination(
      page: _toInt(json['page']),
      limit: _toInt(json['limit']),
      total: _toInt(json['total']),
      totalPages: _toInt(json['totalPages']),
    );
  }

  bool get hasNextPage {
    if (page <= 0 || totalPages <= 0) return false;
    return page < totalPages;
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

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _toListOfMaps(dynamic value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return const <Map<String, dynamic>>[];
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
