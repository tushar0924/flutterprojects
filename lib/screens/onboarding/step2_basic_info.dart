import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/toast_helper.dart';

import '../../providers/partner_onboarding_provider.dart';
import '../../routes/app_router.dart';
import '../address/edit_address_screen.dart';
import '../../widgets/back_confirmation_dialog.dart';

class OnboardingStep2 extends ConsumerStatefulWidget {
  const OnboardingStep2({super.key});

  @override
  ConsumerState<OnboardingStep2> createState() => _OnboardingStep2State();
}

class _OnboardingStep2State extends ConsumerState<OnboardingStep2> {
  static const Color _navy = Color(0xFF07264A);
  static const Color _surface = Color(0xFFF2F3F5);
  static const Color _fieldBorder = Color(0xFFD9DEE6);
  static const Color _fieldFill = Color(0xFFF4F6F9);

  String? _gender;
  final Set<int> _selectedServiceIds = <int>{};
  String? _experience;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCity = '';
  String _selectedPinCode = '';

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
    await ref.read(partnerOnboardingProvider.notifier).bootstrapFromChooseRole();
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

    setState(() => _isInitialLoading = false);
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  bool get _isFormReady {
    final name = _nameController.text.trim();
    final phone = _normalizePhone(_phoneController.text.trim());
    final address = _addressController.text.trim();
    return name.isNotEmpty &&
        phone.length == 10 &&
        _gender != null &&
        _experience != null &&
        address.isNotEmpty &&
        _selectedCity.isNotEmpty &&
        _selectedPinCode.isNotEmpty &&
        _selectedServiceIds.isNotEmpty &&
        _capturedLatitude != null &&
        _capturedLongitude != null;
  }

  String _extractPinCodeFromAddress(String address) {
    final match = RegExp(r'\b\d{6}\b').firstMatch(address);
    return match?.group(0) ?? '';
  }

  String _extractCityFromAddress(String address) {
    final parts = address
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (var i = parts.length - 1; i >= 0; i--) {
      final part = parts[i];
      if (part.toLowerCase() == 'india') continue;
      if (RegExp(r'\d{6}').hasMatch(part)) continue;
      return part;
    }
    return '';
  }

  Future<void> _submitProfile() async {
    if (_isSubmitting) return;
    final name = _nameController.text.trim();
    final phone = _normalizePhone(_phoneController.text.trim());
    final address = _addressController.text.trim();
    final city = _selectedCity.trim().isNotEmpty
      ? _selectedCity.trim()
      : _extractCityFromAddress(address);
    final pinCode = _selectedPinCode.trim().isNotEmpty
      ? _selectedPinCode.trim()
      : _extractPinCodeFromAddress(address);

    if (name.isEmpty) {
      _showMessage('Please enter your full name');
      return;
    }
    if (phone.length != 10) {
      _showMessage('Please enter a valid 10-digit phone number');
      return;
    }
    if (_gender == null) {
      _showMessage('Please select gender');
      return;
    }
    if (address.isEmpty) {
      _showMessage('Please enter your address');
      return;
    }
    if (city.isEmpty) {
      _showMessage('Please select address again to capture city');
      return;
    }
    if (pinCode.isEmpty) {
      _showMessage('Please select address again to capture pin code');
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
    if (_experience == null) {
      _showMessage('Please select previous experience');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(partnerOnboardingProvider.notifier)
        .submitProfile(
          fullName: name,
          phone: phone,
          city: city,
          pinCode: pinCode,
          serviceArea: address,
          serviceIds: _selectedServiceIds.toList(),
          gender: _gender?.toUpperCase() ?? '',
          workTypes: const <String>[],
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

  void _showMessage(String message) => AppToast.showError(message);

  Future<void> _showBackDialog() async {
    final shouldDiscard = await showBackConfirmationDialog(
      context,
      message:
          "Your entered information won't be saved.\nYou'll need to fill in this step again when you continue.",
    );
    if (shouldDiscard == true && mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.chooseRole, (r) => false);
    }
  }

  Future<void> _openAddressMapPicker() async {
    if (_isCapturingLocation) return;
    setState(() => _isCapturingLocation = true);

    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => const EditAddressScreen(),
        ),
      );

      if (!mounted || result == null) return;

      final lat = (result['latitude'] as num?)?.toDouble();
      final lng = (result['longitude'] as num?)?.toDouble();
      final city = (result['city'] ?? '').toString().trim();
        final pinCode = (result['pinCode'] ?? result['postalCode'] ?? '')
          .toString()
          .trim();
      final fullAddress =
          (result['fullAddress'] ?? result['address'] ?? '').toString().trim();

      setState(() {
        if (fullAddress.isNotEmpty) {
          _addressController.text = fullAddress;
        }
        _selectedCity = city.isNotEmpty ? city : _extractCityFromAddress(fullAddress);
        _selectedPinCode = pinCode.isNotEmpty
            ? pinCode
            : _extractPinCodeFromAddress(fullAddress);
        _capturedLatitude = lat;
        _capturedLongitude = lng;
      });
    } catch (e) {
      _showMessage('Unable to open map picker: $e');
    } finally {
      if (mounted) setState(() => _isCapturingLocation = false);
    }
  }

  Widget _toggleChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? _navy : _fieldBorder,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: const Color(0xFF2A3441),
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
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _navy : _fieldBorder,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Text(
          service.name,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF2A3441),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _addressPreviewCard() {
    final fullAddress = _addressController.text.trim();
    final parts = fullAddress
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final title = parts.isNotEmpty ? parts.first : 'Selected Address';
    final remaining = parts.length > 1 ? parts.sublist(1).join(', ') : '';
    final pinCode = _selectedPinCode.trim().isNotEmpty
        ? _selectedPinCode.trim()
        : _extractPinCodeFromAddress(fullAddress);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fieldBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.location_on,
              color: Color(0xFF0D9A55),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF101828),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (remaining.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    remaining,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1F2D3A),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (pinCode.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    pinCode,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1F2D3A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          InkWell(
            onTap: _isCapturingLocation ? null : _openAddressMapPicker,
            borderRadius: BorderRadius.circular(18),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.edit,
                color: Color(0xFF0B57D0),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: Color(0xFF1F2D3A),
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
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Color(0xFF303A47)),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF8C96A5), size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8A93A1), fontSize: 14),
        filled: true,
        fillColor: _fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _navy, width: 1.2),
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

    return WillPopScope(
      onWillPop: () async {
        await _showBackDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: _surface,
        body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              color: _navy,
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
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
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: _surface,
                child: busy
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 24,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE5E8ED),
                                      ),
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
                                          onChanged: (_) => setState(() {}),
                                        ),
                                        const SizedBox(height: 14),
                                        _label('Gender'),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: <Widget>[
                                            SizedBox(
                                              width: 106,
                                              child: _toggleChip(
                                                'Female',
                                                _gender == 'Female',
                                                () => setState(() => _gender = 'Female'),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              width: 106,
                                              child: _toggleChip(
                                                'Male',
                                                _gender == 'Male',
                                                () => setState(() => _gender = 'Male'),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _label('Phone Number *'),
                                        const SizedBox(height: 8),
                                        _field(
                                          controller: _phoneController,
                                          hint: '1234563215',
                                          icon: Icons.phone_outlined,
                                          keyboardType: TextInputType.phone,
                                          readOnly: onboarding.phone.isNotEmpty,
                                          onChanged: (_) => setState(() {}),
                                        ),
                                        const SizedBox(height: 14),
                                        _label('Address *'),
                                        const SizedBox(height: 8),
                                        _addressController.text.trim().isEmpty
                                            ? SizedBox(
                                                width: double.infinity,
                                                height: 46,
                                                child: ElevatedButton(
                                                  onPressed: _isCapturingLocation
                                                      ? null
                                                      : _openAddressMapPicker,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: _navy,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(10),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: _isCapturingLocation
                                                      ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                        )
                                                      : const Text(
                                                          'Add Address',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                ),
                                              )
                                            : _addressPreviewCard(),
                                        const SizedBox(height: 20),
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
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              children: [
                                                Expanded(child: _serviceChip(left)),
                                                const SizedBox(width: 8),
                                                right != null
                                                    ? Expanded(child: _serviceChip(right))
                                                    : const Expanded(child: SizedBox()),
                                              ],
                                            ),
                                          );
                                        }),
                                        const SizedBox(height: 18),
                                        _label('Do you have previous experience?'),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: _toggleChip(
                                                'Yes',
                                                _experience == 'Yes',
                                                () => setState(() => _experience = 'Yes'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _toggleChip(
                                                'No',
                                                _experience == 'No',
                                                () => setState(() => _experience = 'No'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: (_isSubmitting || !_isFormReady)
                                            ? null
                                            : _submitProfile,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isFormReady
                                              ? _navy
                                              : const Color(0xFF8492A0),
                                          disabledBackgroundColor: const Color(0xFF8492A0),
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
                                  ),
                                ],
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
