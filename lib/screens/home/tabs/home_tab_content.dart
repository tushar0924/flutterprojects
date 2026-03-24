import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/upcoming_job_model.dart';
import '../../../../providers/partner_provider.dart';
import '../../../utils/toast_helper.dart';
import '../job_details_screen.dart';
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
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isOnline = true;
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
      final profileRes = await userRepo.getProfile();
      if (profileRes['success'] == true && profileRes['user'] != null) {
        if (mounted) {
          setState(
            () => _userProfile = profileRes['user'] as Map<String, dynamic>,
          );
        }
      }
      final dashRes = await partnerRepo.getOpsDashboard();
      final dashboard = _extractDashboard(dashRes);
      if (dashRes['success'] == true && dashboard.isNotEmpty && mounted) {
        setState(() {
          _dashboard = dashboard;
          _isOnline =
              (_dashboard!['helper'] as Map<String, dynamic>?)?['isOnline']
                  as bool? ??
              true;
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
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleOnline() async {
    if (!mounted) return;

    final nextState = !_isOnline;
    setState(() => _isOnline = nextState);
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
          final res = await partnerRepo.updateOpsStatus(isOnline: targetState);
          final serverState = res['isOnline'] as bool?;

          if (!mounted) return;
          if (serverState != null && _pendingOnlineState == null) {
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

  String get _displayName {
    if (_dashboard != null) {
      final helper = _dashboard!['helper'] as Map<String, dynamic>?;
      if (helper != null && helper['name'] != null) {
        return helper['name'] as String;
      }
    }
    if (_userProfile != null && _userProfile!['name'] != null) {
      return _userProfile!['name'] as String;
    }
    return 'Helper';
  }

  int get _pendingCount =>
      (_dashboard?['pendingRequestsCount'] as num?)?.toInt() ??
      (_dashboard?['pendingRequestCount'] as num?)?.toInt() ??
      0;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentJobCard(context),
                    const SizedBox(height: 16), // Reduced from 24
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: widget.onViewAllJobs,
                          child: const Text(
                            'Upcoming Jobs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                        ),
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
                    const SizedBox(height: 10),
                    _buildUpcomingJobsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0B2239),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 40, 8, 20), // Tightened top/bottom
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
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
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
                    right: 8,
                    top: 8,
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
          const SizedBox(height: 18),
          SizedBox(
            height: 124,
            child: Row(
              children: [
                _StatCard(
                  icon: Icons.work_outline,
                  value: _isLoading ? '...' : '$_totalUpcomingJobs',
                  label: 'Upcoming Jobs',
                  onTap: widget.onViewAllJobs,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.check_circle_outline,
                  value: _isLoading ? '...' : '$_todayCompleted',
                  label: 'Jobs Completed',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.currency_rupee,
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const JobDetailsScreen(),
                      ),
                    );
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

    return SizedBox(
      height: 145, // Reduced from 170 to save space
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < _upcomingJobs.length; i++) ...[
            _UpcomingJobCard(
              job: _upcomingJobs[i],
              onTap: () {
                final selected = _upcomingJobs[i];
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UpcomingJobDetailScreen(
                      customerName: selected.customerName,
                      rating: selected.displayRating,
                      serviceType: selected.serviceName,
                      earnings: selected.displayAmount,
                      bookingId: selected.bookingId,
                      dayLabel: selected.dayLabel,
                      timeLabel: selected.timeLabel,
                      durationLabel: selected.displayDuration,
                      address: selected.address,
                    ),
                  ),
                );
              },
            ),
            if (i < _upcomingJobs.length - 1) const SizedBox(width: 12),
          ],
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
                        fontSize: 9,
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
  final String value;
  final String label;
  final VoidCallback? onTap;
  const _StatCard({
    required this.icon,
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
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, color: Colors.white, size: 25),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: 30 / 3,
                  fontWeight: FontWeight.w400,
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
  const _UpcomingJobCard({required this.job, required this.onTap});

  final UpcomingJobModel job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF0B2239),
              child: Icon(Icons.person_outline, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          job.serviceName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 12),
                      Text(
                        ' ${job.displayRating}',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _miniDetail(Icons.calendar_today, job.displaySchedule),
                  _miniDetail(Icons.access_time, job.displayDuration),
                  _miniDetail(Icons.currency_rupee, job.displayAmount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475467)),
          ),
        ],
      ),
    );
  }
}
