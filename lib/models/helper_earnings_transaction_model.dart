class HelperEarningsTransactionDetail {
  const HelperEarningsTransactionDetail({
    required this.transactionId,
    required this.title,
    required this.amount,
    required this.status,
    required this.dateTime,
    required this.paymentMethod,
    required this.customerName,
    required this.serviceType,
    required this.bookingId,
    required this.serviceDate,
    required this.serviceAmount,
    required this.platformFee,
    required this.finalAmount,
    required this.note,
  });

  final String transactionId;
  final String title;
  final num amount;
  final String status;
  final String dateTime;
  final String paymentMethod;
  final String customerName;
  final String serviceType;
  final String bookingId;
  final String serviceDate;
  final num serviceAmount;
  final num platformFee;
  final num finalAmount;
  final String note;

  factory HelperEarningsTransactionDetail.fromJson(Map<String, dynamic> json) {
    final transaction = _map(json, const ['transaction', 'payment']);
    final service = _map(json, const ['service', 'booking']);
    final customer = _map(json, const ['customer', 'user']);
    final breakdown = _map(json, const ['breakdown', 'paymentBreakdown']);

    final amount = _numFrom(
      [
        json['amount'],
        json['finalAmount'],
        transaction['amount'],
      ],
    );

    final serviceAmount = _numFrom(
      [
        breakdown['serviceAmount'],
        json['serviceAmount'],
        json['amount'],
      ],
    );

    final platformFee = _numFrom(
      [
        breakdown['platformFee'],
        json['platformFee'],
      ],
    );

    final finalAmount = _numFrom(
      [
        breakdown['finalAmount'],
        json['finalAmount'],
        amount,
      ],
    );

    return HelperEarningsTransactionDetail(
      transactionId: _strFrom(
        [
          json['transactionId'],
          transaction['transactionId'],
          transaction['id'],
          json['id'],
        ],
        fallback: '-',
      ),
      title: _strFrom(
        [json['title'], json['type'], transaction['title']],
        fallback: 'Payment Received',
      ),
      amount: amount,
      status: _strFrom(
        [json['status'], transaction['status']],
        fallback: 'COMPLETED',
      ),
      dateTime: _strFrom(
        [
          json['dateTime'],
          json['date'],
          transaction['dateTime'],
          transaction['createdAt'],
        ],
        fallback: '-',
      ),
      paymentMethod: _strFrom(
        [
          json['paymentMethod'],
          transaction['paymentMethod'],
          transaction['method'],
        ],
        fallback: 'UPI Transfer',
      ),
      customerName: _strFrom(
        [json['customerName'], customer['name'], customer['fullName']],
        fallback: '-',
      ),
      serviceType: _strFrom(
        [json['serviceType'], service['serviceType'], service['name']],
        fallback: '-',
      ),
      bookingId: _strFrom(
        [json['bookingId'], service['bookingId'], service['id']],
        fallback: '-',
      ),
      serviceDate: _strFrom(
        [json['serviceDate'], service['serviceDate'], service['date']],
        fallback: '-',
      ),
      serviceAmount: serviceAmount,
      platformFee: platformFee,
      finalAmount: finalAmount,
      note: _strFrom(
        [json['note'], json['description'], transaction['note']],
        fallback:
            'Payment received for completed house cleaning service. Customer was satisfied with the service quality.',
      ),
    );
  }
}

class HelperEarningsTransactionResponse {
  const HelperEarningsTransactionResponse({
    required this.success,
    required this.detail,
    required this.message,
  });

  final bool success;
  final HelperEarningsTransactionDetail? detail;
  final String? message;

  factory HelperEarningsTransactionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final detail = data is Map<String, dynamic>
        ? HelperEarningsTransactionDetail.fromJson(data)
        : null;

    return HelperEarningsTransactionResponse(
      success: json['success'] == true,
      detail: detail,
      message: json['message']?.toString(),
    );
  }
}

Map<String, dynamic> _map(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is Map<String, dynamic>) return value;
  }
  return const <String, dynamic>{};
}

String _strFrom(List<dynamic> values, {String fallback = ''}) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

num _numFrom(List<dynamic> values) {
  for (final value in values) {
    if (value is num) return value;
    final parsed = num.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}
