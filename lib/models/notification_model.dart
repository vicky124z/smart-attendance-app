class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final bool isRead;
  final bool isImportant;
  final String time;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.isRead,
    required this.isImportant,
    required this.time,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'announcement',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      isRead: json['is_read'] ?? false,
      isImportant: json['is_important'] ?? false,
      time: json['time'] ?? '',
    );
  }
}
