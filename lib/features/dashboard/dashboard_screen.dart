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
        onRefresh: () async {
          ref.invalidate(myTeamsProvider);
          ref.invalidate(availableTeamsProvider);
          ref.read(profileProvider.notifier).loadProfile();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Dashboard',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: () => context.push('/create-team'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profile.when(
                      data: (p) => _ProfileHeader(p: p),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Row(
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
                    const SizedBox(height: 32),
                    _SectionHeader(title: 'My Teams', onSeeAll: () => context.go('/teams')),
                    const SizedBox(height: 16),
                    myTeams.when(
                      data: (teams) => teams.isEmpty
                          ? const _EmptyState(msg: "You haven't joined any teams yet.")
                          : _HorizontalTeamList(teams: teams),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 32),
                    _SectionHeader(title: 'Available Teams', onSeeAll: () => context.go('/teams')),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            available.when(
              data: (teams) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _TeamListTile(team: teams[index]),
                  childCount: teams.length,
                ),
              ),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic p;
  const _ProfileHeader({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Text(p?.initials ?? 'U', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${p?.firstName ?? p?.username ?? 'User'}!',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  p?.role ?? 'Member',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
        TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }
}

class _HorizontalTeamList extends StatelessWidget {
  final List<Team> teams;
  const _HorizontalTeamList({required this.teams});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return GestureDetector(
            onTap: () => context.push('/team/${team.id}'),
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(team.description ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(team.memberCountDisplay, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
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

class _TeamListTile extends StatelessWidget {
  final Team team;
  const _TeamListTile({required this.team});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/team/${team.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(team.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(team.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, style: BorderStyle.none),
      ),
      child: Center(child: Text(msg, style: const TextStyle(color: AppColors.textMuted))),
    );
  }
}
