import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/side_popup_provider.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: profileAsync.when(
        data: (p) => SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate700,
                ),
              ),
              const SizedBox(height: 32),
              
              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        p?.initials ?? 'U',
                        style: GoogleFonts.poppins(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold, 
                          color: AppColors.primary
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p?.displayName ?? 'User',
                            style: GoogleFonts.poppins(
                              fontSize: 20, 
                              fontWeight: FontWeight.w600, 
                              color: AppColors.slate700
                            ),
                          ),
                          Text(
                            p?.role ?? 'Software Engineering',
                            style: GoogleFonts.poppins(
                              fontSize: 14, 
                              color: AppColors.slate500
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.editProfile),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFE9D7FE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Stats Row
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Team', value: '0')),
                  const SizedBox(width: 16),
                  Expanded(child: _StatCard(label: 'Points', value: '0')),
                  const SizedBox(width: 16),
                  Expanded(child: _StatCard(label: 'Review', value: '0')),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Menu Sections
              _MenuSection(
                title: 'Account',
                items: [
                  _MenuItem(icon: Icons.lock_outline_rounded, label: 'Password'),
                  _MenuItem(icon: Icons.notifications_none_rounded, label: 'Notification'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _MenuSection(
                title: 'System',
                items: [
                  _MenuItem(icon: Icons.language_rounded, label: 'Language'),
                  _MenuItem(icon: Icons.help_outline_rounded, label: 'Help Center'),
                  _MenuItem(
                    icon: Icons.logout_rounded, 
                    label: 'Log Out', 
                    isDestructive: true,
                    onTap: () async {
                      await ref.read(profileProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/auth');
                      }
                    },
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: AppColors.slate700
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14, 
              color: AppColors.slate500
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16, 
            fontWeight: FontWeight.w600, 
            color: AppColors.slate700
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;
  
  const _MenuItem({
    required this.icon, 
    required this.label, 
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.slate700;
    
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15, 
          fontWeight: FontWeight.w500, 
          color: color
        ),
      ),
      trailing: isDestructive 
        ? null 
        : const Icon(Icons.chevron_right_rounded, color: AppColors.slate500),
    );
  }
}
