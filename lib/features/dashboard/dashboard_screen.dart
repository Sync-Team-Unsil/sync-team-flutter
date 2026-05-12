import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../shared/models/team.dart';
import '../auth/auth_provider.dart';
import 'teams_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final myTeams = ref.watch(myTeamsProvider);
    final available = ref.watch(availableTeamsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(myTeamsProvider);
          ref.invalidate(availableTeamsProvider);
          ref.read(profileProvider.notifier).loadProfile();
        },
        child: CustomScrollView(
          slivers: [
            // ── Profile Header Card ──
            SliverToBoxAdapter(
              child: profile.when(
                data: (p) => _ProfileHeaderCard(p: p),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Divider(color: AppColors.divider, height: 1),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
                        TextButton(
                          onPressed: () async {
                            await ref.read(profileProvider.notifier).signOut();
                            if (context.mounted) context.go('/auth');
                          },
                          child: const Text('Logout', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── My Teams Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _SectionHeader(title: 'Teams', onSeeAll: () => context.go('/teams')),
              ),
            ),
            SliverToBoxAdapter(
              child: myTeams.when(
                data: (teams) => teams.isEmpty
                    ? _EmptyTeamCard()
                    : _MyTeamsHorizontalList(teams: teams),
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Error: $e'),
                ),
              ),
            ),

            // ── Available Teams Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: _SectionHeader(title: 'List Available Teams', onSeeAll: () => context.go('/teams')),
              ),
            ),
            available.when(
              data: (teams) => teams.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No available teams', style: TextStyle(color: AppColors.textMuted))),
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
              error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─── PROFILE HEADER CARD (Purple gradient) ───
class _ProfileHeaderCard extends StatelessWidget {
  final dynamic p;
  const _ProfileHeaderCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: AppColors.gradientCard,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(
                    p?.initials ?? 'U',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p?.displayName ?? 'User',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p?.username != null ? '${p!.username}' : '',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                // Edit icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    onPressed: () => GoRouter.of(context).go('/profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              children: [
                _StatItem(label: 'teams:', value: '—'),
                const SizedBox(width: 48),
                _StatItem(label: 'ratings:', value: '5.0'),
                const SizedBox(width: 48),
                _StatItem(label: 'role', value: p?.role ?? 'Member'),
              ],
            ),
          ],
        ),
      ),
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
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}

// ─── SECTION HEADER ───
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        GestureDetector(
          onTap: onSeeAll,
          child: Text('see all', style: GoogleFonts.inter(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ─── MY TEAMS HORIZONTAL LIST ───
class _MyTeamsHorizontalList extends StatelessWidget {
  final List<Team> teams;
  const _MyTeamsHorizontalList({required this.teams});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return GestureDetector(
            onTap: () => context.push('/team/${team.id}'),
            child: Container(
              width: 300,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.divider),
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
                        child: Text(team.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text(team.memberCountDisplay, style: GoogleFonts.inter(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(team.description ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Member avatars placeholder
                      const SizedBox(),
                      Text('ongoing', style: GoogleFonts.inter(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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

// ─── EMPTY STATE ───
class _EmptyTeamCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text("You haven't joined any teams yet.", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
      ),
    );
  }
}
