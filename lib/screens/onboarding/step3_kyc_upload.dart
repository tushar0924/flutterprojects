import 'package:flutter/material.dart';
import '../../routes/app_router.dart';

class OnboardingStep3 extends StatefulWidget {
  const OnboardingStep3({super.key});

  @override
  State<OnboardingStep3> createState() => _OnboardingStep3State();
}

class _OnboardingStep3State extends State<OnboardingStep3> {
  bool _photoUploaded = false;
  bool _panUploaded = false;
  bool _policeUploaded = false;

  void _togglePhoto() => setState(() => _photoUploaded = !_photoUploaded);
  void _togglePan() => setState(() => _panUploaded = !_panUploaded);
  void _togglePolice() => setState(() => _policeUploaded = !_policeUploaded);

  @override
  Widget build(BuildContext context) {
    final nextEnabled = true;

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
                      // Info box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF7FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCEE8FF)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.info_outline, color: Color(0xFF2B7BD6)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Why KYC is required?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF1A2740),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'KYC verification ensures safety and trust for all users on our platform. Your documents are encrypted and securely stored.',
                                    style: TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Your Photo card
                      _buildUploadCard(
                        title: 'Your Photo',
                        subtitle: 'Clear face photo',
                        actionLabel: _photoUploaded ? 'Retake' : 'Take Selfie',
                        actionOnPressed: _togglePhoto,
                        content: _photoUploaded ? _photoPreview() : _photoPlaceholder(),
                        showActionBelow: true,
                        showTopAction: true,
                      ),

                      const SizedBox(height: 12),

                      // Pan Card
                      _buildUploadCard(
                        title: 'Pan Card',
                        subtitle: 'Front or back side',
                        actionLabel: 'Choose File',
                        actionOnPressed: _togglePan,
                        content: _filePlaceholder(_panUploaded),
                        showActionBelow: true,
                      ),

                      const SizedBox(height: 12),

                      // Police Verification
                      _buildUploadCard(
                        title: 'Police Verification Certificate',
                        subtitle: '',
                        actionLabel: 'Choose File',
                        actionOnPressed: _togglePolice,
                        content: _filePlaceholder(_policeUploaded),
                        showActionBelow: true,
                      ),

                      const SizedBox(height: 16),

                      // Guidelines
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Upload Guidelines:', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 8),
                            Text('• Documents should be clear and readable'),
                            Text('• File size should not exceed 5MB'),
                            Text('• Accepted formats: JPG, PNG, PDF'),
                            Text('• Ensure all corners are visible'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Next button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                            onPressed: nextEnabled
                              ? () => Navigator.of(context).pushReplacementNamed(AppRouter.onboardingStep4)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nextEnabled ? const Color(0xFF0B2B4A) : Colors.grey.shade400,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Next', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Center(
                        child: Text('Your documents are encrypted and securely stored', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ),

                      const SizedBox(height: 18),
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

  Widget _photoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.person_outline, size: 44, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPreview() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade200,
        image: const DecorationImage(
          image: NetworkImage('https://i.pravatar.cc/300'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(),
    );
  }

  Widget _filePlaceholder(bool uploaded) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(uploaded ? 'File chosen' : 'Choose File'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback actionOnPressed,
    required Widget content,
    bool showActionBelow = false,
    bool showTopAction = false,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (subtitle.isNotEmpty) const SizedBox(height: 4),
                    if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
                if (showTopAction)
                  OutlinedButton(
                    onPressed: actionOnPressed,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(actionLabel, style: const TextStyle(color: Colors.black87)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            content,
            if (showActionBelow) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: actionOnPressed,
                  icon: const Icon(Icons.upload_outlined),
                  label: Text(actionLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
