import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _startEditing(profile.valueOrNull))
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: profile.when(
        data: (p) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary,
                child: Text(p?.initials ?? 'U', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 32),
              if (_isEditing) ...[
                _editField('Username', _usernameCtrl),
                const SizedBox(height: 16),
                _editField('First Name', _firstNameCtrl),
                const SizedBox(height: 16),
                _editField('Last Name', _lastNameCtrl),
                const SizedBox(height: 16),
                _editField('Role', _roleCtrl),
              ] else ...[
                _infoTile('Username', p?.username ?? '-'),
                _infoTile('Full Name', '${p?.firstName ?? ''} ${p?.lastName ?? ''}'.trim()),
                _infoTile('Role', p?.role ?? '-'),
                _infoTile('Member Since', '${p?.createdAt.month}/${p?.createdAt.year}'),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(profileProvider.notifier).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
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
    return TextField(
      controller: c,
      decoration: InputDecoration(labelText: l),
    );
  }

  Widget _infoTile(String l, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          Text(v, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
