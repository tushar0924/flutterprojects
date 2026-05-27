class BookingDetailsModel {
  const BookingDetailsModel({
    required this.id,
    required this.status,
    required this.jobState,
    required this.displayState,
    required this.date,
    required this.time,
    required this.durationLabel,
    required this.category,
    required this.services,
    required this.customer,
    required this.helper,
    required this.location,
    required this.payment,
    required this.payout,
    required this.timeline,
    required this.paymentWaiting,
    required this.actions,
    required this.contactUnlocked,
    required this.displayBadge,
    required this.lateStatus,
    required this.paymentBreakdown,
    required this.hasServiceDetails,
  });

  final int id;
  final String status;
  final String jobState;
  final String displayState;
  final String date;
  final String time;
  final String durationLabel;
  final BookingCategory category;
  final List<BookingService> services;
  final BookingCustomer customer;
  final BookingHelper helper;
  final BookingLocation location;
  final BookingPayment payment;
  final BookingPayout payout;
  final BookingTimeline timeline;
  final PaymentWaiting paymentWaiting;
  final BookingActions actions;
  final bool contactUnlocked;
  final DisplayBadge displayBadge;
  final LateStatus lateStatus;
  final PaymentBreakdown paymentBreakdown;
  final bool hasServiceDetails;

  factory BookingDetailsModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailsModel(
      id: _toInt(json['id']),
      status: _toString(json['status']),
      jobState: _toString(json['jobState']),
      displayState: _toString(json['displayState']),
      date: _toString(json['date']),
      time: _toString(json['time']),
      durationLabel: _toString(json['durationLabel']),
      category: BookingCategory.fromJson(_toMap(json['category'])),
      services: _toListOfMaps(
        json['services'],
      ).map(BookingService.fromJson).toList(),
      customer: BookingCustomer.fromJson(_toMap(json['customer'])),
      helper: BookingHelper.fromJson(_toMap(json['helper'])),
      location: BookingLocation.fromJson(_toMap(json['location'])),
      payment: BookingPayment.fromJson(_toMap(json['payment'])),
      payout: BookingPayout.fromJson(_toMap(json['payout'])),
      timeline: BookingTimeline.fromJson(_toMap(json['timeline'])),
      paymentWaiting: PaymentWaiting.fromJson(_toMap(json['paymentWaiting'])),
      actions: BookingActions.fromJson(_toMap(json['actions'])),
      contactUnlocked: json['contactUnlocked'] == true,
      displayBadge: DisplayBadge.fromJson(_toMap(json['displayBadge'])),
      lateStatus: LateStatus.fromJson(_toMap(json['lateStatus'])),
      paymentBreakdown: PaymentBreakdown.fromJson(
        _toMap(json['paymentBreakdown']),
      ),
      hasServiceDetails: json['hasServiceDetails'] == true,
    );
  }

  bool get isPaymentPending {
    final normalizedStatus = status.toUpperCase();
    final normalizedJobState = jobState.toUpperCase();
    final normalizedDisplayState = displayState.toUpperCase();

    return normalizedStatus == 'PENDING_PAYMENT' ||
        normalizedJobState == 'PAYMENT_PENDING' ||
        normalizedDisplayState == 'PAYMENT_PENDING';
  }
}

class BookingCategory {
  const BookingCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory BookingCategory.fromJson(Map<String, dynamic> json) {
    return BookingCategory(
      id: _toInt(json['id']),
      name: _toString(json['name']),
    );
  }
}

class BookingService {
  const BookingService({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unitDurationLabel,
    required this.totalDurationLabel,
    required this.included,
    required this.notIncluded,
    required this.requirements,
  });

  final int id;
  final String name;
  final num price;
  final int quantity;
  final String unitDurationLabel;
  final String totalDurationLabel;
  final List<String> included;
  final List<String> notIncluded;
  final List<String> requirements;

  factory BookingService.fromJson(Map<String, dynamic> json) {
    return BookingService(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      price: _toNum(json['price']),
      quantity: _toInt(json['quantity']),
      unitDurationLabel: _toString(json['unitDurationLabel']),
      totalDurationLabel: _toString(json['totalDurationLabel']),
      included: _toStringList(json['included']),
      notIncluded: _toStringList(json['notIncluded']),
      requirements: _toStringList(json['requirements']),
    );
  }
}

class BookingCustomer {
  const BookingCustomer({
    required this.id,
    required this.name,
    required this.phone,
  });

  final int id;
  final String name;
  final String phone;

  factory BookingCustomer.fromJson(Map<String, dynamic> json) {
    return BookingCustomer(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      phone: _toString(json['phone']),
    );
  }
}

class BookingHelper {
  const BookingHelper({
    required this.id,
    required this.name,
    required this.rating,
  });

  final int id;
  final String name;
  final double rating;

  factory BookingHelper.fromJson(Map<String, dynamic> json) {
    return BookingHelper(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      rating: _toDouble(json['rating']),
    );
  }
}

class BookingLocation {
  const BookingLocation({
    required this.short,
    required this.full,
    required this.latitude,
    required this.longitude,
    required this.navigationUrl,
  });

  final String short;
  final String full;
  final double latitude;
  final double longitude;
  final String navigationUrl;

  factory BookingLocation.fromJson(Map<String, dynamic> json) {
    return BookingLocation(
      short: _toString(json['short']),
      full: _toString(json['full']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      navigationUrl: _toString(json['navigationUrl']),
    );
  }
}

class BookingPayment {
  const BookingPayment({
    required this.amount,
    required this.status,
    required this.method,
    required this.displayMethod,
    required this.isPaid,
  });

  final num amount;
  final String status;
  final String method;
  final String displayMethod;
  final bool isPaid;

  factory BookingPayment.fromJson(Map<String, dynamic> json) {
    return BookingPayment(
      amount: _toNum(json['amount']),
      status: _toString(json['status']),
      method: _toString(json['method']),
      displayMethod: _toString(json['displayMethod']),
      isPaid: json['isPaid'] == true,
    );
  }
}

class BookingPayout {
  const BookingPayout({
    required this.status,
    required this.amount,
    required this.commission,
  });

  final String status;
  final num amount;
  final num commission;

  factory BookingPayout.fromJson(Map<String, dynamic> json) {
    return BookingPayout(
      status: _toString(json['status']),
      amount: _toNum(json['amount']),
      commission: _toNum(json['commission']),
    );
  }
}

class BookingTimeline {
  const BookingTimeline({
    required this.createdAt,
    required this.scheduledAt,
    required this.startedAt,
    required this.completedAt,
  });

  final String createdAt;
  final String scheduledAt;
  final String startedAt;
  final String completedAt;

  factory BookingTimeline.fromJson(Map<String, dynamic> json) {
    return BookingTimeline(
      createdAt: _toString(json['createdAt']),
      scheduledAt: _toString(json['scheduledAt']),
      startedAt: _toString(json['startedAt']),
      completedAt: _toString(json['completedAt']),
    );
  }
}

class PaymentWaiting {
  const PaymentWaiting({
    required this.show,
    required this.reason,
    required this.remainingMinutes,
  });

  final bool show;
  final String reason;
  final int remainingMinutes;

  factory PaymentWaiting.fromJson(Map<String, dynamic> json) {
    return PaymentWaiting(
      show: json['show'] == true,
      reason: _toString(json['reason']),
      remainingMinutes: _toInt(json['remainingMinutes']),
    );
  }
}

class BookingActions {
  const BookingActions({
    required this.canStart,
    required this.canReportIssue,
    required this.canCallCustomer,
    required this.canChatCustomer,
    required this.canNavigate,
  });

  final bool canStart;
  final bool canReportIssue;
  final bool canCallCustomer;
  final bool canChatCustomer;
  final bool canNavigate;

  factory BookingActions.fromJson(Map<String, dynamic> json) {
    return BookingActions(
      canStart: json['canStart'] == true,
      canReportIssue: json['canReportIssue'] == true,
      canCallCustomer: json['canCallCustomer'] == true,
      canChatCustomer: json['canChatCustomer'] == true,
      canNavigate: json['canNavigate'] == true,
    );
  }
}

class DisplayBadge {
  const DisplayBadge({required this.text, required this.color});

  final String text;
  final String color;

  factory DisplayBadge.fromJson(Map<String, dynamic> json) {
    return DisplayBadge(
      text: _toString(json['text']),
      color: _toString(json['color']),
    );
  }
}

class LateStatus {
  const LateStatus({required this.isLate, required this.minutesLate});

  final bool isLate;
  final int minutesLate;

  factory LateStatus.fromJson(Map<String, dynamic> json) {
    return LateStatus(
      isLate: json['isLate'] == true,
      minutesLate: _toInt(json['minutesLate']),
    );
  }
}

class PaymentBreakdown {
  const PaymentBreakdown({
    required this.subtotal,
    required this.platformFee,
    required this.tax,
    required this.total,
  });

  final num subtotal;
  final num platformFee;
  final num tax;
  final num total;

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdown(
      subtotal: _toNum(json['subtotal']),
      platformFee: _toNum(json['platformFee']),
      tax: _toNum(json['tax']),
      total: _toNum(json['total']),
    );
  }
}

String _toString(dynamic value) {
  if (value == null) return '';
  final text = value.toString().trim();
  return text.isEmpty ? '' : text;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _toListOfMaps(dynamic value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return const <Map<String, dynamic>>[];
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString() ?? '')
        .where((text) => text.trim().isNotEmpty)
        .toList();
  }
  return const <String>[];
}
