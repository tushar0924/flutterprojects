import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  static final List<_NotificationItemData> _items = <_NotificationItemData>[
    _NotificationItemData(
      title: 'Upcoming Booking Reminder',
      message:
          'You have a booking today at 9:00 AM. Customer: Priya S., Service: Cook, Duration: 2 hours',
      time: '3 min ago',
      isUnread: true,
      leadingBg: Color(0xFFEFF4FF),
      leadingIcon: Icons.notifications_none_rounded,
      leadingIconColor: Color(0xFF2F6FED),
    ),
    _NotificationItemData(
      title: 'New Booking Request! ⚠️',
      message:
          'Customer Anjali Verma wants to book you for Maid Service (2 hours). Location: Koramangala, Bangalore. Timing: Tomorrow 10:00 AM',
      time: '2 mins ago',
      isUnread: true,
      leadingBg: Color(0xFFEAF1FF),
      leadingIcon: Icons.inventory_2_outlined,
      leadingIconColor: Color(0xFF2C6AF3),
    ),
    _NotificationItemData(
      title: 'New 5-Star Rating! ✨',
      message:
          'Customer loved your service! "Very punctual and professional. Excellent cleaning work!" Keep it up!',
      time: '3 hours ago',
      isUnread: false,
      leadingBg: Color(0xFFFFF4DE),
      leadingIcon: Icons.star_border_rounded,
      leadingIconColor: Color(0xFFCC9A2B),
      highlighted: true,
    ),
    _NotificationItemData(
      title: 'Booking Cancelled',
      message:
          'Customer cancelled booking #BKG12340. Cancellation fee of ₹50 has been credited to your account.',
      time: '5 hours ago',
      isUnread: false,
      leadingBg: Color(0xFFFFECEF),
      leadingIcon: Icons.cancel_outlined,
      leadingIconColor: Color(0xFFE9445A),
    ),
    _NotificationItemData(
      title: 'KYC Verification Approved ✓',
      message:
          'Congratulations! Your KYC documents have been verified successfully. You can now accept booking requests.',
      time: '1 day ago',
      isUnread: false,
      leadingBg: Color(0xFFE8F8EC),
      leadingIcon: Icons.check_circle_outline,
      leadingIconColor: Color(0xFF2AAE5D),
    ),
    _NotificationItemData(
      title: 'Payment Received ✓',
      message:
          '₹450 credited to your account for booking #BKG12345. Customer: Priya S. Service: Maid - Hourly',
      time: '1 hour ago',
      isUnread: false,
      leadingBg: Color(0xFFE8F8EC),
      leadingIcon: Icons.credit_card_rounded,
      leadingIconColor: Color(0xFF1CA958),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleItems = _showUnreadOnly
        ? _items.where((item) => item.isUnread).toList()
        : _items;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NotificationsHeader(
              unreadCount: _items.where((item) => item.isUnread).length,
              showUnreadOnly: _showUnreadOnly,
              onBack: () => Navigator.of(context).pop(),
              onMarkAllRead: () => setState(() {
                for (var i = 0; i < _items.length; i++) {
                  final current = _items[i];
                  _items[i] = current.copyWith(isUnread: false);
                }
                _showUnreadOnly = false;
              }),
              onSelectAll: () => setState(() => _showUnreadOnly = false),
              onSelectUnread: () => setState(() => _showUnreadOnly = true),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: visibleItems.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE1E5EA),
                ),
                itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  return _NotificationTile(item: item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.unreadCount,
    required this.showUnreadOnly,
    required this.onBack,
    required this.onMarkAllRead,
    required this.onSelectAll,
    required this.onSelectUnread,
  });

  final int unreadCount;
  final bool showUnreadOnly;
  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectUnread;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0D355A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onMarkAllRead,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2B4D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF33506E), width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FilterPill(
                    title: 'All (10)',
                    selected: !showUnreadOnly,
                    onTap: onSelectAll,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _FilterPill(
                    title: 'Unread ($unreadCount)',
                    selected: showUnreadOnly,
                    onTap: onSelectUnread,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF8FAFC) : const Color(0xFF1A456A),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? const Color(0xFF0B2239) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final _NotificationItemData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.highlighted ? const Color(0xFFFFFBF4) : const Color(0xFFF3F5F7),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.leadingBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.leadingIcon, color: item.leadingIconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  style: const TextStyle(
                    color: Color(0xFF49566A),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.time,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: item.isUnread
                      ? const Color(0xFF10A8F3)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 48),
              const Icon(Icons.more_horiz, color: Color(0xFF111827), size: 19),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationItemData {
  const _NotificationItemData({
    required this.title,
    required this.message,
    required this.time,
    required this.isUnread,
    required this.leadingBg,
    required this.leadingIcon,
    required this.leadingIconColor,
    this.highlighted = false,
  });

  final String title;
  final String message;
  final String time;
  final bool isUnread;
  final Color leadingBg;
  final IconData leadingIcon;
  final Color leadingIconColor;
  final bool highlighted;

  _NotificationItemData copyWith({
    String? title,
    String? message,
    String? time,
    bool? isUnread,
    Color? leadingBg,
    IconData? leadingIcon,
    Color? leadingIconColor,
    bool? highlighted,
  }) {
    return _NotificationItemData(
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isUnread: isUnread ?? this.isUnread,
      leadingBg: leadingBg ?? this.leadingBg,
      leadingIcon: leadingIcon ?? this.leadingIcon,
      leadingIconColor: leadingIconColor ?? this.leadingIconColor,
      highlighted: highlighted ?? this.highlighted,
    );
  }
}