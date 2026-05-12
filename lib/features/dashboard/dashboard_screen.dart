import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/side_popup_provider.dart';
import '../../shared/models/team.dart';
import '../auth/auth_provider.dart';
import 'teams_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return isWide ? _WebDashboard() : _MobileDashboard();
  }
}

// ═══════════════════════════════════════════════════════════
// WEB DASHBOARD (Existing layout – untouched)
// ═══════════════════════════════════════════════════════════
class _WebDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeams = ref.watch(myTeamsProvider);
    final pendingTeams = ref.watch(pendingTeamsProvider);
    final available = ref.watch(availableTeamsProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(myTeamsProvider);
          ref.invalidate(pendingTeamsProvider);
          ref.invalidate(availableTeamsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Teams Section (Joined/Created) ──
              _SectionTitle(title: 'Joined Teams'),
              const SizedBox(height: 24),
              myTeams.when(
                data: (teams) {
                  if (teams.isEmpty) return _WebEmptyTeamsPlaceholder();
                  final displayTeams = teams.take(2).toList();
                  return Row(
                    children: [
                      for (var team in displayTeams)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _WebJoinedTeamCard(team: team, userId: userId ?? ''),
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

              // ── Requested Teams Section ──
              pendingTeams.when(
                data: (teams) {
                  if (teams.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: 'Requested Teams'),
                      const SizedBox(height: 24),
                      for (var team in teams)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _WebAvailableTeamCard(team: team),
                        ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

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
                          child: _WebAvailableTeamCard(team: t),
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

// ═══════════════════════════════════════════════════════════
// MOBILE DASHBOARD (Figma 1:2039 / 1:2118)
// ═══════════════════════════════════════════════════════════
class _MobileDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeams = ref.watch(myTeamsProvider);
    final pendingTeams = ref.watch(pendingTeamsProvider);
    final available = ref.watch(availableTeamsProvider);
    final profileAsync = ref.watch(profileProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(myTeamsProvider);
          ref.invalidate(pendingTeamsProvider);
          ref.invalidate(availableTeamsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Header Card (Gradient) ──
              profileAsync.when(
                data: (p) => _MobileProfileHeader(
                  profile: p,
                  teamCount: myTeams.valueOrNull?.length ?? 0,
                ),
                loading: () => Container(
                  height: 180,
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9E77ED), Color(0xFFB89AFF)])),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── My Teams Section ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
                        // "see all" removed
                      ],
                    ),
                    const SizedBox(height: 16),
                    myTeams.when(
                      data: (teams) {
                        if (teams.isEmpty) return _MobileEmptyTeams();
                        return Column(
                          children: teams.take(2).map((team) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MobileJoinedTeamCard(team: team, userId: userId ?? ''),
                          )).toList(),
                        );
                      },
                      loading: () => const _LoadingPlaceholder(height: 120),
                      error: (e, _) => Text('Error: $e'),
                    ),

                    const SizedBox(height: 24),

                    // ── Requested Teams Section ──
                    pendingTeams.when(
                      data: (teams) {
                        if (teams.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requested Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
                            const SizedBox(height: 16),
                            for (var team in teams)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _MobileAvailableTeamCard(team: team),
                              ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // ── Available Teams Section ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('List Available Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF344054))),
                        // "see all" removed
                      ],
                    ),
                    const SizedBox(height: 16),
                    available.when(
                      data: (teams) => teams.isEmpty
                          ? Center(child: Text('No available teams', style: GoogleFonts.poppins(color: AppColors.textMuted)))
                          : Column(
                              children: teams.map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _MobileAvailableTeamCard(team: t),
                              )).toList(),
                            ),
                      loading: () => const _LoadingPlaceholder(height: 100),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MOBILE: Profile Header Card (Gradient top) ───
class _MobileProfileHeader extends StatelessWidget {
  final dynamic profile;
  final int teamCount;
  const _MobileProfileHeader({required this.profile, required this.teamCount});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/profile'),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9E77ED), Color(0xFF7C5AC7)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: profile?.avatarUrl != null 
                ? NetworkImage(profile!.avatarUrl!) 
                : null,
            child: profile?.avatarUrl == null
                ? Text(
                    profile?.initials ?? 'U',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  )
                : null,
          ),
            const SizedBox(width: 16),
            // Name & Email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile?.firstName ?? ""} ${profile?.lastName ?? ""}'.trim().isEmpty 
                        ? (profile?.displayName ?? 'User') 
                        : '${profile?.firstName ?? ""} ${profile?.lastName ?? ""}'.trim(),
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile?.username != null ? '@${profile.username}' : '@username',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            // Edit icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                onPressed: () => context.go('/profile'),
              ),
            ),
          ],
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

// ─── MOBILE: Joined Team Card ───
class _MobileJoinedTeamCard extends ConsumerWidget {
  final Team team;
  final String userId;
  const _MobileJoinedTeamCard({required this.team, required this.userId});

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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${team.currentMembers}/${team.maxMembers}', style: GoogleFonts.poppins(fontSize: 14, color: statusColor)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              team.description ?? '',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AvatarStack(count: team.currentMembers),
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
class _MobileAvailableTeamCard extends ConsumerWidget {
  final Team team;
  const _MobileAvailableTeamCard({required this.team});

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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

// ═══════════════════════════════════════════════════════════
// SHARED WEB WIDGETS (kept from original)
// ═══════════════════════════════════════════════════════════
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

class _WebEmptyTeamsPlaceholder extends ConsumerWidget {
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

class _WebJoinedTeamCard extends ConsumerWidget {
  final Team team;
  final String userId;
  const _WebJoinedTeamCard({required this.team, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = team.isOwner(userId);
    final bgColor = isOwner ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7);
    final borderColor = isOwner ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0);
    final statusColor = isOwner ? const Color(0xFFF97316) : const Color(0xFF12B76A);

    return InkWell(
      onTap: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.teamDetail, data: team.id),
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
                Text('${team.currentMembers}/${team.maxMembers}', style: GoogleFonts.poppins(fontSize: 14, color: statusColor)),
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
                _AvatarStack(count: team.currentMembers),
                Text('ongoing', style: GoogleFonts.poppins(fontSize: 14, color: statusColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WebAvailableTeamCard extends ConsumerWidget {
  final Team team;
  const _WebAvailableTeamCard({required this.team});

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
                Text(team.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                Text('${team.currentMembers}/${team.maxMembers}', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary)),
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

// ═══════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════
class _AvatarStack extends StatelessWidget {
  final int count;
  const _AvatarStack({required this.count});

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 4 ? 4 : count;
    if (displayCount == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      width: (displayCount - 1) * 22.0 + 36,
      child: Stack(
        children: List.generate(
          displayCount,
          (index) => Positioned(
            left: index * 22.0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: AppColors.inputFill,
              ),
              child: const Icon(Icons.person, size: 18, color: Colors.grey),
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
