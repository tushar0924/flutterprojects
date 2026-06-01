import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/job_detail_model.dart';
import '../../providers/partner_provider.dart';
import '../../repositories/booking_details_repository.dart';
import '../../routes/app_router.dart';
import '../../utils/toast_helper.dart';
import '../help_support/help_support_screen.dart';
import 'job_completed_popup.dart';

class JobInProgressScreen extends ConsumerStatefulWidget {
  const JobInProgressScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  ConsumerState<JobInProgressScreen> createState() => _JobInProgressScreenState();
}

class _JobInProgressScreenState extends ConsumerState<JobInProgressScreen> {
  Duration _remaining = Duration.zero;
  Timer? _timer;
  JobDetailModel? _jobDetail;
  bool _isLoading = true;
  String? _errorMessage;
  double _progress = 0.0;

  // List to store uploaded images
  final List<File> _uploadedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJobDetail());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimerState() {
    final job = _jobDetail;
    if (job == null) {
      _remaining = Duration.zero;
      _progress = 0.0;
      return;
    }

    final startedAt = job.timeline.startedAt;
    if (startedAt == null || startedAt.isEmpty) {
      _remaining = Duration.zero;
      _progress = 0.0;
      return;
    }

    final started = DateTime.tryParse(startedAt);
    if (started == null) {
      _remaining = Duration.zero;
      _progress = 0.0;
      return;
    }

    final totalMinutes = _totalDurationMinutesFromJob(job);
    final expected = started.add(Duration(minutes: totalMinutes));
    final now = DateTime.now().toUtc();
    final remaining = expected.difference(now);
    final elapsed = now.difference(started);

    _remaining = remaining.isNegative ? Duration.zero : remaining;
    final totalSeconds = (totalMinutes * 60).clamp(1, 1000000);
    final elapsedSeconds = elapsed.inSeconds.clamp(0, totalSeconds);
    _progress = (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  void _startTimer() {
    _timer?.cancel();
    _calculateTimerState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _calculateTimerState();

        if (_remaining.inSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  int _totalDurationMinutesFromJob(JobDetailModel job) {
    final services = job.services;
    if (services.isEmpty) return 0;
    var total = 0;
    for (final s in services) {
      // totalDuration is already calculated by backend
      total += s.totalDuration;
    }
    return total;
  }

  Future<void> _loadJobDetail() async {
    try {
      final repo = ref.read(partnerRepositoryProvider);
      final result = await repo.getBookingDetail(widget.bookingId);
      final response = JobDetailResponse.fromJson(result);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _jobDetail = response.data;
          _calculateTimerState();
          _isLoading = false;
        });

        _startTimer();
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load job details';
          _isLoading = false;
        });
        if (mounted) AppToast.showError(_errorMessage!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      AppToast.showError('Error loading job details');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _uploadedImages.add(File(image.path));
      });
      // upload the picked photo as after-work photo
      try {
        final repo = ref.read(bookingDetailsRepositoryProvider);
        final success = await repo.uploadAfterPhotos(_jobDetail?.id ?? widget.bookingId, [image]);
        if (success) {
          AppToast.showSuccess('Photo uploaded');
        } else {
          AppToast.showError('Failed to upload photo');
        }
      } catch (_) {
        AppToast.showError('Failed to upload photo');
      }
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

  String get _bookingLabel {
    final id = _jobDetail?.id ?? widget.bookingId;
    return id > 0 ? 'Booking ID: $id' : 'Booking ID: --';
  }

  PreferredSizeWidget _buildAppBar(Color backgroundColor) {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        onPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            navigator.pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
          }
        },
      ),
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
            _bookingLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Home',
          icon: const Icon(Icons.home_outlined, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.home,
              (route) => false,
            );
          },
        ),
        IconButton(
          tooltip: 'Help',
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HelpSupportScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color navyDark = Color(0xFF102A43);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(navyDark),
        body: _buildSkeletonBody(navyDark),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(navyDark),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(navyDark),
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
            _buildServiceLocationCard(),
            const SizedBox(height: 16),
            _buildServiceDetailsMainCard(),
            const SizedBox(height: 16),
            _buildTimingCard(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(color: Colors.white),
        child: ElevatedButton.icon(
          onPressed: _uploadedImages.isNotEmpty
              ? () {
                  final startedStr = _jobDetail?.timeline.startedAt;
                  DateTime? started;
                  if (startedStr != null && startedStr.isNotEmpty) started = DateTime.tryParse(startedStr);
                  final now = DateTime.now().toUtc();
                  final elapsed = started != null ? now.difference(started) : Duration.zero;
                  final timeTaken = _formatDuration(elapsed);

                  showJobCompletedPopup(
                    context,
                    timeTaken: timeTaken,
                    onConfirmed: () async {
                      final repo = ref.read(bookingDetailsRepositoryProvider);
                      final success = await repo.completeBooking(_jobDetail?.id ?? widget.bookingId);
                      if (!context.mounted) return;
                      if (success) {
                        showRateExperiencePopup(context);
                      } else {
                        AppToast.showError('Failed to complete booking');
                      }
                    },
                  );
                }
              : null,
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
            backgroundColor: _uploadedImages.isNotEmpty ? const Color(0xFF00C853) : const Color(0xFFCCCCCC),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonBody(Color timerColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimerSkeleton(timerColor),
          const SizedBox(height: 16),
          _buildPhotoSkeleton(),
          const SizedBox(height: 16),
          _buildDetailSkeleton(lines: 3),
          const SizedBox(height: 16),
          _buildDetailSkeleton(lines: 2),
          const SizedBox(height: 16),
          _buildDetailSkeleton(lines: 3),
        ],
      ),
    );
  }

  Widget _buildTimerSkeleton(Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _skeletonBox(width: 110, height: 13, color: Colors.white24),
          const SizedBox(height: 14),
          _skeletonBox(width: 220, height: 48, color: Colors.white24),
          const SizedBox(height: 22),
          _skeletonBox(height: 8, color: Colors.white24),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _skeletonBox(width: 100, height: 12, color: Colors.white24),
              _skeletonBox(width: 100, height: 12, color: Colors.white24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSkeleton() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _skeletonBox(width: 170, height: 16),
              _skeletonBox(width: 78, height: 12),
            ],
          ),
          const SizedBox(height: 8),
          _skeletonBox(width: 230, height: 12),
          const SizedBox(height: 20),
          Row(
            children: [
              _skeletonBox(width: 100, height: 100, radius: 12),
              const SizedBox(width: 12),
              _skeletonBox(width: 100, height: 100, radius: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSkeleton({required int lines}) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skeletonBox(width: 18, height: 18, radius: 9),
              const SizedBox(width: 8),
              _skeletonBox(width: 135, height: 15),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < lines; i++) ...[
            _skeletonBox(width: i == lines - 1 ? 180 : double.infinity, height: 13),
            if (i < lines - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _skeletonBox({
    double width = double.infinity,
    required double height,
    double radius = 6,
    Color color = const Color(0xFFE2E8F0),
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
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
              value: _progress,
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
            children: [
              Text(
                _getStartedTimeLabel(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _getTargetTimeLabel(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
            children: [
              const Text(
                'Upload After Work Photo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'Min 5 photos (${_uploadedImages.length}/5)',
                style: TextStyle(
                  fontSize: 11,
                  color: _uploadedImages.isNotEmpty ? const Color(0xFF00C853) : Colors.grey,
                  fontWeight: _uploadedImages.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                ),
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
    final job = _jobDetail;
    final customer = job?.customer;
    final helper = job?.helper;

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
              CircleAvatar(
                backgroundColor: const Color(0xFF102A43),
                child: Text(
                  customer?.name.isNotEmpty == true ? customer!.name[0].toUpperCase() : 'C',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.name ?? 'Customer',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        Text(
                          ' ${helper?.rating.toStringAsFixed(1) ?? '0.0'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
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

  Widget _buildServiceLocationCard() {
    final job = _jobDetail;
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Service Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job?.location.short ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsMainCard() {
    final job = _jobDetail;
    final category = job?.category.name ?? 'Service';

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Booking ID: ${job?.id ?? ''}',
            style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.0),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Service Detail',
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.0),
                ),
              ),
              TextButton(
                onPressed: job == null ? null : () => _showServiceDetailsDialog(job),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View Detail',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimingCard() {
    final job = _jobDetail;
    if (job == null) return const SizedBox.shrink();

    String dateLabel = '';
    String timeLabel = '';
    String durationLabel = '';

    if (job.timeline.startedAt != null && job.timeline.startedAt!.isNotEmpty) {
      final started = DateTime.tryParse(job.timeline.startedAt!);
      if (started != null) {
        final local = started.toLocal();
        final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        dateLabel = '${dayNames[local.weekday - 1]} ${local.day}/${local.month}/${local.year}';
        final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
        final minute = local.minute.toString().padLeft(2, '0');
        final ampm = local.hour >= 12 ? 'PM' : 'AM';
        timeLabel = '$hour:$minute $ampm';
        
        final totalMinutes = _totalDurationMinutesFromJob(job);
        durationLabel = _formatDurationLabel(totalMinutes);
      }
    }

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule_outlined, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Timing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _timingRow('Date', dateLabel),
          const SizedBox(height: 10),
          _timingRow('Time', timeLabel),
          const SizedBox(height: 10),
          _timingRow('Total Duration', durationLabel),
        ],
      ),
    );
  }

  Widget _timingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  String _formatTimeLocal(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  String _formatDurationLabel(int totalMinutes) {
    if (totalMinutes < 60) return '$totalMinutes minutes';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '$hours hours';
    return '$hours h $minutes m';
  }

  void _showServiceDetailsDialog(JobDetailModel job) {
    final services = job.services
        .map(
          (s) => _ServiceDetailItem(
            name: s.name,
            included: s.included,
            notIncluded: s.notIncluded,
            requirements: s.requirements,
          ),
        )
        .toList();

    List<String> requirements = [];
    for (final s in job.services) {
      if (s.requirements.isNotEmpty) {
        requirements = s.requirements;
        break;
      }
    }

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
                      children: services.map((item) => _ServiceDetailCard(item: item)).toList(),
                    ),
                  ),
                ),
                if (requirements.isNotEmpty) ...[const SizedBox(height: 12), _RequirementsCard(items: requirements)],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStartedTimeLabel() {
    final job = _jobDetail;
    if (job == null || job.timeline.startedAt == null || job.timeline.startedAt!.isEmpty) {
      return 'Started: --:-- --';
    }
    final started = DateTime.tryParse(job.timeline.startedAt!);
    if (started == null) return 'Started: --:-- --';
    return 'Started: ${_formatTimeLocal(started)}';
  }

  String _getTargetTimeLabel() {
    final job = _jobDetail;
    if (job == null) return 'Target: --:-- --';
    final totalMinutes = _totalDurationMinutesFromJob(job);
    if (job.timeline.startedAt == null || job.timeline.startedAt!.isEmpty) {
      return 'Target: --:-- --';
    }
    final started = DateTime.tryParse(job.timeline.startedAt!);
    if (started == null) return 'Target: --:-- --';
    final expected = started.add(Duration(minutes: totalMinutes));
    return 'Target: ${_formatTimeLocal(expected)}';
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
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
