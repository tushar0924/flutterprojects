import 'package:flutter/material.dart';
import 'selfie_verification_screen.dart';
import '../../models/booking_details_model.dart';

class PaymentReceivedJobDetailsScreen extends StatelessWidget {
  const PaymentReceivedJobDetailsScreen({super.key, required this.booking});

  final BookingDetailsModel booking;

  @override
  Widget build(BuildContext context) {
    const Color navyBlue = Color(0xFF0D1F33); // Darker navy from image
    const Color textGrey = Color(0xFF5B6874);
    final customerName = booking.customer?.fullName.isNotEmpty == true
        ? booking.customer!.fullName
        : 'Customer';
    final bookingIdText = booking.id > 0
        ? booking.id.toString()
        : (booking.bookingRequestId.isNotEmpty
            ? booking.bookingRequestId
            : 'N/A');
    final serviceName = booking.service?.name.isNotEmpty == true
        ? booking.service!.name
        : (booking.serviceDisplayName.isNotEmpty
            ? booking.serviceDisplayName
            : 'N/A');
    final paymentAmount = (booking.payment?.amount ?? 0) > 0
        ? booking.payment!.amount
        : booking.finalAmount > 0
            ? booking.finalAmount
            : booking.totalAmount;
    final totalHoursText = booking.totalHours > 0
        ? '${booking.totalHours} hours'
        : '${booking.duration} hours';
    final dateText = booking.formattedDate.isNotEmpty
        ? booking.formattedDate
        : booking.bookingDate.toLocal().toString().split(' ').first;
    final timeText = booking.formattedTime.isNotEmpty
        ? booking.formattedTime
        : '${booking.startTime.toLocal().toString().substring(11, 16)} - ${booking.endTime.toLocal().toString().substring(11, 16)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: navyBlue,
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
            const SizedBox(height: 2),
            Text(
              bookingIdText,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Payment Received Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
              decoration: const BoxDecoration(
                color: navyBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF00C853), // Vibrant green
                      child: Icon(Icons.check, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Received',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          'Received just now',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  // Service Details Section
                  _SectionContainer(
                    title: 'Service Details',
                    icon: Icons.business_center_outlined,
                    child: Column(
                      children: [
                        _infoRow('Booking ID', bookingIdText),
                        _infoRow('Service Type', serviceName),
                        _infoRow('Booking Type', booking.totalHours > 0 ? 'Per Day' : 'Standard', isPill: true),
                        _infoRow('Duration', totalHoursText),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Customer Details Section
                  _SectionContainer(
                    title: 'Customer Details',
                    icon: Icons.person_outline,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFF0D1F33),
                          child: Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking.rating > 0 ? booking.rating.toStringAsFixed(1) : '4.8',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _CircleIconButton(icon: Icons.call, bgColor: booking.customer?.phone.isNotEmpty == true ? const Color(0xFF0D1F33) : Colors.grey),
                        const SizedBox(width: 10),
                        _CircleIconButton(icon: Icons.message, bgColor: const Color(0xFFFF7A00)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Service Location Section
                  _SectionContainer(
                    title: 'Service Location',
                    icon: Icons.location_on_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.fullAddress.isNotEmpty ? booking.fullAddress : booking.location,
                          style: const TextStyle(fontSize: 13, color: textGrey, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            side: const BorderSide(color: Color(0xFFE4E7EC)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.near_me_outlined, size: 18, color: Color(0xFF1570EF)),
                          label: const Text('Get Directions',
                              style: TextStyle(color: Color(0xFF1570EF), fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment Details Section
                  _SectionContainer(
                    title: 'Payment Details',
                    icon: Icons.currency_rupee,
                    child: Column(
                      children: [
                        _infoRow('Service Charge', '₹${paymentAmount.toStringAsFixed(0)}'),
                        _infoRow('Platform Fee', '₹${booking.platformFee.toStringAsFixed(0)}'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(color: Color(0xFFF2F4F7)),
                        ),
                        _infoRow('Total Amount', '₹${booking.finalAmount > 0 ? booking.finalAmount.toStringAsFixed(0) : paymentAmount.toStringAsFixed(0)}', isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Timing Section
                  _SectionContainer(
                    title: 'Timing',
                    icon: Icons.calendar_today_outlined,
                    child: Column(
                      children: [
                        _infoRow('Date', dateText, icon: Icons.calendar_today_outlined),
                        _infoRow('Time', timeText, icon: Icons.access_time),
                        _infoRow('Duration', totalHoursText, icon: Icons.access_time),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: Color(0xFFFEE4E2)),
                            backgroundColor: const Color(0xFFFFF1F0),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SelfieVerificationScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            elevation: 0,
                            backgroundColor: navyBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Start',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false, bool isPill = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF667085), fontSize: 13))),
          if (isPill)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB2DDFF)),
              ),
              child: Text(value, style: const TextStyle(color: Color(0xFF175CD3), fontSize: 11, fontWeight: FontWeight.bold)),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: isBold ? 15 : 13,
                color: const Color(0xFF1D2939),
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

  const _SectionContainer({required this.title, required this.child, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0D1F33)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0D1F33))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.bgColor});

  final IconData icon;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(icon, color: Colors.white, size: 20)),
    );
  }
}
