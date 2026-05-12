import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/notification_model.dart';

import '../auth/auth_provider.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final userId = ref.watch(userIdProvider);
  return NotificationsNotifier(userId);
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final String? userId;
  NotificationsNotifier(this.userId) : super(const AsyncValue.loading()) {
    load();
    _subscribe();
  }

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  Future<void> load() async {
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId!)
          .order('created_at', ascending: false);
      
      state = AsyncValue.data((response as List).map((n) => NotificationModel.fromJson(n)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribe() {
    if (userId == null) return;

    _channel = _supabase
        .channel('public:notifications:user_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId!,
          ),
          callback: (payload) {
            // Handle Postgres change
            if (payload.eventType == PostgresChangeEvent.insert) {
              final newNotif = NotificationModel.fromJson(payload.newRecord);
              state.whenData((currentList) {
                if (!currentList.any((n) => n.id == newNotif.id)) {
                  state = AsyncValue.data([newNotif, ...currentList]);
                }
              });
            } else {
              load();
            }
          },
        )
        .subscribe((status, error) {
          if (error != null) {
            // Log error jika ada masalah koneksi
          }
        });
  }

  Future<void> markAsRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
    load();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifs.where((n) => !n.isRead).length;
});
