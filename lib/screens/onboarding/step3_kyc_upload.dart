import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/toast_helper.dart';

import '../../providers/partner_onboarding_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/back_confirmation_dialog.dart';

class OnboardingStep3 extends ConsumerStatefulWidget {
  const OnboardingStep3({super.key});

  @override
  ConsumerState<OnboardingStep3> createState() => _OnboardingStep3State();
}

class _OnboardingStep3State extends ConsumerState<OnboardingStep3> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _additionalNameController =
      TextEditingController();

  File? _selfieFile;
  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;
  File? _additionalIdentityFile;
  _IdentityDocumentType? _selectedIdentityDocument;
  bool _isInitialLoading = true;
  bool _isSelfieBusy = false;
  bool _isAadhaarBusy = false;
  bool _isAdditionalIdentityBusy = false;

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
    await ref.read(partnerOnboardingProvider.notifier).refreshStatus();
    if (!mounted) return;

    final fullName = ref.read(partnerOnboardingProvider).fullName.trim();
    setState(() {
      if (_additionalNameController.text.trim().isEmpty) {
        _additionalNameController.text = fullName;
      }
      _isInitialLoading = false;
    });
  }

  @override
  void dispose() {
    _additionalNameController.dispose();
    super.dispose();
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
      if (result['success'] == true) {
        AppToast.showSuccess('Selfie uploaded successfully');
      } else {
        AppToast.showError(
          result['message'] as String? ?? 'Failed to upload selfie',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSelfieBusy = false);
      _showMessage('Failed to capture selfie: $e');
    }
  }

  Future<void> _uploadAadhaarFrontBack() async {
    if (_isAadhaarBusy) return;

    try {
      final frontPicked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (frontPicked == null) return;

      final frontFile = File(frontPicked.path);
      if (mounted) {
        setState(() {
          _aadhaarFrontFile = frontFile;
          _aadhaarBackFile = null;
        });
      }

      AppToast.showSuccess(
        'Front Aadhaar selected. Now choose back side image.',
      );

      final backPicked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (backPicked == null) {
        _showMessage('Back side image is mandatory to upload Aadhaar');
        return;
      }

      final backFile = File(backPicked.path);
      if (mounted) {
        setState(() {
          _aadhaarBackFile = backFile;
          _isAadhaarBusy = true;
        });
      }

      ref.read(partnerOnboardingProvider.notifier).prepareForAadhaarUpload();
      final result = await ref
          .read(partnerOnboardingProvider.notifier)
          .uploadAadhar(frontFile: frontFile, backFile: backFile);

      if (!mounted) return;
      setState(() => _isAadhaarBusy = false);

      if (result['success'] == true) {
        final data = result['data'];
        final payloadLog = <String, dynamic>{
          'frontImage': frontFile.path,
          'backImage': backFile.path,
        };
        debugPrint('[Onboarding Step3] Aadhaar upload form-data: $payloadLog');
        debugPrint('[Onboarding Step3] Aadhaar upload response: $data');
        AppToast.showSuccess('Aadhaar front & back uploaded successfully');
      } else {
        AppToast.showError(
          result['message'] as String? ?? 'Failed to upload Aadhaar images',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isAadhaarBusy = false);
      _showMessage('Failed to upload Aadhaar images: $e');
    }
  }

  Future<void> _uploadAdditionalIdentityDocument() async {
    if (_isAdditionalIdentityBusy) return;

    final document = _selectedIdentityDocument;
    final fullName = _additionalNameController.text.trim();
    if (document == null) {
      _showMessage('Please select document type');
      return;
    }
    if (fullName.isEmpty) {
      _showMessage('Please enter name on ${document.shortLabel}');
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
        _additionalIdentityFile = file;
        _isAdditionalIdentityBusy = true;
      });

      ref
          .read(partnerOnboardingProvider.notifier)
          .prepareForAdditionalIdentityUpload();
      final uploadResult = await ref
          .read(partnerOnboardingProvider.notifier)
          .uploadAdditionalIdentityDocument(
            documentType: document.apiValue,
            fullName: fullName,
            file: file,
          );

      if (!mounted) return;
      setState(() => _isAdditionalIdentityBusy = false);
      if (uploadResult['success'] == true) {
        AppToast.showSuccess(
          'Additional identity document uploaded successfully',
        );
      } else {
        AppToast.showError(
          uploadResult['message'] as String? ??
              'Failed to upload additional identity document',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isAdditionalIdentityBusy = false);
      _showMessage('Failed to upload additional identity document: $e');
    }
  }

  void _goToNext() {
    final onboarding = ref.read(partnerOnboardingProvider);
    if (!onboarding.isKycReadyForNext && !onboarding.kycCompleted) {
      _showMessage(
        'Complete selfie, Aadhaar, and additional identity proof upload first',
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRouter.onboardingStep4);
  }

  void _showMessage(String message) => AppToast.showError(message);

  Future<void> _showBackDialog() async {
    final shouldDiscard = await showBackConfirmationDialog(
      context,
      message:
          "Your uploaded documents won't be saved.\nYou'll need to complete this step again when you continue.",
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
    final nextEnabled = onboarding.isKycReadyForNext || onboarding.kycCompleted;
    final uploadInProgress =
        _isSelfieBusy ||
        _isAadhaarBusy ||
        _isAdditionalIdentityBusy ||
        onboarding.isSubmitting;
    final isBusy = _isInitialLoading || onboarding.isBootstrapping;

    return WillPopScope(
      onWillPop: () async {
        await _showBackDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B2842),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                color: const Color(0xFF0B2842),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
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
                  decoration: const BoxDecoration(color: Color(0xFFF4F5F7)),
                  child: isBusy
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(6, 10, 6, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF5FF),
                                  borderRadius: BorderRadius.circular(10),
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
                                  onTap: uploadInProgress
                                      ? null
                                      : _uploadSelfie,
                                ),
                                child: Column(
                                  children: <Widget>[
                                    _buildPhotoPreview(),
                                    const SizedBox(height: 10),
                                    _ActionOutlineButton(
                                      label: onboarding.selfieUploaded
                                          ? 'Retake & Upload'
                                          : 'Upload Photo',
                                      icon: Icons.upload_outlined,
                                      onTap: uploadInProgress
                                          ? null
                                          : _uploadSelfie,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Upload a clear photo of your face or take a selfie',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF667085),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSectionCard(
                                title: 'Upload Adhar Card',
                                subtitle: 'Front and back both side',
                                trailing: _TopActionButton(
                                  label:
                                      _aadhaarFrontFile != null ||
                                          _aadhaarBackFile != null
                                      ? 'Retake'
                                      : 'Take Photo',
                                  onTap: uploadInProgress
                                      ? null
                                      : _uploadAadhaarFrontBack,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _buildAadhaarPreview(),
                                    const SizedBox(height: 10),
                                    _ActionOutlineButton(
                                      label: 'Upload Aadhaar Card',
                                      icon: Icons.upload_outlined,
                                      onTap: uploadInProgress
                                          ? null
                                          : _uploadAadhaarFrontBack,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildAdditionalIdentityCard(uploadInProgress),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5EA),
                                  borderRadius: BorderRadius.circular(8),
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
                                        ? const Color(0xFF0B2842)
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
      ),
    );
  }

  Widget _buildAdditionalIdentityCard(bool uploadInProgress) {
    final document = _selectedIdentityDocument;
    final nameLabel = document == null
        ? 'Name on Document'
        : 'Name on ${document.shortLabel}';
    final uploadedFileName =
        _additionalIdentityFile?.path.split(Platform.pathSeparator).last ?? '';

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
            children: const <Widget>[
              Icon(Icons.badge_outlined, size: 18, color: Color(0xFF344054)),
              SizedBox(width: 8),
              Text(
                'Additional Identity Proof',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Select Document Type',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          _buildIdentityDropdown(),
          if (document != null) ...[
            const SizedBox(height: 14),
            Text(
              nameLabel,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF667085),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _additionalNameController,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1D2939)),
              decoration: InputDecoration(
                hintText: 'John Doe',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF98A2B3),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDE2E8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDE2E8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0B2842)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: uploadInProgress
                  ? null
                  : _uploadAdditionalIdentityDocument,
              child: SizedBox(
                width: double.infinity,
                height: 82,
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: const Color(0xFFD4D8DE),
                    borderRadius: 8,
                  ),
                  child: Center(
                    child: uploadedFileName.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              uploadedFileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF344054),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const <Widget>[
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 20,
                                color: Color(0xFF8B96A6),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Upload Front Side',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF667085),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdentityDropdown() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownButtonHideUnderline(
          child: DropdownButton2<_IdentityDocumentType>(
            isExpanded: true,
            value: _selectedIdentityDocument,
            customButton: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDE2E8)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _selectedIdentityDocument?.title ??
                          'Select document type',
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedIdentityDocument == null
                            ? const Color(0xFF667085)
                            : const Color(0xFF1D2939),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF98A2B3),
                    size: 18,
                  ),
                ],
              ),
            ),
            items: _IdentityDocumentType.values
                .map(
                  (document) => DropdownMenuItem<_IdentityDocumentType>(
                    value: document,
                    child: _IdentityDropdownRow(
                      document: document,
                      selected: document == _selectedIdentityDocument,
                    ),
                  ),
                )
                .toList(),
            onChanged: (document) {
              if (document == null) return;
              setState(() {
                _selectedIdentityDocument = document;
                _additionalIdentityFile = null;
              });
            },
            dropdownStyleData: DropdownStyleData(
              width: constraints.maxWidth,
              maxHeight: 238,
              offset: const Offset(0, -4),
              elevation: 8,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4E7EC)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1A101828),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(
              height: 58,
              padding: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoPreview() {
    if (_selfieFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selfieFile!,
          width: 148,
          height: 88,
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: SizedBox(
          width: 148,
          height: 88,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: const Color(0xFFD4D8DE),
              borderRadius: 6,
            ),
            child: Center(
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 22,
                  color: Color(0xFF667085),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAadhaarPreview() {
    Widget placeholderBox(String side, File? file) {
      return Expanded(
        child: SizedBox(
          height: 72,
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.file(file, fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            side,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : CustomPaint(
                  painter: _DashedBorderPainter(
                    color: const Color(0xFFD4D8DE),
                    borderRadius: 6,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9EEF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            size: 18,
                            color: Color(0xFF8B96A6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          side,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF667085),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        placeholderBox('Front', _aadhaarFrontFile),
        const SizedBox(width: 14),
        placeholderBox('Back', _aadhaarBackFile),
      ],
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
      padding: const EdgeInsets.all(12),
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

enum _IdentityDocumentType {
  pan(
    apiValue: 'PAN',
    title: 'PAN Card',
    subtitle: 'Permanent Account Number',
    shortLabel: 'PAN',
    icon: Icons.credit_card_outlined,
  ),
  drivingLicence(
    apiValue: 'DRIVING_LICENSE',
    title: 'Driving Licence',
    subtitle: 'Government-issued licence',
    shortLabel: 'Driving Licence',
    icon: Icons.directions_car_filled_outlined,
  ),
  voterId(
    apiValue: 'VOTER_ID',
    title: 'Voter ID',
    subtitle: 'Election ID card',
    shortLabel: 'Voter ID',
    icon: Icons.how_to_vote_outlined,
  );

  const _IdentityDocumentType({
    required this.apiValue,
    required this.title,
    required this.subtitle,
    required this.shortLabel,
    required this.icon,
  });

  final String apiValue;
  final String title;
  final String subtitle;
  final String shortLabel;
  final IconData icon;
}

class _IdentityDropdownRow extends StatelessWidget {
  const _IdentityDropdownRow({required this.document, required this.selected});

  final _IdentityDocumentType document;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF8FAFF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? const Color(0xFF0B2842) : const Color(0xFFE4E7EC),
          width: selected ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F4F7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              document.icon,
              size: 16,
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  document.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2939),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  document.subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF0B2842) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xFF0B2842)
                    : const Color(0xFFD0D5DD),
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
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
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF344054),
          side: const BorderSide(color: Color(0xFFD0D5DD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
