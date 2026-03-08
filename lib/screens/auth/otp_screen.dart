import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../routes/app_router.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String? phone;

  const OtpScreen({super.key, this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(4, (_) => FocusNode());

  int _resendSeconds = 25;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _showToast(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [

            /// ---------------- HEADER ---------------- ///
            Container(
              height: 260,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F2A47),
                    Color(0xFF0C223B),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(height: 20),
                  Text(
                    "Helperr4u",
                    style: TextStyle(
                      fontFamily: "Georgia",
                      fontSize: 38,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2FD3C5),
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Welcome back!",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            /// ---------------- SCROLLABLE WHITE CARD ---------------- ///
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 28,
                    right: 28,
                    top: 32,
                    bottom:
                    MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Verify OTP",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Enter the 4-digit code sent to",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        widget.phone != null ? '+91 ${widget.phone}' : '+91',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C6BC0),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        "Enter OTP",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// OTP FIELDS (4 boxes, reduced spacing)
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
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  counterText: "",
                                  filled: true,
                                  fillColor: const Color(0xFFE6E6E6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2FD3C5),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 3) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                },
                              ),
                            ),
                            if (index != 3) const SizedBox(width: 10),
                          ]
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// RESEND
                      Center(
                        child: GestureDetector(
                          onTap: _resendOtp,
                          child: Text(
                            _resendSeconds > 0
                                ? "Resend OTP in ${_resendSeconds}s"
                                : "Resend OTP",
                            style: TextStyle(
                              fontSize: 13,
                              color: _resendSeconds > 0
                                  ? Colors.black45
                                  : const Color(
                                  0xFF5C6BC0),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// VERIFY BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  final phone = widget.phone;
                                  if (phone == null) {
                                    _showToast('Phone number missing');
                                    return;
                                  }

                                  final otp = _controllers.map((c) => c.text).join();
                                  if (otp.length < 4) {
                                    _showToast('Enter the complete OTP');
                                    return;
                                  }

                                  final resp = await ref.read(authProvider.notifier).verifyOtp(phone, otp, helper: true);
                                  if (!context.mounted) return;
                                  if (resp.success) {
                                    _showToast(resp.message);
                                    Navigator.of(context).pushNamed(AppRouter.language);
                                  } else {
                                    _showToast(resp.message);
                                  }
                                },
                          icon: const Icon(
                            Icons.verified_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: authState.isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  "Verify & Login",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF7FA6B5),
                            elevation: 0,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// CHANGE PHONE
                      Center(
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pop(context),
                          child: const Text(
                            "Change Phone Number?",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
