import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

enum _SupportTab { chat, faqs, safety, contact }

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  _SupportTab _selectedTab = _SupportTab.chat;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _contactSubjectController = TextEditingController();
  final TextEditingController _contactMessageController = TextEditingController();
  final Set<int> _expandedFaqIndexes = <int>{0};
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text: 'Hello! How can I help you today?',
      time: '10:30 AM',
      isMe: false,
    ),
    const _ChatMessage(
      text: 'I have a question about my earnings',
      time: '10:31 AM',
      isMe: true,
    ),
    const _ChatMessage(
      text: "Sure! I'd be happy to help with that.\nWhat would you like to know?",
      time: '10:31 AM',
      isMe: false,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _contactSubjectController.dispose();
    _contactMessageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          time: '$hour:$minute $period',
          isMe: true,
        ),
      );
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFF0B2A4A);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(fontSize: 27 / 2, fontWeight: FontWeight.w500),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Row(
              children: [
                _buildTabButton(
                  tab: _SupportTab.chat,
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  tab: _SupportTab.faqs,
                  icon: Icons.help_outline,
                  label: 'FAQs',
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  tab: _SupportTab.safety,
                  icon: Icons.shield_outlined,
                  label: 'Safety',
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  tab: _SupportTab.contact,
                  icon: Icons.call_outlined,
                  label: 'Contact',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildTabBody()),
          if (_selectedTab == _SupportTab.chat) _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required _SupportTab tab,
    required IconData icon,
    required String label,
  }) {
    final active = _selectedTab == tab;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedTab = tab),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: active ? Colors.white : const Color(0xFF23466B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF365D85)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? const Color(0xFF0B2A4A) : Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? const Color(0xFF0B2A4A) : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_selectedTab) {
      case _SupportTab.chat:
        return _buildChatTab();
      case _SupportTab.faqs:
        return _buildFaqTab();
      case _SupportTab.safety:
        return _buildSafetyTab();
      case _SupportTab.contact:
        return _buildContactTab();
    }
  }

  Widget _buildChatTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF5FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB2CCFF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 15, color: Color(0xFF175CD3)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Support available 24/7 • Average response time: 2 minutes',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0037B3)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final message in _messages) _chatBubble(message),
      ],
    );
  }

  Widget _chatBubble(_ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: message.isMe ? const Color(0xFF0B2A4A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe ? Colors.white : const Color(0xFF101828),
                fontSize: 16 / 1.2,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                fontSize: 11,
                color: message.isMe ? Colors.white70 : const Color(0xFF98A2B3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Color(0xFF667085)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF0B2A4A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_outlined, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    const faqItems = <_FaqItem>[
      _FaqItem(
        category: 'Payments',
        question: 'When will I receive my payment?',
        answer:
            'Payments are processed within 24 hours after job completion. You can withdraw your available balance anytime using the "Withdraw" option in the Earnings section.',
      ),
      _FaqItem(
        category: 'Payments',
        question: 'What is the commission rate?',
        answer: 'Commission varies by service category and is shown in your payout summary.',
      ),
      _FaqItem(
        category: 'Jobs',
        question: 'How do I accept a job?',
        answer: 'Tap Accept on booking alert and complete OTP verification to start the job.',
      ),
      _FaqItem(
        category: 'Jobs',
        question: 'Can I cancel a job after accepting?',
        answer: 'Yes, but repeated cancellations may affect your profile score and visibility.',
      ),
      _FaqItem(
        category: 'Account',
        question: 'How can I improve my ratings?',
        answer: 'Arrive on time, maintain quality, and upload clear before/after photos.',
      ),
      _FaqItem(
        category: 'Account',
        question: 'How do I update my availability?',
        answer: 'Go to Manage Service and set your preferred working days and timings.',
      ),
      _FaqItem(
        category: 'Safety',
        question: 'What if I face an emergency during a job?',
        answer: 'Use the SOS option in app and contact emergency support immediately.',
      ),
      _FaqItem(
        category: 'Technical',
        question: 'The app is not working properly',
        answer: 'Try updating the app and clearing cache. If issue persists, contact support.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF101828), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        const Text(
          'Find quick answers to common questions',
          style: TextStyle(fontSize: 11.5, color: Color(0xFF667085)),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < faqItems.length; i++) _buildFaqTile(i, faqItems[i]),
      ],
    );
  }

  Widget _buildFaqTile(int index, _FaqItem item) {
    final expanded = _expandedFaqIndexes.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            if (expanded) {
              _expandedFaqIndexes.remove(index);
            } else {
              _expandedFaqIndexes.add(index);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(fontSize: 9, color: Color(0xFF175CD3), fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: const Color(0xFF98A2B3),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                item.question,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF101828), height: 1.3),
              ),
              if (expanded) ...[
                const SizedBox(height: 8),
                Text(
                  item.answer,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF667085), height: 1.35),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Column(
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Color(0xFFEF4444)),
                  SizedBox(width: 6),
                  Text(
                    'Your Safety Matters',
                    style: TextStyle(fontSize: 12.8, color: Color(0xFF101828), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Follow these guidelines to ensure\nyour safety while working',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF667085)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _safetyChecklistCard(
          title: 'Before Starting a Job',
          items: const [
            'Verify customer details in the app',
            'Share your live location with a trusted contact',
            'Arrive during agreed time slot',
            'Carry necessary equipment and supplies',
          ],
        ),
        _safetyChecklistCard(
          title: 'During the Job',
          items: const [
            'Maintain professional boundaries',
            'Follow all safety protocols',
            'If uncomfortable, politely excuse yourself and contact support',
            'Don\'t share personal contact information',
          ],
        ),
        _safetyChecklistCard(
          title: 'Payment & Completion',
          items: const [
            'All payments are processed through the app',
            'Never accept cash directly unless specified',
            'Mark job as complete only after finishing',
            'Ask for feedback to improve ratings',
          ],
        ),
        _safetyChecklistCard(
          title: 'Emergency Situations',
          items: const [
            'Call emergency helpline: +91 98765 43210',
            'Use in-app SOS button for immediate assistance',
            'Move to a safe location if threatened',
            'Report any incidents to support immediately',
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.phone_in_talk_outlined, size: 14, color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Text(
                'Emergency Helpline: +91 98765 43210',
                style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _safetyChecklistCard({required String title, required List<String> items}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF101828), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check, size: 12, color: Color(0xFF101828)),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF344054), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFBF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFB7E4C7)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get in Touch',
                style: TextStyle(fontSize: 13, color: Color(0xFF101828), fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'Multiple ways to reach our support team',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF667085)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _contactSupportCard(
          icon: Icons.call,
          iconBg: const Color(0xFFD1FADF),
          iconColor: const Color(0xFF12B76A),
          title: 'Phone Support',
          subtitle: 'Available 24/7',
          actionText: 'Call +91 98765 43210',
          actionColor: const Color(0xFF0CB848),
        ),
        _contactSupportCard(
          icon: Icons.email_outlined,
          iconBg: const Color(0xFFEAF2FF),
          iconColor: const Color(0xFF175CD3),
          title: 'Email Support',
          subtitle: 'Response within 24 hours',
          actionText: 'partner-support@helperr4u.com',
          actionColor: const Color(0xFF2563EB),
        ),
        _contactSupportCard(
          icon: Icons.chat_bubble_outline,
          iconBg: const Color(0xFFF2E8FF),
          iconColor: const Color(0xFF9333EA),
          title: 'Live Chat',
          subtitle: 'Instant support',
          actionText: 'Start Chat',
          actionColor: const Color(0xFF9333EA),
          trailingBadge: 'Coming Soon',
        ),
        const SizedBox(height: 10),
        const Text(
          'Send us a Message',
          style: TextStyle(fontSize: 13, color: Color(0xFF101828), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        const Text('Subject', style: TextStyle(fontSize: 11, color: Color(0xFF667085))),
        const SizedBox(height: 4),
        _contactInputField(
          controller: _contactSubjectController,
          hintText: '',
        ),
        const SizedBox(height: 8),
        const Text('Message', style: TextStyle(fontSize: 11, color: Color(0xFF667085))),
        const SizedBox(height: 4),
        _contactInputField(
          controller: _contactMessageController,
          hintText: 'Describe your issue...',
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.send_outlined, size: 15, color: Colors.white),
            label: const Text(
              'Send Message',
              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B2A4A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _contactSupportCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    required Color actionColor,
    String? trailingBadge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF101828), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF98A2B3)),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trailingBadge,
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                actionText,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactInputField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 12.5, color: Color(0xFF101828)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF98A2B3)),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
  });

  final String text;
  final String time;
  final bool isMe;
}

class _FaqItem {
  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });

  final String category;
  final String question;
  final String answer;
}
