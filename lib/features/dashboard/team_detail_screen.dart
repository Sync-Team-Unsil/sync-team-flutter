import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Team Detail'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          teamAsync.when(
            data: (team) => team != null && team.createdBy == userId
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _showDeleteDialog(context, ref, team),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(teamDetailProvider(teamId));
              ref.invalidate(userTeamStatusProvider(teamId));
            },
          ),
        ],
      ),
      body: teamAsync.when(
        data: (team) {
          if (team == null) return const Center(child: Text('Team not found'));
          final isOwner = team.createdBy == userId;
          final status = statusAsync.valueOrNull;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 16),
                if (team.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: team.tags.map((t) => Chip(label: Text('#$t'))).toList(),
                  ),
                const SizedBox(height: 32),
                _InfoSection(title: 'Description', content: team.description ?? 'No description provided.'),
                const SizedBox(height: 24),
                _InfoSection(title: 'Requirements', content: team.requirements ?? 'No specific requirements.'),
                const SizedBox(height: 32),
                Text('Members (${team.memberCountDisplay})', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ...?team.members?.map((m) => _MemberTile(member: m, isOwner: isOwner, onAction: () {
                  ref.invalidate(teamDetailProvider(teamId));
                })),
                const SizedBox(height: 48),
                if (!isOwner && status == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await TeamsService.applyToTeam(teamId);
                          ref.invalidate(userTeamStatusProvider(teamId));
                          ref.invalidate(teamDetailProvider(teamId));
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application sent!')));
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      child: const Text('Apply to Join'),
                    ),
                  )
                else if (status != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Status: ${status.toUpperCase()}',
                        style: TextStyle(
                          color: status == 'accepted' ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to dissolve "${team.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await TeamsService.deleteTeam(team.id);
              if (context.mounted) {
                context.pop(); // Close dialog
                context.pop(); // Go back to dashboard
                ref.invalidate(myTeamsProvider);
              }
            },
            child: const Text('Dissolve', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;
  const _InfoSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(content, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final TeamMember member;
  final bool isOwner;
  final VoidCallback onAction;
  const _MemberTile({required this.member, required this.isOwner, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final p = member.profile;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(p?.initials ?? '?', style: const TextStyle(color: Colors.white)),
      ),
      title: Text(p?.displayName ?? 'Unknown User'),
      subtitle: Text(member.status.toUpperCase()),
      trailing: isOwner && member.status == 'pending'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.success),
                  onPressed: () async {
                    await TeamsService.acceptMember(member.teamId, member.userId);
                    onAction();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error),
                  onPressed: () async {
                    await TeamsService.rejectMember(member.teamId, member.userId);
                    onAction();
                  },
                ),
              ],
            )
          : null,
    );
  }
}
