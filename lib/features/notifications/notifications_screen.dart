import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read logic
            },
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: notifs.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No notifications yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final n = list[index];
                  return ListTile(
                    onTap: () {
                      if (!n.isRead) ref.read(notificationsProvider.notifier).markAsRead(n.id);
                    },
                    leading: CircleAvatar(
                      backgroundColor: _getTypeColor(n.type).withValues(alpha: 0.1),
                      child: Icon(_getTypeIcon(n.type), color: _getTypeColor(n.type)),
                    ),
                    title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.content),
                        const SizedBox(height: 4),
                        Text(
                          '${n.createdAt.hour}:${n.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    trailing: !n.isRead ? const CircleAvatar(radius: 4, backgroundColor: AppColors.primary) : null,
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'team_apply': return Icons.person_add;
      case 'team_accepted': return Icons.check_circle;
      case 'team_rejected': return Icons.cancel;
      default: return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'team_apply': return AppColors.info;
      case 'team_accepted': return AppColors.success;
      case 'team_rejected': return AppColors.error;
      default: return AppColors.primary;
    }
  }
}
