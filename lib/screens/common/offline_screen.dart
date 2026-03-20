import 'package:flutter/material.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({
    super.key,
    required this.onRetry,
    required this.isChecking,
  });

  final VoidCallback onRetry;
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minimalist Icon Graphic
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 64,
                    color: const Color(0xFFFA2F6A),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Direct, Professional Text
              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please check your network settings and try again to restore your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 56),

              // Premium Action Button
              SizedBox(
                width: 200, // Fixed width for a more "designed" look
                height: 52,
                child: ElevatedButton(
                  onPressed: isChecking ? null : onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F1F1F), // Darker for a premium look
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF1F1F1F).withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isChecking
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Secondary "Check Settings" hint (Optional)
            ],
          ),
        ),
      ),
    );
  }
}