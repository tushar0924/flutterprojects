import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../../models/upcoming_job_model.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/partner_provider.dart';

import '../job_details_screen.dart';
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
  bool _isLoadingMore = false;
  String? _jobsApiMessage;
  int _totalUpcomingJobs = 0;
  final int _todayJobsCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  late ScrollController _scrollController;

  static const int _pageLimit = 15;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJobs());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreJobs();
    }
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _jobsApiMessage = null;
      _currentPage = 1;
      _totalPages = 1;
      _apiJobs = [];
    });

    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.getUpcomingBookings(
      page: 1,
      limit: _pageLimit,
      day: _dayParam(),
      serviceType: _serviceTypeParam(),
    );
    if (!mounted) return;

    final success = res.success;
    if (success) {
      setState(() {
        _apiJobs = res.jobs;
        _totalUpcomingJobs = res.pagination.total;
        _currentPage = res.pagination.page;
        _totalPages = res.pagination.totalPages;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _apiJobs = [];
      _totalUpcomingJobs = 0;
      _jobsApiMessage = res.message;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreJobs() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;
    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.getUpcomingBookings(
      page: nextPage,
      limit: _pageLimit,
      day: _dayParam(),
      serviceType: _serviceTypeParam(),
    );
    if (!mounted) return;

    if (res.success) {
      setState(() {
        _apiJobs.addAll(res.jobs);
        _currentPage = res.pagination.page;
        _totalPages = res.pagination.totalPages;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _isLoadingMore = false;
      });
    }
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
    // Match the selected display name against the API category list.
    if (_selectedServiceType == null) return null;
    return _selectedServiceType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B2545),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF0B2545),
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
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
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Upcoming Jobs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF3F5F8),
                child: RefreshIndicator(
                  onRefresh: _loadJobs,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _ServiceTypeFilterDropdown(
                                        selectedValue: _selectedServiceType,
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
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _StatBox(
                                        title: _isLoading ? '...' : '$_todayJobsCount',
                                        subtitle: 'Available Today',
                                        backgroundColor: const Color(0xFFEAF3FF),
                                        borderColor: const Color(0xFFBBD8FF),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatBox(
                                        title: _isLoading ? '...' : '$_totalUpcomingJobs',
                                        subtitle: 'Total Jobs Available',
                                        backgroundColor: const Color(0xFFEAF9E9),
                                        borderColor: const Color(0xFFB7E6B4),
                                      ),
                                    ),
                                  ],
                                ),
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
                              const SizedBox(height: 12),
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
                                  const SizedBox(height: 18),
                                  itemBuilder: (context, index) {
                                    final UpcomingJobModel job = _jobs[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      child: _JobCard(
                                        job: job,
                                        onViewDetails: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => JobDetailsScreen(
                                                bookingId: job.id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              if (_isLoadingMore)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue[400]!,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
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
                          fontSize: 13,
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
              maxHeight: 140,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(height: 40),
          ),
        );
      },
    );
  }
}

// ── State model for the API list ──────────────────────────────────────────────
class _ServiceTypeData {
  final bool isLoading;
  final List<String> items;
  _ServiceTypeData({required this.isLoading, required this.items});
}

// ── Service-Type filter ───────────────────────────────────────────────────────
class _ServiceTypeFilterDropdown extends ConsumerStatefulWidget {
  const _ServiceTypeFilterDropdown({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String> onChanged;

  @override
  ConsumerState<_ServiceTypeFilterDropdown> createState() =>
      _ServiceTypeFilterDropdownState();
}

class _ServiceTypeFilterDropdownState
    extends ConsumerState<_ServiceTypeFilterDropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  final ValueNotifier<_ServiceTypeData> _dataNotifier = ValueNotifier(
    _ServiceTypeData(isLoading: false, items: []),
  );

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _fetchFresh();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _dataNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchFresh() async {
    // Preserve existing items but mark as loading so skeletons appear instantly
    _dataNotifier.value = _ServiceTypeData(isLoading: true, items: _dataNotifier.value.items);

    try {
      final repo = ref.read(partnerRepositoryProvider);
      final response = await repo.getManageServices();
      if (!mounted) return;

      if (response.success) {
        ref
            .read(selectedCategoriesProvider.notifier)
            .setCategories(response.categories);

        _dataNotifier.value = _ServiceTypeData(
          isLoading: false,
          // ONLY MAPPING ITEMS WHERE isSelected IS TRUE
          items: response.categories
              .where((c) => c.isSelected == true)
              .map((c) => c.name)
              .toList(),
        );
      } else {
        _dataNotifier.value = _ServiceTypeData(isLoading: false, items: []);
      }
    } catch (_) {
      if (mounted) {
        final cached = ref.read(selectedCategoriesProvider);
        _dataNotifier.value = _ServiceTypeData(
          isLoading: false,
          items: cached
              .where((c) => c.isSelected == true)
              .map((c) => c.name)
              .toList(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            isExpanded: true,
            onMenuStateChange: (isOpen) {
              if (isOpen) {
                // Hit API *every* time the dropdown opens
                _fetchFresh();
              }
            },
            customButton: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.selectedValue ?? 'Service Type',
                      style: const TextStyle(
                        color: Color(0xFF1D2939),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: Color(0xFF98A2B3),
                  ),
                ],
              ),
            ),
            // We use a single item wrapper to maintain the inner reactive state
            items: [
              DropdownMenuItem<String>(
                value: 'wrapper',
                enabled: false, // Prevents default hover effect on the entire block
                child: ValueListenableBuilder<_ServiceTypeData>(
                  valueListenable: _dataNotifier,
                  builder: (context, data, child) {
                    if (data.isLoading) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: 4,
                        itemBuilder: (_, _) => _SkeletonRow(controller: _shimmerController),
                      );
                    }

                    if (data.items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No active services available',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 13,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: data.items.length,
                      itemBuilder: (context, index) {
                        final item = data.items[index];
                        final isSelected = widget.selectedValue == item;

                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop(); // Close the dropdown manually
                            widget.onChanged(item);      // Trigger the selection update
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      color: Color(0xFF1D2939),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0EA5E9)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0EA5E9)
                                          : const Color(0xFF98A2B3),
                                      width: 1,
                                    ),
                                  ),
                                  child: isSelected
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
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            onChanged: (_) {}, // Handled manually inside the custom list
            dropdownStyleData: DropdownStyleData(
              width: constraints.maxWidth,
              offset: const Offset(0, -2),
              maxHeight: 240,
              elevation: 0,
              padding: EdgeInsets.zero, // Remove padding to allow inner list full control
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(
              height: 240, // Match maxHeight to lock the menu size securely
              padding: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }
}

// ── Skeleton shimmer row ─────────────────────────────────────────────────────
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, child) {
          final t = controller.value;
          return Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [
                  (t - 0.3).clamp(0.0, 1.0),
                  t.clamp(0.0, 1.0),
                  (t + 0.3).clamp(0.0, 1.0),
                ],
                colors: const [
                  Color(0xFFEEEEEE),
                  Color(0xFFDDDDDD),
                  Color(0xFFEEEEEE),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── StatBox ──────────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
              fontSize: 34,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
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

// ── JobCard ──────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onViewDetails});

  final UpcomingJobModel job;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final statusText = _statusText(job.displayState.isNotEmpty ? job.displayState : job.dayLabel);
    final borderColor = statusText.toLowerCase() == 'today'
        ? const Color(0xFF22C55E)
        : statusText.toLowerCase() == 'tomorrow'
        ? const Color(0xFF0EA5E9)
        : statusText.toLowerCase().contains('cancel')
        ? const Color(0xFFEF4444)
        : const Color(0xFFF97316);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFF0B2545),
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.customerName,
                          style: const TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Color(0xFFFDB022),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              job.displayRating,
                              style: const TextStyle(
                                color: Color(0xFF475467),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2545),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      job.serviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                value: job.displaySchedule,
              ),
              _DetailRow(
                icon: Icons.access_time_outlined,
                value: job.displayDuration,
              ),
              _DetailRow(icon: Icons.location_on_outlined, value: job.address),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    job.displayAmount,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: onViewDetails,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        side: const BorderSide(color: Color(0xFFD0D5DD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: Color(0xFF1D2939),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusText(String dayLabel) {
    final normalized = dayLabel.trim().toLowerCase();
    if (normalized.contains('today')) return 'Today';
    if (normalized.contains('tomorrow')) return 'Tomorrow';
    if (normalized.contains('cancel')) return 'Cancelled';
    return 'Upcoming';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF344054)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}