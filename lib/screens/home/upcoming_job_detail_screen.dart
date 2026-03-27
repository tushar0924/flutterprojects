import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UpcomingJobDetailScreen extends StatelessWidget {
  const UpcomingJobDetailScreen({
    super.key,
    required this.customerName,
    required this.rating,
    required this.serviceType,
    required this.earnings,
    required this.bookingId,
    required this.dayLabel,
    required this.timeLabel,
    required this.durationLabel,
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String customerName;
  final String rating;
  final String serviceType;
  final String earnings;
  final int bookingId;
  final String dayLabel;
  final String timeLabel;
  final String durationLabel;
  final String address;
  final double? latitude;
  final double? longitude;

  String get _timeAndDuration {
    final parts = [
      timeLabel.trim(),
      durationLabel.trim(),
    ].where((item) => item.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    return parts.join(' • ');
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final lat = latitude;
    final lng = longitude;
    final hasCoordinates = lat != null && lng != null;
    final locationQuery = address.trim();

    if (!hasCoordinates && locationQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address not available for navigation')),
      );
      return;
    }

    late final Uri mapsDirectionsUri;
    late final Uri mapsSearchUri;

    if (hasCoordinates) {
      final latLng = '$lat,$lng';
      mapsDirectionsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latLng',
      );
      mapsSearchUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latLng',
      );
    } else {
      final encoded = Uri.encodeComponent(locationQuery);
      mapsDirectionsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$encoded',
      );
      mapsSearchUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded',
      );
    }

    try {
      final openedDirections = await launchUrl(
        mapsDirectionsUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedDirections) return;

      final openedSearch = await launchUrl(
        mapsSearchUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedSearch) return;
    } on PlatformException {
      // Can happen right after adding a new plugin until app is fully restarted.
    } catch (_) {
      // Fall through to user-facing message.
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open Maps. Please fully restart the app and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7), // Light grey background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2239), // Dark blue from image
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Job Detail',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            _serviceCard(context),
            const SizedBox(height: 16),
            _customerCard(),
            const SizedBox(height: 16),
            _earningsCard(),
            const SizedBox(height: 16),
            _importantInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$serviceType Service',
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Booking ID: $bookingId',
            style: const TextStyle(color: Color(0xFF667085), fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'Jhadu, Pocha aur Bartan',
            style: TextStyle(color: Color(0xFF475467), fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFEAECF0), height: 1),
          ),
          _ServiceInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: dayLabel.isNotEmpty ? dayLabel : '—',
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
            value: address.isNotEmpty ? address : '—',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _openGoogleMaps(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B2239),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.navigation_outlined, size: 22),
              label: const Text(
                'Get Directions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF0B2239),
            child: Icon(Icons.person_outline, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFDB022), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      rating,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.currency_rupee, size: 28, color: Color(0xFF667085)),
              SizedBox(width: 12),
              Text(
                'Your Earnings',
                style: TextStyle(
                  color: Color(0xFF344054),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            earnings,
            style: const TextStyle(
              color: Color(0xFF22C55E), // Exact green from image
              fontSize: 42,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Payment will be transferred after service completion.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _importantInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue background
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 24),
              SizedBox(width: 12),
              Text(
                'Important Information',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 14,
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
        Icon(icon, color: const Color(0xFF0EA5E9), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF667085), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
