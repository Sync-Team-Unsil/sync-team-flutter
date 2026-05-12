import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/side_popup_provider.dart';
import '../auth/auth_provider.dart';
import '../dashboard/teams_provider.dart';
import '../../shared/models/team.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return isWide ? _WebProfileScreen() : _MobileProfileScreen();
  }
}

// ═══════════════════════════════════════════════════════════
// WEB PROFILE (existing layout – untouched)
// ═══════════════════════════════════════════════════════════
class _WebProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final myTeamsAsync = ref.watch(myTeamsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: profileAsync.when(
        data: (p) => SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 231,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                        colors: [Color(0xFF2059B5), Color(0xFF8BA9F5)],
                        stops: [0.125, 0.993],
                        transform: GradientRotation(-68.56 * 3.14159 / 180),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(64, 116, 64, 0),
                    child: Column(
                      children: [
                        _buildWebProfileMainCard(context, ref, p, myTeamsAsync),
                        const SizedBox(height: 24),
                        _buildAboutCard(p),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSettingsCard(context, ref)),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 333,
                              child: Column(
                                children: [
                                  _buildSupportCard(),
                                  const SizedBox(height: 24),
                                  _buildSystemCard(context, ref),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildWebProfileMainCard(BuildContext context, WidgetRef ref, dynamic p, AsyncValue<List<Team>> myTeamsAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    p?.initials ?? 'U',
                    style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p?.displayName ?? 'User', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.slate700)),
                    const SizedBox(height: 4),
                    Text(
                      p?.username != null ? '${p.username}@gmail.com' : 'user@gmail.com',
                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.slate500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p?.username != null ? '@${p.username}' : '@user',
                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.editProfile),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4EBFF),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatItem('teams', '${myTeamsAsync.valueOrNull?.length ?? 0}/2'),
              const SizedBox(width: 48),
              _buildStatItem('ratings', '5.0'),
              const SizedBox(width: 48),
              _buildStatItem('role', p?.role ?? 'Back-end Developer'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate500)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.slate700)),
      ],
    );
  }

  Widget _buildAboutCard(dynamic p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(33),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.slate700)),
          const SizedBox(height: 16),
          Text(p?.bio ?? 'No bio yet.', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.slate500, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(33),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.slate700)),
          const SizedBox(height: 16),
          _buildMenuRow(Icons.shield_outlined, 'Account and Security'),
          _buildMenuRow(Icons.language_outlined, 'Language'),
          _buildMenuRow(Icons.palette_outlined, 'Theme'),
          _buildMenuRow(Icons.notifications_none_outlined, 'Notification'),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(33),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Support', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.slate700)),
          const SizedBox(height: 16),
          _buildMenuRow(Icons.help_outline_rounded, 'Question'),
        ],
      ),
    );
  }

  Widget _buildSystemCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(33),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.slate700)),
          const SizedBox(height: 16),
          _buildMenuRow(
            Icons.logout_rounded,
            'Log Out',
            showArrow: false,
            onTap: () async {
              await ref.read(profileProvider.notifier).signOut();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String label, {bool showArrow = true, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF6C6F85)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6C6F85))),
            const Spacer(),
            if (showArrow) const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF6C6F85)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MOBILE PROFILE (Figma 1:2650)
// ═══════════════════════════════════════════════════════════
class _MobileProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final myTeamsAsync = ref.watch(myTeamsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: profileAsync.when(
        data: (p) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient Banner + Avatar ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                        colors: [Color(0xFF2059B5), Color(0xFF8BA9F5)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: -40,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          p?.initials ?? 'U',
                          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // ── Name, Email, Edit Button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p?.displayName ?? 'User',
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.slate700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p?.username != null ? '${p?.username}@gmail.com' : 'user@gmail.com',
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.slate500),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.editProfile),
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Edit Profile',
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Stats Row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _mobileStatItem('teams:', '${myTeamsAsync.valueOrNull?.length ?? 0}/2'),
                    const SizedBox(width: 32),
                    _mobileStatItem('ratings:', '5.0'),
                    const SizedBox(width: 32),
                    Expanded(child: _mobileStatItem('role', p?.role ?? 'Back-end Developer')),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── About Section ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.slate700)),
                    const SizedBox(height: 8),
                    Text(
                      p?.bio ?? 'No bio yet.',
                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.slate500, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Settings ──
              _mobileMenuSection('Settings', [
                _mobileMenuItem(Icons.shield_outlined, 'Account and Security'),
                _mobileMenuItem(Icons.language_outlined, 'Language'),
                _mobileMenuItem(Icons.palette_outlined, 'Theme'),
                _mobileMenuItem(Icons.notifications_none_outlined, 'Notification'),
              ]),

              // ── Support ──
              _mobileMenuSection('Support', [
                _mobileMenuItem(Icons.help_outline_rounded, 'Question'),
              ]),

              // ── System ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.slate700)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        await ref.read(profileProvider.notifier).signOut();
                        if (context.mounted) context.go('/auth');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.logout_rounded, size: 22, color: Color(0xFF6C6F85)),
                            const SizedBox(width: 12),
                            Text('Log Out', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6C6F85))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _mobileStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate500)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ],
    );
  }

  Widget _mobileMenuSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.slate700)),
          const SizedBox(height: 8),
          ...items,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _mobileMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF6C6F85)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6C6F85)))),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF6C6F85)),
          ],
        ),
      ),
    );
  }
}
