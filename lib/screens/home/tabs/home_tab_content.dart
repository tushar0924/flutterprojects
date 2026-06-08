import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../models/user_profile_model.dart';
import '../../../../models/upcoming_job_model.dart';
import '../../../../providers/partner_provider.dart';
import '../../../../providers/categories_provider.dart';
import '../../../utils/toast_helper.dart';
import '../job_details_screen.dart';
import '../job_workflow_navigation.dart';
import '../upcoming_job_detail_screen.dart';

class HomeTabContent extends ConsumerStatefulWidget {
  const HomeTabContent({
    super.key,
    required this.onMenuTap,
    required this.onNotificationTap,
    required this.onViewAllJobs,
  });

  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onViewAllJobs;

  @override
  ConsumerState<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends ConsumerState<HomeTabContent> {
  Map<String, dynamic>? _dashboard;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isOnline = true;
  // Tracks whether the user has manually toggled the status at least once this
  // session. When true, we never let the dashboard API overwrite the local state.
  bool _userHasManuallyToggled = false;
  bool _isSyncingOnlineStatus = false;
  bool? _pendingOnlineState;
  List<UpcomingJobModel> _upcomingJobs = [];
  int _totalUpcomingJobs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final partnerRepo = ref.read(partnerRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    try {
      // Pre-load categories for the Jobs tab service-type filter in parallel.
      final categoriesFuture = partnerRepo.getManageServices();

      final profile = await userRepo.getProfileModel();
      if (profile != null && mounted) {
        setState(() => _userProfile = profile);
      }
      final dashRes = await partnerRepo.getOpsDashboard();
      final dashboard = _extractDashboard(dashRes);
      if (dashboard.isNotEmpty && mounted) {
        setState(() {
          _dashboard = dashboard;
          // Only let the server state set the toggle when the user hasn't
          // manually changed it yet this session. This prevents the toggle from
          // flipping back to offline on every refresh after the user went online.
          if (!_userHasManuallyToggled) {
            _isOnline = _resolveOnlineStatus(dashboard, fallback: _isOnline);
          }
        });
      }

      final upcomingRes = await partnerRepo.getUpcomingBookings(limit: 2);
      if (mounted) {
        setState(() {
          _upcomingJobs = upcomingRes.success
              ? upcomingRes.jobs.take(2).toList()
              : <UpcomingJobModel>[];
          _totalUpcomingJobs = upcomingRes.success
              ? upcomingRes.totalUpcomingJobs
              : 0;
        });
      }

      // Resolve & cache the categories so the Jobs tab dropdown is ready.
      final categoriesRes = await categoriesFuture;
      if (categoriesRes.success && mounted) {
        ref
            .read(selectedCategoriesProvider.notifier)
            .setCategories(categoriesRes.categories);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleOnline() async {
    if (!mounted) return;

    final nextState = !_isOnline;
    setState(() {
      _isOnline = nextState;
      _userHasManuallyToggled = true;
    });
    _pendingOnlineState = nextState;

    // Keep tap response instant and sync server state in the background.
    await _flushOnlineStatusSyncQueue();
  }

  Future<void> _flushOnlineStatusSyncQueue() async {
    if (_isSyncingOnlineStatus) return;
    _isSyncingOnlineStatus = true;

    final partnerRepo = ref.read(partnerRepositoryProvider);
    try {
      while (_pendingOnlineState != null) {
        final targetState = _pendingOnlineState!;
        _pendingOnlineState = null;

        try {
          Map<String, dynamic> res;
          try {
            res = await partnerRepo.updateOpsStatus(isOnline: targetState);
          } catch (_) {
            res = <String, dynamic>{};
          }

          // Only accept the server-returned state when it is explicitly
          // present in the response; otherwise keep the user's chosen state.
          final serverState = _resolveOnlineStatus(res, fallback: targetState);

          if (!mounted) return;
          if (_pendingOnlineState == null) {
            setState(() => _isOnline = serverState);
          }
        } catch (_) {
          // Revert only when there isn't a newer user action to apply.
          if (mounted && _pendingOnlineState == null) {
            setState(() => _isOnline = !targetState);
            AppToast.showError('Failed to update status. Please try again.');
          }
        }
      }
    } finally {
      _isSyncingOnlineStatus = false;
    }
  }

  Map<String, dynamic> _extractDashboard(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    final dashboard = payload['dashboard'];
    if (dashboard is Map<String, dynamic>) return dashboard;
    if (dashboard is Map) return Map<String, dynamic>.from(dashboard);

    if (payload['helper'] is Map) return Map<String, dynamic>.from(payload);
    return const <String, dynamic>{};
  }

  bool _resolveOnlineStatus(
    Map<String, dynamic> payload, {
    required bool fallback,
  }) {
    final helper = payload['helper'];
    if (helper is Map) {
      final helperMap = Map<String, dynamic>.from(helper);
      final helperResolved = _readOnlineFromMap(helperMap);
      if (helperResolved != null) return helperResolved;
    }

    final resolved = _readOnlineFromMap(payload);
    return resolved ?? fallback;
  }

  bool? _readOnlineFromMap(Map<String, dynamic> source) {
    const keys = <String>[
      'isOnline',
      'online',
      'active',
      'availability',
      'status',
      'opsStatus',
      'currentStatus',
    ];

    for (final key in keys) {
      final parsed = _parseOnlineValue(source[key]);
      if (parsed != null) return parsed;
    }

    return null;
  }

  bool? _parseOnlineValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'online' || normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'offline' ||
          normalized == 'false' ||
          normalized == '0') {
        return false;
      }
    }
    return null;
  }

  String get _displayName {
    if (_dashboard != null) {
      final helper = _dashboard!['helper'];
      if (helper is Map<String, dynamic>) {
        final fullName = helper['fullName'];
        if (fullName is String && fullName.trim().isNotEmpty) {
          return fullName.trim();
        }

        final name = helper['name'];
        if (name is String && name.trim().isNotEmpty) {
          return name.trim();
        }
      }
    }
    return _userProfile?.displayName ?? 'Helper';
  }

  int get _todayCompleted =>
      (_dashboard?['completedToday'] as num?)?.toInt() ??
      (_dashboard?['todayCompletedJobs'] as num?)?.toInt() ??
      0;

  num get _headlineEarnings {
    final oldSummary = _dashboard?['earningsSummary'] as Map<String, dynamic>?;
    if (oldSummary != null && oldSummary['week'] is num) {
      return oldSummary['week'] as num;
    }

    final earnings = _dashboard?['earnings'] as Map<String, dynamic>?;
    if (earnings != null) {
      return earnings['lifetime'] as num? ??
          earnings['totalPaid'] as num? ??
          earnings['pending'] as num? ??
          0;
    }

    return 0;
  }

  String get _totalEarningLabel {
    if (_headlineEarnings % 1 == 0) {
      return '₹${_headlineEarnings.toInt()}';
    }
    return '₹${_headlineEarnings.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUpcomingJobs = _totalUpcomingJobs > 0 || _upcomingJobs.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isOnline
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Upcoming Jobs',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                              if (hasUpcomingJobs)
                                GestureDetector(
                                  onTap: widget.onViewAllJobs,
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF0EA5E9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildActiveJobCard(context),
                          if (_hasActiveBooking) const SizedBox(height: 30),
                          _buildUpcomingJobsList(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    )
                  : _buildOfflineBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Go online for job request and grab\nyour first booking',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1D2939),
                    fontSize: 21,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0B2239),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 38, 12, 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleButton(icon: Icons.menu, onTap: widget.onMenuTap),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleOnline,
                child: Column(
                  children: [
                    Text(
                      _isLoading ? '...' : _displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      // Invisible hit slop around the toggle; visual UI remains unchanged.
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
                      child: _OnlineToggle(
                        isOnline: _isOnline,
                        onTap: _toggleOnline,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  _circleButton(
                    icon: Icons.notifications_none,
                    onTap: widget.onNotificationTap,
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 132,
            child: Row(
              children: [
                _StatCard(
                  icon: Icons.work_outline,
                  iconAssetPath: 'assets/home_tiles/job_tile.svg',
                  value: _isLoading ? '...' : '$_totalUpcomingJobs',
                  label: 'Upcoming Jobs',
                  onTap: widget.onViewAllJobs,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.check_circle_outline,
                  value: _isLoading ? '...' : '$_todayCompleted',
                  label: 'Jobs Completed',
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.currency_rupee,
                  iconAssetPath: 'assets/home_tiles/earning_tile.svg',
                  value: _isLoading ? '...' : _totalEarningLabel,
                  label: 'Total Earning',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  bool get _hasActiveBooking => _activeBookingMap != null;

  Map<String, dynamic>? get _activeBookingMap {
    final activeBooking = _dashboard?['activeBooking'];
    if (activeBooking is Map<String, dynamic>) return activeBooking;
    if (activeBooking is Map) return Map<String, dynamic>.from(activeBooking);
    return null;
  }

  Widget _buildActiveJobCard(BuildContext context) {
    final activeBooking = _activeBookingMap;
    if (activeBooking == null) return const SizedBox.shrink();

    final bookingId = _activeBookingId(activeBooking);
    final customer = _mapValue(activeBooking['customer']);
    final helper = _mapValue(activeBooking['helper']);
    final location = _mapValue(activeBooking['location']);
    final category = _mapValue(activeBooking['category']);
    final payment = _mapValue(activeBooking['payment']);
    final services = activeBooking['services'] is List
        ? activeBooking['services'] as List
        : const [];
    final service = services.whereType<Map>().isNotEmpty
        ? Map<String, dynamic>.from(services.whereType<Map>().first)
        : const <String, dynamic>{};

    final status = _textValue(activeBooking['status'], fallback: 'IN_PROGRESS');
    final workflowState = _textValue(activeBooking['workflowState']);
    final customerName = _textValue(
      customer['name'] ?? activeBooking['customerName'],
      fallback: 'Customer',
    );
    final serviceName = _textValue(
      service['name'] ?? activeBooking['serviceName'] ?? category['name'],
      fallback: 'Service',
    );
    final address = _textValue(
      activeBooking['address'] ?? location['full'] ?? location['short'],
      fallback: 'Address not available',
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF9B208)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF101828),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
                                _ratingLabel(helper['rating']),
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
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B2545),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            serviceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _HomeJobInfoRow(
                  icon: Icons.calendar_today_outlined,
                  value: _scheduleLabel(activeBooking),
                ),
                _HomeJobInfoRow(
                  icon: Icons.access_time_outlined,
                  value: _textValue(
                    activeBooking['durationLabel'] ?? activeBooking['duration'],
                    fallback: 'Duration not available',
                  ),
                ),
                _HomeJobInfoRow(
                  icon: Icons.location_on_outlined,
                  value: address,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _amountLabel(
                          payment['amount'] ??
                              activeBooking['amount'] ??
                              activeBooking['finalAmount'],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () => _openActiveBooking(
                          context,
                          bookingId,
                          status,
                          workflowState,
                          customerName,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B6472),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9B208),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _activeStatusLabel(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openActiveBooking(
    BuildContext context,
    int bookingId,
    String status,
    String workflowState,
    String customerName,
  ) {
    if (bookingId <= 0) return;
    if (status.toUpperCase() == 'IN_PROGRESS') {
      if (workflowState.trim().isEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JobDetailsScreen(bookingId: bookingId),
          ),
        );
        return;
      }

      openJobWorkflowStep(
        context,
        bookingId: bookingId,
        status: status,
        workflowState: workflowState,
        customerName: customerName,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JobDetailsScreen(bookingId: bookingId)),
    );
  }

  int _activeBookingId(Map<String, dynamic> booking) {
    final value = booking['id'] ?? booking['bookingId'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  String _textValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _activeStatusLabel(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'IN_PROGRESS') return 'In progress';
    if (normalized == 'CONFIRMED') return 'Confirmed';
    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0] + part.substring(1).toLowerCase())
        .join(' ');
  }

  String _ratingLabel(dynamic value) {
    final rating = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (rating == null || rating == 0) return '4.9';
    return rating % 1 == 0
        ? rating.toStringAsFixed(0)
        : rating.toStringAsFixed(1);
  }

  String _scheduleLabel(Map<String, dynamic> booking) {
    final date = _textValue(booking['date']);
    final time = _textValue(booking['time']);
    if (date.isNotEmpty && time.isNotEmpty) return '$date \u2022 $time';
    if (date.isNotEmpty) return date;
    if (time.isNotEmpty) return time;

    final timeline = _mapValue(booking['timeline']);
    final scheduledAt = DateTime.tryParse(_textValue(timeline['scheduledAt']));
    if (scheduledAt == null) return 'Schedule not available';
    final local = scheduledAt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = (local.year % 100).toString().padLeft(2, '0');
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year \u2022 $hour:$minute $period';
  }

  String _amountLabel(dynamic value) {
    final amount = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (amount == null) return '\u20B90';
    if (amount % 1 == 0) return '\u20B9${amount.toInt()}';
    return '\u20B9${amount.toStringAsFixed(2)}';
  }

  // ignore: unused_element
  Widget _buildCurrentJobCard(BuildContext context) {
    final activeBooking = _dashboard?['activeBooking'] as Map<String, dynamic>?;
    if (activeBooking == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: const Center(
          child: Text(
            'No active job',
            style: TextStyle(color: Color(0xFF667085), fontSize: 14),
          ),
        ),
      );
    }
    final customer = activeBooking['customer'] as Map<String, dynamic>?;
    final address = activeBooking['address'] as String? ?? '—';
    final status = activeBooking['status'] as String? ?? 'IN_PROGRESS';
    return Container(
      padding: const EdgeInsets.all(14), // Tighter inner padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Job',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status == 'CONFIRMED' ? 'Confirmed' : 'In Progress',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.person_outline,
            text: customer?['name'] as String? ?? 'Customer',
          ),
          _DetailRow(icon: Icons.location_on_outlined, text: address),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final bookingId = activeBooking['id'] as int? ?? 0;
                    final status =
                        (activeBooking['status'] as String? ?? 'CONFIRMED')
                            .toUpperCase();
                    final workflowState =
                        activeBooking['workflowState'] as String? ?? '';
                    if (status == 'IN_PROGRESS') {
                      if (workflowState.trim().isEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                JobDetailsScreen(bookingId: bookingId),
                          ),
                        );
                      } else {
                        openJobWorkflowStep(
                          context,
                          bookingId: bookingId,
                          status: status,
                          workflowState: workflowState,
                          customerName:
                              customer?['name'] as String? ?? 'Customer',
                        );
                      }
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              JobDetailsScreen(bookingId: bookingId),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Detail',
                    style: TextStyle(color: Color(0xFF344054), fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.check,
                    size: 16,
                    color: Color(0xFF22C55E),
                  ),
                  label: const Text(
                    'Mark as done',
                    style: TextStyle(color: Color(0xFF22C55E), fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFF22C55E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  void _openJobFromIndex(int i) {
    final selected = _upcomingJobs[i];
    final status = (selected.status).toUpperCase();
    if (status == 'IN_PROGRESS') {
      if (selected.workflowState.trim().isEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JobDetailsScreen(bookingId: selected.id),
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
      // For UPCOMING / TODAY / TOMORROW jobs show the dedicated detail screen
      // with the Start button and full job info layout.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UpcomingJobDetailScreen(jobId: selected.id),
        ),
      );
    }
  }

  Widget _buildUpcomingJobsList() {
    if (!_isLoading && _upcomingJobs.isEmpty) {
      return Container(
        width: double.infinity,
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: const Text(
          'No upcoming jobs found',
          style: TextStyle(color: Color(0xFF667085), fontSize: 13),
        ),
      );
    }

    // Single card → full width; multiple cards → horizontal scroll
    if (_upcomingJobs.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: _UpcomingJobCard(
          job: _upcomingJobs[0],
          fullWidth: true,
          onTap: () => _openJobFromIndex(0),
        ),
      );
    }

    return SizedBox(
      // Taller to accommodate the status badge that overflows the top
      height: 240,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(top: 18),
        children: [
          for (int i = 0; i < _upcomingJobs.length; i++) ...[
            _UpcomingJobCard(
              job: _upcomingJobs[i],
              fullWidth: false,
              onTap: () => _openJobFromIndex(i),
            ),
            if (i < _upcomingJobs.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _HomeJobInfoRow extends StatelessWidget {
  const _HomeJobInfoRow({required this.icon, required this.value});

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({this.isOnline = true, this.onTap});
  final bool isOnline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      width: 65,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -11,
            bottom: -11,
            left: -5,
            right: -5,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: const SizedBox.expand(),
            ),
          ),
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 65,
              height: 22,
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF667085),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 160),
                    alignment: isOnline
                        ? const Alignment(-0.6, 0)
                        : const Alignment(0.6, 0),
                    child: Text(
                      isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 160),
                    alignment: isOnline
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String? iconAssetPath;
  final String value;
  final String label;
  final VoidCallback? onTap;
  const _StatCard({
    required this.icon,
    this.iconAssetPath,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.46)),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.10),
                blurRadius: 0,
                spreadRadius: 0.6,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: iconAssetPath == null
                    ? Icon(icon, color: Colors.white, size: 24)
                    : SvgPicture.asset(
                        iconAssetPath!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        placeholderBuilder: (context) =>
                            Icon(icon, color: Colors.white, size: 24),
                      ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0), // Reduced spacing
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF667085)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF475467), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingJobCard extends StatelessWidget {
  const _UpcomingJobCard({
    required this.job,
    required this.onTap,
    this.fullWidth = false,
  });

  final UpcomingJobModel job;
  final VoidCallback onTap;
  /// When true the card expands to fill the available width (single-card layout).
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final statusSource =
        job.displayState.isNotEmpty ? job.displayState : job.dayLabel;

    String normalize(String src) {
      final n = src.trim().toLowerCase();
      if (n.contains('today')) return 'Today';
      if (n.contains('tomorrow')) return 'Tomorrow';
      if (n.contains('in progress') || n.contains('in_progress')) {
        return 'In Progress';
      }
      if (n.contains('cancel')) return 'Cancelled';
      return 'Upcoming';
    }

    final statusText = normalize(statusSource);

    final borderColor = statusText.toLowerCase() == 'today'
        ? const Color(0xFF22C55E)
        : statusText.toLowerCase() == 'tomorrow'
            ? const Color(0xFF0EA5E9)
            : statusText.toLowerCase().contains('cancel')
                ? const Color(0xFFEF4444)
                : statusText.toLowerCase().contains('progress')
                    ? const Color(0xFFF9B208)
                    : const Color(0xFFF97316);

    final cardContent = Container(
      width: fullWidth ? double.infinity : 290,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Customer row ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B2545),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFF59E0B),
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          job.displayRating,
                          style: const TextStyle(
                            color: Color(0xFF475467),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Service badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2545),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Info rows ─────────────────────────────────────────────────────
          _infoRow(Icons.calendar_month_outlined, job.displaySchedule),
          const SizedBox(height: 5),
          _infoRow(Icons.access_time_outlined, _durationLine),
          const SizedBox(height: 5),
          _infoRow(Icons.location_on_outlined, job.displayAddress),
          const SizedBox(height: 14),
          // ── Amount + View Details ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _amountLabel,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B6472),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card must be first so the badge renders on top of it
        cardContent,
        // Status badge floats above the card border, centered at the top
        Positioned(
          top: -14,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _durationLine {
    final raw = job.displayDuration.trim();
    if (raw.isEmpty || raw == '—') return '—';
    final lower = raw.toLowerCase();
    if (lower.contains('hour') || lower.contains('hr') ||
        lower.contains('duration')) {
      return raw;
    }
    return '$raw hours';
  }

  String get _amountLabel {
    final raw = job.displayAmount.trim();
    if (raw.isEmpty || raw == '—') return '₹0';
    if (raw.startsWith('₹') || raw.startsWith('Rs')) return raw;
    return '₹$raw';
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF344054)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF475467),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
