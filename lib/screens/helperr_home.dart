import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'home/booking_alert.dart';
import 'home/home_side_drawer.dart';
import 'home/job_details_screen.dart';
import 'home/tabs/earnings_tab_content.dart';
import 'home/tabs/home_tab_content.dart';
import 'home/tabs/jobs_tab_content.dart';
import '../utils/toast_helper.dart';

class HelperrHome extends StatefulWidget {
  const HelperrHome({super.key});

  @override
  State<HelperrHome> createState() => _HelperrHomeState();
}

class _HelperrHomeState extends State<HelperrHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  DateTime? _lastBackPressAt;

  Future<bool> _onWillPop() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return false;
    }

    if (Navigator.of(context).canPop()) {
      return true;
    }

    final now = DateTime.now();
    if (_lastBackPressAt == null ||
        now.difference(_lastBackPressAt!) > const Duration(seconds: 2)) {
      _lastBackPressAt = now;
      AppToast.showNeutral('Press again to exit app');
      return false;
    }

    return true;
  }

  Future<void> _showBookingAlert() async {
    final res = await showDialog(
      context: context,
      builder: (_) => const BookingAlert(),
    );
    if (res == 'accepted' && mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const JobDetailsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF3F5F8),
        drawer: const HomeSideDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeTabContent(
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              onNotificationTap: _showBookingAlert,
              onViewAllJobs: () => setState(() => _currentIndex = 1),
            ),
            const JobsTabContent(),
            const EarningsTabContent(),
          ],
        ),
        bottomNavigationBar: _HomeBottomNav(
          currentIndex: _currentIndex,
          onChanged: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              index: 0,
              currentIndex: currentIndex,
              assetPath: 'assets/icons/home.svg',
              fallbackIcon: Icons.home_outlined,
              label: 'Home',
              onTap: onChanged,
            ),
            _NavItem(
              index: 1,
              currentIndex: currentIndex,
              assetPath: 'assets/icons/job.svg',
              fallbackIcon: Icons.work_outline,
              label: 'Jobs',
              onTap: onChanged,
            ),
            _NavItem(
              index: 2,
              currentIndex: currentIndex,
              assetPath: 'assets/icons/earning.svg',
              fallbackIcon: Icons.account_balance_wallet_outlined,
              label: 'Earnings',
              onTap: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.assetPath,
    required this.fallbackIcon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String assetPath;
  final IconData fallbackIcon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bool active = index == currentIndex;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(index),
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF10AFC0) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    width: 19,
                    height: 19,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      active ? Colors.white : const Color(0xFF667085),
                      BlendMode.srcIn,
                    ),
                    placeholderBuilder: (context) => Icon(
                      fallbackIcon,
                      size: 19,
                      color: active ? Colors.white : const Color(0xFF667085),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 24 / 2,
                  height: 1.05,
                  color: active
                      ? const Color(0xFF101828)
                      : const Color(0xFF667085),
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
