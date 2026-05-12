import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../features/dashboard/teams_provider.dart';

import '../../../shared/models/team.dart';

class ManageApplicantsSidebar extends ConsumerWidget {
  final String teamId;
  const ManageApplicantsSidebar({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kelola Pendaftar',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: teamAsync.when(
              data: (team) {
                if (team == null) return const Center(child: Text('Team not found'));
                final pending = team.members?.where((m) => m.status == 'pending').toList() ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
                      child: Text(
                        'Pendaftar Pending (${pending.length})',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    Expanded(
                      child: pending.isEmpty
                          ? const Center(child: Text('Tidak ada pendaftar baru'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              itemCount: pending.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final member = pending[index];
                                return _ApplicantItem(member: member, teamId: teamId);
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantItem extends ConsumerWidget {
  final TeamMember member;
  final String teamId;
  const _ApplicantItem({required this.member, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(member.initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(member.role, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                onPressed: () async {
                  try {
                    await ref.read(teamsServiceProvider).acceptMember(teamId, member.userId);
                    ref.invalidate(teamDetailProvider(teamId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendaftar diterima!')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                onPressed: () async {
                  try {
                    await ref.read(teamsServiceProvider).rejectMember(teamId, member.userId);
                    ref.invalidate(teamDetailProvider(teamId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendaftar ditolak')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
