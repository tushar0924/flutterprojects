import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../models/booking_alert_model.dart';
import '../../network/api_endpoint.dart';
import '../../session/session_manager.dart';
import '../../utils/toast_helper.dart';
import 'booking_request_actions_repository.dart';

class BookingSocketState {
  const BookingSocketState({
    this.isConnecting = false,
    this.isConnected = false,
    this.activeBooking,
    this.message,
    this.lastAcceptedBookingId,
    this.lastPaymentConfirmation,
  });

  final bool isConnecting;
  final bool isConnected;
  final BookingAlertModel? activeBooking;
  final String? message;
  final int? lastAcceptedBookingId;
  final PaymentConfirmationEvent? lastPaymentConfirmation;

  BookingSocketState copyWith({
    bool? isConnecting,
    bool? isConnected,
    BookingAlertModel? activeBooking,
    bool clearActiveBooking = false,
    String? message,
    bool clearMessage = false,
    int? lastAcceptedBookingId,
    PaymentConfirmationEvent? lastPaymentConfirmation,
  }) {
    return BookingSocketState(
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      activeBooking: clearActiveBooking
          ? null
          : (activeBooking ?? this.activeBooking),
      message: clearMessage ? null : (message ?? this.message),
      lastAcceptedBookingId:
          lastAcceptedBookingId ?? this.lastAcceptedBookingId,
      lastPaymentConfirmation:
          lastPaymentConfirmation ?? this.lastPaymentConfirmation,
    );
  }
}

class PaymentConfirmationEvent {
  const PaymentConfirmationEvent({
    required this.bookingId,
    required this.paymentId,
    required this.status,
    required this.amount,
    required this.method,
    required this.receivedAt,
  });

  final int bookingId;
  final int paymentId;
  final String status;
  final num amount;
  final String method;
  final DateTime receivedAt;

  String get eventKey =>
      '$bookingId-$paymentId-${receivedAt.microsecondsSinceEpoch}';

  factory PaymentConfirmationEvent.fromSocketPayload(dynamic data) {
    final map = _socketPayloadToMap(data);
    return PaymentConfirmationEvent(
      bookingId: _socketToInt(map['bookingId'] ?? map['booking_id']),
      paymentId: _socketToInt(map['paymentId'] ?? map['payment_id']),
      status: _socketToString(map['status']),
      amount: _socketToNum(map['amount']),
      method: _socketToString(map['method']),
      receivedAt: DateTime.now(),
    );
  }
}

class BookingSocketNotifier extends StateNotifier<BookingSocketState> {
  BookingSocketNotifier(this._ref) : super(const BookingSocketState());

  final Ref _ref;
  final SessionManager _session = SessionManager();
  final AudioPlayer _audioPlayer = AudioPlayer();
  io.Socket? _socket;
  bool _started = false;
  int? _lastNewBookingRequestId;
  DateTime? _lastNewBookingAt;
  int? _inFlightActionRequestId;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _connect();
  }

  Future<void> stop() async {
    _started = false;
    _disconnect();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    final token = await _session.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        clearMessage: true,
      );
      return;
    }

    _disconnect();
    state = state.copyWith(isConnecting: true, clearMessage: true);

    final socket = io.io(
      ApiEndpoint.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth(<String, dynamic>{'token': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket = socket;

    socket.onConnect((_) {
      state = state.copyWith(isConnecting: false, isConnected: true);
    });

    socket.onDisconnect((_) {
      state = state.copyWith(isConnecting: false, isConnected: false);
    });

    socket.onConnectError((_) {
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        message: 'Live booking connection failed',
      );
      AppToast.showError('Live booking connection failed');
    });

    socket.onError((_) {
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        message: 'Live booking socket error',
      );
    });

    socket.on('booking:new', _handleNewBooking);
    socket.on('payment:confirmed', _handlePaymentConfirmed);
    socket.on(
      'booking:closed',
      (data) =>
          _handleBookingClosedEvent(data, 'Booking was closed by the server'),
    );
    socket.on(
      'booking:expired',
      (data) => _handleBookingClosedEvent(data, 'Booking expired'),
    );
    socket.on('booking:alreadyAccepted', (data) {
      _handleBookingClosedEvent(
        data,
        'This booking was already accepted by someone else',
      );
      AppToast.showInfo('This booking was already accepted by someone else');
    });

    socket.connect();
  }

  void _disconnect() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    socket.off('booking:new');
    socket.off('payment:confirmed');
    socket.off('booking:closed');
    socket.off('booking:expired');
    socket.off('booking:alreadyAccepted');
    socket.disconnect();
    socket.dispose();
  }

  Future<void> _playAlertSound() async {
    const candidates = <String>[
      'alert_sounds/alert_sound.mp3',
      'alert_sounds/alert_sound.wav',
      'alert_sounds/alert_sound.m4a',
      'alert_sounds/alert_sound.ogg',
    ];

    try {
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);

      for (final assetPath in candidates) {
        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource(assetPath));
          return;
        } catch (_) {
          // Try next candidate
        }
      }
    } catch (_) {
      // Fall through to system alert sound
    }

    SystemSound.play(SystemSoundType.alert);
  }

  void _handleNewBooking(dynamic data) {
    final booking = BookingAlertModel.fromSocketPayload(data);
    if (booking.requestId == 0) {
      state = state.copyWith(message: 'Received an invalid booking payload');
      return;
    }

    final now = DateTime.now();
    final isDuplicateBurst =
        _lastNewBookingRequestId == booking.requestId &&
        _lastNewBookingAt != null &&
        now.difference(_lastNewBookingAt!).inMilliseconds <= 2500;
    if (isDuplicateBurst) {
      return;
    }

    _lastNewBookingRequestId = booking.requestId;
    _lastNewBookingAt = now;

    state = state.copyWith(activeBooking: booking, clearMessage: true);

    // Play sound asynchronously without blocking
    _playAlertSound().ignore();
    HapticFeedback.heavyImpact();
  }

  void _handlePaymentConfirmed(dynamic data) {
    final event = PaymentConfirmationEvent.fromSocketPayload(data);
    if (event.bookingId <= 0) {
      state = state.copyWith(message: 'Received an invalid payment payload');
      return;
    }

    state = state.copyWith(
      lastPaymentConfirmation: event,
      message: 'Payment confirmed',
    );
  }

  void _handleBookingClosedEvent(dynamic data, String message) {
    final eventRequestId = _extractRequestId(data);
    final activeRequestId = state.activeBooking?.requestId;

    // Ignore stale close events once the popup is already gone.
    if (activeRequestId == null) return;

    // While user action is in flight (accept/reject), that action controls dialog closure.
    if (_inFlightActionRequestId != null &&
        _inFlightActionRequestId == activeRequestId) {
      return;
    }

    if (eventRequestId != null && eventRequestId != activeRequestId) {
      return;
    }

    state = state.copyWith(clearActiveBooking: true, message: message);
    AppToast.showInfo(message);
  }

  int? _extractRequestId(dynamic data) {
    final map = _toMap(data);
    if (map == null) return null;
    final payload = _toMap(map['payload']);

    final value =
        map['requestId'] ??
        payload?['requestId'] ??
        map['id'] ??
        payload?['id'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Future<bool> acceptBooking(BookingAlertModel booking) async {
    final repo = _ref.read(bookingRequestActionsRepositoryProvider);
    _inFlightActionRequestId = booking.requestId;
    try {
      final response = await repo.acceptByRequestId(booking.requestId);
      final success =
          response['success'] == true ||
          response['statusCode'] == 200 ||
          response['statusCode'] == 201;
      if (!success) {
        final message = response['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          state = state.copyWith(message: message);
          AppToast.showError(message);
        }
      } else {
        // Extract bookingId from the response
        final data = response['data'] as Map<String, dynamic>?;
        final bookingId = _extractBookingId(response, data);
        if (bookingId != null) {
          state = state.copyWith(lastAcceptedBookingId: bookingId);
        }
      }
      return success;
    } catch (_) {
      AppToast.showError('Failed to accept booking request');
      return false;
    } finally {
      if (_inFlightActionRequestId == booking.requestId) {
        _inFlightActionRequestId = null;
      }
    }
  }

  int? _extractBookingId(
    Map<String, dynamic> response,
    Map<String, dynamic>? data,
  ) {
    final candidates = <dynamic>[
      data?['bookingId'],
      data?['id'],
      data?['booking_id'],
      response['bookingId'],
      response['id'],
      response['booking_id'],
      data?['booking'] is Map ? (data!['booking'] as Map)['id'] : null,
      data?['booking'] is Map ? (data!['booking'] as Map)['bookingId'] : null,
    ];

    for (final candidate in candidates) {
      if (candidate is int) return candidate;
      if (candidate is num) return candidate.toInt();
      final parsed = int.tryParse(candidate?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  Future<bool> rejectBooking(BookingAlertModel booking) async {
    final repo = _ref.read(bookingRequestActionsRepositoryProvider);
    _inFlightActionRequestId = booking.requestId;
    try {
      final response = await repo.rejectByRequestId(booking.requestId);
      final success =
          response['success'] == true ||
          response['statusCode'] == 200 ||
          response['statusCode'] == 201;
      if (!success) {
        final message = response['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          state = state.copyWith(message: message);
          AppToast.showError(message);
        }
      }
      return success;
    } catch (_) {
      AppToast.showError('Failed to reject booking request');
      return false;
    } finally {
      if (_inFlightActionRequestId == booking.requestId) {
        _inFlightActionRequestId = null;
      }
    }
  }

  void clearActiveBooking(int requestId) {
    final booking = state.activeBooking;
    if (booking == null || booking.requestId != requestId) return;
    state = state.copyWith(clearActiveBooking: true, clearMessage: true);
  }
}

Map<String, dynamic> _socketPayloadToMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _socketToString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

int _socketToInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _socketToNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

final bookingRequestActionsRepositoryProvider =
    Provider<BookingRequestActionsRepository>((ref) {
      return BookingRequestActionsRepository();
    });

final bookingSocketProvider =
    StateNotifierProvider.autoDispose<
      BookingSocketNotifier,
      BookingSocketState
    >((ref) {
      return BookingSocketNotifier(ref);
    });
