import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/booking_alert_model.dart';
import '../providers/booking_socket_provider.dart';
import '../utils/toast_helper.dart';
import '../features/booking_alert/booking_alert_dialog.dart';
import 'home/home_side_drawer.dart';
import 'home/tabs/earnings_tab_content.dart';
import 'home/tabs/home_tab_content.dart';
import 'home/tabs/jobs_tab_content.dart';
import 'home/job_details_screen.dart';
import 'home/notifications_screen.dart';

class HelperrHome extends ConsumerStatefulWidget {
  const HelperrHome({super.key});

  @override
  ConsumerState<HelperrHome> createState() => _HelperrHomeState();
}

class _HelperrHomeState extends ConsumerState<HelperrHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  DateTime? _lastBackPressAt;
  bool _bookingAlertVisible = false;
  bool _bookingAlertClosing = false;
  BuildContext? _bookingAlertDialogContext;
  BookingAlertModel? _pendingBooking;
  ProviderSubscription<BookingSocketState>? _bookingSocketSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingSocketProvider.notifier).start();
      _bookingSocketSubscription = ref.listenManual<BookingSocketState>(
        bookingSocketProvider,
        _onBookingSocketStateChanged,
      );
    });
  }

  @override
  void dispose() {
    _bookingSocketSubscription?.close();
    try {
      ref.read(bookingSocketProvider.notifier).stop();
    } catch (_) {
      // Ignore error if ref is no longer available after dispose
    }
    super.dispose();
  }

  void _onBookingSocketStateChanged(
    BookingSocketState? previous,
    BookingSocketState next,
  ) {
    final nextBooking = next.activeBooking;
    final previousId = previous?.activeBooking?.requestId;

    if (nextBooking != null && nextBooking.requestId != previousId) {
      if (_bookingAlertVisible) {
        _pendingBooking = nextBooking;
      } else {
        _showBookingAlert(nextBooking);
      }
    }

    if (previous?.activeBooking != null &&
        nextBooking == null &&
        _bookingAlertVisible) {
      _closeBookingAlertFromSocket();
    }
  }

  void _closeBookingAlertFromSocket() {
    if (_bookingAlertClosing || !_bookingAlertVisible) return;
    final dialogContext = _bookingAlertDialogContext;
    if (dialogContext == null) return;

    final route = ModalRoute.of(dialogContext);
    if (route is! PopupRoute || !route.isCurrent || route.navigator == null) {
      return;
    }

    _bookingAlertClosing = true;
    route.navigator!.pop('closed');
  }

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

  Future<void> _showBookingAlert(BookingAlertModel booking) async {
    if (!mounted) return;

    _bookingAlertVisible = true;
    _bookingAlertClosing = false;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        _bookingAlertDialogContext = dialogContext;
        return BookingAlert(
          booking: booking,
          onAccept: (item) =>
              ref.read(bookingSocketProvider.notifier).acceptBooking(item),
          onReject: (item) =>
              ref.read(bookingSocketProvider.notifier).rejectBooking(item),
        );
      },
    );

    _bookingAlertVisible = false;
    _bookingAlertClosing = false;
    _bookingAlertDialogContext = null;

    if (!mounted) return;

    ref
      .read(bookingSocketProvider.notifier)
      .clearActiveBooking(booking.requestId);

    if (result == 'accepted') {
      AppToast.showSuccess('Booking accepted');
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      // Navigate to job details screen with the booking ID from accept response
      final bookingId = ref.read(bookingSocketProvider).lastAcceptedBookingId;
      if (bookingId != null && bookingId > 0) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JobDetailsScreen(bookingId: bookingId),
          ),
        );
      }
    } else if (result == 'rejected') {
      AppToast.showNeutral('Booking rejected');
      await Future.delayed(const Duration(milliseconds: 120));
    }

    final pendingBooking = _pendingBooking;
    _pendingBooking = null;
    final currentBooking = ref.read(bookingSocketProvider).activeBooking;
    if (pendingBooking != null &&
        currentBooking?.requestId == pendingBooking.requestId &&
        pendingBooking.requestId != booking.requestId) {
      await _showBookingAlert(pendingBooking);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) navigator.pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF3F5F8),
        drawer: const HomeSideDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeTabContent(
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              onNotificationTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
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
                  color: active ? const Color(0xFF0B2239) : Colors.transparent,
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
