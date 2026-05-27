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

  String get _categoryName {
    return _getNestedString(
      const ['category', 'name'],
      fallback: _serviceType,
    );
  }

  List<String> get _serviceNames {
    final services = _detail['services'];
    if (services is List) {
      return services
          .whereType<Map<String, dynamic>>()
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.trim().isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  List<_ServiceDetailItem> get _serviceDetails {
    final services = _detail['services'];
    if (services is List) {
      return services.whereType<Map<String, dynamic>>().map((item) {
        return _ServiceDetailItem(
          name: item['name']?.toString() ?? 'Service',
          included: _toStringList(item['included']),
          notIncluded: _toStringList(item['notIncluded']),
          requirements: _toStringList(item['requirements']),
        );
      }).toList();
    }
    return const <_ServiceDetailItem>[];
  }

  List<String> get _requirements {
    final services = _detail['services'];
    if (services is List) {
      for (final entry in services) {
        if (entry is Map<String, dynamic>) {
          final items = _toStringList(entry['requirements']);
          if (items.isNotEmpty) return items;
        }
      }
    }
    return const <String>[];
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
    final locationFull = _getNestedString(const ['location', 'full']);
    if (locationFull.trim().isNotEmpty) return locationFull;
    return _getString(
      const ['fullAddress', 'address', 'serviceLocation'],
      fallback: widget.summary.fullAddress.isNotEmpty
          ? widget.summary.fullAddress
          : widget.summary.address,
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

  num get _serviceCharge {
    final value = _getNestedNum(const ['paymentBreakdown', 'serviceCharge']);
    return value > 0 ? value : _amount;
  }

  num get _companyCharge {
    return _getNestedNum(const ['paymentBreakdown', 'platformFee']);
  }

  num get _totalAmount {
    final value = _getNestedNum(const ['paymentBreakdown', 'finalPayable']);
    return value > 0 ? value : _amount;
  }

  String _formatAmount(num value) {
    if (value % 1 == 0) return '₹${value.toInt()}';
    return '₹${value.toStringAsFixed(2)}';
  }

  num _getNestedNum(List<String> path, {num fallback = 0}) {
    dynamic current = _detail;
    for (final segment in path) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return fallback;
      }
    }
    if (current is num) return current;
    return num.tryParse(current?.toString() ?? '') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1B3A52),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Job Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _bookingRef,
                  style: const TextStyle(
                    color: Color(0xFFA0A9B3),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
        child: _isLoading
            ? const _JobHistoryDetailSkeleton()
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      children: [
                        _serviceDetailsCard(),
                        const SizedBox(height: 12),
                        _customerDetailsCard(),
                        const SizedBox(height: 12),
                        _serviceLocationCard(),
                        const SizedBox(height: 12),
                        _timingCard(),
                        const SizedBox(height: 12),
                        _paymentDetailsCard(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _serviceDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: Color(0xFF0F172A), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Service Details',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Booking ID', value: _bookingRef),
          const SizedBox(height: 10),
          _DetailRow(label: 'Category Name', value: _categoryName),
          const SizedBox(height: 10),
          _DetailRow(label: 'Duration', value: _durationLabel.isNotEmpty ? _durationLabel : '-'),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Service detail',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _serviceNames.isEmpty ? null : _showServiceDetails,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 1),
                  decoration: _serviceNames.isEmpty
                      ? null
                      : const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF60A5FA),
                              width: 1,
                            ),
                          ),
                        ),
                  child: Text(
                    'View Detail',
                    style: TextStyle(
                      color: _serviceNames.isEmpty
                          ? const Color(0xFF98A2B3)
                          : const Color(0xFF60A5FA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customerDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline, color: Color(0xFF0F172A), size: 18),
              SizedBox(width: 8),
              Text(
                'Customer Details',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF0B2239),
                child: Icon(Icons.person_outline, color: Colors.white, size: 22),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFDB022), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _displayRating,
                          style: const TextStyle(
                            color: Color(0xFF475467),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _circleAction(icon: Icons.call),
              const SizedBox(width: 8),
              _circleAction(icon: Icons.chat_bubble_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_outlined, color: Color(0xFF0F172A), size: 18),
              SizedBox(width: 8),
              Text(
                'Service Location',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _address.isNotEmpty ? _address : '-',
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.access_time, color: Color(0xFF0F172A), size: 18),
              SizedBox(width: 8),
              Text(
                'Timing',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TimingRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: _dateLabel.isNotEmpty ? _dateLabel : '-',
          ),
          const SizedBox(height: 10),
          _TimingRow(
            icon: Icons.access_time,
            label: 'Time',
            value: _timeLabel.isNotEmpty ? _timeLabel : '-',
          ),
          const SizedBox(height: 10),
          _TimingRow(
            icon: Icons.timelapse,
            label: 'Duration',
            value: _durationLabel.isNotEmpty ? _durationLabel : '-',
          ),
        ],
      ),
    );
  }

  Widget _paymentDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.currency_rupee, color: Color(0xFF0F172A), size: 18),
              SizedBox(width: 8),
              Text(
                'Payment Details',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Service Charge', value: _formatAmount(_serviceCharge)),
          const SizedBox(height: 8),
          _DetailRow(label: 'Company Charge', value: _formatAmount(_companyCharge)),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          const SizedBox(height: 10),
          _DetailRow(
            label: 'Total Amount',
            value: _formatAmount(_totalAmount),
            isEmphasis: true,
          ),
        ],
      ),
    );
  }

  Widget _circleAction({required IconData icon}) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Color(0xFF0B2239),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  void _showServiceDetails() {
    final items = _serviceDetails;
    if (items.isEmpty) return;
    final requirements = _requirements;
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Services Details',
                        style: TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF667085)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: items
                          .map((item) => _ServiceDetailCard(item: item))
                          .toList(),
                    ),
                  ),
                ),
                if (requirements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _RequirementsCard(items: requirements),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceDetailItem {
  const _ServiceDetailItem({
    required this.name,
    required this.included,
    required this.notIncluded,
    required this.requirements,
  });

  final String name;
  final List<String> included;
  final List<String> notIncluded;
  final List<String> requirements;
}

class _ServiceDetailCard extends StatefulWidget {
  const _ServiceDetailCard({required this.item});

  final _ServiceDetailItem item;

  @override
  State<_ServiceDetailCard> createState() => _ServiceDetailCardState();
}

class _ServiceDetailCardState extends State<_ServiceDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF2563EB),
                  size: 20,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            _chipSection(
              title: 'Includes',
              items: item.included,
              background: const Color(0xFFDCFCE7),
              foreground: const Color(0xFF166534),
            ),
            if (item.notIncluded.isNotEmpty) ...[
              const SizedBox(height: 12),
              _chipSection(
                title: 'Not Included',
                items: item.notIncluded,
                background: const Color(0xFFFEE2E2),
                foreground: const Color(0xFFB91C1C),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _chipSection({
    required String title,
    required List<String> items,
    required Color background,
    required Color foreground,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (text) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What You Need From Customer',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 6, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      color: const Color(0xFF101828),
      fontSize: isEmphasis ? 14 : 12,
      fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w600,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
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

class _TimingRow extends StatelessWidget {
  const _TimingRow({
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
      children: [
        Icon(icon, size: 14, color: const Color(0xFF98A2B3)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _JobHistoryDetailSkeleton extends StatelessWidget {
  const _JobHistoryDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFE4E7EC);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(width: 120, height: 12, color: baseColor),
              const SizedBox(height: 12),
              _line(width: double.infinity, height: 10, color: baseColor),
              const SizedBox(height: 10),
              _line(width: 180, height: 10, color: baseColor),
              const SizedBox(height: 10),
              _line(width: 140, height: 10, color: baseColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _skeletonCard(
          child: Row(
            children: [
              _circle(size: 44, color: baseColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(width: 120, height: 10, color: baseColor),
                    const SizedBox(height: 6),
                    _line(width: 60, height: 10, color: baseColor),
                  ],
                ),
              ),
              _circle(size: 28, color: baseColor),
              const SizedBox(width: 8),
              _circle(size: 28, color: baseColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _skeletonCard(child: _line(width: double.infinity, height: 10, color: baseColor)),
        const SizedBox(height: 12),
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(width: 90, height: 10, color: baseColor),
              const SizedBox(height: 8),
              _line(width: double.infinity, height: 10, color: baseColor),
              const SizedBox(height: 8),
              _line(width: double.infinity, height: 10, color: baseColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(width: 100, height: 10, color: baseColor),
              const SizedBox(height: 8),
              _line(width: double.infinity, height: 10, color: baseColor),
              const SizedBox(height: 8),
              _line(width: double.infinity, height: 10, color: baseColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _skeletonCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: child,
    );
  }

  static Widget _line({required double width, required double height, required Color color}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  static Widget _circle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
