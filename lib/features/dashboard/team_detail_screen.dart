import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared/models/team.dart';
import 'teams_provider.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final statusAsync = ref.watch(userTeamStatusProvider(teamId));
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradientHeader),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            centerTitle: true,
            title: Text('Detail Team', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            actions: [
              teamAsync.when(
                data: (team) => team != null && team.createdBy == userId
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: () => _showDeleteDialog(context, ref, team),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () {
                  ref.invalidate(teamDetailProvider(teamId));
                  ref.invalidate(userTeamStatusProvider(teamId));
                },
              ),
            ],
          ),
        ),
      ),
      body: teamAsync.when(
        data: (team) {
          if (team == null) return const Center(child: Text('Team not found'));
          final isOwner = team.createdBy == userId;
          final status = statusAsync.valueOrNull;
          final accepted = team.members?.where((m) => m.status == 'accepted').toList() ?? [];
          final pending = team.members?.where((m) => m.status == 'pending').toList() ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),

                if (team.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: team.tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tagBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('# $t', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.tagText, fontWeight: FontWeight.w500)),
                    )).toList(),
                  ),

                const SizedBox(height: 24),

                Text('Detail', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _DetailRow(label: 'Joined team', value: team.memberCountDisplay),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Competition time',
                  value: DateFormat('dd MMM yyyy').format(team.createdAt),
                  valueColor: AppColors.primary,
                ),

                const SizedBox(height: 24),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 24),

                Text('Description', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Text(team.description ?? '', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),

                const SizedBox(height: 24),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 24),

                Text('Requirement', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Text(team.requirements ?? '', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),

                const SizedBox(height: 32),

                if (isOwner) ...[
                  Text('Applicants (${pending.length})', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (pending.isEmpty)
                    const Text('No pending applications')
                  else
                    ...pending.map((m) => _ApplicantCard(member: m, teamId: team.id)),
                  
                  const SizedBox(height: 32),
                  Text('Current Members (${accepted.length})', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ...accepted.map((m) => _MemberItem(member: m)),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (status == null || status == 'none') ? () => _apply(context, ref) : null,
                      child: Text(
                        status == 'pending' ? 'Application Pending' : 
                        status == 'accepted' ? 'Already in Team' : 'Apply Now'
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(teamsServiceProvider).applyToTeam(teamId);
      ref.invalidate(userTeamStatusProvider(teamId));
      ref.invalidate(teamDetailProvider(teamId));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application sent!')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Team team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete "${team.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(teamsServiceProvider).deleteTeam(team.id);
              if (context.mounted) {
                ref.invalidate(myTeamsProvider);
                context.pop();
                context.pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _ApplicantCard extends ConsumerWidget {
  final TeamMember member;
  final String teamId;
  const _ApplicantCard({required this.member, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(member.initials, style: const TextStyle(color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName ?? 'Unknown', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                Text('Pending', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warning)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () async {
              await ref.read(teamsServiceProvider).acceptMember(teamId, member.userId);
              ref.invalidate(teamDetailProvider(teamId));
            },
          ),
        ],
      ),
    );
  }
}

class _MemberItem extends StatelessWidget {
  final TeamMember member;
  const _MemberItem({required this.member});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.inputFill,
        child: Text(member.initials, style: const TextStyle(color: AppColors.textPrimary)),
      ),
      title: Text(member.displayName ?? 'Unknown', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text('Member', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
    );
  }
}
