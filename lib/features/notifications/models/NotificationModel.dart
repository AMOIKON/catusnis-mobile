// lib/features/notifications/models/notification_model.dart

class NotificationModel {
  final int id;
  final int? userId;
  final String title;
  final String body;
  final String type;
  final int? relatedId;
  final String? relatedCode;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.relatedCode,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as int,
        userId: json['userId'] as int?,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        relatedId: json['relatedId'] as int?,
        relatedCode: json['relatedCode'] as String?,
        isRead: json['read'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        relatedCode: relatedCode,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get typeLabel {
    switch (type) {
      case 'INTERVENTION':
        return 'Intervention';
      case 'DEPLOIEMENT':
        return 'Déploiement';
      case 'VEHICULE':
        return 'Engin';
      case 'EQUIPEMENT':
        return 'Équipement';
      case 'BOOKLET':
        return 'Cahier';
      default:
        return 'Système';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays}j';
  }
}
