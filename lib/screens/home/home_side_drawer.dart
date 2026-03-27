import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile_model.dart';
import '../../providers/partner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../session/session_manager.dart';
import '../../routes/app_router.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/logout_confirmation_dialog.dart';
import '../address/edit_address_screen.dart';
import '../help_support/help_support_screen.dart';
import '../profile/partner_profile_screen.dart';
import '../reviews/my_reviews_screen.dart';
import '../services/manage_services_screen.dart';
import 'job_history/job_history_screen.dart';

class HomeSideDrawer extends ConsumerStatefulWidget {
  const HomeSideDrawer({super.key});

  @override
  ConsumerState<HomeSideDrawer> createState() => _HomeSideDrawerState();
}

class _HomeSideDrawerState extends ConsumerState<HomeSideDrawer> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    try {
      final repo = ref.read(userRepositoryProvider);
      final profile = await repo.getProfileModel();
      if (mounted && profile != null) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _initials {
    return _profile?.initials ?? 'H';
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const LogoutConfirmationDialog(),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authRepositoryProvider).logout();
      final session = SessionManager();
      await session.clearSession();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
    } catch (_) {
      AppToast.showError('Logout failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // The drawer in the image appears to take up about 75-80% of the width
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _PrimaryTile(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  subtitle: 'View and edit profile',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PartnerProfileScreen(),
                      ),
                    );
                  },
                ),
                _PrimaryTile(
                  icon: Icons.location_on_outlined,
                  title: 'Address',
                  subtitle: 'Update your address',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditAddressScreen(),
                      ),
                    );
                  },
                ),
                _PrimaryTile(
                  icon: Icons.work_outline,
                  title: 'Job History',
                  subtitle: 'See your past jobs',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const JobHistoryScreen(),
                      ),
                    );
                  },
                ),
                _PrimaryTile(
                  icon: Icons.star_outline,
                  title: 'My Reviews',
                  subtitle: 'View your ratings & Reviews',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyReviewsScreen(),
                      ),
                    );
                  },
                ),
                _PrimaryTile(
                  icon: Icons
                      .settings_outlined, // Closer to the "Manage Service" icon
                  title: 'Manage Service',
                  subtitle: 'Add or remove services',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageServicesScreen(),
                      ),
                    );
                  },
                ),
                _PrimaryTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get assistance',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Color(0xFFEAECF0), thickness: 1),
                ),
                _SimpleTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                _SimpleTile(
                  icon: Icons.assignment_outlined,
                  title: 'Terms & Conditions',
                  onTap: () {},
                ),
                _SimpleTile(
                  icon: Icons.handshake_outlined,
                  title: 'Welfare Policy',
                  onTap: () {},
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF0D253F), // Deep Navy Blue
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFF7941D),
            child: Text(
              _loading ? '...' : _initials,
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loading ? '...' : (_profile?.displayName ?? 'Helper'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<String?>(
                  future: SessionManager().getUserPhone(),
                  builder: (_, snap) => Text(
                    snap.data ?? _profile?.phone ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEAECF0))),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF1F0), // Light red tint
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, color: Color(0xFFD92D20), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFFD92D20),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Zynexx Partner v1.0.0',
            style: TextStyle(color: Color(0xFF98A2B3), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PrimaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrimaryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: Icon(icon, color: const Color(0xFF344054), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Color(0xFF1D2939),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF98A2B3),
        size: 20,
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SimpleTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 0),
      leading: Icon(icon, color: const Color(0xFF344054), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF344054),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
