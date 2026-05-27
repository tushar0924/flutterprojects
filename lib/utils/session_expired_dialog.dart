import 'package:flutter/material.dart';
import '../routes/app_router.dart';

/// Shows a professional session expired dialog and navigates to login
Future<void> showSessionExpiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (BuildContext dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFFD32F2F),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Session Expired',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B3A52),
                ),
              ),
              const SizedBox(height: 12),
              // Message
              const Text(
                'Your session has expired. Please login again to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF667085),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // OK Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // Navigate to login and clear all previous routes
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.login,
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3A52),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Login Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows session expired dialog using global navigator key
void showSessionExpiredDialogGlobal(
  BuildContext context, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final navContext = context;
  showSessionExpiredDialog(navContext);
}
