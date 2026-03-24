import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/partner_provider.dart';
import '../../utils/toast_helper.dart';

class PartnerProfileScreen extends ConsumerStatefulWidget {
  const PartnerProfileScreen({super.key});

  @override
  ConsumerState<PartnerProfileScreen> createState() =>
      _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends ConsumerState<PartnerProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;

  String _initialName = '';
  String _initialPhone = '';
  String _initialAddress = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.getPartnerProfile();
    if (!mounted) return;

    final profile = _extractProfile(res);

    _nameController.text = (profile['fullName'] ?? profile['name'] ?? '')
        .toString();
    _phoneController.text = (profile['phone'] ?? profile['phoneNumber'] ?? '')
        .toString();
    _addressController.text = _extractAddressValue(
      profile['address'] ?? profile['serviceArea'],
    );

    _initialName = _nameController.text;
    _initialPhone = _phoneController.text;
    _initialAddress = _addressController.text;

    setState(() => _isLoading = false);
  }

  bool get _hasChanges {
    return _nameController.text.trim() != _initialName.trim() ||
        _phoneController.text.trim() != _initialPhone.trim() ||
        _addressController.text.trim() != _initialAddress.trim();
  }

  void _onEditTap() {
    setState(() => _isEditMode = true);
  }

  void _onCancelEdit() {
    _nameController.text = _initialName;
    _phoneController.text = _initialPhone;
    _addressController.text = _initialAddress;
    setState(() => _isEditMode = false);
  }

  Future<void> _onSave() async {
    if (_isSaving) return;

    if (_nameController.text.trim().isEmpty) {
      AppToast.showError('Please enter full name');
      return;
    }

    if (!_hasChanges) {
      setState(() => _isEditMode = false);
      return;
    }

    setState(() => _isSaving = true);

    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.updatePartnerProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    if (!mounted) return;

    final success = res['success'] == true;
    if (success) {
      _initialName = _nameController.text;
      _initialPhone = _phoneController.text;
      _initialAddress = _addressController.text;
      setState(() {
        _isSaving = false;
        _isEditMode = false;
      });
      AppToast.showSuccess('Profile updated successfully');
      return;
    }

    setState(() => _isSaving = false);
    AppToast.showError(
      (res['message'] ?? 'Failed to update profile').toString(),
    );
  }

  Map<String, dynamic> _extractProfile(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final partner = data['partner'];
      if (partner is Map<String, dynamic>) return partner;
      final profile = data['profile'];
      if (profile is Map<String, dynamic>) return profile;
      return data;
    }

    final partner = payload['partner'];
    if (partner is Map<String, dynamic>) return partner;

    final profile = payload['profile'];
    if (profile is Map<String, dynamic>) return profile;

    return payload;
  }

  String _extractAddressValue(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      // Prefer explicit address-like keys when provided by API.
      for (final key in const ['fullAddress', 'address', 'line1', 'street']) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      // Fallback: join primitive values so UI shows readable text only.
      final parts = map.values
          .where((v) => v is String || v is num)
          .map((v) => v.toString().trim())
          .where((v) => v.isNotEmpty)
          .toList();

      return parts.join(', ');
    }

    return raw.toString();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          _isEditMode ? 'Edit Profile' : 'Profile',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: _onEditTap,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B2239),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF091A2D),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              if (_isEditMode)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF8A00),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _fieldLabel('Full Name'),
                          _profileInput(
                            controller: _nameController,
                            hint: 'Enter your full name',
                            icon: Icons.person_outline,
                            enabled: _isEditMode,
                          ),
                          const SizedBox(height: 12),
                          _fieldLabel('Phone Number'),
                          _profileInput(
                            controller: _phoneController,
                            hint: 'Phone number',
                            icon: Icons.phone_outlined,
                            enabled: _isEditMode,
                          ),
                          const SizedBox(height: 12),
                          _fieldLabel('Address (Optional)'),
                          _profileInput(
                            controller: _addressController,
                            hint: 'Enter your address',
                            icon: Icons.location_on_outlined,
                            enabled: _isEditMode,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isEditMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF17A2D8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _onCancelEdit,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD0D5DD)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF1D2939),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _profileInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF98A2B3), size: 20),
        ),
      ),
    );
  }
}
