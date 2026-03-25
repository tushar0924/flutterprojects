import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/job_history_model.dart';
import '../../../providers/partner_provider.dart';

class JobHistoryDetailScreen extends ConsumerStatefulWidget {
  const JobHistoryDetailScreen({
    super.key,
    required this.summary,
  });

  final JobHistoryModel summary;

  @override
  ConsumerState<JobHistoryDetailScreen> createState() =>
      _JobHistoryDetailScreenState();
}

class _JobHistoryDetailScreenState extends ConsumerState<JobHistoryDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _detail = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(partnerRepositoryProvider);
      final response = await repo.getBookingDetail(widget.summary.bookingId);
      if (!mounted) return;

      setState(() {
        _detail = _extractPayload(response);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detail = const <String, dynamic>{};
        _error = 'Failed to load job details';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _extractPayload(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;

    final booking = response['booking'];
    if (booking is Map<String, dynamic>) return booking;

    return response;
  }

  String _getString(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = _detail[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String _getNestedString(List<String> path, {String fallback = ''}) {
    dynamic current = _detail;
    for (final segment in path) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return fallback;
      }
    }

    final text = current?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  num _getNum(List<String> keys, {num fallback = 0}) {
    for (final key in keys) {
      final value = _detail[key];
      if (value is num) return value;
      final parsed = num.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  double _getDouble(List<String> keys, {double fallback = 0}) {
    for (final key in keys) {
      final value = _detail[key];
      if (value is double) return value;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  String get _serviceType {
    final nestedServiceName = _getNestedString(const ['service', 'name']);
    return _getString(
      const ['serviceDisplayName', 'serviceName', 'serviceType', 'workType'],
      fallback: nestedServiceName.isNotEmpty
          ? nestedServiceName
          : widget.summary.serviceType,
    );
  }

  String get _bookingRef {
    return _getString(
      const ['bookingRequestId', 'bookingReference', 'bookingCode', 'referenceId', 'id'],
      fallback: widget.summary.bookingId.toString(),
    );
  }

  String get _statusRaw {
    return _getString(
      const ['status', 'jobStatus'],
      fallback: widget.summary.status,
    );
  }

  String get _statusText {
    final normalized = _statusRaw.trim().toUpperCase();
    if (normalized == 'COMPLETED') return 'Delivered';
    if (normalized == 'CANCELLED' || normalized == 'CANCELED') {
      return 'Cancelled';
    }
    if (normalized.isEmpty) return widget.summary.displayStatus;
    return _toTitleCase(normalized.toLowerCase());
  }

  Color get _statusBgColor {
    final normalized = _statusRaw.trim().toUpperCase();
    if (normalized == 'CANCELLED' || normalized == 'CANCELED') {
      return const Color(0xFFFEE4E2);
    }
    return const Color(0xFF0EA5E9);
  }

  Color get _statusTextColor {
    final normalized = _statusRaw.trim().toUpperCase();
    if (normalized == 'CANCELLED' || normalized == 'CANCELED') {
      return const Color(0xFFB42318);
    }
    return Colors.white;
  }

  String get _dateLabel {
    return _getString(
      const ['formattedDate', 'dateLabel', 'dayLabel', 'bookingDate', 'date'],
      fallback: widget.summary.bookingDate,
    );
  }

  String get _timeLabel {
    final label = _getString(const ['formattedTime', 'timeLabel']);
    if (label.isNotEmpty) return label;

    final start = _getString(
      const ['startTime'],
      fallback: widget.summary.startTime,
    );
    final end = _getString(
      const ['endTime'],
      fallback: widget.summary.endTime,
    );

    if (start.isNotEmpty && end.isNotEmpty) return '$start - $end';
    return start;
  }

  String get _durationLabel {
    final durationLabel = _getString(const ['durationLabel']);
    if (durationLabel.isNotEmpty) return durationLabel;

    final hours = _getNum(const ['duration', 'durationHours']);
    if (hours > 0) {
      final intHours = hours % 1 == 0 ? hours.toInt().toString() : hours.toString();
      return '$intHours hours';
    }
    return '';
  }

  String get _timeAndDuration {
    final formatted = _getString(const ['formattedTime']);
    if (formatted.isNotEmpty) return formatted;

    final parts = <String>[];
    if (_timeLabel.trim().isNotEmpty) parts.add(_timeLabel.trim());
    if (_durationLabel.trim().isNotEmpty) parts.add(_durationLabel.trim());
    if (parts.isEmpty) return '-';
    return parts.join(' • ');
  }

  String get _address {
    return _getString(
      const ['fullAddress', 'address', 'serviceLocation', 'location'],
      fallback: widget.summary.address,
    );
  }

  String get _customerName {
    final nestedCustomerName = _getNestedString(const ['customer', 'fullName']);
    return _getString(
      const ['customerName', 'userName', 'name'],
      fallback: nestedCustomerName.isNotEmpty
          ? nestedCustomerName
          : widget.summary.customerName,
    );
  }

  double get _rating {
    final helper = _detail['helper'];
    if (helper is Map<String, dynamic>) {
      final nested = helper['rating'];
      if (nested is num) return nested.toDouble();
      final parsed = double.tryParse(nested?.toString() ?? '');
      if (parsed != null) return parsed;
    }

    final value = _getDouble(
      const ['helperRating', 'rating'],
      fallback: widget.summary.rating,
    );
    return value;
  }

  String get _displayRating {
    if (_rating <= 0) return '0';
    return _rating % 1 == 0 ? _rating.toStringAsFixed(0) : _rating.toStringAsFixed(1);
  }

  num get _amount {
    return _getNum(
      const ['finalAmount', 'amount', 'price', 'fee'],
      fallback: widget.summary.amount,
    );
  }

  String get _displayAmount {
    if (_amount % 1 == 0) return '₹${_amount.toInt()}';
    return '₹${_amount.toStringAsFixed(2)}';
  }

  String get _serviceSummary {
    return 'Jhadu, Pocha aur Bartan';
  }

  String get _serviceTitle {
    final name = _serviceType.trim();
    if (name.isEmpty) return 'Service';
    if (name.toLowerCase().contains('service')) return name;
    return '$name Service';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2239),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Job Detail',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
        child: _isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    _serviceCard(),
                    const SizedBox(height: 16),
                    _customerCard(),
                    const SizedBox(height: 16),
                    _earningsCard(),
                    const SizedBox(height: 16),
                    _importantInfoCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _serviceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _serviceTitle,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusText,
                  style: TextStyle(
                    color: _statusTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Booking ID: $_bookingRef',
            style: const TextStyle(color: Color(0xFF667085), fontSize: 14),
          ),
          Text(
            _serviceSummary,
            style: const TextStyle(color: Color(0xFF475467), fontSize: 14),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Color(0xFFEAECF0), height: 1),
          ),
          _ServiceInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: _dateLabel.isNotEmpty ? _dateLabel : '-',
          ),
          const SizedBox(height: 16),
          _ServiceInfoRow(
            icon: Icons.access_time,
            label: 'Time & Duration',
            value: _timeAndDuration,
          ),
          const SizedBox(height: 16),
          _ServiceInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Service Location',
            value: _address.isNotEmpty ? _address : '-',
          ),
        ],
      ),
    );
  }

  Widget _customerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF0B2239),
            child: Icon(Icons.person_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customerName,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFDB022), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _displayRating,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.currency_rupee, size: 24, color: Color(0xFF667085)),
              SizedBox(width: 10),
              Text(
                'Your Earnings',
                style: TextStyle(
                  color: Color(0xFF344054),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _displayAmount,
            style: const TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Payment will be transferred after service completion.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _importantInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 10),
              Text(
                'Important Information',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoPoint('Arrive 10 minutes before scheduled time'),
          _infoPoint('Carry necessary cleaning supplies'),
          _infoPoint('Follow all safety guidelines'),
          _infoPoint('Be professional and courteous'),
        ],
      ),
    );
  }

  Widget _infoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceInfoRow extends StatelessWidget {
  const _ServiceInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
