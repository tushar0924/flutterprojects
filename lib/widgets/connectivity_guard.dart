import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';
import '../screens/common/offline_screen.dart';

class ConnectivityGuard extends ConsumerWidget {
  const ConnectivityGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectivityControllerProvider);

    return Stack(
      children: [
        child,
        if (!connectionState.isOnline)
          Positioned.fill(
            child: OfflineScreen(
              isChecking: connectionState.isChecking,
              onRetry: () {
                ref.read(connectivityControllerProvider.notifier).retryCheck();
              },
            ),
          ),
      ],
    );
  }
}
