import 'profile.dart';

class Team {
  final String id;
  final String name;
  final String? description;
  final String? requirements;
  final String createdBy;
  final int maxMembers;
  final List<String> tags;
  final DateTime createdAt;
  final List<TeamMember>? members;

  Team({
    required this.id,
    required this.name,
    this.description,
    this.requirements,
    required this.createdBy,
    required this.maxMembers,
    required this.tags,
    required this.createdAt,
    this.members,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      requirements: json['requirements'],
      createdBy: json['created_by'],
      maxMembers: json['max_members'] ?? 5,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      members: json['team_members'] != null
          ? (json['team_members'] as List)
              .map((m) => TeamMember.fromJson(m))
              .toList()
          : null,
    );
  }

  String get memberCountDisplay {
    final accepted = members?.where((m) => m.status == 'accepted').length ?? 0;
    return '$accepted/$maxMembers';
  }
}

class TeamMember {
  final String id;
  final String teamId;
  final String userId;
  final String status;
  final DateTime joinedAt;
  final Profile? profile;

  TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.status,
    required this.joinedAt,
    this.profile,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'],
      teamId: json['team_id'],
      userId: json['user_id'],
      status: json['status'],
      joinedAt: DateTime.parse(json['joined_at'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      profile: json['profiles'] != null ? Profile.fromJson(json['profiles']) : null,
    );
  }

  String? get displayName => profile?.displayName;
  String get initials => profile?.initials ?? '?';
}
