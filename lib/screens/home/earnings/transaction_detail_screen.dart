import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/helper_earnings_transaction_model.dart';
import '../../../providers/partner_provider.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  final String transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  bool _isLoading = true;
  String? _error;
  HelperEarningsTransactionDetail? _detail;

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

    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.getHelperEarningsTransactionDetail(widget.transactionId);

    if (!mounted) return;

    if (res.success && res.detail != null) {
      setState(() {
        _detail = res.detail;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _detail = null;
      _error = res.message ?? 'Failed to load transaction detail';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                children: [
                  _summaryCard(_detail!),
                  const SizedBox(height: 12),
                  _detailSection(
                    title: 'Transaction Details',
                    icon: Icons.receipt_outlined,
                    rows: [
                      _pair('Date & Time', _detail!.dateTime),
                      _statusPair('Status', _detail!.status),
                      _pair('Payment Method', _detail!.paymentMethod),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _detailSection(
                    title: 'Service Details',
                    icon: Icons.person_outline,
                    rows: [
                      _pair('Customer Name', _detail!.customerName),
                      _pair('Service Type', _detail!.serviceType),
                      _pair('Booking ID', _detail!.bookingId),
                      _pair('Service Date', _detail!.serviceDate),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _paymentBreakdown(_detail!),
                  const SizedBox(height: 12),
                  _noteCard(_detail!.note),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D66E8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.support_agent_outlined, color: Colors.white, size: 16),
                      label: const Text(
                        'Contact Support',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _summaryCard(HelperEarningsTransactionDetail detail) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1CB84B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF15A140)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircleAvatar(
                radius: 11,
                backgroundColor: Color(0xFF4DD37D),
                child: Icon(Icons.check, size: 13, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text(
                'Payment Received',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _money(detail.amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Transaction ID: ${detail.transactionId}',
            style: const TextStyle(
              color: Color(0xFFEAFDF1),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection({
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF98A2B3)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ...rows,
        ],
      ),
    );
  }

  Widget _paymentBreakdown(HelperEarningsTransactionDetail detail) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_outlined, size: 14, color: Color(0xFF98A2B3)),
              SizedBox(width: 6),
              Text(
                'Payment Breakdown',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _pair('Service Amount', _money(detail.serviceAmount)),
          _pair('Platform Fee', '-${_money(detail.platformFee)}', valueColor: const Color(0xFFEF4444)),
          const Divider(height: 16, color: Color(0xFFE5E7EB)),
          _pair('Final Amount', _money(detail.finalAmount), isBold: true, valueColor: const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _noteCard(String note) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFACE9C6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, color: Color(0xFF16A34A), size: 14),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(
                color: Color(0xFF166534),
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pair(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: valueColor ?? const Color(0xFF111827),
                  fontSize: 11,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPair(String label, String status) {
    final normalized = status.trim().toUpperCase();
    final isCompleted = normalized == 'COMPLETED';

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _toTitle(status),
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  String _money(num value) {
    if (value % 1 == 0) return '₹${value.toInt()}';
    return '₹${value.toStringAsFixed(2)}';
  }

  String _toTitle(String value) {
    final s = value.trim().toLowerCase();
    if (s.isEmpty) return '-';
    return s[0].toUpperCase() + s.substring(1);
  }
}
