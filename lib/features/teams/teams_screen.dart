import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/side_popup_provider.dart';
import '../../shared/models/team.dart';
import '../dashboard/teams_provider.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return isWide ? _WebTeamsScreen() : _MobileTeamsScreen();
  }
}

// ═══════════════════════════════════════════════════════════
// WEB TEAMS SCREEN (original, kept intact)
// ═══════════════════════════════════════════════════════════
class _WebTeamsScreen extends ConsumerWidget {
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
                            child: _WebMyTeamCard(team: teams[index]),
                          ),
                          childCount: teams.length,
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary)))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            ),
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
                            child: _WebAvailableTeamCard(team: teams[index]),
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

// ═══════════════════════════════════════════════════════════
// MOBILE TEAMS SCREEN (Figma 1:2359 / 1:2418)
// ═══════════════════════════════════════════════════════════
class _MobileTeamsScreen extends ConsumerWidget {
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── My Teams Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
                      Text('see all', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  myTeams.when(
                    data: (teams) {
                      if (teams.isEmpty) {
                        return _MobileEmptyTeams();
                      }
                      return Column(
                        children: teams.take(2).map((team) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MobileMyTeamCard(team: team, userId: userId ?? ''),
                        )).toList(),
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary))),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),

                  const SizedBox(height: 24),

                  // ── Available Teams Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('List Available Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
                      GestureDetector(
                        onTap: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.createTeam),
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
                              Text('Add', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  available.when(
                    data: (teams) => teams.isEmpty
                        ? Center(child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text('No available teams found.', style: GoogleFonts.poppins(color: AppColors.textMuted)),
                          ))
                        : Column(
                            children: teams.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _MobileAvailableCard(team: t),
                            )).toList(),
                          ),
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── MOBILE: Empty Teams ───
class _MobileEmptyTeams extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9D7FE)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            "You aren't currently a member of any team",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF667085)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.createTeam),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text('Create or Join Team', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MOBILE: My Team Card ───
class _MobileMyTeamCard extends ConsumerWidget {
  final Team team;
  final String userId;
  const _MobileMyTeamCard({required this.team, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = team.isOwner(userId);
    final bgColor = isOwner ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7);
    final borderColor = isOwner ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0);
    final statusColor = isOwner ? const Color(0xFFF97316) : const Color(0xFF12B76A);

    return GestureDetector(
      onTap: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.teamDetail, data: team.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
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
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${team.currentMembers}/${team.maxMembers}', style: GoogleFonts.poppins(fontSize: 14, color: statusColor)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              team.description ?? '',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MobileAvatarStack(count: team.currentMembers),
                Text('ongoing', style: GoogleFonts.poppins(fontSize: 13, color: statusColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MOBILE: Available Team Card ───
class _MobileAvailableCard extends ConsumerWidget {
  final Team team;
  const _MobileAvailableCard({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysSince = DateTime.now().difference(team.createdAt).inDays;
    final timeAgo = daysSince == 0 ? 'Hari ini' : 'Diposting $daysSince Hari yang lalu';

    return GestureDetector(
      onTap: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.teamDetail, data: team.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F5FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9D7FE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(team.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                ),
                Text('${team.currentMembers}/${team.maxMembers}', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              team.description ?? '',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (team.tags.isNotEmpty)
                  ...team.tags.take(2).map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('# $tag', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary)),
                  )),
                if (team.tags.length > 2)
                  Text('${team.tags.length - 2}+', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary)),
                const Spacer(),
                Text(timeAgo, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileAvatarStack extends StatelessWidget {
  final int count;
  const _MobileAvatarStack({required this.count});

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 4 ? 4 : count;
    if (displayCount == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      width: (displayCount - 1) * 20.0 + 32,
      child: Stack(
        children: List.generate(
          displayCount,
          (index) => Positioned(
            left: index * 20.0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: AppColors.inputFill,
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WEB-ONLY CARDS
// ═══════════════════════════════════════════════════════════
class _WebMyTeamCard extends StatelessWidget {
  final Team team;
  const _WebMyTeamCard({required this.team});

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
                Expanded(child: Text(team.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
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

class _WebAvailableTeamCard extends StatelessWidget {
  final Team team;
  const _WebAvailableTeamCard({required this.team});

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
