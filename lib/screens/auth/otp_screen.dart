import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/toast_helper.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String? phone;

  const OtpScreen({super.key, this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  int _resendSeconds = 25;
  Timer? _timer;
  bool _isOtpComplete = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (final controller in _controllers) {
      controller.addListener(_checkOtpCompletion);
    }
  }

  void _checkOtpCompletion() {
    final otp = _controllers.map((c) => c.text).join();
    setState(() {
      _isOtpComplete = otp.length == 4;
      _errorMessage = '';
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _resendOtp() {
    if (_resendSeconds == 0) {
      setState(() => _resendSeconds = 25);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.removeListener(_checkOtpCompletion);
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyAndContinue() async {
    final phone = widget.phone;
    final otp = _controllers.map((c) => c.text).join();

    if (phone == null || phone.isEmpty) {
      setState(() => _errorMessage = 'Phone number is missing');
      return;
    }

    if (otp.length < 4) {
      setState(() => _errorMessage = 'Enter the complete OTP');
      return;
    }

    final resp = await ref
        .read(authProvider.notifier)
        .verifyOtp(phone, otp, helper: true);

    if (!mounted) return;

    if (resp.success) {
      AppToast.showSuccess(resp.message);
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.chooseRole, (r) => false);
    } else {
      AppToast.showError(resp.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0F2A47),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F2A47),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 318,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0E2743), Color(0xFF11304F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: const Alignment(0, 0.96),
                      child: Image.asset(
                        'assets/login.png',
                        height: 170,
                        width: 300,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                    const Positioned(
                      top: 30,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bookus',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 42,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Partner',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Welcome!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: 28,
                          right: 28,
                          top: 32,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Enter the 4-digit code sent to',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.phone != null
                                      ? '+91 ${widget.phone}'
                                      : '+91',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5C6BC0),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  'Enter OTP',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (int index = 0; index < 4; index++) ...[
                                      SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: TextField(
                                          controller: _controllers[index],
                                          focusNode: _focusNodes[index],
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          maxLength: 1,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(1),
                                          ],
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: InputDecoration(
                                            counterText: '',
                                            filled: true,
                                            fillColor: const Color(0xFFE6E6E6),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF2FD3C5),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            if (value.isNotEmpty && index < 3) {
                                              _focusNodes[index + 1]
                                                  .requestFocus();
                                            } else if (value.isEmpty &&
                                                index > 0) {
                                              _focusNodes[index - 1]
                                                  .requestFocus();
                                            }
                                          },
                                        ),
                                      ),
                                      if (index != 3)
                                        const SizedBox(width: 10),
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (_errorMessage.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 6.0),
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Center(
                                  child: GestureDetector(
                                    onTap:
                                        authState.isLoading ? null : _resendOtp,
                                    child: Text(
                                      _resendSeconds > 0
                                          ? 'Resend OTP in ${_resendSeconds}s'
                                          : 'Resend OTP',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _resendSeconds > 0
                                            ? Colors.black45
                                            : const Color(0xFF5C6BC0),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: (authState.isLoading ||
                                            !_isOtpComplete)
                                        ? null
                                        : _verifyAndContinue,
                                    icon: Icon(
                                      Icons.verified_outlined,
                                      size: 18,
                                      color: _isOtpComplete
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                    label: authState.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            'Verify & Login',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: _isOtpComplete
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withValues(alpha: 0.5),
                                            ),
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isOtpComplete
                                          ? const Color(0xFF0F2A47)
                                          : const Color(0xFF0F2A47)
                                              .withValues(alpha: 0.5),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: GestureDetector(
                                    onTap: authState.isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: const Text(
                                      'Change Phone Number?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(height: 28),
                                const Center(
                                  child: Text(
                                    'By continuing, you agree to our Terms &\nConditions',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
