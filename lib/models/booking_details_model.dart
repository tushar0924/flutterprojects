class BookingDetailsModel {
  final int id;
  final int customerId;
  final int serviceId;
  final int servicePlanId;
  final int helperId;
  final String? reservedHelperId;
  final DateTime? reservedAt;
  final DateTime bookingDate;
  final DateTime startTime;
  final DateTime endTime;
  final int duration;
  final int totalHours;
  final DateTime paymentExpiresAt;
  final String status;
  final String location;
  final String address;
  final String city;
  final String pinCode;
  final double latitude;
  final double longitude;
  final String? notes;
  final String? specialRequirements;
  final String? startOtp;
  final DateTime? otpGeneratedAt;
  final int otpAttempts;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? completedAt;
  final bool jobTimerStarted;
  final DateTime? jobStartedAt;
  final String? cancelReason;
  final String? cancelledBy;
  final String? refundAmount;
  final DateTime? refundedAt;
  final double totalAmount;
  final double platformFee;
  final double tax;
  final double finalAmount;
  final String payoutStatus;
  final DateTime? payoutEligibleAt;
  final String? payoutId;
  final DateTime? payoutAt;
  final int retryCount;
  final DateTime? lastRetryAt;
  final DateTime? nextRetryAt;
  final double commissionRateSnapshot;
  final double platformCommissionAmount;
  final double helperPayoutAmount;
  final String bookingRequestId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ServiceDetail? service;
  final HelperDetail? helper;
  final CustomerDetail? customer;
  final PaymentDetail? payment;
  final double rating;
  final String formattedDate;
  final String formattedTime;
  final String fullAddress;
  final String serviceDisplayName;

  BookingDetailsModel({
    required this.id,
    required this.customerId,
    required this.serviceId,
    required this.servicePlanId,
    required this.helperId,
    this.reservedHelperId,
    this.reservedAt,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.totalHours,
    required this.paymentExpiresAt,
    required this.status,
    required this.location,
    required this.address,
    required this.city,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.specialRequirements,
    this.startOtp,
    this.otpGeneratedAt,
    required this.otpAttempts,
    this.startedAt,
    this.endedAt,
    this.completedAt,
    required this.jobTimerStarted,
    this.jobStartedAt,
    this.cancelReason,
    this.cancelledBy,
    this.refundAmount,
    this.refundedAt,
    required this.totalAmount,
    required this.platformFee,
    required this.tax,
    required this.finalAmount,
    required this.payoutStatus,
    this.payoutEligibleAt,
    this.payoutId,
    this.payoutAt,
    required this.retryCount,
    this.lastRetryAt,
    this.nextRetryAt,
    required this.commissionRateSnapshot,
    required this.platformCommissionAmount,
    required this.helperPayoutAmount,
    required this.bookingRequestId,
    required this.createdAt,
    required this.updatedAt,
    this.service,
    this.helper,
    this.customer,
    this.payment,
    required this.rating,
    required this.formattedDate,
    required this.formattedTime,
    required this.fullAddress,
    required this.serviceDisplayName,
  });

  factory BookingDetailsModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailsModel(
      id: json['id'] ?? 0,
      customerId: json['customerId'] ?? 0,
      serviceId: json['serviceId'] ?? 0,
      servicePlanId: json['servicePlanId'] ?? 0,
      helperId: json['helperId'] ?? 0,
      reservedHelperId: json['reservedHelperId'],
      reservedAt: json['reservedAt'] != null
          ? DateTime.parse(json['reservedAt'])
          : null,
      bookingDate: json['bookingDate'] != null
          ? DateTime.parse(json['bookingDate'])
          : DateTime.now(),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : DateTime.now(),
      duration: json['duration'] ?? 0,
      totalHours: json['totalHours'] ?? 0,
      paymentExpiresAt: json['paymentExpiresAt'] != null
          ? DateTime.parse(json['paymentExpiresAt'])
          : DateTime.now(),
      status: json['status'] ?? '',
      location: json['location'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      pinCode: json['pinCode'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
      specialRequirements: json['specialRequirements'],
      startOtp: json['startOtp'],
      otpGeneratedAt: json['otpGeneratedAt'] != null
          ? DateTime.parse(json['otpGeneratedAt'])
          : null,
      otpAttempts: json['otpAttempts'] ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      jobTimerStarted: json['jobTimerStarted'] ?? false,
      jobStartedAt: json['jobStartedAt'] != null
          ? DateTime.parse(json['jobStartedAt'])
          : null,
      cancelReason: json['cancelReason'],
      cancelledBy: json['cancelledBy'],
      refundAmount: json['refundAmount'],
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'])
          : null,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      payoutStatus: json['payoutStatus'] ?? '',
      payoutEligibleAt: json['payoutEligibleAt'] != null
          ? DateTime.parse(json['payoutEligibleAt'])
          : null,
      payoutId: json['payoutId'],
      payoutAt: json['payoutAt'] != null
          ? DateTime.parse(json['payoutAt'])
          : null,
      retryCount: json['retryCount'] ?? 0,
      lastRetryAt: json['lastRetryAt'] != null
          ? DateTime.parse(json['lastRetryAt'])
          : null,
      nextRetryAt: json['nextRetryAt'] != null
          ? DateTime.parse(json['nextRetryAt'])
          : null,
      commissionRateSnapshot:
          (json['commissionRateSnapshot'] as num?)?.toDouble() ?? 0.0,
      platformCommissionAmount:
          (json['platformCommissionAmount'] as num?)?.toDouble() ?? 0.0,
      helperPayoutAmount:
          (json['helperPayoutAmount'] as num?)?.toDouble() ?? 0.0,
      bookingRequestId: json['bookingRequestId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      service: json['service'] != null
          ? ServiceDetail.fromJson(json['service'])
          : null,
      helper: json['helper'] != null
          ? HelperDetail.fromJson(json['helper'])
          : null,
      customer: json['customer'] != null
          ? CustomerDetail.fromJson(json['customer'])
          : null,
      payment: json['payment'] != null
          ? PaymentDetail.fromJson(json['payment'])
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      formattedDate: json['formattedDate'] ?? '',
      formattedTime: json['formattedTime'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
      serviceDisplayName: json['serviceDisplayName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'serviceId': serviceId,
      'servicePlanId': servicePlanId,
      'helperId': helperId,
      'reservedHelperId': reservedHelperId,
      'reservedAt': reservedAt?.toIso8601String(),
      'bookingDate': bookingDate.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration,
      'totalHours': totalHours,
      'paymentExpiresAt': paymentExpiresAt.toIso8601String(),
      'status': status,
      'location': location,
      'address': address,
      'city': city,
      'pinCode': pinCode,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'specialRequirements': specialRequirements,
      'startOtp': startOtp,
      'otpGeneratedAt': otpGeneratedAt?.toIso8601String(),
      'otpAttempts': otpAttempts,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'jobTimerStarted': jobTimerStarted,
      'jobStartedAt': jobStartedAt?.toIso8601String(),
      'cancelReason': cancelReason,
      'cancelledBy': cancelledBy,
      'refundAmount': refundAmount,
      'refundedAt': refundedAt?.toIso8601String(),
      'totalAmount': totalAmount,
      'platformFee': platformFee,
      'tax': tax,
      'finalAmount': finalAmount,
      'payoutStatus': payoutStatus,
      'payoutEligibleAt': payoutEligibleAt?.toIso8601String(),
      'payoutId': payoutId,
      'payoutAt': payoutAt?.toIso8601String(),
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
      'nextRetryAt': nextRetryAt?.toIso8601String(),
      'commissionRateSnapshot': commissionRateSnapshot,
      'platformCommissionAmount': platformCommissionAmount,
      'helperPayoutAmount': helperPayoutAmount,
      'bookingRequestId': bookingRequestId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'service': service?.toJson(),
      'helper': helper?.toJson(),
      'customer': customer?.toJson(),
      'payment': payment?.toJson(),
      'rating': rating,
      'formattedDate': formattedDate,
      'formattedTime': formattedTime,
      'fullAddress': fullAddress,
      'serviceDisplayName': serviceDisplayName,
    };
  }
}

class ServiceDetail {
  final int id;
  final String name;

  ServiceDetail({required this.id, required this.name});

  factory ServiceDetail.fromJson(Map<String, dynamic> json) {
    return ServiceDetail(id: json['id'] ?? 0, name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class HelperDetail {
  final int id;
  final int userId;
  final double rating;
  final UserDetail? user;

  HelperDetail({
    required this.id,
    required this.userId,
    required this.rating,
    this.user,
  });

  factory HelperDetail.fromJson(Map<String, dynamic> json) {
    return HelperDetail(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      user: json['user'] != null ? UserDetail.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'rating': rating,
      'user': user?.toJson(),
    };
  }
}

class UserDetail {
  final String fullName;

  UserDetail({required this.fullName});

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(fullName: json['fullName'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'fullName': fullName};
  }
}

class CustomerDetail {
  final int id;
  final String fullName;
  final String phone;

  CustomerDetail({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'fullName': fullName, 'phone': phone};
  }
}

class PaymentDetail {
  final int id;
  final int bookingId;
  final double amount;
  final String status;
  final String? transactionId;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String escrowStatus;
  final String? refundReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentDetail({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    this.transactionId,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.escrowStatus,
    this.refundReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      id: json['id'] ?? 0,
      bookingId: json['bookingId'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      transactionId: json['transactionId'],
      razorpayOrderId: json['razorpayOrderId'],
      razorpayPaymentId: json['razorpayPaymentId'],
      escrowStatus: json['escrowStatus'] ?? '',
      refundReason: json['refundReason'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amount': amount,
      'status': status,
      'transactionId': transactionId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'escrowStatus': escrowStatus,
      'refundReason': refundReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
