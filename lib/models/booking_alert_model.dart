class BookingLocation {
  const BookingLocation({
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  factory BookingLocation.fromJson(Map<String, dynamic> json) {
    return BookingLocation(
      address: _readString(json['address'], fallback: ''),
      city: _readString(json['city'], fallback: ''),
      latitude: _readNullableDouble(json['latitude']),
      longitude: _readNullableDouble(json['longitude']),
      distanceKm: _readNullableDouble(json['distanceKm']),
    );
  }

  String get displayLabel {
    final parts = <String>[];
    if (address.trim().isNotEmpty) parts.add(address.trim());
    if (city.trim().isNotEmpty) parts.add(city.trim());
    return parts.isEmpty ? 'Location not available' : parts.join(', ');
  }
}

class BookingAlertModel {
  const BookingAlertModel({
    required this.requestId,
    required this.bookingId,
    required this.serviceId,
    required this.totalAmount,
    required this.location,
    required this.requestedDate,
    required this.estimatedHours,
    required this.expiresAt,
    required this.acceptanceWindowSeconds,
    required this.customerName,
    required this.serviceName,
    required this.bookingCode,
    required this.startTime,
    required this.endTime,
  });

  final int requestId;
  final int bookingId;
  final int serviceId;
  final num totalAmount;
  final BookingLocation location;
  final DateTime? requestedDate;
  final int estimatedHours;
  final DateTime? expiresAt;
  final int acceptanceWindowSeconds;
  final String customerName;
  final String serviceName;
  final String bookingCode;
  final String startTime;
  final String endTime;

  factory BookingAlertModel.fromSocketPayload(dynamic payload) {
    final map = _readMap(payload);
    final payloadMap = _readMap(map['payload']);
    final source = payloadMap.isNotEmpty ? payloadMap : map;

    final customerMap = _readMap(source['customer']);
    final serviceMap = _readMap(source['service']);
    final earningsMap = _readMap(source['earnings']);
    final timingMap = _readMap(source['timing']);
    final locationMap = _readMap(source['location']);
    final metaMap = _readMap(source['meta']);

    final requestId = _readInt(source['requestId'] ?? source['booking_id']);
    final bookingId = _readInt(
      source['bookingId'] ?? source['id'] ?? requestId,
    );
    final serviceId = _readInt(
      source['serviceId'] ?? source['service_id'] ?? serviceMap['id'],
    );
    final totalAmount = _readNum(
      source['totalAmount'] ?? source['amount'] ?? earningsMap['amount'],
    );
    final requestedDate = _readDate(
      source['requestedDate'] ??
          source['bookingDate'] ??
          source['scheduledAt'] ??
          timingMap['date'],
    );
    final expiresAt = _readDate(source['expiresAt'] ?? source['expires_at']);
    final acceptanceWindowSeconds = _readInt(
      source['acceptanceWindowSeconds'] ??
          source['acceptance_window_seconds'] ??
          metaMap['expiresInSeconds'],
    );
    final serviceName = _firstString([
      source['serviceName'],
      source['serviceType'],
      source['title'],
      serviceMap['name'],
    ], fallback: serviceId > 0 ? 'Service #$serviceId' : 'New Service');
    final customerName = _firstString([
      source['customerName'],
      source['clientName'],
      source['userName'],
      source['name'],
      customerMap['name'],
    ], fallback: 'Customer');
    final bookingCode = _firstString([
      source['bookingCode'],
      source['reference'],
      source['code'],
    ], fallback: requestId > 0 ? 'Booking ID: $requestId' : 'Booking ID: —');

    final startTime = _firstString([
      source['startTime'],
      timingMap['startTime'],
    ], fallback: '');
    final endTime = _firstString([
      source['endTime'],
      timingMap['endTime'],
    ], fallback: '');

    return BookingAlertModel(
      requestId: requestId,
      bookingId: bookingId,
      serviceId: serviceId,
      totalAmount: totalAmount,
      location: BookingLocation.fromJson(locationMap),
      requestedDate: requestedDate,
      estimatedHours: _readInt(
        source['estimatedHours'] ??
            source['durationHours'] ??
            source['duration'] ??
            timingMap['durationHours'],
      ),
      expiresAt: expiresAt,
      acceptanceWindowSeconds: acceptanceWindowSeconds > 0
          ? acceptanceWindowSeconds
          : 30,
      customerName: customerName,
      serviceName: serviceName,
      bookingCode: bookingCode,
      startTime: startTime,
      endTime: endTime,
    );
  }

  int get countdownSeconds {
    final expiresAtValue = expiresAt;
    if (expiresAtValue != null) {
      final secondsLeft = expiresAtValue.difference(DateTime.now()).inSeconds;
      if (secondsLeft > 0) return secondsLeft;
    }
    return acceptanceWindowSeconds > 0 ? acceptanceWindowSeconds : 30;
  }

  String get amountLabel {
    if (totalAmount % 1 == 0) return '₹${totalAmount.toInt()}';
    return '₹${totalAmount.toStringAsFixed(2)}';
  }

  String get requestedDateLabel {
    final value = requestedDate;
    if (value == null) return 'Timing not shared yet';

    final day = _weekday(value.weekday);
    final date =
        '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
    final time = _timeLabel(value);
    return '$day, $date • $time';
  }

  String get durationLabel {
    if (estimatedHours <= 0) return '—';
    return estimatedHours == 1 ? '1 hour' : '$estimatedHours hours';
  }

  String get timingHeaderLabel {
    if (estimatedHours <= 0) return 'Per day';
    return 'Per day ($durationLabel)';
  }

  String get timingValueLabel {
    final range = timeRangeLabel;
    final dayDate = dayDateLabel;
    if (range.isEmpty && dayDate.isEmpty) return 'Timing not shared yet';
    if (range.isEmpty) return dayDate;
    if (dayDate.isEmpty) return range;
    return '$range   $dayDate';
  }

  String get timeRangeLabel {
    if (startTime.trim().isNotEmpty && endTime.trim().isNotEmpty) {
      return '${startTime.trim()} - ${endTime.trim()}';
    }
    if (startTime.trim().isNotEmpty) return startTime.trim();
    if (endTime.trim().isNotEmpty) return endTime.trim();
    return '';
  }

  String get dayDateLabel {
    final value = requestedDate;
    if (value == null) return '';
    final date =
        '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
    return '$date ${_weekday(value.weekday)}';
  }

  String get distanceLabel {
    final distance = location.distanceKm;
    if (distance == null) return '';
    return distance.toStringAsFixed(1);
  }

  String get footerLabel {
    final seconds = countdownSeconds;
    return 'Auto-rejected in ${seconds > 0 ? seconds : acceptanceWindowSeconds} seconds if no action';
  }
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _readString(dynamic value, {required String fallback}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _firstString(List<dynamic> values, {required String fallback}) {
  for (final value in values) {
    final text = _readString(value, fallback: '');
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _readNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String _weekday(int weekday) {
  const labels = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  if (weekday < 1 || weekday > labels.length) return 'Day';
  return labels[weekday - 1];
}

String _timeLabel(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
