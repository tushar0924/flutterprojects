import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/booking_details_repository.dart';
import '../../utils/toast_helper.dart';
import 'selfie_verification_screen.dart';

class StartJobOtpScreen extends ConsumerStatefulWidget {
  const StartJobOtpScreen({
    super.key,
    required this.bookingId,
    required this.customerName,
  });

  final int bookingId;
  final String customerName;

  @override
  ConsumerState<StartJobOtpScreen> createState() => _StartJobOtpScreenState();
}

class _StartJobOtpScreenState extends ConsumerState<StartJobOtpScreen> {
  static const Color _navy = Color(0xFF0D233A);

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _isSubmitting = false;

  static const int _otpLength = 4;

  String get _otp => _controllers.map((controller) => controller.text).join();
  bool get _canSubmit => _otp.length == _otpLength && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      _fillFromPaste(value);
      return;
    }

    setState(() {});

    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _fillFromPaste(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '').split('');
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final nextIndex = digits.length.clamp(0, _focusNodes.length - 1);
    _focusNodes[nextIndex].requestFocus();
    setState(() {});
  }

  Future<void> _verifyOtp() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);
    final repository = ref.read(bookingDetailsRepositoryProvider);
    final success = await repository.startBookingWithOtp(
      widget.bookingId,
      _otp,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) return;

    AppToast.showSuccess('OTP verified');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SelfieVerificationScreen(bookingId: widget.bookingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.customerName.trim().isNotEmpty
        ? widget.customerName.trim()
        : 'Customer';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 56,
        backgroundColor: _navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Enter OTP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
        child: Column(
          children: [
            const Text(
              'Verify Customer OTP',
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask $customerName for the verification code\nsent to their phone',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _otpLength,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    right: index == _otpLength - 1 ? 0 : 12,
                  ),
                  child: _otpBox(index),
                ),
              ),
            ),
            const SizedBox(height: 34),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _canSubmit ? _verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  disabledBackgroundColor: const Color(0xFF98A2B3),
                  backgroundColor: _navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify OTP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 34),
            const _ImportantCard(),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 42,
      height: 44,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: index == _focusNodes.length - 1
            ? TextInputAction.done
            : null,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 1,
        style: const TextStyle(
          color: _navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _navy),
          ),
        ),
        onChanged: (value) => _onOtpChanged(index, value),
        onFieldSubmitted: (_) {
          if (_canSubmit) _verifyOtp();
        },
      ),
    );
  }
}

class _ImportantCard extends StatelessWidget {
  const _ImportantCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 15, color: Color(0xFF2563EB)),
              SizedBox(width: 7),
              Text(
                'Important',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 9),
          _Bullet(text: 'Customer will provide you the 4-digit OTP.'),
          _Bullet(text: 'Timer will start immediately after verification.'),
          _Bullet(text: 'You cannot pause the timer once started.'),
          _Bullet(text: 'Complete the work within allocated time.'),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        '- $text',
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 10,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
