import 'dart:async';
import 'package:flutter/material.dart';
import 'payment_received_job_details_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  static const int _initialSeconds = 3;
  int _secondsLeft = _initialSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PaymentReceivedJobDetailsScreen()),
        );
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const Color navyBlue = Color(0xFF13223A);
    const Color cardBorderColor = Color(0xFFE0E5EA);
    const Color textGrey = Color(0xFF5B6874);

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
          children: const [
            Text('Job Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            Text('176269121756',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: navyBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFF9A825),
                      child: Icon(Icons.access_time_filled, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Awaiting Customer Payment',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Waiting time: ${_formatTime(_secondsLeft)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Waiting For Payment Warning
            _warningCard(),
            const SizedBox(height: 12),

            // Service Details
            _SectionContainer(
              title: 'Service Details',
              icon: Icons.business_center_outlined,
              child: Column(
                children: [
                  _infoRow('Booking ID', '1762415711831'),
                  _infoRow('Service Type', 'Maid'),
                  _infoRow('Booking Type', 'Per Day', isPill: true),
                  _infoRow('Duration', '8 hours'),
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
                        child: const Text('P', style: TextStyle(color: textGrey)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Priya Sharma', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Customer', style: TextStyle(color: textGrey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _LockedActionCard(text: 'Contact to customer will be available after payment'),
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
                  const Text('Lorem ipsum dolor sit amet consectetur. Porttitor faucibus nisi cursus.',
                      style: TextStyle(fontSize: 13, color: textGrey)),
                  const SizedBox(height: 12),
                  _LockedActionCard(text: 'Navigation will be available after payment'),
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
                  _infoRow('Date', 'Tomorrow, Dec 9, 2025', icon: Icons.calendar_today_outlined),
                  _infoRow('Time', '10:00 AM - 05:00 PM', icon: Icons.access_time),
                  _infoRow('Duration', '8 hours', icon: Icons.access_time),
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
                  _infoRow('Service Charge', '₹254'),
                  _infoRow('Platform Fee', '₹10'),
                  const Divider(height: 24),
                  _infoRow('Total Amount', '₹330', isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Important Information
            _importantInfo(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
                Text('Waiting For Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(height: 4),
                Text('The remaining information will be shown when the customer makes the payment.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6D4C41))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false, bool isPill = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF5B6874), fontSize: 13))),
          if (isPill)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(value, style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          else
            Text(value, style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 15 : 13,
            )),
        ],
      ),
    );
  }

  Widget _importantInfo() {
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
              Text('Important Information', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF13223A))),
            ],
          ),
          const SizedBox(height: 12),
          _bulletPoint('Customer is currently completing the payment process'),
          _bulletPoint('Complete job details including contact information will be available after payment confirmation'),
          _bulletPoint('You will receive a notification once payment is completed'),
          _bulletPoint('Please be ready to start the job as scheduled'),
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
          const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 4, color: Colors.blue)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF344054)))),
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
        border: Border.all(color: const Color(0xFFE0E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF13223A)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF667085), fontSize: 11)),
        ],
      ),
    );
  }
}
