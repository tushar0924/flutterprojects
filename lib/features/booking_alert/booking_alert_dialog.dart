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

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Material(
          color: Colors.white,
          elevation: 20,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF0B2239), Color(0xFF132B46)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 20,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_secondsLeft}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.bookingCode,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF344054),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _infoCard(
                        color: const Color(0xFFF1F7FF),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF0B2239),
                              child: Text(
                                _initialLetter(booking.customerName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
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
                            ),
                          ],
                        ),
                      ),
                      _infoCard(
                        color: const Color(0xFFFFF6ED),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF8B4513),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Work Details',
                                    style: const TextStyle(
                                      color: Color(0xFF8B4513),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.serviceName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF7C5C3D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _infoCard(
                        color: const Color(0xFFEFFFF4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.currency_rupee,
                              color: Color(0xFF2E7D32),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _infoCard(
                        color: const Color(0xFFF8F8F8),
                        child: Column(
                          children: [
                            _detailRow(
                              Icons.access_time_outlined,
                              '${booking.timingHeaderLabel}\n${booking.timingValueLabel}',
                            ),
                            const SizedBox(height: 12),
                            _detailRow(
                              Icons.location_on_outlined,
                              booking.location.displayLabel,
                            ),
                            if (booking.distanceLabel.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const SizedBox(width: 28),
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _activeAction != _AlertAction.none
                                  ? null
                                  : () => _handleAction(
                                      widget.onReject,
                                      'rejected',
                                      _AlertAction.reject,
                                    ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE11D48),
                                side: const BorderSide(
                                  color: Color(0xFFFCA5A5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _activeAction == _AlertAction.reject
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFFE11D48),
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Reject',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _activeAction != _AlertAction.none
                                  ? null
                                  : () => _handleAction(
                                      widget.onAccept,
                                      'accepted',
                                      _AlertAction.accept,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C853),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _activeAction == _AlertAction.accept
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Accept',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.footerLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF667085),
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
    );
  }

  Widget _infoCard({required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF667085)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF344054),
              height: 1.35,
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
