import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'job_completed_popup.dart';

class JobInProgressScreen extends StatefulWidget {
  const JobInProgressScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<JobInProgressScreen> createState() => _JobInProgressScreenState();
}

class _JobInProgressScreenState extends State<JobInProgressScreen> {
  // Updated timer to 5:16 as per your second image
  Duration _remaining = const Duration(minutes: 5, seconds: 16);
  Timer? _timer;

  // List to store uploaded images
  final List<File> _uploadedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _remaining -= const Duration(seconds: 1);
      });
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _uploadedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
  }

  String _formatDuration(Duration value) {
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes = (value.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    const Color navyDark = Color(0xFF102A43);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: navyDark,
        leading: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job In Progress',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'BKG_1765279069209',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.home_outlined, color: Colors.white),
          SizedBox(width: 12),
          Icon(Icons.help_outline, color: Colors.white),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTimerCard(navyDark),
            const SizedBox(height: 16),
            _buildUploadSection(),
            const SizedBox(height: 16),
            _buildCustomerCard(),
            const SizedBox(height: 16),
            _buildServiceDetailsCard(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(color: Colors.white),
        child: ElevatedButton.icon(
          onPressed: () => showJobCompletedPopup(context),
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          label: const Text(
            'Mark Job as Done',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard(Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Time Remaining',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(_remaining),
            style: const TextStyle(
              color: Colors.red, // Red color as seen in second image
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.8, // Static high progress to match image
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00C853),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Started: 10:00 AM',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Target: 12:00 PM',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Upload After Work Photo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'Min 5 photos',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const Text(
            'Capture photos showing the work done.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Image Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...List.generate(_uploadedImages.length, (index) {
                return _buildImageThumbnail(index);
              }),
              _buildAddPhotoButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00C853), width: 2),
            image: DecorationImage(
              image: FileImage(_uploadedImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Delete button
        PositionBy(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        // Index number bubble
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF00C853),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Color(0xFF64748B), size: 32),
            Text(
              'Add Photo',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Customer Details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF102A43),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priya Sharma',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 14),
                        Text(
                          ' 4.8',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _actionIcon(Icons.call, const Color(0xFF102A43)),
              const SizedBox(width: 8),
              _actionIcon(Icons.chat_bubble, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maid Service',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Booking ID: 1762415711831',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Text(
            'Jhadu, Pocha aur Bartan',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _infoRow(Icons.calendar_today, 'Date', 'Thursday, November 6, 2025'),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time, 'Time & Duration', '06:00 AM • 8 hours'),
          const SizedBox(height: 12),
          _infoRow(
            Icons.location_on_outlined,
            'Service Location',
            'Location...\nJaipur, India',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

// Simple helper to fix the Positioned issue in the snippet
class PositionBy extends StatelessWidget {
  final double? top, right, bottom, left;
  final Widget child;
  const PositionBy({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.child,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    right: right,
    bottom: bottom,
    left: left,
    child: child,
  );
}
