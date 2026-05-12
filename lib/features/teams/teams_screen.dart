import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../shared/models/team.dart';
import '../dashboard/teams_provider.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeams = ref.watch(myTeamsProvider);
    final available = ref.watch(availableTeamsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(myTeamsProvider);
          ref.invalidate(availableTeamsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── My Teams Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text('Teams', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
            ),
            myTeams.when(
              data: (teams) => teams.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _EmptyCard(msg: "You haven't joined any teams yet."),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MyTeamCard(team: teams[index]),
                          ),
                          childCount: teams.length,
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary)))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            ),

            // ── Available Teams Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('List Available Teams', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => context.push('/create-team'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('Create', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            available.when(
              data: (teams) => teams.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _EmptyCard(msg: 'No available teams found.'),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AvailableTeamCard(team: teams[index]),
                          ),
                          childCount: teams.length,
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─── MY TEAM CARD ───
class _MyTeamCard extends StatelessWidget {
  final Team team;
  const _MyTeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/team/${team.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(team.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                Text(team.memberCountDisplay, style: GoogleFonts.inter(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(team.description ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('ongoing', style: GoogleFonts.inter(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AVAILABLE TEAM CARD ───
class _AvailableTeamCard extends StatelessWidget {
  final Team team;
  const _AvailableTeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final daysSince = DateTime.now().difference(team.createdAt).inDays;
    final timeAgo = daysSince == 0 ? 'Hari ini' : 'Diposting $daysSince Hari yang lalu';

    return GestureDetector(
      onTap: () => context.push('/team/${team.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(team.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                Text(team.memberCountDisplay, style: GoogleFonts.inter(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(team.description ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                if (team.tags.isNotEmpty)
                  ...team.tags.take(3).map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('# $t', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  )),
                if (team.tags.length > 3)
                  Text('${team.tags.length - 3}+', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                const Spacer(),
                Text(timeAgo, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── EMPTY CARD ───
class _EmptyCard extends StatelessWidget {
  final String msg;
  const _EmptyCard({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(child: Text(msg, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14))),
    );
  }
}
