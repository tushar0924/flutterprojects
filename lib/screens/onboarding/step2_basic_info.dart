import 'package:flutter/material.dart';
import '../../routes/app_router.dart';

class OnboardingStep2 extends StatefulWidget {
  const OnboardingStep2({super.key});

  @override
  State<OnboardingStep2> createState() => _OnboardingStep2State();
}

class _OnboardingStep2State extends State<OnboardingStep2> {
  // Selections
  String? _gender;
  final Set<String> _services = {};
  String? _workType;
  String? _experience;
  String? _startTime;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ── Reusable toggle chip ──────────────────────────────────────
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

  // ── Service chip (multi-select) ───────────────────────────────
  Widget _serviceChip(String label) {
    final selected = _services.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _services.remove(label);
        } else {
          _services.add(label);
        }
      }),
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

  // ── Section label ─────────────────────────────────────────────
  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: Colors.black87,
    ),
  );

  // ── Text field ────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: Color(0xFF4DD9C0), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = _nameController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1A2740),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            Container(
              color: const Color(0xFF1A2740),
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        style:
                        TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── White scrollable card ────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      _label('Full Name *'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _nameController,
                        hint: 'Enter Your full name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      _label('Gender'),
                      const SizedBox(height: 8),
                      Row(children: [
                        _toggleChip('Female', _gender == 'Female',
                                () => setState(() => _gender = 'Female')),
                        const SizedBox(width: 10),
                        _toggleChip('Male', _gender == 'Male',
                                () => setState(() => _gender = 'Male')),
                      ]),
                      const SizedBox(height: 16),

                      // Phone
                      _label('Phone Number *'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _phoneController,
                        hint: '1234563215',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Address
                      _label('Address *'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _addressController,
                        hint: 'Enter complete address',
                        icon: Icons.location_on_outlined,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      // Location
                      _label('Location *'),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.navigation_outlined,
                              size: 18),
                          label: const Text('Capture GPS Location'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Services
                      _label('Choose Service You Provide'),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3.2,
                        children: [
                          'Maid',
                          'Cook',
                          'Shop-helper',
                          'Driver',
                          'Nanny',
                          'Elder Care',
                          'Baby Sitter',
                          'Patient Care',
                        ].map((s) => _serviceChip(s)).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Work type
                      _label('Type of work you prefer'),
                      const SizedBox(height: 8),
                      Row(children: [
                        _toggleChip('Hourly', _workType == 'Hourly',
                                () => setState(() => _workType = 'Hourly')),
                        const SizedBox(width: 8),
                        _toggleChip('Per day', _workType == 'Per day',
                                () => setState(() => _workType = 'Per day')),
                        const SizedBox(width: 8),
                        _toggleChip('Monthly', _workType == 'Monthly',
                                () => setState(() => _workType = 'Monthly')),
                      ]),
                      const SizedBox(height: 18),

                      // Experience
                      _label('Do you have previous experience?'),
                      const SizedBox(height: 8),
                      Row(children: [
                        _toggleChip('Yes', _experience == 'Yes',
                                () => setState(() => _experience = 'Yes')),
                        const SizedBox(width: 8),
                        _toggleChip('No', _experience == 'No',
                                () => setState(() => _experience = 'No')),
                      ]),
                      const SizedBox(height: 18),

                      // Start time
                      _label('When can you start working?'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _toggleChip(
                              'Immediately',
                              _startTime == 'Immediately',
                                  () => setState(
                                      () => _startTime = 'Immediately')),
                          _toggleChip(
                              'Within a week',
                              _startTime == 'Within a week',
                                  () => setState(
                                      () => _startTime = 'Within a week')),
                          _toggleChip(
                              'Next month',
                              _startTime == 'Next month',
                                  () => setState(
                                      () => _startTime = 'Next month')),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(AppRouter.onboardingStep3),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A2740),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to KYC Upload',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 18),
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