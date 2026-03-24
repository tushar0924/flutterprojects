import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../../models/upcoming_job_model.dart';
import '../../../providers/partner_provider.dart';

import '../upcoming_job_detail_screen.dart';
import 'jobs_data.dart';

class JobsDashboardTab extends ConsumerStatefulWidget {
  const JobsDashboardTab({super.key});

  @override
  ConsumerState<JobsDashboardTab> createState() => _JobsDashboardTabState();
}

class _JobsDashboardTabState extends ConsumerState<JobsDashboardTab> {
  String? _selectedServiceType;
  String? _selectedDay;
  List<UpcomingJobModel> _apiJobs = [];
  bool _isLoading = true;
  String? _jobsApiMessage;
  int _totalUpcomingJobs = 0;
  int _todayJobsCount = 0;

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
    final res = await repo.getUpcomingBookings(
      limit: 50,
      day: _dayParam(),
      serviceType: _serviceTypeParam(),
    );
    if (!mounted) return;

    final success = res.success;
    if (success) {
      setState(() {
        _apiJobs = res.jobs;
        _totalUpcomingJobs = res.totalUpcomingJobs;
        _todayJobsCount = res.todayJobsCount;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _apiJobs = [];
      _totalUpcomingJobs = 0;
      _todayJobsCount = 0;
      _jobsApiMessage = res.message;
      _isLoading = false;
    });
  }

  List<UpcomingJobModel> get _jobs => _apiJobs;

  String? _dayParam() {
    switch (_selectedDay) {
      case 'Today':
        return 'today';
      case 'Tomorrow':
        return 'tomorrow';
      case 'This Week':
        return 'week';
      default:
        return null;
    }
  }

  String? _serviceTypeParam() {
    switch (_selectedServiceType) {
      case 'Maid':
        return 'MAID';
      case 'Cook':
        return 'COOK';
      case 'Driver':
        return 'DRIVER';
      default:
        return null;
    }
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
                          child: _FilterDropdown2(
                            title: kServiceTypeFilters.first,
                            selectedValue: _selectedServiceType,
                            items: kServiceTypeFilters.skip(1).toList(),
                            onChanged: (value) async {
                              setState(() {
                                _selectedServiceType =
                                    _selectedServiceType == value
                                    ? null
                                    : value;
                              });
                              await _loadJobs();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterDropdown2(
                            title: kDayFilters.first,
                            selectedValue: _selectedDay,
                            items: kDayFilters.skip(1).toList(),
                            onChanged: (value) async {
                              setState(() {
                                _selectedDay = _selectedDay == value
                                    ? null
                                    : value;
                              });
                              await _loadJobs();
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
                            title: _isLoading ? '...' : '$_todayJobsCount',
                            subtitle: 'Available Today',
                            backgroundColor: Color(0xFFEAF3FF),
                            borderColor: Color(0xFFBBD8FF),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            title: _isLoading ? '...' : '$_totalUpcomingJobs',
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
                    if (_jobs.isEmpty && !_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text(
                            'No upcoming jobs found',
                            style: TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        itemCount: _jobs.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final UpcomingJobModel job = _jobs[index];
                          return _JobCard(
                            job: job,
                            onViewDetails: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => UpcomingJobDetailScreen(
                                    customerName: job.customerName,
                                    rating: job.displayRating,
                                    serviceType: job.serviceName,
                                    earnings: job.displayAmount,
                                    bookingId: job.bookingId,
                                    dayLabel: job.dayLabel,
                                    timeLabel: job.timeLabel,
                                    durationLabel: job.displayDuration,
                                    address: job.address,
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

class _FilterDropdown2 extends StatelessWidget {
  const _FilterDropdown2({
    required this.title,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final String? selectedValue;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            isExpanded: true,
            customButton: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedValue ?? title,
                      style: const TextStyle(
                        color: Color(0xFF1D2939),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Color(0xFF98A2B3),
                  ),
                ],
              ),
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Color(0xFF1D2939),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: selectedValue == item
                                ? const Color(0xFF0EA5E9)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: selectedValue == item
                                  ? const Color(0xFF0EA5E9)
                                  : const Color(0xFF98A2B3),
                              width: 1,
                            ),
                          ),
                          child: selectedValue == item
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
            dropdownStyleData: DropdownStyleData(
              width: constraints.maxWidth,
              offset: const Offset(0, -2),
              maxHeight: 124,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(height: 34),
          ),
        );
      },
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

  final UpcomingJobModel job;
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
                      job.customerName,
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
                          job.displayRating,
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
                  job.serviceName,
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
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            value: job.displaySchedule,
          ),
          _DetailRow(
            icon: Icons.access_time_outlined,
            value: job.displayDuration,
          ),
          _DetailRow(icon: Icons.location_on_outlined, value: job.address),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.displayAmount,
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
