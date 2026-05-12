import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  void _startEditing(dynamic p) {
    _usernameCtrl.text = p?.username ?? '';
    _firstNameCtrl.text = p?.firstName ?? '';
    _lastNameCtrl.text = p?.lastName ?? '';
    _roleCtrl.text = p?.role ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _save() async {
    await ref.read(profileProvider.notifier).updateProfile(
      username: _usernameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      role: _roleCtrl.text.trim(),
    );
    setState(() => _isEditing = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profile.when(
        data: (p) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover + Avatar ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cover gradient
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppColors.gradientHeader,
                    ),
                  ),
                  // Avatar
                  Positioned(
                    left: 16,
                    bottom: -32,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          p?.initials ?? 'U',
                          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 44),

              // ── Name + Edit Button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p?.displayName ?? 'User',
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p?.username != null ? '${p!.username}' : '',
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (!_isEditing)
                      GestureDetector(
                        onTap: () => _startEditing(p),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                            const SizedBox(width: 4),
                            Text('Edit Profile', style: GoogleFonts.inter(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text('Save', style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Stats Row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatItem(label: 'teams:', value: '—'),
                    const SizedBox(width: 48),
                    _StatItem(label: 'ratings:', value: '5.0'),
                    const SizedBox(width: 48),
                    _StatItem(label: 'role', value: p?.role ?? 'Member'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: AppColors.divider),
              ),

              // ── Edit Mode ──
              if (_isEditing) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _editField('Username', _usernameCtrl),
                      const SizedBox(height: 16),
                      _editField('First Name', _firstNameCtrl),
                      const SizedBox(height: 16),
                      _editField('Last Name', _lastNameCtrl),
                      const SizedBox(height: 16),
                      _editField('Role', _roleCtrl),
                    ],
                  ),
                ),
              ] else ...[
                // ── About Section ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        p?.role != null ? 'Role: ${p!.role}' : 'No bio yet.',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Settings Section ──
                _SettingsSection(
                  title: 'Settings',
                  items: [
                    _SettingsItem(icon: Icons.verified_user_outlined, label: 'Account and Security'),
                    _SettingsItem(icon: Icons.translate_rounded, label: 'Language'),
                    _SettingsItem(icon: Icons.palette_outlined, label: 'Theme'),
                    _SettingsItem(icon: Icons.notifications_none_rounded, label: 'Notification'),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Support Section ──
                _SettingsSection(
                  title: 'Support',
                  items: [
                    _SettingsItem(icon: Icons.help_outline_rounded, label: 'Question'),
                  ],
                ),

                const SizedBox(height: 8),

                // ── System Section ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          await ref.read(profileProvider.notifier).signOut();
                          if (context.mounted) context.go('/auth');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                              const SizedBox(width: 12),
                              Text('Log Out', style: GoogleFonts.inter(fontSize: 15, color: AppColors.error, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading profile: $e', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(profileProvider.notifier).signOut();
                  if (context.mounted) context.go('/auth');
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(String l, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          ...items,
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SettingsItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
        ],
      ),
    );
  }
}
