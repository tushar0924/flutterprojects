import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/partner_provider.dart';

import '../upcoming_job_detail_screen.dart';
import 'jobs_data.dart';
import 'jobs_models.dart';

class JobsDashboardTab extends ConsumerStatefulWidget {
  const JobsDashboardTab({super.key});

  @override
  ConsumerState<JobsDashboardTab> createState() => _JobsDashboardTabState();
}

class _JobsDashboardTabState extends ConsumerState<JobsDashboardTab> {
  String _selectedServiceType = kServiceTypeFilters.first;
  String _selectedDay = kDayFilters.first;
  List<Map<String, dynamic>> _apiJobs = [];
  bool _isLoading = true;
  String? _jobsApiMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJobs());
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _jobsApiMessage = null;
    });

    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.getPublicJobs(limit: 50);
    if (!mounted) return;

    final success = res['success'] == true;
    if (success) {
      final jobsList =
          (res['jobs'] as List<dynamic>?) ??
          (res['data'] as List<dynamic>?) ??
          const <dynamic>[];
      setState(() {
        _apiJobs = jobsList.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _apiJobs = [];
      _jobsApiMessage = res['message'] as String?;
      _isLoading = false;
    });
  }

  List<UpcomingJobItem> get _jobs {
    if (_apiJobs.isEmpty) return kUpcomingJobs;
    return _apiJobs.map(_mapApiJob).toList();
  }

  int get _availableTodayCount {
    final now = DateTime.now();
    int count = 0;
    for (final j in _apiJobs) {
      final raw = j['scheduledAt'] ?? j['schedule'] ?? j['date'];
      if (raw is! String) continue;
      final dt = DateTime.tryParse(raw);
      if (dt != null &&
          dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        count++;
      }
    }
    return count;
  }

  String _formatAmount(dynamic raw) {
    if (raw == null) return '₹0';
    if (raw is num) return '₹${raw.toStringAsFixed(raw % 1 == 0 ? 0 : 2)}';
    return '₹$raw';
  }

  UpcomingJobItem _mapApiJob(Map<String, dynamic> job) {
    final customer = job['customer'] as Map<String, dynamic>?;
    final service = job['service'] as Map<String, dynamic>?;
    final scheduleRaw = job['scheduledAt'] ?? job['schedule'] ?? job['date'];
    final durationRaw =
        job['estimatedHours'] ?? job['durationHours'] ?? job['duration'];

    return UpcomingJobItem(
      name:
          (customer?['name'] ??
                  job['customerName'] ??
                  job['title'] ??
                  'Customer')
              .toString(),
      rating: (customer?['rating'] ?? job['rating'] ?? '4.5').toString(),
      serviceType:
          (service?['name'] ??
                  job['serviceType'] ??
                  job['category'] ??
                  'Service')
              .toString(),
      schedule: scheduleRaw?.toString() ?? '—',
      duration: durationRaw != null ? '$durationRaw hours duration' : '—',
      address: (job['address'] ?? job['location'] ?? '—').toString(),
      amount: _formatAmount(
        job['totalAmount'] ?? job['amount'] ?? job['budget'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F5F8),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF0B2545),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.business_center_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Upcoming Jobs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _FilterDropdown(
                            value: _selectedServiceType,
                            items: kServiceTypeFilters,
                            onChanged: (value) {
                              setState(() => _selectedServiceType = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterDropdown(
                            value: _selectedDay,
                            items: kDayFilters,
                            onChanged: (value) {
                              setState(() => _selectedDay = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            title: _isLoading
                                ? '...'
                                : '${_apiJobs.isEmpty ? 0 : _availableTodayCount}',
                            subtitle: 'Available Today',
                            backgroundColor: Color(0xFFEAF3FF),
                            borderColor: Color(0xFFBBD8FF),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            title: _isLoading ? '...' : '${_jobs.length}',
                            subtitle: 'Total Jobs Available',
                            backgroundColor: Color(0xFFEAF9E9),
                            borderColor: Color(0xFFB7E6B4),
                          ),
                        ),
                      ],
                    ),
                    if (_jobsApiMessage != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _jobsApiMessage!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    ListView.separated(
                      itemCount: _jobs.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final UpcomingJobItem job = _jobs[index];
                        return _JobCard(
                          job: job,
                          onViewDetails: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UpcomingJobDetailScreen(
                                  customerName: job.name,
                                  rating: job.rating,
                                  serviceType: job.serviceType,
                                  earnings: job.amount,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Color(0xFF98A2B3),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(8),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475467),
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 32,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onViewDetails});

  final UpcomingJobItem job;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF0B2545),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 11,
                          color: Color(0xFFFDB022),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          job.rating,
                          style: const TextStyle(
                            color: Color(0xFF475467),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.serviceType,
                  style: const TextStyle(
                    color: Color(0xFF0B2545),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DetailRow(icon: Icons.calendar_today_outlined, value: job.schedule),
          _DetailRow(icon: Icons.access_time_outlined, value: job.duration),
          _DetailRow(icon: Icons.location_on_outlined, value: job.address),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.amount,
                style: const TextStyle(
                  color: Color(0xFF0EA5E9),
                  fontSize: 35,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF1D2939),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF344054)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
