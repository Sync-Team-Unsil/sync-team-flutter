import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/team.dart';

final myTeamsProvider = FutureProvider<List<Team>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final response = await supabase
      .from('teams')
      .select('*, team_members(*, profiles(*))')
      .or('created_by.eq.${user.id}, team_members.user_id.eq.${user.id}')
      .order('created_at', ascending: false);

  return (response as List).map((t) => Team.fromJson(t)).toList();
});

final availableTeamsProvider = FutureProvider<List<Team>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  var query = supabase.from('teams').select('*, team_members(*, profiles(*))');
  
  if (user != null) {
    // Exclude teams I'm already in or created
    // Note: Simple filtering for demo, in production use a better SQL query or RPC
  }

  final response = await query.order('created_at', ascending: false).limit(20);
  final allTeams = (response as List).map((t) => Team.fromJson(t)).toList();
  
  if (user != null) {
    return allTeams.where((t) {
      final isCreator = t.createdBy == user.id;
      final isMember = t.members?.any((m) => m.userId == user.id) ?? false;
      return !isCreator && !isMember;
    }).toList();
  }
  
  return allTeams;
});

final teamDetailProvider = FutureProvider.family<Team?, String>((ref, id) async {
  final supabase = Supabase.instance.client;
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

class TeamsService {
  static final _supabase = Supabase.instance.client;

  static Future<void> createTeam({
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

  static Future<void> applyToTeam(String teamId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    await _supabase.from('team_members').insert({
      'team_id': teamId,
      'user_id': user.id,
      'status': 'pending',
    });
  }

  static Future<void> acceptMember(String teamId, String userId) async {
    await _supabase
        .from('team_members')
        .update({'status': 'accepted'})
        .eq('team_id', teamId)
        .eq('user_id', userId);
  }

  static Future<void> rejectMember(String teamId, String userId) async {
    await _supabase
        .from('team_members')
        .delete()
        .eq('team_id', teamId)
        .eq('user_id', userId);
  }
}
