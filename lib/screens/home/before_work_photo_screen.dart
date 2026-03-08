import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'job_in_progress_screen.dart';

class BeforeWorkPhotoScreen extends StatefulWidget {
  const BeforeWorkPhotoScreen({super.key});

  @override
  State<BeforeWorkPhotoScreen> createState() => _BeforeWorkPhotoScreenState();
}

class _BeforeWorkPhotoScreenState extends State<BeforeWorkPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = <XFile>[];

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || source == null) return;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    final hasPermission = await _ensureImagePermission(source);
    if (!hasPermission) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      setState(() {
        _photos.add(image);
      });
    } catch (e) {
      if (!mounted) return;
      final message = 'Could not pick image. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }

  Future<bool> _ensureImagePermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      try {
        final status = await Permission.camera.request();
        if (status.isGranted) return true;
        return _handlePermissionDenied(status, 'camera');
      } catch (e) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission error. Open settings.')),
        );
        return false;
      }
    }

    if (Platform.isAndroid) {
      try {
        final statuses = await <Permission>[Permission.photos, Permission.storage].request();
        final photos = statuses[Permission.photos];
        final storage = statuses[Permission.storage];
        final granted = (photos?.isGranted ?? false) ||
            (photos?.isLimited ?? false) ||
            (storage?.isGranted ?? false);
        if (granted) return true;

        final permanentlyDenied =
            (photos?.isPermanentlyDenied ?? false) || (storage?.isPermanentlyDenied ?? false);
        return _handlePermissionDenied(
          permanentlyDenied ? PermissionStatus.permanentlyDenied : PermissionStatus.denied,
          'gallery',
        );
      } catch (e) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery permission error. Open settings.')),
        );
        return false;
      }
    }

    try {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      return _handlePermissionDenied(status, 'gallery');
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery permission error. Open settings.')),
      );
      return false;
    }
  }

  Future<bool> _handlePermissionDenied(PermissionStatus status, String type) async {
    if (!mounted) return false;

    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type permission permanently denied. Open settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please allow $type permission to continue.')),
    );
    return false;
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _photos.length) return;
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color navyBlue = Color(0xFF0D1F33);
    final bool isStartEnabled = _photos.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: navyBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Before Work Photo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Capture photos showing the work to be\ndone.',
              style: TextStyle(fontSize: 15, color: Color(0xFF101828), height: 1.35),
            ),
            const SizedBox(height: 18),
            _uploadCard(),
            const SizedBox(height: 16),
            _guidelinesCard(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: isStartEnabled
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JobInProgressScreen()),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: navyBlue,
              disabledBackgroundColor: const Color(0xFF98A2B3),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Start Timer',
              style: TextStyle(color: Colors.white, fontSize: 22 / 2, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Upload Work Photo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF101828)),
              ),
              Text(
                'Min 5 photos',
                style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_photos.isEmpty) _takePhotoButton() else _photoGrid(),
        ],
      ),
    );
  }

  Widget _takePhotoButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton.icon(
        onPressed: _showImageSourceSheet,
        icon: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 17),
        label: const Text(
          'Take Photo',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D1F33),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _photoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 12;
        final double tileWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (int i = 0; i < _photos.length; i++) _photoTile(i, tileWidth),
            _addPhotoTile(tileWidth),
          ],
        );
      },
    );
  }

  Widget _photoTile(int index, double width) {
    return SizedBox(
      width: width,
      height: width * 0.96,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00C853), width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.file(
                File(_photos[index].path),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0x99000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF00C853),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPhotoTile(double width) {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: SizedBox(
        width: width,
        height: width * 0.96,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC0C6D0), width: 3),
            color: const Color(0xFFF4F6FA),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 44, color: Color(0xFF98A2B3)),
              SizedBox(height: 6),
              Text(
                'Add Photo',
                style: TextStyle(color: Color(0xFF1D2939), fontSize: 20 / 2, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guidelinesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB2CCFF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF175CD3)),
              SizedBox(width: 8),
              Text(
                'Photo Guidelines',
                style: TextStyle(fontSize: 22 / 2, fontWeight: FontWeight.w500, color: Color(0xFF0D1F33)),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text('• Ensure good lighting', style: TextStyle(fontSize: 10 / 1, color: Color(0xFF0037B3), height: 1.5)),
          Text('• Capture entire work area', style: TextStyle(fontSize: 10 / 1, color: Color(0xFF0037B3), height: 1.5)),
          Text('• Photo should be clear and focused', style: TextStyle(fontSize: 10 / 1, color: Color(0xFF0037B3), height: 1.5)),
          Text('• Include all areas mentioned in work\ndescription',
              style: TextStyle(fontSize: 10 / 1, color: Color(0xFF0037B3), height: 1.5)),
        ],
      ),
    );
  }
}
