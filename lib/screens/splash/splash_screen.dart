import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/partner_onboarding_provider.dart';
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

    final role = (await session.getUserRole() ?? '').trim().toUpperCase();
    if (!mounted) return;

    if (role == 'HELPER') {
      await ref.read(partnerOnboardingProvider.notifier).bootstrap();
      if (!mounted) return;

      final onboarding = ref.read(partnerOnboardingProvider);
      final nextRoute = helperLaunchRouteForState(onboarding);
      Navigator.of(context).pushReplacementNamed(nextRoute);
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRouter.chooseRole);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF29C9E0), Color(0xFF00D09C)],
          ),
        ),
        child: const Center(
          child: Text(
            'Helperr4u',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 34,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
