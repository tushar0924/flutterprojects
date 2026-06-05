import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/booking_alert_model.dart';

class BookingAlert extends StatefulWidget {
  const BookingAlert({
    super.key,
    required this.booking,
    required this.onAccept,
    required this.onReject,
  });

  final BookingAlertModel booking;
  final Future<bool> Function(BookingAlertModel booking) onAccept;
  final Future<bool> Function(BookingAlertModel booking) onReject;

  @override
  State<BookingAlert> createState() => _BookingAlertState();
}

class _BookingAlertState extends State<BookingAlert> {
  late int _secondsLeft;
  Timer? _timer;
  _AlertAction _activeAction = _AlertAction.none;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.booking.countdownSeconds;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        Navigator.of(context).pop('timeout');
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _handleAction(
    Future<bool> Function(BookingAlertModel booking) action,
    String result,
    _AlertAction actionType,
  ) async {
    if (_activeAction != _AlertAction.none) return;
    setState(() => _activeAction = actionType);
    final success = await action(widget.booking);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() => _activeAction = _AlertAction.none);
  }

  /// Determines the booking status label based on the requested date.
  String get _statusLabel {
    final date = widget.booking.requestedDate;
    if (date == null) return 'Upcoming';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'Upcoming';
  }

  /// Border / badge color based on status.
  Color get _statusColor {
    final label = _statusLabel;
    if (label == 'Today') return const Color(0xFF22C55E);    // green
    if (label == 'Tomorrow') return const Color(0xFF0EA5E9); // blue
    return const Color(0xFFF97316);                           // orange for Upcoming
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final statusLabel = _statusLabel;
    final statusColor = _statusColor;

    // The cube circle sits completely OUTSIDE and ABOVE the popup card.
    // ─────────────────────────────────────────────────────────────────
    // Layout (outer Stack, children ordered lowest-z → highest-z):
    //
    //   [0] Cube circle  →  top: 0            (behind everything)
    //   [1] Card wrapper →  top: cubeDiameter  (in front; pushed below cube)
    //         inner Stack:
    //           [0] Colored-border card  (behind badge)
    //           [1] Status badge  →  top: -15  (in front, sits on border)
    //
    // Z-order: badge > card > cube  ✓  (badge never hidden)
    // ─────────────────────────────────────────────────────────────────
    const double cubeDiameter = 72.0;
    const double badgeHalfHeight = 15.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ── [0] Cube circle — FIRST child (lowest z, behind card) ──────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: cubeDiameter,
                  height: cubeDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A6B8A), Color(0xFF0B2239)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.40),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/cube.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.view_in_ar_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── [1] Card + badge — SECOND child (highest z, in front) ──────
            // Pushed down by the full cube diameter so the cube is entirely
            // above the card. The status badge then floats ON the top border.
            Padding(
              padding: const EdgeInsets.only(top: cubeDiameter),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── [1a] Coloured-border card ─────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: statusColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.18),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                        const BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Dark header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0B2239),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.notifications_active_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'New Booking alert!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    // Timer badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_secondsLeft}s',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Booking ID
                                Text(
                                  booking.bookingCode,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Scrollable body
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Customer card
                                  _infoCard(
                                    color: const Color(0xFFF1F7FF),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              const Color(0xFF0B2239),
                                          child: Text(
                                            _initialLetter(
                                              booking.customerName,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              booking.customerName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: Color(0xFF101828),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Customer',
                                              style: TextStyle(
                                                color: Color(0xFF667085),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Category card
                                  _infoCard(
                                    color: const Color(0xFFFFF6ED),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.inventory_2_outlined,
                                          color: Color(0xFFB45309),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Category',
                                                style: TextStyle(
                                                  color: Color(0xFFB45309),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                booking.serviceName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF78350F),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.remove_red_eye_outlined,
                                          color: Color(0xFF0EA5E9),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Earnings card
                                  _infoCard(
                                    color: const Color(0xFFEFFFF4),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.currency_rupee,
                                          color: Color(0xFF16A34A),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Earnings',
                                              style: TextStyle(
                                                color: Color(0xFF667085),
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              booking.amountLabel,
                                              style: const TextStyle(
                                                color: Color(0xFF16A34A),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Time + Location card
                                  _infoCard(
                                    color: const Color(0xFFF8F9FA),
                                    child: Column(
                                      children: [
                                        _detailRow(
                                          Icons.access_time_outlined,
                                          booking.timingValueLabel,
                                        ),
                                        const SizedBox(height: 10),
                                        _detailRow(
                                          Icons.location_on_outlined,
                                          booking.location.displayLabel,
                                        ),
                                        if (booking.distanceLabel
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const SizedBox(width: 28),
                                              const Icon(
                                                Icons.location_on,
                                                size: 13,
                                                color: Colors.redAccent,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  '${booking.distanceLabel} km away',
                                                  style: const TextStyle(
                                                    color: Color(0xFF667085),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Reject / Accept buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              _activeAction !=
                                                      _AlertAction.none
                                                  ? null
                                                  : () => _handleAction(
                                                    widget.onReject,
                                                    'rejected',
                                                    _AlertAction.reject,
                                                  ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFFE11D48),
                                            side: const BorderSide(
                                              color: Color(0xFFFCA5A5),
                                              width: 1.5,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child:
                                              _activeAction ==
                                                      _AlertAction.reject
                                                  ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            Color(0xFFE11D48),
                                                          ),
                                                    ),
                                                  )
                                                  : const Text(
                                                    'Reject',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              _activeAction !=
                                                      _AlertAction.none
                                                  ? null
                                                  : () => _handleAction(
                                                    widget.onAccept,
                                                    'accepted',
                                                    _AlertAction.accept,
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF22C55E),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child:
                                              _activeAction ==
                                                      _AlertAction.accept
                                                  ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                  : const Text(
                                                    'Accept',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Footer warning
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Auto-rejected in ${widget.booking.acceptanceWindowSeconds} seconds if no action',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF667085),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── [1b] Status badge — SECOND child (front, on border) ──
                  // Rendered on top of the card. Sits centred on the top
                  // border line between cube and dark header.
                  Positioned(
                    top: -badgeHalfHeight,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: const Color(0xFF667085)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF344054),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String _initialLetter(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'N';
    return trimmed[0].toUpperCase();
  }
}

enum _AlertAction { none, accept, reject }
