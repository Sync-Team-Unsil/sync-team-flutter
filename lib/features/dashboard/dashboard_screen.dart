import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/side_popup_provider.dart';
import '../../shared/models/team.dart';
import 'teams_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeams = ref.watch(myTeamsProvider);
    final available = ref.watch(availableTeamsProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(myTeamsProvider);
          ref.invalidate(availableTeamsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Teams Section (Joined/Created) ──
              _SectionTitle(title: 'Teams'),
              const SizedBox(height: 24),
              myTeams.when(
                data: (teams) {
                  if (teams.isEmpty) return _EmptyTeamsPlaceholder();
                  // Max 2 teams as per requirement
                  final displayTeams = teams.take(2).toList();
                  return Row(
                    children: [
                      for (var team in displayTeams)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _JoinedTeamCard(team: team, userId: userId ?? ''),
                          ),
                        ),
                      if (displayTeams.length < 2) const Spacer(),
                    ],
                  );
                },
                loading: () => const _LoadingPlaceholder(height: 200),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 48),

              // ── List Available Teams Section ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionTitle(title: 'List Available Teams'),
                  TextButton.icon(
                    onPressed: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.createTeam),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text('Create Team', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              available.when(
                data: (teams) => teams.isEmpty
                    ? const Center(child: Text('No available teams'))
                    : Column(
                        children: teams.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _AvailableTeamCard(team: t),
                        )).toList(),
                      ),
                loading: () => const _LoadingPlaceholder(height: 100),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, color: const Color(0xFF344054)),
    );
  }
}

class _EmptyTeamsPlaceholder extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9D7FE)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_outlined, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada tim yang diikuti',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1D2939)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Cari tim yang tersedia di bawah atau buat tim barumu sendiri untuk mulai berkolaborasi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF667085)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.createTeam),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Buat Tim Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinedTeamCard extends ConsumerWidget {
  final Team team;
  final String userId;
  const _JoinedTeamCard({required this.team, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = team.isOwner(userId);
    final bgColor = isOwner ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7);
    final borderColor = isOwner ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0);
    final statusColor = isOwner ? const Color(0xFFF97316) : const Color(0xFF12B76A);

    return InkWell(
      onTap: () => ref.read(sidePopupProvider.notifier).show(
        SidePopupType.teamDetail,
        data: team.id,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 240,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isOwner ? 'Tim ${team.name}' : team.name,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${team.currentMembers}/${team.maxMembers}',
                  style: GoogleFonts.poppins(fontSize: 14, color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Text(
                team.description ?? '',
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B)),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar Stack
                _AvatarStack(count: team.currentMembers),
                Text(
                  'ongoing',
                  style: GoogleFonts.poppins(fontSize: 14, color: statusColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableTeamCard extends ConsumerWidget {
  final Team team;
  const _AvailableTeamCard({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.teamDetail, data: team.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F5FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9D7FE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  team.name,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                ),
                Text(
                  '${team.currentMembers}/${team.maxMembers}',
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              team.description ?? '',
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (team.tags.isNotEmpty)
                  ...team.tags.take(2).map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('# $tag', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary)),
                  )),
                if (team.tags.length > 2)
                  Text('${team.tags.length - 2}+', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary)),
                const Spacer(),
                Text(
                  'Diposting ${DateTime.now().difference(team.createdAt).inDays} Hari yang lalu',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final int count;
  const _AvatarStack({required this.count});

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 4 ? 4 : count;
    if (displayCount == 0) return const SizedBox.shrink();
    
    return SizedBox(
      height: 48,
      width: (displayCount - 1) * 30.0 + 48,
      child: Stack(
        children: List.generate(
          displayCount,
          (index) => Positioned(
            left: index * 30.0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: AppColors.inputFill,
              ),
              child: const Icon(Icons.person, size: 24, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final double height;
  const _LoadingPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
