import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking_details_model.dart';
import '../../repositories/booking_details_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            // Waiting For Payment Warning
            if (booking.status == 'PENDING_PAYMENT') _warningCard(),
            if (booking.status == 'PENDING_PAYMENT') const SizedBox(height: 12),

            // Service Details
            _SectionContainer(
              title: 'Service Details',
              icon: Icons.business_center_outlined,
              child: Column(
                children: [
                  _infoRow('Booking ID', booking.id.toString()),
                  _infoRow('Service Type', booking.service?.name ?? 'N/A'),
                  _infoRow(
                    'Booking Type',
                    '${booking.totalHours} Hours',
                    isPill: true,
                  ),
                  _infoRow('Duration', '${booking.duration} hours'),
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
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          booking.customer?.fullName.isNotEmpty == true
                              ? booking.customer!.fullName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(color: textGrey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.customer?.fullName ?? 'Customer',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            booking.customer?.phone ?? 'N/A',
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 12,
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
                  if (booking.status == 'PENDING_PAYMENT')
                    _LockedActionCard(
                      text: 'Navigation will be available after payment',
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
                    'Duration',
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
                    'Platform Fee',
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
            const SizedBox(height: 12),

            // Important Information
            _importantInfo(booking.status),
            const SizedBox(height: 20),
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

  Widget _warningCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.error_outline, color: Colors.orange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting For Payment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'The remaining information will be shown when the customer makes the payment.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6D4C41)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _importantInfo(String status) {
    final List<String> infoPoints = status == 'PENDING_PAYMENT'
        ? [
            'Customer is currently completing the payment process',
            'Complete job details including contact information will be available after payment confirmation',
            'You will receive a notification once payment is completed',
            'Please be ready to start the job as scheduled',
          ]
        : [
            'Make sure to arrive on time',
            'Contact customer before arrival',
            'Maintain professional standards',
            'Complete the job as agreed',
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1E3FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text(
                'Important Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF13223A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...infoPoints.map((point) => _bulletPoint(point)),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 4, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF344054)),
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
