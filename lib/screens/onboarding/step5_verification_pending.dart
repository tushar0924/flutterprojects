import 'package:flutter/material.dart';

class OnboardingStep5 extends StatelessWidget {
  const OnboardingStep5({super.key});

  @override
  Widget build(BuildContext context) {
    // Exact colors from the provided images
    const Color themeNavy = Color(0xFF09233D);
    const Color accentCyan = Color(0xFF00C8D7);
    const Color lightBg = Color(0xFFF8F9FB);
    const Color timelineBlue = Color(0xFFEBF5FF);

    return Scaffold(
      backgroundColor: themeNavy,
      appBar: AppBar(
        backgroundColor: themeNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Verification Pending',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Step 5 of 5 • Almost Done!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Top Status Icon
              const Center(
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: accentCyan,
                  child: Icon(Icons.access_time, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verification Pending',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const Text(
                'Step 5 of 5 • Almost Done!',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 25),

              // Main Application Review Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFE8F1FF),
                      child: Icon(Icons.access_time, color: themeNavy, size: 26),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Thanks, Parul Gupta!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your application is under review. We\'ll notify\nyou once it\'s approved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Info Data Pills
                    _buildDataPill('Request ID', 'iDFY_1764232460896', lightBg),
                    _buildDataPill('Role', 'Helper', lightBg),
                    _buildDataPill('Submitted', '28 Nov 2025, 11:20 am', lightBg),

                    const SizedBox(height: 20),

                    // Status Timeline
                    _buildTimelineItem('Registration Complete', 'Your details have been submitted', isDone: true, color: Colors.green),
                    _buildTimelineItem('Documents Uploaded', 'KYC documents received', isDone: true, color: Colors.green),
                    _buildTimelineItem('Admin Verification', 'In progress...', isCurrent: true, color: Colors.amber),
                    _buildTimelineItem('Account Activation', 'Pending approval', isLast: true, color: Colors.grey.shade300),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Expected Timeline Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: timelineBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1E9FF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Expected Timeline', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 14)),
                          SizedBox(height: 4),
                          Text(
                            'In production, KYC verification takes 24-48 hours via iDFY API.',
                            style: TextStyle(color: Color(0xFF1565C0), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Support Contact Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Need Help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 16),
                    _buildContactRow(Icons.phone_outlined, 'Call Support', '+91 1234567896'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ),
                    _buildContactRow(Icons.email_outlined, 'Email Support', 'support@helperr4u.com'),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "We'll send you an SMS and email once your account is verified",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataPill(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String sub, {bool isDone = false, bool isCurrent = false, bool isLast = false, required Color color}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Icon(isDone ? Icons.check_circle : (isCurrent ? Icons.access_time_filled : Icons.radio_button_unchecked), color: color, size: 22),
              if (!isLast)
                Expanded(
                  child: Container(width: 1.5, color: isDone ? Colors.green : Colors.grey.shade200),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String title, String sub) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF0F7FF), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.black87, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text(sub, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}