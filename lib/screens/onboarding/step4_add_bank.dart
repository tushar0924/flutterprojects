import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/partner_onboarding_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/back_confirmation_dialog.dart';

class OnboardingStep4 extends ConsumerStatefulWidget {
  const OnboardingStep4({super.key});

  @override
  ConsumerState<OnboardingStep4> createState() => _OnboardingStep4State();
}

class _OnboardingStep4State extends ConsumerState<OnboardingStep4> {
  static const Color _navy = Color(0xFF0B2239);

  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();

  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialState();
      }
    });
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    await ref.read(partnerOnboardingProvider.notifier).refreshStatus();
    if (!mounted) return;

    final onboarding = ref.read(partnerOnboardingProvider);

    if (_accountNameController.text.isEmpty && onboarding.fullName.isNotEmpty) {
      _accountNameController.text = onboarding.fullName;
    }

    setState(() => _isInitialLoading = false);
  }

  Future<void> _submitBank() async {
    final accountName = _accountNameController.text.trim();
    final account = _accountNumberController.text.trim();
    final confirm = _confirmAccountController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();

    if (accountName.isEmpty) {
      _showMessage('Enter account name');
      return;
    }
    if (account.isEmpty || account.length < 8) {
      _showMessage('Enter a valid account number');
      return;
    }
    if (account != confirm) {
      _showMessage('Account numbers do not match');
      return;
    }
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscRegex.hasMatch(ifsc)) {
      _showMessage('Enter a valid IFSC code');
      return;
    }
    final result = await ref
        .read(partnerOnboardingProvider.notifier)
        .submitBank(
          accountName: accountName,
          accountNumber: account,
          ifsc: ifsc,
        );

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.of(context).pushReplacementNamed(AppRouter.onboardingStep5);
      return;
    }

    _showMessage(
      result['message'] as String? ?? 'Failed to submit bank details',
    );
  }

  void _showMessage(String message) {
    AppToast.showError(message);
  }

  Future<void> _showBackDialog() async {
    final shouldDiscard = await showBackConfirmationDialog(
      context,
      message:
          "Your bank details won't be saved.\nYou'll need to fill in this step again when you continue.",
    );
    if (shouldDiscard == true && mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.chooseRole, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(partnerOnboardingProvider);
    final busy =
        _isInitialLoading ||
        onboarding.isBootstrapping ||
        onboarding.isSubmitting;
    final isFormReady =
        _accountNameController.text.trim().isNotEmpty &&
        _accountNumberController.text.trim().length >= 8 &&
        _confirmAccountController.text.trim() ==
            _accountNumberController.text.trim() &&
        RegExp(
          r'^[A-Z]{4}0[A-Z0-9]{6}$',
        ).hasMatch(_ifscController.text.trim().toUpperCase());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _showBackDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              color: _navy,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: _showBackDialog,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Add Bank Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Step 4 of 5 • Add Account Details',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF3F4F6),
                child: busy
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Enter your bank details.',
                                    style: TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    'Account holder name',
                                    _accountNameController,
                                    hintText: 'Enter account holder name',
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    'Bank Account Number',
                                    _accountNumberController,
                                    keyboardType: TextInputType.number,
                                    hintText: 'Enter bank account number',
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    'Re-Enter Bank Account Number',
                                    _confirmAccountController,
                                    keyboardType: TextInputType.number,
                                    hintText: 'Re-enter bank account number',
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    'Enter IFSC Code',
                                    _ifscController,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    hintText: 'Enter IFSC code',
                                  ),
                                  if (onboarding.errorMessage.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 10),
                                    Text(
                                      onboarding.errorMessage,
                                      style: const TextStyle(
                                        color: Color(0xFFB42318),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: (onboarding.isSubmitting || !isFormReady)
                                      ? null
                                      : _submitBank,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _navy,
                                    disabledBackgroundColor: _navy.withValues(alpha: 0.55),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: onboarding.isSubmitting
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              'Proceed for verification',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.lock_outline,
                                    size: 14,
                                    color: Color(0xFF98A2B3),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Your documents are encrypted and securely stored',
                                    style: TextStyle(
                                      color: Color(0xFF98A2B3),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF98A2B3),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            filled: true,
            fillColor: const Color(0xFFF2F4F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _navy, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
