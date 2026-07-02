import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../models/upcoming_job_model.dart';
import '../../providers/partner_provider.dart';
import 'job_details_screen.dart';
import 'upcoming_job_detail_screen.dart';
import 'job_workflow_navigation.dart';

class UpcomingJobsScreen extends ConsumerStatefulWidget {
  const UpcomingJobsScreen({super.key});

  @override
  ConsumerState<UpcomingJobsScreen> createState() => _UpcomingJobsScreenState();
}

class _UpcomingJobsScreenState extends ConsumerState<UpcomingJobsScreen> {
  String? _selectedServiceType;
  String? _selectedDay;
  List<UpcomingJobModel> _bookings = [];
  bool _isLoading = true;
  String? _apiMessage;
  int _todayJobsCount = 0;
  int _totalUpcomingJobs = 0;

  static const List<String> _serviceTypes = [
    'Service Type',
    'Maid',
    'Cook',
    'Driver',
  ];

  static const List<String> _days = ['Day', 'ALL', 'Today', 'Tomorrow', 'Upcoming'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookings());
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _apiMessage = null;
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
        _bookings = res.jobs;
        _todayJobsCount = res.todayJobsCount;
        _totalUpcomingJobs = res.totalUpcomingJobs;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _bookings = [];
      _todayJobsCount = 0;
      _totalUpcomingJobs = 0;
      _apiMessage = res.message;
      _isLoading = false;
    });
  }

  List<UpcomingJobModel> get _jobs => _bookings;

  String? _dayParam() {
    switch (_selectedDay) {
      case 'ALL':
        return null;
      case 'Today':
        return 'today';
      case 'Tomorrow':
        return 'tomorrow';
      case 'Upcoming':
        return 'upcoming';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2545),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'Upcoming Jobs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown2(
                        title: _serviceTypes.first,
                        selectedValue: _selectedServiceType,
                        items: _serviceTypes.skip(1).toList(),
                        onChanged: (value) async {
                          setState(() {
                            _selectedServiceType = _selectedServiceType == value
                                ? null
                                : value;
                          });
                          await _loadBookings();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterDropdown2(
                        title: _days.first,
                        selectedValue: _selectedDay,
                        items: _days.skip(1).toList(),
                        onChanged: (value) async {
                          setState(() {
                            _selectedDay = _selectedDay == value ? null : value;
                          });
                          await _loadBookings();
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
                    const SizedBox(width: 8),
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
                if (_apiMessage != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _apiMessage!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _jobs.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: Color(0xFF98A2B3),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No Data Found',
                                    style: TextStyle(
                                      color: Color(0xFF667085),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _jobs.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) => _JobCard(
                            job: _jobs[index],
                            onViewDetails: () {
                              final UpcomingJobModel selected = _jobs[index];
                              final status = (selected.status).toUpperCase();
                              if (status == 'IN_PROGRESS') {
                                if (selected.workflowState.trim().isEmpty) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => JobDetailsScreen(
                                        bookingId: selected.id,
                                      ),
                                    ),
                                  );
                                } else {
                                  openJobWorkflowStep(
                                    context,
                                    bookingId: selected.id,
                                    status: selected.status,
                                    workflowState: selected.workflowState,
                                    customerName: selected.customerName,
                                  );
                                }
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UpcomingJobDetailScreen(
                                      jobId: selected.id,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
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
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 11,
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
          _detailRow(Icons.calendar_today_outlined, job.displaySchedule),
          _detailRow(Icons.access_time_outlined, job.displayDuration),
          _detailRow(Icons.location_on_outlined, job.address),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.displayAmount,
                style: const TextStyle(
                  color: Color(0xFF0EA5E9),
                  fontSize: 23,
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

  Widget _detailRow(IconData icon, String value) {
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
