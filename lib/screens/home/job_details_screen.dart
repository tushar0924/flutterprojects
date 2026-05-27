import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking_details_model.dart';
import '../../repositories/booking_details_repository.dart';
import 'payment_received_job_details_screen.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final int bookingId;

  const JobDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  BookingDetailsModel? _booking;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _paymentRedirectTimer;
  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  @override
  void dispose() {
    _paymentRedirectTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBookingDetails() async {
    final repository = ref.read(bookingDetailsRepositoryProvider);
    final booking = await repository.getBookingDetails(widget.bookingId);

    if (!mounted) return;

    setState(() {
      _booking = booking;
      _isLoading = false;
      if (booking == null) {
        _errorMessage = 'Failed to load booking details';
      }
    });

    if (booking != null && booking.status == 'PENDING_PAYMENT') {
      _schedulePaymentRedirect(booking);
    }
  }

  void _schedulePaymentRedirect(BookingDetailsModel booking) {
    if (_redirectScheduled || !mounted) return;
    _redirectScheduled = true;
    _paymentRedirectTimer?.cancel();
    _paymentRedirectTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_booking?.id != booking.id || _booking?.status != 'PENDING_PAYMENT') {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentReceivedJobDetailsScreen(booking: booking),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Failed to load booking details'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final booking = _booking!;
    const Color navyBlue = Color(0xFF13223A);
    const Color textGrey = Color(0xFF5B6874);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: navyBlue,
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              booking.id.toString(),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(86),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: _buildStatusHeader(booking),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
        child: Column(
          children: [
            // Service Details
            _SectionContainer(
              title: 'Service Details',
              icon: Icons.business_center_outlined,
              child: Column(
                children: [
                  _infoRow('Booking ID', booking.id.toString()),
                  _infoRow('Category Name', booking.service?.name ?? 'N/A'),
                  _infoRow('Duration', '${booking.totalHours} hours'),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'View Detail',
                        style: TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Customer Details
            _SectionContainer(
              title: 'Customer Details',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF0B2545),
                        child: Text(
                          booking.customer?.fullName.isNotEmpty == true
                              ? booking.customer!.fullName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customer?.fullName ?? 'Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Color(0xFFFDB022),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '4.8',
                                  style: const TextStyle(
                                    color: textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B2545),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.call,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF97316),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (booking.status == 'PENDING_PAYMENT')
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        _LockedActionCard(
                          text:
                              'Contact to customer will be available after payment',
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Service Location
            _SectionContainer(
              title: 'Service Location',
              icon: Icons.location_on_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.fullAddress,
                    style: const TextStyle(fontSize: 13, color: textGrey),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        const Icon(
                          Icons.done,
                          size: 16,
                          color: Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Get Directions',
                          style: TextStyle(
                            color: Color(0xFF0EA5E9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (booking.status == 'PENDING_PAYMENT')
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        _LockedActionCard(
                          text: 'Navigation will be available after payment',
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Timing
            _SectionContainer(
              title: 'Timing',
              icon: Icons.calendar_today_outlined,
              child: Column(
                children: [
                  _infoRow(
                    'Date',
                    booking.formattedDate,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _infoRow(
                    'Time',
                    booking.formattedTime,
                    icon: Icons.access_time,
                  ),
                  _infoRow(
                    'Total Duration',
                    '${booking.totalHours} hours',
                    icon: Icons.access_time,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Payment Details
            _SectionContainer(
              title: 'Payment Details',
              icon: Icons.attach_money,
              child: Column(
                children: [
                  _infoRow(
                    'Service Charge',
                    '₹${booking.totalAmount.toStringAsFixed(0)}',
                  ),
                  _infoRow(
                    'Tax & Fee',
                    '₹${booking.platformFee.toStringAsFixed(0)}',
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    'Total Amount',
                    '₹${booking.finalAmount.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Report Issue',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF1D2939),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BookingDetailsModel booking) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _getStatusColor(booking.status),
            child: Icon(
              _getStatusIcon(booking.status),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusLabel(booking.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getStatusDescription(booking.status),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING_PAYMENT':
        return const Color(0xFFF9A825);
      case 'CONFIRMED':
      case 'ACCEPTED':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING_PAYMENT':
        return Icons.access_time_filled;
      case 'CONFIRMED':
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'COMPLETED':
        return Icons.done_all;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING_PAYMENT':
        return 'Awaiting Customer Payment';
      case 'CONFIRMED':
      case 'ACCEPTED':
        return 'Booking Confirmed';
      case 'COMPLETED':
        return 'Booking Completed';
      case 'CANCELLED':
        return 'Booking Cancelled';
      default:
        return status;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'PENDING_PAYMENT':
        return 'Waiting for customer payment';
      case 'CONFIRMED':
      case 'ACCEPTED':
        return 'Ready to proceed';
      case 'COMPLETED':
        return 'Job completed successfully';
      case 'CANCELLED':
        return 'This booking was cancelled';
      default:
        return '';
    }
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isBold = false,
    bool isPill = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF5B6874), fontSize: 13),
            ),
          ),
          if (isPill)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: isBold ? 15 : 13,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData icon;

  const _SectionContainer({
    required this.title,
    required this.child,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF13223A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LockedActionCard extends StatelessWidget {
  final String text;
  const _LockedActionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF98A2B3), size: 20),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
