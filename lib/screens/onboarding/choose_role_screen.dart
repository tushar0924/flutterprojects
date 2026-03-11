import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/partner_onboarding_provider.dart';
import '../../routes/app_router.dart';

class ChooseRoleScreen extends ConsumerStatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  ConsumerState<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends ConsumerState<ChooseRoleScreen> {
  int _selected = -1;
  bool _isContinuing = false;

  Future<void> _continue() async {
    setState(() => _isContinuing = true);
    try {
      await ref
          .read(partnerOnboardingProvider.notifier)
          .bootstrap(loadServices: true);
      if (!mounted) return;

      final onboarding = ref.read(partnerOnboardingProvider);
      final route = onboardingRouteForStep(onboarding.currentStep);
      if (route == AppRouter.home) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
      } else {
        Navigator.of(context).pushReplacementNamed(route);
      }
    } finally {
      if (mounted) setState(() => _isContinuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2740),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DD9C0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose Your Role',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select how you want to partner with us',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: <Widget>[
                    _roleCard(
                      id: 0,
                      title: 'Vendor',
                      iconBg: const Color(0xFF2E9BFF),
                      icon: Icons.storefront_outlined,
                      subtitle:
                          'Perfect for Kirana stores, grocery shops and retail businesses.',
                      tags: const <_TagData>[
                        _TagData('Kirana Stores', Color(0xFFFF9800)),
                        _TagData('Retail Business', Color(0xFF9C27B0)),
                      ],
                      comingSoon: true,
                    ),
                    const SizedBox(height: 14),
                    _roleCard(
                      id: 1,
                      title: 'Helper',
                      iconBg: const Color(0xFFFFA726),
                      icon: Icons.person_outline,
                      subtitle:
                          'For maids, cleaners, plumbers, electricians and service providers.',
                      tags: const <_TagData>[
                        _TagData('Maid', Color(0xFFE91E8C)),
                        _TagData('Driver', Color(0xFF2196F3)),
                        _TagData('Cook', Color(0xFF4CAF50)),
                        _TagData('More', Color(0xFF9E9E9E)),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_selected == -1 || _isContinuing)
                            ? null
                            : _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCDD5DC),
                          disabledBackgroundColor: const Color(0xFFCDD5DC),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isContinuing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black87,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Step 1 of 5 • Choose your Role',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard({
    required int id,
    required String title,
    required Color iconBg,
    required IconData icon,
    required String subtitle,
    required List<_TagData> tags,
    bool comingSoon = false,
  }) {
    final selected = _selected == id;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: comingSoon ? const Color(0xFFF0F0F0) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF2196F3) : Colors.transparent,
          width: 1.8,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: comingSoon ? 0.5 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      ...tags.map(_buildTag),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: comingSoon ? null : () => setState(() => _selected = id),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          card,
          if (comingSoon)
            Positioned(
              top: -10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTag(_TagData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TagData {
  const _TagData(this.label, this.color);

  final String label;
  final Color color;
}
