import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class AppConnectivityState {
  const AppConnectivityState({
    required this.isOnline,
    required this.isChecking,
  });

  final bool isOnline;
  final bool isChecking;

  AppConnectivityState copyWith({
    bool? isOnline,
    bool? isChecking,
  }) {
    return AppConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

class ConnectivityController extends StateNotifier<AppConnectivityState> {
  ConnectivityController()
      : _connectivity = Connectivity(),
        super(const AppConnectivityState(isOnline: true, isChecking: true)) {
    _startPeriodicCheck();
    unawaited(_refreshConnection(showLoading: true));
  }

  final Connectivity _connectivity;
  Timer? _periodicTimer;

  Future<void> retryCheck() async {
    await _refreshConnection(showLoading: true);
  }

  void _startPeriodicCheck() {
    _periodicTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_refreshConnection(showLoading: false));
    });
  }

  Future<void> _refreshConnection({required bool showLoading}) async {
    if (showLoading) {
      state = state.copyWith(isChecking: true);
    }

    final hasInternet = await _hasInternetConnection();
    state = AppConnectivityState(
      isOnline: hasInternet,
      isChecking: false,
    );
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (!_hasTransport(result)) {
        return false;
      }
    } on MissingPluginException {
      // Plugin may not be registered after hot restart. Fall back to DNS check.
    } on PlatformException {
      // Fall back to DNS check when channel invocation fails temporarily.
    }

    try {
      final lookup = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  bool _hasTransport(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }

    if (result is List<ConnectivityResult>) {
      return result.any((value) => value != ConnectivityResult.none);
    }

    return false;
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }
}

final connectivityControllerProvider =
    StateNotifierProvider<ConnectivityController, AppConnectivityState>((ref) {
  return ConnectivityController();
});
