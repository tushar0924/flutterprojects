import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routes/app_router.dart';
import '../../session/session_manager.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final session = SessionManager();
    final isLoggedIn = await session.isLoggedIn;
    if (!mounted) return;

    if (!isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRouter.chooseRole);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background color to solid white to match your design
      backgroundColor: Colors.white,
      body: Center(
        // Render the image from assets
        child: Image.asset(
          'assets/splashicon.png',
          width: 180, // You can adjust the width/height to fit your exact preference
          height: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}