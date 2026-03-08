import 'dart:async';
import 'package:flutter/material.dart';

class BookingAlert extends StatefulWidget {
  const BookingAlert({super.key});

  @override
  State<BookingAlert> createState() => _BookingAlertState();
}

class _BookingAlertState extends State<BookingAlert> {
  int _seconds = 14;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          t.cancel();
          // Logic for auto-reject can go here
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Section
          Container(
            color: const Color(0xFF0D1F33), // Dark Navy
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Text('🔔', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'New Booking alert!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_seconds}s',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking ID: 1762415711831',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),

                // Customer Info Card
                _buildInfoCard(
                  color: const Color(0xFFF1F7FF),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF0D1F33),
                        child: const Text('A', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Anjali Verma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Customer', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Work Details Card
                _buildInfoCard(
                  color: const Color(0xFFFFF6ED),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, color: Color(0xFF8B4513), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Work Details', style: TextStyle(color: Color(0xFF8B4513), fontWeight: FontWeight.bold)),
                          Text('Work: Jhadu, Pocha aur Bartan', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Earnings Card
                _buildInfoCard(
                  color: const Color(0xFFEFFFF4),
                  child: Row(
                    children: [
                      const Icon(Icons.currency_rupee, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Earnings', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          Text('₹300', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Address & Time Card (The gray one)
                _buildInfoCard(
                  color: const Color(0xFFF8F8F8),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.access_time, 'Per days (8 hours)\n9:00 AM - 11:00 AM'),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.location_on_outlined, 'Apartment 302, Prestige Towers, Koramangala, Bangalore'),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          SizedBox(width: 28),
                          Icon(Icons.location_on, size: 14, color: Colors.red),
                          Text(' 1.5 km away', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Color(0xFFFFCDD2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853), // Bright Green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer Warning
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Auto-rejected in $_seconds seconds if no action',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
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

  Widget _buildInfoCard({required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black45),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
          ),
        ),
      ],
    );
  }
}
