class Profile {
  final String id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? role;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.role,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      avatarUrl: json['avatar_url'],
      role: json['role'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get displayName => (firstName != null && lastName != null)
      ? '$firstName $lastName'
      : (username ?? 'User');

  String get initials {
    if (firstName != null && firstName!.isNotEmpty && lastName != null && lastName!.isNotEmpty) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName![0].toUpperCase();
    }
    if (username != null && username!.isNotEmpty) {
      return username![0].toUpperCase();
    }
    return 'U';
  }
}
