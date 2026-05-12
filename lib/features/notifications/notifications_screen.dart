import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../shared/models/notification_model.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifs = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Tab bar with purple gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.gradientHeader,
            ),
            child: SafeArea(
              bottom: false,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unread'),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'All'),
                  const Tab(text: 'Applicants'),
                  const Tab(text: 'Applied'),
                ],
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: notifs.when(
              data: (list) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Unread
                    _buildNotifList(list.where((n) => !n.isRead).toList(), ref),
                    // All
                    _buildNotifList(list, ref),
                    // Applicants (team_apply type)
                    _buildNotifList(list.where((n) => n.type == 'team_apply').toList(), ref),
                    // Applied
                    _buildNotifList(list.where((n) => n.type == 'team_accepted' || n.type == 'team_rejected').toList(), ref),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifList(List<dynamic> list, WidgetRef ref) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No notifications', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final n = list[index] as NotificationModel;
        return _NotifItem(n: n, ref: ref);
      },
    );
  }
}

class _NotifItem extends StatelessWidget {
  final NotificationModel n;
  final WidgetRef ref;
  const _NotifItem({required this.n, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isUnread = !n.isRead;

    return GestureDetector(
      onTap: () {
        if (isUnread) ref.read(notificationsProvider.notifier).markAsRead(n.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Icon(_getTypeIcon(n.type), color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      children: [
                        TextSpan(
                          text: n.title,
                          style: TextStyle(fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.message,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(n.createdAt),
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} Minutes Ago';
    if (diff.inHours < 24) return '${diff.inHours} Hours Ago';
    return '${diff.inDays} Days Ago';
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'team_apply':
        return Icons.person_add_rounded;
      case 'team_accepted':
        return Icons.check_circle_rounded;
      case 'team_rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
