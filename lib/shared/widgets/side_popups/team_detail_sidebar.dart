import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../features/dashboard/teams_provider.dart';
import '../../../core/side_popup_provider.dart';

class TeamDetailSidebar extends ConsumerWidget {
  final String teamId;
  const TeamDetailSidebar({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final statusAsync = ref.watch(userTeamStatusProvider(teamId));
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (!isWide) {
      return _buildMobileLayout(context, ref, teamAsync, statusAsync, userId);
    }
    return _buildDesktopLayout(context, ref, teamAsync, statusAsync, userId);
  }

  // ═══════════════════════════════════════════════════════════
  // MOBILE LAYOUT (Scaffold + AppBar + Refresh)
  // ═══════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, AsyncValue<dynamic> teamAsync, AsyncValue<dynamic> statusAsync, String? userId) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Detail Team', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            Navigator.pop(context);
            ref.read(sidePopupProvider.notifier).hide();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(teamDetailProvider(teamId));
              ref.invalidate(userTeamStatusProvider(teamId));
            },
          ),
          teamAsync.when(
            data: (team) {
              if (team == null) return const SizedBox.shrink();
              final isOwner = team.createdBy == userId;
              final isMember = team.members?.any((m) => m.userId == userId && m.status == 'accepted') ?? false;

              if (isOwner) {
                return IconButton(
                  icon: const Icon(Icons.delete_forever_outlined, color: Colors.white),
                  onPressed: () => _confirmDisband(context, ref),
                );
              } else if (isMember) {
                return IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () => _confirmQuit(context, ref),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teamDetailProvider(teamId));
          ref.invalidate(userTeamStatusProvider(teamId));
        },
        child: teamAsync.when(
          data: (team) => _buildContent(context, ref, team, statusAsync, userId),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DESKTOP LAYOUT (Column with internal header for Drawer)
  // ═══════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, AsyncValue<dynamic> teamAsync, AsyncValue<dynamic> statusAsync, String? userId) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Internal Header
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
                Text('Detail Team', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  onPressed: () {
                    ref.invalidate(teamDetailProvider(teamId));
                    ref.invalidate(userTeamStatusProvider(teamId));
                  },
                ),
                teamAsync.when(
                  data: (team) {
                    if (team == null) return const SizedBox.shrink();
                    final isOwner = team.createdBy == userId;
                    final isMember = team.members?.any((m) => m.userId == userId && m.status == 'accepted') ?? false;

                    if (isOwner) {
                      return TextButton.icon(
                        onPressed: () => _confirmDisband(context, ref),
                        icon: const Icon(Icons.delete_forever_outlined, size: 18, color: AppColors.error),
                        label: Text('Disband', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
                      );
                    } else if (isMember) {
                      return TextButton.icon(
                        onPressed: () => _confirmQuit(context, ref),
                        icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                        label: Text('Quit', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: teamAsync.when(
              data: (team) => _buildContent(context, ref, team, statusAsync, userId),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Content Section ───
  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic team, AsyncValue<dynamic> statusAsync, String? userId) {
    if (team == null) return const Center(child: Text('Team not found'));
    final status = statusAsync.valueOrNull;
    final isOwner = team.createdBy == userId;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                if (team.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: team.tags.map<Widget>((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      child: Text('# $t', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    )).toList(),
                  ),
                const SizedBox(height: 32),
                Text('Detail', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.slate700)),
                const SizedBox(height: 16),
                _InfoRow(label: 'Joined team', value: team.memberCountDisplay, valueColor: AppColors.primary),
                const SizedBox(height: 12),
                const _InfoRow(label: 'Competition time', value: '4 Maret 2026 - 10 Maret 2026', valueColor: AppColors.primary),
                const SizedBox(height: 32),
                Text('Deskripsi', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.slate700)),
                const SizedBox(height: 12),
                Text(team.description ?? '', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                const SizedBox(height: 32),
                Text('Requirements', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.slate700)),
                const SizedBox(height: 12),
                ..._buildRequirements(team.requirements),
                if (isOwner) ...[
                  const SizedBox(height: 32),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 32),
                  _buildApplicantsSection(context, ref, team),
                  const SizedBox(height: 32),
                  _buildJoinedSection(team),
                ],
              ],
            ),
          ),
        ),
        if (!isOwner)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: status == 'pending'
                  ? OutlinedButton(
                      onPressed: () => _cancelApplication(context, ref),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel Application'),
                    )
                  : ElevatedButton(
                      onPressed: (status == null || status == 'none') ? () => _apply(context, ref) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        status == 'accepted' ? 'Already in Team' : 'Join Team',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildRequirements(String? requirements) {
    if (requirements == null || requirements.isEmpty) return [];
    final lines = requirements.split('\n');
    return lines.map((line) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Expanded(child: Text(line, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary))),
        ],
      ),
    )).toList();
  }

  Widget _buildApplicantsSection(BuildContext context, WidgetRef ref, dynamic team) {
    final pending = team.members?.where((m) => m.status == 'pending').toList() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Applicants', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (pending.isEmpty)
          Text('Tidak ada pendaftar baru', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMuted))
        else
          ...pending.map((m) => _ApplicantCard(member: m, teamId: teamId)),
      ],
    );
  }

  Widget _buildJoinedSection(dynamic team) {
    final joined = team.members?.where((m) => m.status == 'accepted').toList() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Joined', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ...joined.map((m) => _MemberCard(member: m)),
      ],
    );
  }

  Future<void> _cancelApplication(BuildContext context, WidgetRef ref) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await ref.read(teamsServiceProvider).rejectMember(teamId, userId);
      ref.invalidate(userTeamStatusProvider(teamId));
      ref.invalidate(teamDetailProvider(teamId));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application cancelled.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(teamsServiceProvider).applyToTeam(teamId);
      ref.invalidate(userTeamStatusProvider(teamId));
      ref.invalidate(teamDetailProvider(teamId));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil mendaftar ke tim!')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mendaftar: $e')));
    }
  }

  Future<void> _confirmDisband(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disband Team?'),
        content: const Text('Are you sure you want to disband this team? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Disband'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(teamsServiceProvider).deleteTeam(teamId);
        ref.invalidate(myTeamsProvider);
        if (context.mounted) {
          Navigator.pop(context);
          ref.read(sidePopupProvider.notifier).hide();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team disbanded successfully.')));
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmQuit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Team?'),
        content: const Text('Are you sure you want to quit this team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Quit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(teamsServiceProvider).quitTeam(teamId);
        ref.invalidate(myTeamsProvider);
        ref.invalidate(userTeamStatusProvider(teamId));
        ref.invalidate(teamDetailProvider(teamId));
        if (context.mounted) {
          Navigator.pop(context);
          ref.read(sidePopupProvider.notifier).hide();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have left the team.')));
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _ApplicantCard extends ConsumerWidget {
  final dynamic member;
  final String teamId;
  const _ApplicantCard({required this.member, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            key: ValueKey(member.profile?.avatarUrl),
            radius: 20, 
            backgroundColor: AppColors.inputFill,
            backgroundImage: member.profile?.avatarUrl != null 
                ? NetworkImage(member.profile!.avatarUrl!) 
                : null,
            child: member.profile?.avatarUrl == null 
                ? const Icon(Icons.person, color: AppColors.textMuted, size: 20) 
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.slate700)),
                Text('Recently', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionBtn(
                label: 'Accept',
                onPressed: () async {
                  await ref.read(teamsServiceProvider).acceptMember(teamId, member.userId);
                  ref.invalidate(teamDetailProvider(teamId));
                  ref.invalidate(myTeamsProvider);
                },
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Reject',
                onPressed: () async {
                  await ref.read(teamsServiceProvider).rejectMember(teamId, member.userId);
                  ref.invalidate(teamDetailProvider(teamId));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final dynamic member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundColor: AppColors.inputFill, child: Icon(Icons.person, color: AppColors.textMuted, size: 20)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.displayName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary)),
              Text('Member', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _ActionBtn({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE9D7FE)),
        foregroundColor: const Color(0xFF42307D),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.slate500)),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}
