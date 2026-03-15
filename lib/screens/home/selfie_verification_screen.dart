import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'customer_otp_screen.dart';
import '../../utils/toast_helper.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() => _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  CameraController? _cameraController;
  XFile? _capturedSelfie;
  bool _isCapturing = false;
  bool _isVerified = false;
  bool _isPermissionPermanentlyDenied = false;
  String? _cameraError;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _initializeFrontCamera();
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeFrontCamera() async {
    final previousController = _cameraController;
    if (previousController != null) {
      await previousController.dispose();
      if (!mounted) return;
    }

    if (mounted) {
      setState(() {
        _cameraController = null;
        _cameraError = null;
      });
    }

    try {
      final granted = await _ensureCameraPermission();
      if (!granted) return;

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found on this device.');
        return;
      }

      final CameraDescription selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isPermissionPermanentlyDenied = false;
        _cameraError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraController = null;
        _cameraError = 'Camera access denied or unavailable.';
      });
    }
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _isPermissionPermanentlyDenied = false;
          _cameraError = null;
        });
      }
      return true;
    }

    if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _isPermissionPermanentlyDenied = false;
          _cameraError = null;
        });
      }
      return true;
    }

    if (!mounted) return false;
    setState(() {
      _isPermissionPermanentlyDenied = status.isPermanentlyDenied;
      _cameraError = status.isPermanentlyDenied
          ? 'Camera permission permanently denied. Tap Open Settings.'
          : 'Camera permission denied. Please allow camera access.';
    });
    return false;
  }

  Future<void> _captureSelfie() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedSelfie = file;
        _isVerified = false;
      });
    } catch (_) {
      if (!mounted) return;
      AppToast.showError('Could not capture selfie. Please try again.');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _retakeSelfie() {
    _redirectTimer?.cancel();
    setState(() {
      _capturedSelfie = null;
      _isVerified = false;
    });
  }

  void _verifySelfie() {
    if (_isVerified) return;

    setState(() => _isVerified = true);
    _redirectTimer?.cancel();
    _redirectTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerOtpScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color navyBlue = Color(0xFF0D1F33);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: navyBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Selfie Verification',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            _cameraWindow(),
            const SizedBox(height: 14),
            _actionButtons(),
            const SizedBox(height: 14),
            _instructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _cameraWindow() {
    final controller = _cameraController;

    return Container(
      width: double.infinity,
      height: 290,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(2),
      ),
      clipBehavior: Clip.hardEdge,
      child: _capturedSelfie != null
          ? Image.file(
              File(_capturedSelfie!.path),
              fit: BoxFit.cover,
            )
          : _cameraError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _cameraError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                )
              : (controller == null || !controller.value.isInitialized)
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                      ),
                    )
                  : SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.previewSize!.height,
                          height: controller.value.previewSize!.width,
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),
    );
  }

  Widget _actionButtons() {
    if (_cameraError != null) {
      return SizedBox(
        width: 220,
        child: OutlinedButton(
          onPressed: _isPermissionPermanentlyDenied
              ? () async {
                  await openAppSettings();
                }
              : _initializeFrontCamera,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            side: const BorderSide(color: Color(0xFF98A2B3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(
            _isPermissionPermanentlyDenied ? 'Open Settings' : 'Retry Camera',
            style: const TextStyle(color: Color(0xFF0D1F33), fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    if (_capturedSelfie == null) {
      return SizedBox(
        width: 220,
        child: ElevatedButton.icon(
          onPressed: _isCapturing || _cameraController == null ? null : _captureSelfie,
          icon: const Icon(Icons.photo_camera_outlined, size: 16, color: Colors.white),
          label: Text(
            _isCapturing ? 'Capturing...' : 'Take Selfie',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            backgroundColor: const Color(0xFF0D1F33),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            elevation: 0,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: 220,
          child: ElevatedButton(
            onPressed: _isVerified ? null : _verifySelfie,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              backgroundColor: _isVerified ? const Color(0xFF95EE9A) : const Color(0xFF0D1F33),
              disabledBackgroundColor: const Color(0xFF95EE9A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            child: _isVerified
                ? const Icon(Icons.check_circle_outline, color: Color(0xFF0D1F33), size: 18)
                : const Text('Verify',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 220,
          child: OutlinedButton(
            onPressed: _retakeSelfie,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              side: const BorderSide(color: Color(0xFF98A2B3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Retake Selfie',
                style: TextStyle(color: Color(0xFF0D1F33), fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  Widget _instructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8D8FF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Color(0xFF175CD3)),
              SizedBox(width: 6),
              Text('Face Verification Instructions',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0D1F33))),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Keep the camera straight in front of your face. Ensure your face is fully visible (no mask, cap, or scarf).',
            style: TextStyle(fontSize: 9.5, color: Color(0xFF175CD3), height: 1.45),
          ),
          SizedBox(height: 4),
          Text(
            '• Female partners must tie their hair properly.',
            style: TextStyle(fontSize: 9.5, color: Color(0xFF175CD3), height: 1.45),
          ),
          SizedBox(height: 4),
          Text(
            '• Make sure the background is plain and no one else is visible.',
            style: TextStyle(fontSize: 9.5, color: Color(0xFF175CD3), height: 1.45),
          ),
          SizedBox(height: 4),
          Text(
            '• Upload a live selfie only (no gallery photos).',
            style: TextStyle(fontSize: 9.5, color: Color(0xFF175CD3), height: 1.45),
          ),
        ],
      ),
    );
  }
}
