import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/team.dart';
import '../auth/auth_provider.dart';

final myTeamsProvider = FutureProvider<List<Team>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];
  
  final supabase = Supabase.instance.client;

  // Query 1: Teams I created
  final createdResponse = await supabase
      .from('teams')
      .select('*, team_members(*, profiles(*))')
      .eq('created_by', userId);

  // Query 2: Teams I am a member of
  final joinedResponse = await supabase
      .from('team_members')
      .select('teams(*, team_members(*, profiles(*)))')
      .eq('user_id', userId)
      .not('teams.created_by', 'eq', userId);

  final createdTeams = (createdResponse as List).map((t) => Team.fromJson(t)).toList();
  final joinedTeams = (joinedResponse as List)
      .where((m) => m['teams'] != null)
      .map((m) => Team.fromJson(m['teams']))
      .toList();

  return [...createdTeams, ...joinedTeams]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final availableTeamsProvider = FutureProvider<List<Team>>((ref) async {
  final userId = ref.watch(userIdProvider);
  final supabase = Supabase.instance.client;
  
  var query = supabase.from('teams').select('*, team_members(*, profiles(*))');
  
  if (userId != null) {
    // Exclude teams I'm already in or created
  }

  final response = await query.order('created_at', ascending: false).limit(20);
  final allTeams = (response as List).map((t) => Team.fromJson(t)).toList();
  
  if (userId != null) {
    return allTeams.where((t) {
      final isCreator = t.createdBy == userId;
      final isMember = t.members?.any((m) => m.userId == userId) ?? false;
      return !isCreator && !isMember;
    }).toList();
  }
  
  return allTeams;
});

final teamDetailProvider = FutureProvider.family<Team?, String>((ref, id) async {
  final supabase = Supabase.instance.client;
  
  // Realtime subscription to invalidate on changes
  final channel = supabase.channel('team_detail_$id').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'team_members',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'team_id',
      value: id,
    ),
    callback: (payload) {
      ref.invalidateSelf();
    },
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  final response = await supabase
      .from('teams')
      .select('*, team_members(*, profiles(*))')
      .eq('id', id)
      .single();
  
  return Team.fromJson(response);
});

final userTeamStatusProvider = FutureProvider.family<String?, String>((ref, teamId) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  try {
    final response = await supabase
        .from('team_members')
        .select('status')
        .eq('team_id', teamId)
        .eq('user_id', user.id)
        .maybeSingle();
    
    return response?['status'];
  } catch (_) {
    return null;
  }
});

final teamsServiceProvider = Provider((ref) => TeamsService());

class TeamsService {
  final _supabase = Supabase.instance.client;

  Future<void> createTeam({
    required String name,
    required String description,
    required String requirements,
    required int maxMembers,
    required List<String> tags,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    await _supabase.from('teams').insert({
      'name': name,
      'description': description,
      'requirements': requirements,
      'max_members': maxMembers,
      'tags': tags,
      'created_by': user.id,
    });
  }

  Future<void> applyToTeam(String teamId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // 1. Check if user is already in 2 teams (created or accepted)
    final createdResponse = await _supabase
        .from('teams')
        .select('id')
        .eq('created_by', user.id);
    
    final joinedResponse = await _supabase
        .from('team_members')
        .select('team_id')
        .eq('user_id', user.id)
        .eq('status', 'accepted');

    final totalTeams = (createdResponse as List).length + (joinedResponse as List).length;

    if (totalTeams >= 2) {
      throw 'Anda sudah mencapai batas maksimal 2 tim. Silakan keluar dari salah satu tim untuk bergabung dengan tim baru.';
    }

    // 2. Check if already applied
    final existing = await _supabase
        .from('team_members')
        .select()
        .eq('team_id', teamId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      throw 'Anda sudah mengirimkan pendaftaran ke tim ini.';
    }

    await _supabase.from('team_members').insert({
      'team_id': teamId,
      'user_id': user.id,
      'status': 'pending',
    });
  }

  Future<void> acceptMember(String teamId, String userId) async {
    await _supabase
        .from('team_members')
        .update({'status': 'accepted'})
        .eq('team_id', teamId)
        .eq('user_id', userId);
  }

  Future<void> rejectMember(String teamId, String userId) async {
    await _supabase
        .from('team_members')
        .delete()
        .eq('team_id', teamId)
        .eq('user_id', userId);
  }

  Future<void> deleteTeam(String teamId) async {
    await _supabase.from('team_members').delete().eq('team_id', teamId);
    await _supabase.from('teams').delete().eq('id', teamId);
  }
}
