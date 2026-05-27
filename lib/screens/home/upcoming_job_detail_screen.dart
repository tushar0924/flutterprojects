import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_detail_model.dart';
import '../../providers/partner_provider.dart';
import '../../utils/toast_helper.dart';

class UpcomingJobDetailScreen extends ConsumerStatefulWidget {
  const UpcomingJobDetailScreen({
    super.key,
    required this.jobId,
  });

  final int jobId;

  @override
  ConsumerState<UpcomingJobDetailScreen> createState() =>
      _UpcomingJobDetailScreenState();
}

class _UpcomingJobDetailScreenState
    extends ConsumerState<UpcomingJobDetailScreen> {
  JobDetailModel? _jobDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJobDetail());
  }

  Future<void> _loadJobDetail() async {
    try {
      final repo = ref.read(partnerRepositoryProvider);
      final result = await repo.getBookingDetail(widget.jobId);
      final response = JobDetailResponse.fromJson(result);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _jobDetail = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load job details';
          _isLoading = false;
        });
        if (mounted) {
          AppToast.showError(_errorMessage!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        AppToast.showError('Error loading job details');
      }
    }
  }

  List<_ServiceDetailItem> get _serviceDetails {
    final services = _jobDetail?.services ?? const <JobService>[];
    return services
        .map(
          (service) => _ServiceDetailItem(
            name: service.name,
            included: service.included,
            notIncluded: service.notIncluded,
            requirements: service.requirements,
          ),
        )
        .toList();
  }

  List<String> get _requirements {
    final services = _jobDetail?.services ?? const <JobService>[];
    for (final service in services) {
      if (service.requirements.isNotEmpty) return service.requirements;
    }
    return const <String>[];
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final lat = _jobDetail?.location.latitude;
    final lng = _jobDetail?.location.longitude;
    final hasCoordinates = lat != null && lng != null && lat != 0 && lng != 0;
    final locationQuery = _jobDetail?.location.full.trim() ?? '';

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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF1B3A52),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Job Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const _JobDetailSkeleton(),
      );
    }

    if (_errorMessage != null || _jobDetail == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF1B3A52),
              leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Job Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Center(
          child: Text(
            _errorMessage ?? 'Failed to load job details',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final job = _jobDetail!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1B3A52),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Job Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  job.id.toString(),
                  style: const TextStyle(
                    color: Color(0xFFA0A9B3),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        child: Column(
          children: [
            _serviceDetailsCard(),
            const SizedBox(height: 12),
            _customerDetailsCard(),
            const SizedBox(height: 12),
            _serviceLocationCard(context),
            const SizedBox(height: 12),
            _timingCard(),
            const SizedBox(height: 12),
            _paymentDetailsCard(),
            const SizedBox(height: 16),
            _actionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _serviceDetailsCard() {
    if (_jobDetail == null) return const SizedBox.shrink();
    final job = _jobDetail!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.design_services_outlined, 
                color: Color(0xFF667085), size: 18),
              const SizedBox(width: 10),
              const Text(
                'Service Details',
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Booking ID', job.id.toString()),
          const SizedBox(height: 10),
          _detailRow('Category Name', job.category.name),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duration',
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.duration,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _serviceDetails.isEmpty ? null : _showServiceDetails,
                child: Text(
                  'View Detail',
                  style: TextStyle(
                    color: _serviceDetails.isEmpty
                        ? const Color(0xFF98A2B3)
                        : const Color(0xFF60A5FA),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: _serviceDetails.isEmpty
                        ? TextDecoration.none
                        : TextDecoration.underline,
                    decorationColor: const Color(0xFF60A5FA),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showServiceDetails() {
    final items = _serviceDetails;
    if (items.isEmpty) return;
    final requirements = _requirements;
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
                      children: items
                          .map((item) => _ServiceDetailCard(item: item))
                          .toList(),
                    ),
                  ),
                ),
                if (requirements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _RequirementsCard(items: requirements),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _servicesList() {
    if (_jobDetail == null) return const SizedBox.shrink();
    final job = _jobDetail!;
    if (job.services.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFFEAECF0), height: 12),
        const Text(
          'Service detail',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        ...job.services.map((service) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${service.name} (x${service.quantity})',
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '₹${(service.price * service.quantity).toInt()}',
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _customerDetailsCard() {
    if (_jobDetail == null) return const SizedBox.shrink();
    final job = _jobDetail!;
    final firstLetter = job.customer.name.isNotEmpty 
        ? job.customer.name[0].toUpperCase() 
        : 'C';
    final helperLetter = job.helper.name.isNotEmpty 
        ? job.helper.name[0].toUpperCase() 
        : 'H';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, 
                color: Color(0xFF667085), size: 18),
              const SizedBox(width: 10),
              const Text(
                'Customer Details',
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1B3A52),
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.customer.name,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star, 
                          color: Color(0xFFFDB022), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          job.helper.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF475467),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF0EA5E9),
                child: Text(
                  helperLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceLocationCard(BuildContext context) {
    if (_jobDetail == null) return const SizedBox.shrink();
    final job = _jobDetail!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, 
                color: Color(0xFF667085), size: 18),
              const SizedBox(width: 10),
              const Text(
                'Service Location',
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            job.location.full,
            style: const TextStyle(
              color: Color(0xFF475467),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => _openGoogleMaps(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0EA5E9),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFD0D5DD), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text(
                'Get Directions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timingCard() {
    if (_jobDetail == null) return const SizedBox.shrink();
    final job = _jobDetail!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_outlined, 
                color: Color(0xFF667085), size: 18),
              const SizedBox(width: 10),
              const Text(
                'Timing',
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _timingRow('Date', job.date),
          const SizedBox(height: 10),
          _timingRow('Time', job.time),
          const SizedBox(height: 10),
          _timingRow('Total Duration', job.duration),
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
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _paymentDetailsCard() {
    if (_jobDetail == null) return const SizedBox.shrink();
    final job = _jobDetail!;
    final totalAmount = job.payment.amount;
    final serviceCharge = (totalAmount * 0.8).toInt();
    final tax = (totalAmount * 0.05).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_outlined, 
                color: Color(0xFF667085), size: 18),
              const SizedBox(width: 10),
              const Text(
                'Payment Details',
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _paymentRow('Service Charge', '₹$serviceCharge'),
          const SizedBox(height: 8),
          _paymentRow('Tax & Fee', '₹$tax'),
          const Divider(color: Color(0xFFEAECF0), height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₹${totalAmount.toInt()}',
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    if (_jobDetail == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Handle Report Issue
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.report_problem_outlined, 
              color: Color(0xFFEF4444), size: 16),
            label: const Text(
              'Report Issue',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Handle Start
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3A52),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text(
              'Start',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JobDetailSkeleton extends StatelessWidget {
  const _JobDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFE4E7EC);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _line(width: 140, height: 14, color: baseColor),
                  const Spacer(),
                  _line(width: 64, height: 12, color: baseColor),
                ],
              ),
              const SizedBox(height: 12),
              _line(width: 120, height: 10, color: baseColor),
              const SizedBox(height: 10),
              _line(width: 180, height: 10, color: baseColor),
              const SizedBox(height: 16),
              _divider(color: baseColor),
              const SizedBox(height: 14),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 10),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 10),
              _infoRowSkeleton(baseColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _skeletonCard(
          child: Row(
            children: [
              _circle(size: 48, color: baseColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(width: 140, height: 12, color: baseColor),
                    const SizedBox(height: 6),
                    _line(width: 60, height: 10, color: baseColor),
                  ],
                ),
              ),
              _circle(size: 30, color: baseColor),
              const SizedBox(width: 8),
              _circle(size: 30, color: baseColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(width: 110, height: 12, color: baseColor),
              const SizedBox(height: 8),
              _line(width: double.infinity, height: 12, color: baseColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(width: 90, height: 12, color: baseColor),
              const SizedBox(height: 10),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 8),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 8),
              _infoRowSkeleton(baseColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(width: 120, height: 12, color: baseColor),
              const SizedBox(height: 10),
              _line(width: double.infinity, height: 10, color: baseColor),
              const SizedBox(height: 8),
              _line(width: 140, height: 10, color: baseColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _skeletonCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: child,
    );
  }

  static Widget _line({required double width, required double height, required Color color}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  static Widget _circle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget _divider({required Color color}) {
    return Container(
      height: 1,
      color: color,
    );
  }

  static Widget _infoRowSkeleton(Color color) {
    return Row(
      children: [
        _circle(size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: _line(width: double.infinity, height: 12, color: color),
        ),
      ],
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
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
