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
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();

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
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    await ref.read(partnerOnboardingProvider.notifier).bootstrap();
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
    final bankName = _bankNameController.text.trim();

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
    if (bankName.isEmpty) {
      _showMessage('Enter bank name');
      return;
    }

    final result = await ref
        .read(partnerOnboardingProvider.notifier)
        .submitBank(
          accountName: accountName,
          accountNumber: account,
          ifsc: ifsc,
          bankName: bankName,
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

    return WillPopScope(
      onWillPop: () async {
        await _showBackDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A2740),
        body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              color: const Color(0xFF1A2740),
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
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: busy
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (onboarding.errorMessage.isNotEmpty) ...<Widget>[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFFD2A6),
                                  ),
                                ),
                                child: Text(
                                  onboarding.errorMessage,
                                  style: const TextStyle(
                                    color: Color(0xFF8A4B00),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            const Text(
                              'Enter your bank details for partner payouts.',
                              style: TextStyle(
                                color: Color(0xFF475467),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              'Account Name',
                              _accountNameController,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              'Bank Account Number',
                              _accountNumberController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              'Confirm Bank Account Number',
                              _confirmAccountController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              'Enter IFSC Code',
                              _ifscController,
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField('Bank Name', _bankNameController),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: onboarding.isSubmitting
                                    ? null
                                    : _submitBank,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B95A0),
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
                            const SizedBox(height: 24),
                            const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Your bank details are encrypted and securely stored',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
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
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}
