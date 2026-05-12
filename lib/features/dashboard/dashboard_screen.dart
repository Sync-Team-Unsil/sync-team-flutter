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
import '../../core/connectivity_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return isWide ? _WebDashboard() : _MobileDashboard();
  }
}

// ─── WIDGET MANDIRI UNTUK STATUS OFFLINE ───
class _OfflinePlaceholder extends StatelessWidget {
  const _OfflinePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'Mode Offline',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
          ),
          Text(
            'Gagal memuat data tim karena tidak ada koneksi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WEB DASHBOARD
// ═══════════════════════════════════════════════════════════
class _WebDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeams = ref.watch(myTeamsProvider);
    final pendingTeams = ref.watch(pendingTeamsProvider);
    final available = ref.watch(availableTeamsProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final isOffline = ref.watch(connectivityStatusProvider) == ConnectivityStatus.isDisconnected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                  Text('Welcome back to SyncTeam', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => ref.read(sidePopupProvider.notifier).show(SidePopupType.createTeam),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Joined Teams
          Text('Joined Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
          const SizedBox(height: 16),
          if (isOffline)
            const _OfflinePlaceholder()
          else
            myTeams.when(
              data: (teams) => teams.isEmpty 
                  ? const _WebEmptyTeamsPlaceholder()
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 180,
                      ),
                      itemCount: teams.length,
                      itemBuilder: (context, index) => _WebJoinedTeamCard(team: teams[index], userId: userId ?? ''),
                    ),
              loading: () => const _LoadingPlaceholder(height: 180),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),

          const SizedBox(height: 32),
          
          // Pending Requests
          pendingTeams.when(
            data: (teams) {
              if (teams.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Requested Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                  const SizedBox(height: 16),
                  if (isOffline)
                    const _OfflinePlaceholder()
                  else
                    for (var team in teams)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WebAvailableTeamCard(team: team),
                      ),
                  const SizedBox(height: 32),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Available Teams
          Text('List Available Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
          const SizedBox(height: 16),
          if (isOffline)
            const _OfflinePlaceholder()
          else
            available.when(
              data: (teams) => teams.isEmpty
                  ? const Center(child: Text('No available teams'))
                  : Column(
                      children: teams.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WebAvailableTeamCard(team: t),
                      )).toList(),
                    ),
              loading: () => const _LoadingPlaceholder(height: 100),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MOBILE DASHBOARD
// ═══════════════════════════════════════════════════════════
class _MobileDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeams = ref.watch(myTeamsProvider);
    final pendingTeams = ref.watch(pendingTeamsProvider);
    final available = ref.watch(availableTeamsProvider);
    final profileAsync = ref.watch(profileProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final isOffline = ref.watch(connectivityStatusProvider) == ConnectivityStatus.isDisconnected;

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
              // ── Profile Header Card ──
              profileAsync.when(
                data: (p) => _MobileProfileHeader(
                  profile: p,
                  teamCount: myTeams.valueOrNull?.length ?? 0,
                ),
                loading: () => Container(
                  height: 180,
                  width: double.infinity,
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
                    Text('Joined Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                    const SizedBox(height: 12),
                    if (isOffline)
                      const _OfflinePlaceholder()
                    else
                      myTeams.when(
                        data: (teams) => teams.isEmpty 
                            ? const _MobileEmptyTeams()
                            : Column(children: teams.take(2).map((team) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _MobileJoinedTeamCard(team: team, userId: userId ?? ''),
                              )).toList()),
                        loading: () => const _LoadingPlaceholder(height: 120),
                        error: (e, _) => Text('Error: $e'),
                      ),

                    const SizedBox(height: 24),

                    // Requested Teams
                    pendingTeams.when(
                      data: (teams) {
                        if (teams.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requested Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                            const SizedBox(height: 12),
                            if (isOffline)
                              const _OfflinePlaceholder()
                            else
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

                    // Available Teams
                    Text('List Available Teams', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                    const SizedBox(height: 12),
                    if (isOffline)
                      const _OfflinePlaceholder()
                    else
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

// ─── HELPER WIDGETS (Sederhana untuk memperbaiki error) ───

class _MobileProfileHeader extends StatelessWidget {
  final dynamic profile;
  final int teamCount;
  const _MobileProfileHeader({required this.profile, required this.teamCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF9E77ED), Color(0xFF7C5AC7)]),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
            child: profile?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile?.fullName ?? 'User', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('$teamCount Teams Joined', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _MobileEmptyTeams extends StatelessWidget {
  const _MobileEmptyTeams();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.group_add_outlined, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text('Belum ada tim', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Ayo buat atau cari tim baru!', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MobileJoinedTeamCard extends StatelessWidget {
  final Team team;
  final String userId;
  const _MobileJoinedTeamCard({required this.team, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.divider)),
      child: ListTile(
        title: Text(team.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text('${team.members?.length ?? 0} members', style: GoogleFonts.poppins(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/teams/${team.id}'),
      ),
    );
  }
}

class _MobileAvailableTeamCard extends StatelessWidget {
  final Team team;
  const _MobileAvailableTeamCard({required this.team});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.divider)),
      child: ListTile(
        title: Text(team.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        onTap: () => context.go('/teams/${team.id}'),
      ),
    );
  }
}

class _WebEmptyTeamsPlaceholder extends StatelessWidget {
  const _WebEmptyTeamsPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No teams found.'));
  }
}

class _WebJoinedTeamCard extends StatelessWidget {
  final Team team;
  final String userId;
  const _WebJoinedTeamCard({required this.team, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(team.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton(onPressed: () => context.go('/teams/${team.id}'), child: const Text('View Details')),
        ],
      ),
    );
  }
}

class _WebAvailableTeamCard extends StatelessWidget {
  final Team team;
  const _WebAvailableTeamCard({required this.team});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(team.name),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/teams/${team.id}'),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final double height;
  const _LoadingPlaceholder({required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(height: height, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)), child: const Center(child: CircularProgressIndicator()));
  }
}
