import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/partner_provider.dart';
import '../job_details_screen.dart';
import '../upcoming_jobs_screen.dart';

class HomeTabContent extends ConsumerStatefulWidget {
  const HomeTabContent({
    super.key,
    required this.onMenuTap,
    required this.onNotificationTap,
  });

  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;

  @override
  ConsumerState<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends ConsumerState<HomeTabContent> {
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isOnline = true;

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
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleOnline() async {
    final partnerRepo = ref.read(partnerRepositoryProvider);
    try {
      final res = await partnerRepo.updateOpsStatus(isOnline: !_isOnline);
      if (res['success'] == true && mounted) {
        setState(() => _isOnline = res['isOnline'] as bool? ?? !_isOnline);
      }
    } catch (_) {}
  }

  void _openUpcomingJobs(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UpcomingJobsScreen()));
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

  String get _headlineEarningsLabel {
    final hasOldWeek =
        (_dashboard?['earningsSummary'] as Map<String, dynamic>?)?['week'] !=
        null;
    return hasOldWeek ? 'Week Earning' : 'Lifetime Earning';
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
                          onTap: () => _openUpcomingJobs(context),
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
                          onTap: () => _openUpcomingJobs(context),
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
      padding: const EdgeInsets.fromLTRB(
        16,
        40,
        16,
        20,
      ), // Tightened top/bottom
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleButton(icon: Icons.menu, onTap: widget.onMenuTap),
              Column(
                children: [
                  Text(
                    _isLoading ? '...' : _displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _OnlineToggle(isOnline: _isOnline, onTap: _toggleOnline),
                ],
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
          const SizedBox(height: 20), // Reduced from 25
          Row(
            children: [
              _StatCard(
                icon: Icons.business_center_outlined,
                value: _isLoading ? '...' : '$_pendingCount',
                label: 'Pending Requests',
                onTap: () => _openUpcomingJobs(context),
              ),
              const SizedBox(width: 8),
              _StatCard(
                icon: Icons.check_circle_outline,
                value: _isLoading ? '...' : '$_todayCompleted',
                label: 'Today Completed',
              ),
              const SizedBox(width: 8),
              _StatCard(
                icon: Icons.currency_rupee,
                value: _isLoading ? '...' : '₹$_headlineEarnings',
                label: _headlineEarningsLabel,
              ),
            ],
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
    return SizedBox(
      height: 145, // Reduced from 170 to save space
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: const [
          _UpcomingJobCard(),
          SizedBox(width: 12),
          _UpcomingJobCard(),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF22C55E) : Colors.grey,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 4,
              backgroundColor: isOnline ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 4),
          ],
        ),
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
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 4,
          ), // Tighter padding
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
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
  const _UpcomingJobCard();
  @override
  Widget build(BuildContext context) {
    return Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Priya Sharma',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Maid',
                        style: TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 12),
                    Text(
                      ' 4.9',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _miniDetail(
                  Icons.calendar_today,
                  'Tomorrow • 08-00 AM - 11 AM',
                ),
                _miniDetail(Icons.access_time, '3 hours duration'),
                _miniDetail(Icons.currency_rupee, '₹750 per hour'),
              ],
            ),
          ),
        ],
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
