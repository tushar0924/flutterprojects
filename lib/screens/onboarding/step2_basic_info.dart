import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/toast_helper.dart';

import '../../providers/partner_onboarding_provider.dart';
import '../../routes/app_router.dart';

class OnboardingStep2 extends ConsumerStatefulWidget {
  const OnboardingStep2({super.key});

  @override
  ConsumerState<OnboardingStep2> createState() => _OnboardingStep2State();
}

class _OnboardingStep2State extends ConsumerState<OnboardingStep2> {
  String? _gender;
  final Set<int> _selectedServiceIds = <int>{};
  final Set<String> _workTypes = <String>{};
  String? _experience;
  String? _startTime;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  double? _capturedLatitude;
  double? _capturedLongitude;
  bool _isCapturingLocation = false;
  bool _isInitialLoading = true;
  bool _isSubmitting = false;
  bool _hasHydratedForm = false;

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
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    await ref
        .read(partnerOnboardingProvider.notifier)
        .bootstrap(loadServices: true);
    if (!mounted) return;

    final onboarding = ref.read(partnerOnboardingProvider);
    if (!_hasHydratedForm) {
      if (onboarding.fullName.isNotEmpty) {
        _nameController.text = onboarding.fullName;
      }
      if (onboarding.phone.isNotEmpty) {
        _phoneController.text = _normalizePhone(onboarding.phone);
      }
      _hasHydratedForm = true;
    }

    final nextStep = onboarding.currentStep;
    if (nextStep != PartnerOnboardingStep.basicInfo) {
      Navigator.of(
        context,
      ).pushReplacementNamed(onboardingRouteForStep(nextStep));
      return;
    }

    setState(() => _isInitialLoading = false);
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  Future<void> _submitProfile() async {
    if (_isSubmitting) return;
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter your full name');
      return;
    }
    if (address.isEmpty) {
      _showMessage('Please enter your address');
      return;
    }
    if (_selectedServiceIds.isEmpty) {
      _showMessage('Please select at least one service');
      return;
    }
    if (_capturedLatitude == null || _capturedLongitude == null) {
      _showMessage('Please capture GPS location first');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(partnerOnboardingProvider.notifier)
        .submitProfile(
          fullName: name,
          serviceArea: address,
          serviceIds: _selectedServiceIds.toList(),
          gender: _gender?.toUpperCase() ?? '',
          workTypes: _workTypes.toList(),
          latitude: _capturedLatitude,
          longitude: _capturedLongitude,
        );

    if (!mounted) return;

    if (result['success'] == true) {
      // Navigate immediately — don't wait for the background refreshStatus()
      // to complete, which would cause step 2 to flicker with a spinner.
      Navigator.of(context).pushReplacementNamed(AppRouter.onboardingStep3);
      return;
    }

    setState(() => _isSubmitting = false);
    _showMessage(result['message'] as String? ?? 'Failed to submit profile');
  }

  Future<void> _captureGpsLocation() async {
    if (_isCapturingLocation) return;
    setState(() => _isCapturingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Please enable location services and try again');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission denied');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission permanently denied. Enable it from app settings.',
        );
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _capturedLatitude = position.latitude;
        _capturedLongitude = position.longitude;
      });
      AppToast.showSuccess('Location captured successfully');
    } on MissingPluginException {
      _showMessage(
        'Location plugin is not ready. Restart the app and try again.',
      );
    } catch (e) {
      _showMessage('Unable to capture location: $e');
    } finally {
      if (mounted) setState(() => _isCapturingLocation = false);
    }
  }

  void _showMessage(String message) => AppToast.showError(message);

  Widget _toggleChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF4DD9C0) : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? const Color(0xFF1A2740) : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _serviceChip(ServiceModel service) {
    final selected = _selectedServiceIds.contains(service.id);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedServiceIds.remove(service.id);
        } else {
          _selectedServiceIds.add(service.id);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF4DD9C0) : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          service.name,
          style: TextStyle(
            fontSize: 13,
            color: selected ? const Color(0xFF1A2740) : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4DD9C0), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(partnerOnboardingProvider);
    final services = onboarding.availableServices;
    // Only block the whole screen on the very first load. Submission state is
    // handled locally via _isSubmitting so the button shows its own loader
    // without re-rendering the entire page.
    final busy = _isInitialLoading || onboarding.isBootstrapping;

    return Scaffold(
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
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(
                            AppRouter.chooseRole, (r) => false),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Helper Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Step 2 of 5 • Basic Information',
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
                  color: Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: busy
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
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
                            // ── Form card ──────────────────────────────────
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _label('Full Name *'),
                                  const SizedBox(height: 8),
                                  _field(
                                    controller: _nameController,
                                    hint: 'Enter Your full name',
                                    icon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 16),
                                  _label('Gender'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      _toggleChip(
                                        'Female',
                                        _gender == 'Female',
                                        () => setState(() => _gender = 'Female'),
                                      ),
                                      const SizedBox(width: 10),
                                      _toggleChip(
                                        'Male',
                                        _gender == 'Male',
                                        () => setState(() => _gender = 'Male'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _label('Phone Number *'),
                                  const SizedBox(height: 8),
                                  _field(
                                    controller: _phoneController,
                                    hint: '1234563215',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    readOnly: onboarding.phone.isNotEmpty,
                                  ),
                                  const SizedBox(height: 16),
                                  _label('Address *'),
                                  const SizedBox(height: 8),
                                  _field(
                                    controller: _addressController,
                                    hint: 'Enter complete address',
                                    icon: Icons.location_on_outlined,
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 16),
                                  _label('Location *'),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: _isCapturingLocation
                                          ? null
                                          : _captureGpsLocation,
                                      icon: _isCapturingLocation
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.navigation_outlined,
                                              size: 18,
                                            ),
                                      label: Text(
                                        _isCapturingLocation
                                            ? 'Capturing location...'
                                            : 'Capture GPS Location',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black87,
                                        side: BorderSide(
                                            color: Colors.grey.shade300),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_capturedLatitude != null &&
                                      _capturedLongitude != null) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF9E9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFB7E6B4),
                                        ),
                                      ),
                                      child: Text(
                                        'Location captured: ${_capturedLatitude!.toStringAsFixed(6)}, ${_capturedLongitude!.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF166534),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  _label('Choose Service You Provide'),
                                  const SizedBox(height: 10),
                                  ...List.generate(
                                      (services.length / 2).ceil(), (rowIdx) {
                                    final left = services[rowIdx * 2];
                                    final rightIdx = rowIdx * 2 + 1;
                                    final right = rightIdx < services.length
                                        ? services[rightIdx]
                                        : null;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                              child: _serviceChip(left)),
                                          const SizedBox(width: 8),
                                          right != null
                                              ? Expanded(
                                                  child: _serviceChip(right))
                                              : const Expanded(
                                                  child: SizedBox()),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 18),
                                  _label('Type of work you prefer'),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      _toggleChip(
                                        'Hourly',
                                        _workTypes.contains('Hourly'),
                                        () => setState(() {
                                          if (_workTypes.contains('Hourly')) {
                                            _workTypes.remove('Hourly');
                                          } else {
                                            _workTypes.add('Hourly');
                                          }
                                        }),
                                      ),
                                      _toggleChip(
                                        'Per day',
                                        _workTypes.contains('Per day'),
                                        () => setState(() {
                                          if (_workTypes
                                              .contains('Per day')) {
                                            _workTypes.remove('Per day');
                                          } else {
                                            _workTypes.add('Per day');
                                          }
                                        }),
                                      ),
                                      _toggleChip(
                                        'Monthly',
                                        _workTypes.contains('Monthly'),
                                        () => setState(() {
                                          if (_workTypes
                                              .contains('Monthly')) {
                                            _workTypes.remove('Monthly');
                                          } else {
                                            _workTypes.add('Monthly');
                                          }
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  _label('Do you have previous experience?'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      _toggleChip(
                                        'Yes',
                                        _experience == 'Yes',
                                        () =>
                                            setState(() => _experience = 'Yes'),
                                      ),
                                      const SizedBox(width: 8),
                                      _toggleChip(
                                        'No',
                                        _experience == 'No',
                                        () =>
                                            setState(() => _experience = 'No'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  _label('When can you start working?'),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      _toggleChip(
                                        'Immediately',
                                        _startTime == 'Immediately',
                                        () => setState(
                                          () => _startTime = 'Immediately',
                                        ),
                                      ),
                                      _toggleChip(
                                        'Within a week',
                                        _startTime == 'Within a week',
                                        () => setState(
                                          () => _startTime = 'Within a week',
                                        ),
                                      ),
                                      _toggleChip(
                                        'Next month',
                                        _startTime == 'Next month',
                                        () => setState(
                                            () => _startTime = 'Next month'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // ── Submit button ───────────────────────────────
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _submitProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A2740),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
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
                                            'Continue to KYC Upload',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ],
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
