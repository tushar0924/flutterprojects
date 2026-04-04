import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/partner_address_model.dart';
import '../../providers/partner_provider.dart';
import '../../utils/toast_helper.dart';
import 'location_map_picker_screen.dart';

class EditAddressScreen extends ConsumerStatefulWidget {
  const EditAddressScreen({super.key});

  @override
  ConsumerState<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends ConsumerState<EditAddressScreen> {
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  double? _latitude;
  double? _longitude;
  String _pinCode = '';

  String _initialBuilding = '';
  String _initialStreet = '';
  String _initialArea = '';
  double? _initialLatitude;
  double? _initialLongitude;
  String _initialPinCode = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAddress());
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    setState(() => _isLoading = true);

    final repo = ref.read(partnerRepositoryProvider);
    final address = await repo.getPartnerAddress();
    if (!mounted) return;

    // Expected persisted format: "Building/Floor || Street Address || Area/Locality"
    final parts = address.address.split('||').map((s) => s.trim()).toList();

    final normalizedAddress = address.address.replaceAll('||', ', ').trim();

    _buildingController.text = parts.isNotEmpty ? parts[0] : '';
    _streetController.text = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1]
        : normalizedAddress;
    _areaController.text = parts.length > 2 && parts[2].isNotEmpty
        ? parts[2]
        : '';

    _latitude = address.latitude;
    _longitude = address.longitude;
    _pinCode = address.pinCode.trim();

    _initialBuilding = _buildingController.text;
    _initialStreet = _streetController.text;
    _initialArea = _areaController.text;
    _initialLatitude = address.latitude;
    _initialLongitude = address.longitude;
    _initialPinCode = _pinCode;

    setState(() => _isLoading = false);
  }

  bool get _hasChanges {
    return _buildingController.text.trim() != _initialBuilding.trim() ||
        _streetController.text.trim() != _initialStreet.trim() ||
        _areaController.text.trim() != _initialArea.trim() ||
        _latitude != _initialLatitude ||
        _longitude != _initialLongitude ||
        _pinCode != _initialPinCode;
  }

  String _extractPinCode(String text) {
    final match = RegExp(r'\b\d{6}\b').firstMatch(text);
    return match?.group(0) ?? '';
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => LocationMapPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        final building = (result['building'] ?? '').toString().trim();
        final street = (result['street'] ?? '').toString().trim();
        final area = (result['area'] ?? '').toString().trim();
        final postalCode = (result['postalCode'] ?? '').toString().trim();
        final fullAddress = (result['fullAddress'] ?? result['address'] ?? '')
            .toString()
            .trim();

        _buildingController.text = building;
        _streetController.text = street;
        _areaController.text = fullAddress.isNotEmpty ? fullAddress : area;
        _pinCode = postalCode.isNotEmpty
            ? postalCode
            : _extractPinCode(
                '$fullAddress ${_areaController.text} ${_streetController.text}',
              );
      });
    }
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1C2430),
        fontSize: 32 / 2,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    String? hint,
    bool readOnly = false,
    int? maxLines = 1,
    int? minLines,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      minLines: minLines,
      maxLines: maxLines,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      style: const TextStyle(
        fontSize: 17,
        color: Color(0xFF111827),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF7A8392),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFFF2F4F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0B2239), width: 1.2),
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (_isSaving) return;

    final building = _buildingController.text.trim();
    final street = _streetController.text.trim();
    final area = _areaController.text.trim();
    final pinCode = _pinCode.isNotEmpty
        ? _pinCode
        : _extractPinCode('$street $area');

    if (building.isEmpty) {
      AppToast.showError('Please enter building/floor');
      return;
    }
    if (street.isEmpty) {
      AppToast.showError('Please enter street address');
      return;
    }
    if (area.isEmpty) {
      AppToast.showError('Please enter area/locality');
      return;
    }
    if (pinCode.isEmpty) {
      AppToast.showError(
        'Unable to detect pin code. Please select location again.',
      );
      return;
    }

    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);

    // Combine address fields
    final fullAddress = '$building || $street || $area';

    final model = PartnerAddressModel(
      address: fullAddress,
      city: area,
      pinCode: pinCode,
      latitude: _latitude,
      longitude: _longitude,
    );

    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.updatePartnerAddress(model);

    if (!mounted) return;

    final success = res['success'] == true;
    if (success) {
      Navigator.of(context).pop(<String, dynamic>{
        'address': fullAddress,
        'fullAddress': fullAddress,
        'building': building,
        'street': street,
        'area': area,
        'city': area,
        'pinCode': pinCode,
        'latitude': _latitude,
        'longitude': _longitude,
      });
      return;
    }

    setState(() => _isSaving = false);
    AppToast.showError(
      (res['message'] ?? 'Failed to update address').toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFE3E5E8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2239),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'Edit Address',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + keyboardInset),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B2239),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save Address',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31 / 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Location Details',
                      style: TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 32 / 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFDFE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Building / Floor'),
                        const SizedBox(height: 8),
                        _inputField(
                          controller: _buildingController,
                          hint: 'Enter Building / Floor address',
                        ),
                        const SizedBox(height: 14),
                        _sectionLabel('Street Address'),
                        const SizedBox(height: 8),
                        _inputField(
                          controller: _streetController,
                          hint: 'Street (Recommended)',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        _sectionLabel('Area / Locality'),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _inputField(
                                controller: _areaController,
                                hint: 'Enter area/locality or select from map',
                                minLines: 3,
                                maxLines: null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: _isSaving ? null : _openMapPicker,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 78,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF8C8F94),
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Color(0xFF0D9A55),
                                      size: 30,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Change',
                                      style: TextStyle(
                                        color: Color(0xFF101828),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
