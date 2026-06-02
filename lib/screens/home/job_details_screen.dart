import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking_details_model.dart';
import '../../providers/booking_socket_provider.dart';
import '../../repositories/booking_details_repository.dart';
import 'job_workflow_navigation.dart';
import 'payment_received_job_details_screen.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  const JobDetailsScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  BookingDetailsModel? _booking;
  bool _isLoading = true;
  bool _isRedirectingForPayment = false;
  String? _errorMessage;
  String? _handledPaymentEventKey;
  ProviderSubscription<BookingSocketState>? _bookingSocketSubscription;
  Timer? _paymentTimer;
  int? _remainingSeconds;
  bool _navigatedForTimeout = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingSocketProvider.notifier).start();
      _bookingSocketSubscription = ref.listenManual<BookingSocketState>(
        bookingSocketProvider,
        _onBookingSocketStateChanged,
      );
      _handlePaymentConfirmation(ref.read(bookingSocketProvider));
    });
  }

  @override
  void dispose() {
    _bookingSocketSubscription?.close();
    _paymentTimer?.cancel();
    super.dispose();
  }

  void _onBookingSocketStateChanged(
    BookingSocketState? previous,
    BookingSocketState next,
  ) {
    if (previous?.lastPaymentConfirmation?.eventKey ==
        next.lastPaymentConfirmation?.eventKey) {
      return;
    }

    _handlePaymentConfirmation(next);
  }

  void _handlePaymentConfirmation(BookingSocketState state) {
    final event = state.lastPaymentConfirmation;
    if (event == null || event.bookingId != widget.bookingId) return;
    if (_handledPaymentEventKey == event.eventKey) return;

    _handledPaymentEventKey = event.eventKey;
    _redirectToPaymentReceived();
  }

  Future<void> _fetchBookingDetails() async {
    final repository = ref.read(bookingDetailsRepositoryProvider);
    final booking = await repository.getBookingDetails(widget.bookingId);

    if (!mounted) return;

    if (booking != null) {
      final status = booking.status.toUpperCase();
      if (status == 'IN_PROGRESS') {
        openBookingWorkflowStep(context, booking: booking, replace: true);
        return;
      }
    }

    setState(() {
      _booking = booking;
      _isLoading = false;
      if (booking == null) {
        _errorMessage = 'Failed to load booking details';
      }
    });

    if (booking != null) {
      _initPaymentCountdownFromBooking(booking);
    }
  }

  Future<void> _redirectToPaymentReceived() async {
    if (_isRedirectingForPayment) return;
    _isRedirectingForPayment = true;

    final booking = await _loadConfirmedBookingForRedirect();
    if (!mounted) return;

    if (booking == null) {
      _isRedirectingForPayment = false;
      return;
    }

    // If the booking is already IN_PROGRESS (e.g. OTP_VERIFIED),
    // route through the workflow navigator instead of showing
    // the payment-received detail page.
    if (booking.status.toUpperCase() == 'IN_PROGRESS') {
      openBookingWorkflowStep(context, booking: booking, replace: true);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentReceivedJobDetailsScreen(booking: booking),
      ),
    );
  }

  Future<BookingDetailsModel?> _loadConfirmedBookingForRedirect() async {
    final repository = ref.read(bookingDetailsRepositoryProvider);

    for (var attempt = 0; attempt < 5; attempt++) {
      final booking = await repository.getBookingDetails(widget.bookingId);
      if (!mounted) return null;

      if (booking != null) {
        setState(() {
          _booking = booking;
          _isLoading = false;
          _errorMessage = null;
        });

        _initPaymentCountdownFromBooking(booking);

        if (!booking.isPaymentPending) {
          return booking;
        }
      }

      await Future.delayed(const Duration(milliseconds: 700));
    }

    final booking = _booking;
    if (booking != null && !booking.isPaymentPending) {
      return booking;
    }
    return null;
  }

  void _initPaymentCountdownFromBooking(BookingDetailsModel booking) {
    if (!booking.isPaymentPending) {
      _paymentTimer?.cancel();
      setState(() {
        _remainingSeconds = null;
      });
      return;
    }

    // Use remainingMinutes from backend if provided; otherwise default to 10 minutes
    final minutes = booking.paymentWaiting.remainingMinutes > 0
        ? booking.paymentWaiting.remainingMinutes
        : 10;

    final seconds = minutes * 60;
    _startPaymentCountdown(seconds);
  }

  void _startPaymentCountdown(int seconds) {
    _paymentTimer?.cancel();
    _remainingSeconds = seconds;
    _paymentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds == null) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds! <= 0) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });

        if (!_navigatedForTimeout) {
          _navigatedForTimeout = true;
          // Navigate back to the app's first route (home)
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return;
      }

      setState(() {
        _remainingSeconds = _remainingSeconds! - 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          elevation: 0,
          backgroundColor: const Color(0xFF13223A),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: const Text(
            'Job Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(86),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 100,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const _JobDetailsSkeleton(),
      );
    }

    if (_errorMessage != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Failed to load booking details'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final booking = _booking!;
    final statusLabel = booking.displayBadge.text.isNotEmpty
        ? booking.displayBadge.text
        : booking.displayState.isNotEmpty
        ? booking.displayState
        : booking.status;
    final canShowActions = booking.actions.canStart;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: const Color(0xFF13223A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              booking.id.toString(),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(86),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: _buildStatusHeader(statusLabel, booking),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
        child: Column(
          children: [
            if (booking.isPaymentPending) ...[
              _PendingPaymentCard(booking: booking),
              const SizedBox(height: 12),
            ],
            _SectionContainer(
              title: 'Service Details',
              icon: Icons.business_center_outlined,
              child: Column(
                children: [
                  _infoRow('Booking ID', booking.id.toString()),
                  _infoRow('Category Name', booking.category.name),
                  _infoRow('Total Duration', booking.durationLabel),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: booking.services.isEmpty
                          ? null
                          : () => _showServiceDetails(booking),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Service detail',
                              style: TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            'View Detail',
                            style: TextStyle(
                              color: booking.services.isEmpty
                                  ? const Color(0xFF98A2B3)
                                  : const Color(0xFF60A5FA),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: booking.services.isEmpty
                                  ? TextDecoration.none
                                  : TextDecoration.underline,
                              decorationColor: const Color(0xFF60A5FA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionContainer(
              title: 'Customer Details',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFE2E8F0),
                        child: Text(
                          booking.customer.name.isNotEmpty
                              ? booking.customer.name[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: Color(0xFF475467),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customer.name.isNotEmpty
                                  ? booking.customer.name
                                  : 'Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Customer',
                              style: TextStyle(
                                color: Color(0xFF98A2B3),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!booking.contactUnlocked) ...[
                    const SizedBox(height: 12),
                    const _LockedActionCard(
                      text:
                          'Contact to customer will be available after payment',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionContainer(
              title: 'Service Location',
              icon: Icons.location_on_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (booking.isPaymentPending || !booking.actions.canNavigate)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Navigation will be available after payment',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      booking.location.full,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5B6874),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          const Icon(
                            Icons.done,
                            size: 16,
                            color: Color(0xFF22C55E),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Get Directions',
                            style: TextStyle(
                              color: Color(0xFF0EA5E9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionContainer(
              title: 'Timing',
              icon: Icons.calendar_today_outlined,
              child: Column(
                children: [
                  _infoRow(
                    'Date',
                    booking.date,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _infoRow('Time', booking.time, icon: Icons.access_time),
                  _infoRow(
                    'Total Duration',
                    booking.durationLabel,
                    icon: Icons.access_time,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionContainer(
              title: 'Payment Details',
              icon: Icons.attach_money,
              child: Column(
                children: [
                  _infoRow(
                    'Service Charge',
                    _formatAmount(booking.paymentBreakdown.subtotal),
                  ),
                  _infoRow(
                    'Tax & Fee',
                    _formatAmount(booking.paymentBreakdown.tax),
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    'Total Amount',
                    _formatAmount(booking.paymentBreakdown.total),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _ImportantInfoCard(),
          ],
        ),
      ),
      bottomSheet: canShowActions ? _ActionButtons(booking: booking) : null,
    );
  }

  Widget _buildStatusHeader(String statusLabel, BookingDetailsModel booking) {
    if (booking.isPaymentPending) {
      String waitingText;
      if (_remainingSeconds != null && _remainingSeconds! > 0) {
        final mins = _remainingSeconds! ~/ 60;
        final secs = _remainingSeconds! % 60;
        final formatted =
            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
        waitingText = 'Waiting time: $formatted';
      } else if (booking.paymentWaiting.remainingMinutes > 0) {
        waitingText =
            'Waiting time: ${booking.paymentWaiting.remainingMinutes} minutes';
      } else {
        waitingText = 'Waiting time: 00:00';
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFACC15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Awaiting Customer Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        waitingText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _getStatusColor(booking),
            child: Icon(_getStatusIcon(booking), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusLabel.isNotEmpty ? statusLabel : booking.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _statusDescription(booking),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingDetailsModel booking) {
    final status = booking.status.toUpperCase();
    if (status == 'PENDING_PAYMENT') return const Color(0xFFF9A825);
    if (status == 'COMPLETED') return const Color(0xFF0EA5E9);
    if (status == 'CANCELLED') return const Color(0xFFEF4444);
    return const Color(0xFF22C55E);
  }

  IconData _getStatusIcon(BookingDetailsModel booking) {
    final status = booking.status.toUpperCase();
    if (status == 'PENDING_PAYMENT') return Icons.access_time_filled;
    if (status == 'COMPLETED') return Icons.done_all;
    if (status == 'CANCELLED') return Icons.cancel;
    return Icons.check_circle;
  }

  String _statusDescription(BookingDetailsModel booking) {
    if (booking.isPaymentPending) {
      return 'Waiting for customer payment';
    }
    return 'Ready to proceed';
  }

  String _formatAmount(num value) {
    if (value % 1 == 0) return '₹${value.toInt()}';
    return '₹${value.toStringAsFixed(2)}';
  }

  void _showServiceDetails(BookingDetailsModel booking) {
    final items = booking.services
        .map(
          (service) => _ServiceDetailItem(
            name: service.name,
            included: service.included,
            notIncluded: service.notIncluded,
            requirements: service.requirements,
          ),
        )
        .toList();
    if (items.isEmpty) return;

    final requirements = _requirementsFromServices(booking.services);

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Services Details',
                        style: TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF667085),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: items
                          .map((item) => _ServiceDetailCard(item: item))
                          .toList(),
                    ),
                  ),
                ),
                if (requirements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _RequirementsCard(items: requirements),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _requirementsFromServices(List<BookingService> services) {
    for (final service in services) {
      if (service.requirements.isNotEmpty) return service.requirements;
    }
    return const <String>[];
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isBold = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: const Color(0xFF98A2B3)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF101828),
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPaymentCard extends StatelessWidget {
  const _PendingPaymentCard({required this.booking});

  final BookingDetailsModel booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: Color(0xFFF97316), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting For Payment',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'The remaining information will be shown when the customer makes the payment.',
                  style: TextStyle(color: Color(0xFF9A3412), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
              Icon(icon, size: 16, color: const Color(0xFF475467)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _LockedActionCard extends StatelessWidget {
  const _LockedActionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.booking});

  final BookingDetailsModel booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (booking.actions.canStart) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () =>
                    openBookingWorkflowStep(context, booking: booking),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF1D2939),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImportantInfoCard extends StatelessWidget {
  const _ImportantInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Important Information',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          _InfoBullet(
            text: 'Customer is currently completing the payment process',
          ),
          _InfoBullet(
            text:
                'Complete job details including contact information will be available after payment confirmation',
          ),
          _InfoBullet(
            text: 'You will receive a notification once payment is completed',
          ),
          _InfoBullet(text: 'Please be ready to start the job as scheduled'),
        ],
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF2563EB))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceDetailItem {
  const _ServiceDetailItem({
    required this.name,
    required this.included,
    required this.notIncluded,
    required this.requirements,
  });

  final String name;
  final List<String> included;
  final List<String> notIncluded;
  final List<String> requirements;
}

class _ServiceDetailCard extends StatefulWidget {
  const _ServiceDetailCard({required this.item});

  final _ServiceDetailItem item;

  @override
  State<_ServiceDetailCard> createState() => _ServiceDetailCardState();
}

class _ServiceDetailCardState extends State<_ServiceDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF2563EB),
                  size: 20,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            _chipSection(
              title: 'Includes',
              items: item.included,
              background: const Color(0xFFDCFCE7),
              foreground: const Color(0xFF166534),
            ),
            if (item.notIncluded.isNotEmpty) ...[
              const SizedBox(height: 12),
              _chipSection(
                title: 'Not Included',
                items: item.notIncluded,
                background: const Color(0xFFFEE2E2),
                foreground: const Color(0xFFB91C1C),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _chipSection({
    required String title,
    required List<String> items,
    required Color background,
    required Color foreground,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (text) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What You Need From Customer',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 6, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

class _JobDetailsSkeleton extends StatelessWidget {
  const _JobDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFE4E7EC);
    const lightColor = Color(0xFFF2F4F7);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        // Service Details skeleton
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _box(width: 16, height: 16, color: baseColor),
                  const SizedBox(width: 8),
                  _box(width: 110, height: 13, color: baseColor),
                ],
              ),
              const SizedBox(height: 14),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 10),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 10),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _box(width: 80, height: 11, color: lightColor),
                  _box(width: 60, height: 11, color: baseColor),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Customer Details skeleton
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _box(width: 16, height: 16, color: baseColor),
                  const SizedBox(width: 8),
                  _box(width: 120, height: 13, color: baseColor),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _circle(size: 44, color: baseColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 130, height: 14, color: baseColor),
                        const SizedBox(height: 6),
                        _box(width: 70, height: 11, color: lightColor),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Service Location skeleton
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _box(width: 16, height: 16, color: baseColor),
                  const SizedBox(width: 8),
                  _box(width: 110, height: 13, color: baseColor),
                ],
              ),
              const SizedBox(height: 14),
              _box(width: double.infinity, height: 12, color: lightColor),
              const SizedBox(height: 6),
              _box(width: 180, height: 12, color: lightColor),
              const SizedBox(height: 12),
              _box(width: 100, height: 12, color: baseColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Timing skeleton
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _box(width: 16, height: 16, color: baseColor),
                  const SizedBox(width: 8),
                  _box(width: 55, height: 13, color: baseColor),
                ],
              ),
              const SizedBox(height: 14),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 10),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 10),
              _infoRowSkeleton(baseColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Payment Details skeleton
        _skeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _box(width: 16, height: 16, color: baseColor),
                  const SizedBox(width: 8),
                  _box(width: 110, height: 13, color: baseColor),
                ],
              ),
              const SizedBox(height: 14),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 10),
              _infoRowSkeleton(baseColor),
              const SizedBox(height: 8),
              Container(height: 1, color: lightColor),
              const SizedBox(height: 8),
              _infoRowSkeleton(baseColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Important Info skeleton
        _skeletonCard(
          bgColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFDBEAFE),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 150, height: 13, color: const Color(0xFFBFDBFE)),
              const SizedBox(height: 12),
              _box(
                  width: double.infinity,
                  height: 10,
                  color: const Color(0xFFBFDBFE)),
              const SizedBox(height: 8),
              _box(width: 240, height: 10, color: const Color(0xFFBFDBFE)),
              const SizedBox(height: 8),
              _box(width: 200, height: 10, color: const Color(0xFFBFDBFE)),
              const SizedBox(height: 8),
              _box(width: 180, height: 10, color: const Color(0xFFBFDBFE)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _skeletonCard({
    required Widget child,
    Color bgColor = Colors.white,
    Color borderColor = const Color(0xFFE4E7EC),
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  static Widget _box({
    required double width,
    required double height,
    required Color color,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  static Widget _circle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget _infoRowSkeleton(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _box(width: 90, height: 11, color: color.withValues(alpha: 0.6)),
        _box(width: 70, height: 12, color: color),
      ],
    );
  }
}
