import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/partner_onboarding_provider.dart';
import '../../routes/app_router.dart';

class OnboardingStep3 extends ConsumerStatefulWidget {
  const OnboardingStep3({super.key});

  @override
  ConsumerState<OnboardingStep3> createState() => _OnboardingStep3State();
}

class _OnboardingStep3State extends ConsumerState<OnboardingStep3> {
  final ImagePicker _picker = ImagePicker();

  File? _selfieFile;
  File? _panFile;
  File? _policeFile;
  bool _isInitialLoading = true;
  bool _isSelfieBusy = false;
  bool _isPanBusy = false;
  bool _isPoliceBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialState();
      }
    });
  }

  Future<void> _loadInitialState() async {
    await ref.read(partnerOnboardingProvider.notifier).bootstrap();
    if (!mounted) return;

    final onboarding = ref.read(partnerOnboardingProvider);
    final nextStep = onboarding.currentStep;
    if (nextStep != PartnerOnboardingStep.kyc) {
      Navigator.of(
        context,
      ).pushReplacementNamed(onboardingRouteForStep(nextStep));
      return;
    }

    setState(() => _isInitialLoading = false);
  }

  Future<void> _uploadSelfie() async {
    if (_isSelfieBusy) return;
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (xFile == null) return;

      final file = File(xFile.path);
      setState(() {
        _selfieFile = file;
        _isSelfieBusy = true;
      });

      ref.read(partnerOnboardingProvider.notifier).prepareForSelfieUpload();
      final result = await ref
          .read(partnerOnboardingProvider.notifier)
          .uploadSelfie(file);

      if (!mounted) return;
      setState(() => _isSelfieBusy = false);
      _showMessage(
        result['success'] == true
            ? 'Selfie uploaded successfully'
            : result['message'] as String? ?? 'Failed to upload selfie',
      );
    } catch (e) {
      if (mounted) setState(() => _isSelfieBusy = false);
      _showMessage('Failed to capture selfie: $e');
    }
  }

  Future<void> _uploadPan() async {
    if (_isPanBusy) return;
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (xFile == null) return;

      final file = File(xFile.path);
      setState(() {
        _panFile = file;
        _policeFile = null;
        _isPanBusy = true;
      });

      ref.read(partnerOnboardingProvider.notifier).prepareForPanUpload();
      final result = await ref
          .read(partnerOnboardingProvider.notifier)
          .verifyPan(file);

      if (!mounted) return;
      setState(() => _isPanBusy = false);

      final verificationStatus = (result['verificationStatus'] as String? ?? '')
          .trim()
          .toUpperCase();
      final uploadSucceeded = result['success'] == true;
      final canProceedToPolice =
          uploadSucceeded &&
          (verificationStatus.isEmpty || verificationStatus == 'VERIFIED');

      _showMessage(
        canProceedToPolice
            ? (verificationStatus == 'VERIFIED'
                  ? 'PAN verified successfully'
                  : 'PAN uploaded successfully')
            : result['message'] as String? ??
                  'PAN verification failed. Please upload a clear PAN image.',
      );
    } catch (e) {
      if (mounted) setState(() => _isPanBusy = false);
      _showMessage('Failed to pick PAN image: $e');
    }
  }

  Future<void> _uploadPolice() async {
    if (_isPoliceBusy) return;

    final onboarding = ref.read(partnerOnboardingProvider);
    if (!onboarding.panVerified) {
      _showMessage('Upload PAN successfully before uploading police document');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'pdf'],
      );
      final path = result?.files.single.path;
      if (path == null) return;

      final file = File(path);
      setState(() {
        _policeFile = file;
        _isPoliceBusy = true;
      });

      ref.read(partnerOnboardingProvider.notifier).prepareForPoliceUpload();
      final uploadResult = await ref
          .read(partnerOnboardingProvider.notifier)
          .uploadPolice(file);

      if (!mounted) return;
      setState(() => _isPoliceBusy = false);
      _showMessage(
        uploadResult['success'] == true
            ? 'Police verification document uploaded successfully'
            : uploadResult['message'] as String? ??
                  'Failed to upload police verification document',
      );
    } catch (e) {
      if (mounted) setState(() => _isPoliceBusy = false);
      _showMessage('Failed to pick police document: $e');
    }
  }

  void _goToNext() {
    final onboarding = ref.read(partnerOnboardingProvider);
    if (!onboarding.isKycReadyForNext && !onboarding.kycCompleted) {
      _showMessage(
        'Complete selfie upload, PAN verification, and police document upload first',
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRouter.onboardingStep4);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _fileName(File? file) {
    if (file == null) return '';
    final normalized = file.path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  String _panStatusText(PartnerOnboardingState onboarding) {
    if (onboarding.panVerificationStatus.isNotEmpty) {
      return formatOnboardingStatus(onboarding.panVerificationStatus);
    }
    if (onboarding.panVerified) return 'Verified';
    if (onboarding.panUploaded) return 'Uploaded';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(partnerOnboardingProvider);
    final nextEnabled = onboarding.isKycReadyForNext || onboarding.kycCompleted;
    final uploadInProgress =
        _isSelfieBusy || _isPanBusy || _isPoliceBusy || onboarding.isSubmitting;
    final isBusy = _isInitialLoading || onboarding.isBootstrapping;

    return Scaffold(
      backgroundColor: const Color(0xFF0B2842),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              color: const Color(0xFF0B2842),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'KYC Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Step 3 of 5 • Upload Documents',
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
                  color: Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: isBusy
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF5FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFC8DAF6),
                                ),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF1F63D0),
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Why KYC is required?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Color(0xFF0B2842),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'KYC verification ensures safety and trust for all users on our platform. Your documents are encrypted and securely stored.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF355070),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildSectionCard(
                              title: 'Your Photo',
                              subtitle: onboarding.selfieUploaded
                                  ? 'Clear face photo uploaded'
                                  : 'Clear face photo',
                              trailing: _TopActionButton(
                                label: onboarding.selfieUploaded
                                    ? 'Retake'
                                    : 'Take Selfie',
                                onTap: uploadInProgress ? null : _uploadSelfie,
                              ),
                              child: Column(
                                children: <Widget>[
                                  _buildPhotoPreview(),
                                  const SizedBox(height: 14),
                                  _ActionOutlineButton(
                                    label: onboarding.selfieUploaded
                                        ? 'Retake & Upload'
                                        : 'Upload Photo',
                                    icon: Icons.upload_outlined,
                                    onTap: uploadInProgress
                                        ? null
                                        : _uploadSelfie,
                                  ),
                                  if (onboarding.selfieUploaded) ...<Widget>[
                                    const SizedBox(height: 10),
                                    _StatusRow(
                                      icon: Icons.check_circle,
                                      color: const Color(0xFF1E8E3E),
                                      text: 'Selfie uploaded successfully',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSectionCard(
                              title: 'Pan Card',
                              subtitle: 'Front or back side',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _ActionOutlineButton(
                                    label: onboarding.panVerified
                                        ? 'Re-upload PAN'
                                        : 'Choose File',
                                    icon: Icons.upload_outlined,
                                    onTap: uploadInProgress ? null : _uploadPan,
                                  ),
                                  const SizedBox(height: 10),
                                  _StatusRow(
                                    icon: onboarding.panVerified
                                        ? Icons.verified
                                        : Icons.description_outlined,
                                    color: onboarding.panVerified
                                        ? const Color(0xFF1E8E3E)
                                        : const Color(0xFF667085),
                                    text: _panFile != null
                                        ? '${_fileName(_panFile)} • ${_panStatusText(onboarding)}'
                                        : 'Status: ${_panStatusText(onboarding)}',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSectionCard(
                              title: 'Police Verification Certificate',
                              subtitle: 'JPG, PNG, or PDF',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _ActionOutlineButton(
                                    label: onboarding.policeUploaded
                                        ? 'Re-upload Document'
                                        : 'Choose File',
                                    icon: Icons.upload_outlined,
                                    onTap:
                                        !uploadInProgress &&
                                            onboarding.panVerified
                                        ? _uploadPolice
                                        : null,
                                  ),
                                  const SizedBox(height: 10),
                                  _StatusRow(
                                    icon: onboarding.policeUploaded
                                        ? Icons.check_circle
                                        : Icons.picture_as_pdf_outlined,
                                    color: onboarding.policeUploaded
                                        ? const Color(0xFF1E8E3E)
                                        : const Color(0xFF667085),
                                    text: _policeFile != null
                                        ? _fileName(_policeFile)
                                        : onboarding.panVerified
                                        ? 'Ready to upload'
                                        : 'Verify PAN first',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5EA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF4C892),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Upload Guidelines:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '- Documents should be clear and readable',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '- File size should not exceed 5MB',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '- Accepted formats: JPG, PNG, PDF',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '- Ensure all corners are visible',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: nextEnabled ? _goToNext : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: nextEnabled
                                      ? const Color(0xFF7E8D9C)
                                      : const Color(0xFFC4CCD4),
                                  disabledBackgroundColor: const Color(
                                    0xFFC4CCD4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      'Next',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
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
                            const SizedBox(height: 12),
                            const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.lock_outline,
                                    size: 14,
                                    color: Color(0xFF667085),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Your documents are encrypted and securely stored',
                                    style: TextStyle(
                                      color: Color(0xFF667085),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
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

  Widget _buildPhotoPreview() {
    if (_selfieFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selfieFile!,
          width: double.infinity,
          height: 156,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 156,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: 132,
          height: 108,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: const Color(0xFFD4D8DE),
              borderRadius: 10,
            ),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 26,
                  color: Color(0xFF667085),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: Color(0xFF344054),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActionOutlineButton extends StatelessWidget {
  const _ActionOutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF344054),
          side: const BorderSide(color: Color(0xFFD0D5DD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.camera_alt_outlined, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF344054),
        side: const BorderSide(color: Color(0xFFD0D5DD)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(borderRadius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + 7;
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance = nextDistance + 5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
