class Notification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  Notification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  factory Notification.fromMap(String id, Map<String, dynamic> map) {
    return Notification(
      id: id,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as DateTime),
    );
  }
} 