import 'package:flutter/material.dart';

import '../../models/booking_details_model.dart';
import 'start_job_otp_screen.dart';

class PaymentReceivedJobDetailsScreen extends StatelessWidget {
  const PaymentReceivedJobDetailsScreen({super.key, required this.booking});

  final BookingDetailsModel booking;

  static const Color _navy = Color(0xFF0D233A);

  @override
  Widget build(BuildContext context) {
    final bookingIdText = booking.id > 0 ? booking.id.toString() : 'N/A';
    final categoryName = booking.category.name.isNotEmpty
        ? booking.category.name
        : 'N/A';
    final duration = booking.durationLabel.isNotEmpty
        ? booking.durationLabel
        : 'N/A';
    final customerName = booking.customer.name.isNotEmpty
        ? booking.customer.name
        : 'Customer';
    final date = booking.date.isNotEmpty ? booking.date : 'N/A';
    final time = booking.time.isNotEmpty ? booking.time : 'N/A';
    final totalAmount = booking.paymentBreakdown.total > 0
        ? booking.paymentBreakdown.total
        : booking.payment.amount;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: _navy,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              bookingIdText,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(86),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: _PaymentHeader(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            _SectionContainer(
              title: 'Service Details',
              icon: Icons.business_center_outlined,
              child: Column(
                children: [
                  _InfoRow(label: 'Booking ID', value: bookingIdText),
                  _InfoRow(label: 'Category Name', value: categoryName),
                  _InfoRow(label: 'Total Duration', value: duration),
                  _InfoRow(
                    label: 'Service detail',
                    value: 'View Detail',
                    isLink: true,
                    onTap: booking.services.isEmpty
                        ? null
                        : () => _showServiceDetails(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionContainer(
              title: 'Customer Details',
              icon: Icons.person_outline,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: _navy,
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFF59E0B),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.helper.rating > 0
                                  ? booking.helper.rating.toStringAsFixed(1)
                                  : '4.8',
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.call,
                    color: booking.actions.canCallCustomer
                        ? _navy
                        : const Color(0xFF98A2B3),
                  ),
                  const SizedBox(width: 10),
                  _CircleIconButton(
                    icon: Icons.chat_bubble,
                    color: booking.actions.canChatCustomer
                        ? const Color(0xFFFF7900)
                        : const Color(0xFF98A2B3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionContainer(
              title: 'Service Location',
              icon: Icons.location_on_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.location.full,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: booking.actions.canNavigate ? () {} : null,
                      icon: const Icon(
                        Icons.near_me_outlined,
                        color: Color(0xFF2563EB),
                        size: 16,
                      ),
                      label: const Text(
                        'Get Directions',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD0D5DD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionContainer(
              title: 'Timing',
              icon: Icons.calendar_today_outlined,
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Date',
                    value: date,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _InfoRow(label: 'Time', value: time, icon: Icons.access_time),
                  _InfoRow(
                    label: 'Total Duration',
                    value: duration,
                    icon: Icons.access_time,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionContainer(
              title: 'Payment Details',
              icon: Icons.currency_rupee,
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Service Charge',
                    value: _formatAmount(booking.paymentBreakdown.subtotal),
                  ),
                  _InfoRow(
                    label: 'Tax & Fee',
                    value: _formatAmount(booking.paymentBreakdown.tax),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 7),
                    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ),
                  _InfoRow(
                    label: 'Total\nAmount',
                    value: _formatAmount(totalAmount),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    side: const BorderSide(color: Color(0xFFFEE4E2)),
                    backgroundColor: const Color(0xFFFFF1F0),
                    foregroundColor: const Color(0xFFE11D48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: const Text(
                    'Report Issue',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StartJobOtpScreen(
                          bookingId: booking.id,
                          customerName: booking.customer.name,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    elevation: 0,
                    backgroundColor: _navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showServiceDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF667085),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        ...booking.services.map(
                          (service) => _ServiceDetailCard(service: service),
                        ),
                        _RequirementsCard(items: _requirementsFromServices()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _requirementsFromServices() {
    for (final service in booking.services) {
      if (service.requirements.isNotEmpty) return service.requirements;
    }
    return const <String>[];
  }

  String _formatAmount(num value) {
    if (value % 1 == 0) return '\u20B9${value.toInt()}';
    return '\u20B9${value.toStringAsFixed(2)}';
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF18C66A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Received',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Received just now',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.title,
    required this.child,
    required this.icon,
  });

  final String title;
  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: PaymentReceivedJobDetailsScreen._navy,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: PaymentReceivedJobDetailsScreen._navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isLink = false,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final bool isBold;
  final bool isLink;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      textAlign: TextAlign.right,
      style: TextStyle(
        color: isLink ? const Color(0xFF2563EB) : const Color(0xFF111827),
        decoration: isLink ? TextDecoration.underline : TextDecoration.none,
        decorationColor: const Color(0xFF2563EB),
        fontSize: isBold ? 13 : 12,
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: const Color(0xFF98A2B3)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isLink && onTap != null)
            InkWell(onTap: onTap, child: valueText)
          else
            valueText,
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _ServiceDetailCard extends StatefulWidget {
  const _ServiceDetailCard({required this.service});

  final BookingService service;

  @override
  State<_ServiceDetailCard> createState() => _ServiceDetailCardState();
}

class _ServiceDetailCardState extends State<_ServiceDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: const Color(0xFF98A2B3),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            _ChipSection(
              title: 'Included',
              items: service.included,
              background: Color(0xFFDCFCE7),
              foreground: Color(0xFF166534),
            ),
            if (service.notIncluded.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ChipSection(
                title: 'Not Included',
                items: service.notIncluded,
                background: Color(0xFFFEE2E2),
                foreground: Color(0xFFB91C1C),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.items,
    required this.background,
    required this.foreground,
  });

  final String title;
  final List<String> items;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (text) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What You Need From Customer',
            style: TextStyle(
              color: PaymentReceivedJobDetailsScreen._navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.water_drop,
                    size: 14,
                    color: Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF344054),
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
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
