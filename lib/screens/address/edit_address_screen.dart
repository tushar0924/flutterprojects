import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/partner_address_model.dart';
import '../../providers/partner_provider.dart';
import '../../utils/toast_helper.dart';

class EditAddressScreen extends ConsumerStatefulWidget {
  const EditAddressScreen({super.key});

  @override
  ConsumerState<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends ConsumerState<EditAddressScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocating = false;

  double? _latitude;
  double? _longitude;

  String _initialAddress = '';
  String _initialCity = '';
  String _initialPinCode = '';
  double? _initialLatitude;
  double? _initialLongitude;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAddress());
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    setState(() => _isLoading = true);

    final repo = ref.read(partnerRepositoryProvider);
    final address = await repo.getPartnerAddress();
    if (!mounted) return;

    _addressController.text = address.address;
    _cityController.text = address.city;
    _pinCodeController.text = address.pinCode;
    _latitude = address.latitude;
    _longitude = address.longitude;

    _initialAddress = address.address;
    _initialCity = address.city;
    _initialPinCode = address.pinCode;
    _initialLatitude = address.latitude;
    _initialLongitude = address.longitude;

    setState(() => _isLoading = false);
  }

  bool get _hasChanges {
    return _addressController.text.trim() != _initialAddress.trim() ||
        _cityController.text.trim() != _initialCity.trim() ||
        _pinCodeController.text.trim() != _initialPinCode.trim() ||
        _latitude != _initialLatitude ||
        _longitude != _initialLongitude;
  }

  Future<void> _updateGpsLocation() async {
    if (_isLocating) return;

    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppToast.showError('Please enable location services');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppToast.showError('Location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (_) {
      AppToast.showError('Unable to get GPS location');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _saveAddress() async {
    if (_isSaving) return;

    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final pinCode = _pinCodeController.text.trim();
    if (address.isEmpty) {
      AppToast.showError('Please enter address');
      return;
    }
    if (city.isEmpty) {
      AppToast.showError('Please enter city');
      return;
    }
    if (pinCode.isEmpty) {
      AppToast.showError('Please enter pin code');
      return;
    }

    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);

    final model = PartnerAddressModel(
      address: address,
      city: city,
      pinCode: pinCode,
      latitude: _latitude,
      longitude: _longitude,
    );

    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.updatePartnerAddress(model);

    if (!mounted) return;

    final success = res['success'] == true;
    if (success) {
      Navigator.of(context).pop();
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
      backgroundColor: const Color(0xFFF2F4F7),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(12, 14, 12, 16 + keyboardInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD0D5DD)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Address',
                                style: TextStyle(
                                  color: Color(0xFF344054),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F4F7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFD0D5DD),
                                  ),
                                ),
                                child: TextField(
                                  controller: _addressController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your address',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFF98A2B3),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'City',
                                style: TextStyle(
                                  color: Color(0xFF344054),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F4F7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFD0D5DD),
                                  ),
                                ),
                                child: TextField(
                                  controller: _cityController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter city',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.location_city_outlined,
                                      color: Color(0xFF98A2B3),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Pin Code',
                                style: TextStyle(
                                  color: Color(0xFF344054),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F4F7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFD0D5DD),
                                  ),
                                ),
                                child: TextField(
                                  controller: _pinCodeController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter pin code',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.pin_drop_outlined,
                                      color: Color(0xFF98A2B3),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'GPS Coordinates',
                                style: TextStyle(
                                  color: Color(0xFF344054),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: OutlinedButton.icon(
                                  onPressed: _isLocating
                                      ? null
                                      : _updateGpsLocation,
                                  icon: _isLocating
                                      ? const SizedBox(
                                          height: 14,
                                          width: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.near_me_outlined,
                                          size: 16,
                                        ),
                                  label: const Text('Update GPS Location'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF0B2239),
                                    ),
                                    foregroundColor: const Color(0xFF0B2239),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _latitude != null && _longitude != null
                                    ? '✓ GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                    : 'GPS not available',
                                style: TextStyle(
                                  color: _latitude != null && _longitude != null
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF98A2B3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFB7D2FF)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('💡', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tip: Accurate location helps customers find you easily and improves booking efficiency.',
                                  style: TextStyle(
                                    color: Color(0xFF1D4ED8),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B2239),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
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
                                    'Save',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF475467),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
