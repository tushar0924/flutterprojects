import 'package:flutter/material.dart';

import 'home/booking_alert.dart';
import 'home/home_side_drawer.dart';
import 'home/job_details_screen.dart';
import 'home/tabs/earnings_tab_content.dart';
import 'home/tabs/home_tab_content.dart';
import 'home/tabs/jobs_tab_content.dart';

class HelperrHome extends StatefulWidget {
  const HelperrHome({super.key});

  @override
  State<HelperrHome> createState() => _HelperrHomeState();
}

class _HelperrHomeState extends State<HelperrHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

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
    return Scaffold(
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              index: 0,
              currentIndex: currentIndex,
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: onChanged,
            ),
            _NavItem(
              index: 1,
              currentIndex: currentIndex,
              icon: Icons.work_outline,
              label: 'Jobs',
              onTap: onChanged,
            ),
            _NavItem(
              index: 2,
              currentIndex: currentIndex,
              icon: Icons.account_balance_wallet_outlined,
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
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
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
          height: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF10AFC0) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: active ? Colors.white : const Color(0xFF344054),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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
