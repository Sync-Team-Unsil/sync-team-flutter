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
    final profileAsync = ref.watch(profileProvider);
    final myTeamsAsync = ref.watch(myTeamsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: profileAsync.when(
        data: (p) => SingleChildScrollView(
          child: Column(
            children: [
              // Banner & Profile Card Stack
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Blue Gradient Banner
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
                  
                  // Profile Card Overlay
                  Padding(
                    padding: const EdgeInsets.fromLTRB(64, 116, 64, 0),
                    child: Column(
                      children: [
                        _buildProfileMainCard(context, ref, p, myTeamsAsync),
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

  Widget _buildProfileMainCard(BuildContext context, WidgetRef ref, dynamic p, AsyncValue<List<Team>> myTeamsAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    p?.initials ?? 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 40, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.primary
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p?.displayName ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 24, 
                        fontWeight: FontWeight.w500, 
                        color: AppColors.slate700
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p?.username != null ? '${p.username}@gmail.com' : 'user@gmail.com',
                      style: GoogleFonts.poppins(
                        fontSize: 14, 
                        color: AppColors.slate500
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p?.username != null ? '@${p.username}' : '@user',
                      style: GoogleFonts.poppins(
                        fontSize: 14, 
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
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
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: 12, 
            fontWeight: FontWeight.w500, 
            color: AppColors.slate500
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16, 
            fontWeight: FontWeight.w500, 
            color: AppColors.slate700
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard(dynamic p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(33),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.w600, 
              color: AppColors.slate700
            ),
          ),
          const SizedBox(height: 16),
          Text(
            p?.bio ?? 'No bio yet.',
            style: GoogleFonts.poppins(
              fontSize: 14, 
              color: AppColors.slate500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(33),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.w600, 
              color: AppColors.slate700
            ),
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support',
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.w600, 
              color: AppColors.slate700
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuRow(Icons.help_outline_rounded, 'Question'),
        ],
      ),
    );
  }

  Widget _buildSystemCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(33),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System',
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.w600, 
              color: AppColors.slate700
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuRow(
            Icons.logout_rounded, 
            'Log Out', 
            showArrow: false,
            onTap: () async {
              await ref.read(profileProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/auth');
              }
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
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12, 
                color: const Color(0xFF6C6F85)
              ),
            ),
            const Spacer(),
            if (showArrow)
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF6C6F85)),
          ],
        ),
      ),
    );
  }
}
