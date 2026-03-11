import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/partner_onboarding_provider.dart';
import '../../routes/app_router.dart';

class OnboardingStep5 extends ConsumerStatefulWidget {
  const OnboardingStep5({super.key});

  @override
  ConsumerState<OnboardingStep5> createState() => _OnboardingStep5State();
}

class _OnboardingStep5State extends ConsumerState<OnboardingStep5> {
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadStatus();
      }
    });
  }

  Future<void> _loadStatus() async {
    await ref.read(partnerOnboardingProvider.notifier).bootstrap();
    if (!mounted) return;

    final onboarding = ref.read(partnerOnboardingProvider);
    final nextStep = onboarding.currentStep;
    if (nextStep == PartnerOnboardingStep.home) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.home, (r) => false);
      return;
    }
    if (nextStep == PartnerOnboardingStep.basicInfo ||
        nextStep == PartnerOnboardingStep.kyc ||
        nextStep == PartnerOnboardingStep.bank) {
      Navigator.of(
        context,
      ).pushReplacementNamed(onboardingRouteForStep(nextStep));
      return;
    }

    setState(() => _isInitialLoading = false);
  }

  Future<void> _refreshStatus() async {
    await ref.read(partnerOnboardingProvider.notifier).refreshStatus();
    if (!mounted) return;

    final onboarding = ref.read(partnerOnboardingProvider);
    final nextStep = onboarding.currentStep;
    if (nextStep == PartnerOnboardingStep.home) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.home, (r) => false);
      return;
    }
    if (nextStep == PartnerOnboardingStep.basicInfo ||
        nextStep == PartnerOnboardingStep.kyc ||
        nextStep == PartnerOnboardingStep.bank) {
      Navigator.of(
        context,
      ).pushReplacementNamed(onboardingRouteForStep(nextStep));
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const Color pageNavy = Color(0xFF09233D);
    const Color accentBlue = Color(0xFF0BC1D6);

    final onboarding = ref.watch(partnerOnboardingProvider);
    final status = onboarding.effectiveStatus;
    final isRejected = onboardingStatusIsRejected(status);
    final displayName = onboarding.fullName.isNotEmpty
        ? onboarding.fullName
        : 'Partner';
    final requestId = onboarding.requestId.isNotEmpty
        ? onboarding.requestId
        : 'Not available';
    final submittedAt = onboarding.submittedAt.isNotEmpty
        ? _formatDateTime(onboarding.submittedAt)
        : 'Not available';
    final busy = _isInitialLoading || onboarding.isBootstrapping;

    return Scaffold(
      backgroundColor: pageNavy,
      appBar: AppBar(
        backgroundColor: pageNavy,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: busy
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : RefreshIndicator(
                onRefresh: _refreshStatus,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: accentBlue,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: accentBlue.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isRejected
                            ? 'Verification Rejected'
                            : 'Verification Pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRejected
                            ? 'Step 5 of 5 • Action Required'
                            : 'Step 5 of 5 • Almost Done!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE4E7EC),
                                ),
                              ),
                              child: Icon(
                                isRejected
                                    ? Icons.error_outline
                                    : Icons.access_time_rounded,
                                color: isRejected
                                    ? const Color(0xFFD92D20)
                                    : const Color(0xFF344054),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Thanks, $displayName!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF101828),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isRejected
                                  ? (onboarding.rejectionReason.isNotEmpty
                                        ? onboarding.rejectionReason
                                        : 'Your application needs changes before approval.')
                                  : 'Your application is under review. We\'ll notify you once it\'s approved.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildDataRow('Request ID', requestId),
                            _buildDivider(),
                            _buildDataRow('Role', 'Helper'),
                            _buildDivider(),
                            _buildDataRow('Submitted', submittedAt),
                            const SizedBox(height: 18),
                            _buildTimelineItem(
                              title: 'Registration Complete',
                              subtitle: 'Your details have been submitted',
                              color: const Color(0xFF12B76A),
                              icon: Icons.check_circle,
                              showLine: true,
                            ),
                            _buildTimelineItem(
                              title: 'Documents Uploaded',
                              subtitle: 'KYC documents received',
                              color: const Color(0xFF12B76A),
                              icon: Icons.check_circle,
                              showLine: true,
                            ),
                            _buildTimelineItem(
                              title: 'Admin Verification',
                              subtitle: isRejected
                                  ? 'Review failed'
                                  : 'In progress...',
                              color: isRejected
                                  ? const Color(0xFFD92D20)
                                  : const Color(0xFFF6C343),
                              icon: isRejected
                                  ? Icons.error_outline
                                  : Icons.access_time_filled,
                              showLine: true,
                              lineColor: isRejected
                                  ? const Color(0xFFF04438)
                                  : const Color(0xFFD0D5DD),
                            ),
                            _buildTimelineItem(
                              title: 'Account Activation',
                              subtitle: isRejected
                                  ? 'Pending resubmission'
                                  : 'Pending approval',
                              color: const Color(0xFF98A2B3),
                              icon: Icons.lock_outline,
                              showLine: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD0D5FF)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Color(0xFF155EEF),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Expected Timeline',
                                    style: TextStyle(
                                      color: Color(0xFF0B4A6F),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isRejected
                                        ? 'Please re-upload the required details and documents for a fresh review.'
                                        : 'In production, KYC verification takes 24-48 hours via IDFY API.',
                                    style: const TextStyle(
                                      color: Color(0xFF175CD3),
                                      fontSize: 11,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Need Help?',
                              style: TextStyle(
                                color: Color(0xFF101828),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildHelpTile(
                              icon: Icons.phone_outlined,
                              title: 'Call Support',
                              subtitle: '+91 1234567896',
                            ),
                            const SizedBox(height: 10),
                            _buildHelpTile(
                              icon: Icons.email_outlined,
                              title: 'Email Support',
                              subtitle: 'support@helperr4u.com',
                            ),
                          ],
                        ),
                      ),
                      if (isRejected) ...<Widget>[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRouter.onboardingStep3),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD92D20),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Review Documents'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        isRejected
                            ? 'Update your details and documents, then submit again.'
                            : 'We\'ll send you an SMS and email once your account is verified.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF475467), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Divider(height: 1, color: Color(0xFFEAECF0)),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool showLine,
    Color lineColor = const Color(0xFFD0D5DD),
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Icon(icon, size: 22, color: color),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: lineColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFF101828)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF667085), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year.toString();
    final hour24 = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'pm' : 'am';
    final hour12 = hour24 == 0
        ? 12
        : hour24 > 12
        ? hour24 - 12
        : hour24;

    return '$day $month $year, $hour12:$minute $suffix';
  }
}
