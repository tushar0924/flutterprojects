import 'package:flutter/material.dart';
import '../../routes/app_router.dart';

class OnboardingStep4 extends StatelessWidget {
  const OnboardingStep4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2740),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1A2740),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                        'Add Bank Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Step 4 of 5 • Add Account Details',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // white card
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
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      const Text('Enter your bank details.'),
                      const SizedBox(height: 14),

                      _buildTextField('Bank Account Name'),
                      const SizedBox(height: 12),
                      _buildTextField('Bank Account Number', keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField('Confirm Bank Account Number', keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField('Enter IFSC Code'),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRouter.onboardingStep5),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B95A0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Proceed for verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.lock_outline, size: 16, color: Colors.black54),
                            SizedBox(width: 6),
                            Text('Your documents are encrypted and securely stored', style: TextStyle(color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
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

  Widget _buildTextField(String label, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue)),
      ),
    );
  }
}
