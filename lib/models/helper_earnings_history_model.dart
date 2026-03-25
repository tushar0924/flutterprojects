class HelperEarningsHistoryItem {
  const HelperEarningsHistoryItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.title,
    required this.status,
    required this.date,
  });

  final String id;
  final String type;
  final num amount;
  final String title;
  final String status;
  final String date;

  factory HelperEarningsHistoryItem.fromJson(Map<String, dynamic> json) {
    return HelperEarningsHistoryItem(
      id: _toString(json['id']),
      type: _toString(json['type'], fallback: 'CREDIT'),
      amount: _toNum(json['amount']),
      title: _toString(json['title'], fallback: 'Transaction'),
      status: _toString(json['status'], fallback: 'COMPLETED'),
      date: _toString(json['date'], fallback: '-'),
    );
  }
}

class HelperEarningsHistoryResponse {
  const HelperEarningsHistoryResponse({
    required this.success,
    required this.items,
    required this.message,
  });

  final bool success;
  final List<HelperEarningsHistoryItem> items;
  final String? message;

  factory HelperEarningsHistoryResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['data'] as List<dynamic>?) ?? const <dynamic>[];

    return HelperEarningsHistoryResponse(
      success: json['success'] == true,
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(HelperEarningsHistoryItem.fromJson)
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

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
