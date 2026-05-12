class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // team_apply, team_accepted, team_rejected, etc.
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? 'No content',
      type: json['type'] ?? 'info',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      data: json['data'],
    );
  }
}
