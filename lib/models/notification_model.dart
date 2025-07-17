import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  studentBoarded,
  studentLeft,
  tripStarted,
  tripEnded,
  general,
  studentAssigned,
  studentUnassigned,
  absenceRequested,
  absenceApproved,
  absenceRejected,
  complaintSubmitted,
  complaintResponded,
  emergency,
  tripDelayed,
  systemUpdate,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String recipientId;
  final String? studentId;
  final String? studentName;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.recipientId,
    this.studentId,
    this.studentName,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  // Convert NotificationModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'recipientId': recipientId,
      'studentId': studentId,
      'studentName': studentName,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'data': data,
    };
  }

  // Create NotificationModel from Firestore document
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] ?? '',
      body: map['body'] ?? map['message'] ?? '', // Support both 'body' and 'message'
      recipientId: map['recipientId'] ?? map['userId'] ?? '', // Support both 'recipientId' and 'userId'
      studentId: map['studentId'],
      studentName: map['studentName'],
      type: _parseNotificationType(map['type']),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    );
  }

  // Helper method to parse NotificationType from string
  static NotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'studentBoarded':
        return NotificationType.studentBoarded;
      case 'studentLeft':
        return NotificationType.studentLeft;
      case 'tripStarted':
        return NotificationType.tripStarted;
      case 'tripEnded':
        return NotificationType.tripEnded;
      case 'general':
      case 'admin_message': // Support old admin message type
        return NotificationType.general;
      default:
        return NotificationType.general;
    }
  }

  // Create a copy of NotificationModel with updated fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? recipientId,
    String? studentId,
    String? studentName,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      recipientId: recipientId ?? this.recipientId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  // Get formatted timestamp
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Get formatted date
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  /// الحصول على أيقونة الإشعار
  String get icon {
    switch (type) {
      case NotificationType.studentBoarded:
      case NotificationType.studentLeft:
        return '🚌';
      case NotificationType.studentAssigned:
      case NotificationType.studentUnassigned:
        return '👨‍🎓';
      case NotificationType.absenceRequested:
      case NotificationType.absenceApproved:
      case NotificationType.absenceRejected:
        return '📝';
      case NotificationType.complaintSubmitted:
      case NotificationType.complaintResponded:
        return '📢';
      case NotificationType.emergency:
        return '🚨';
      case NotificationType.tripStarted:
      case NotificationType.tripEnded:
      case NotificationType.tripDelayed:
        return '🚌';
      case NotificationType.systemUpdate:
        return '⚙️';
      default:
        return '🔔';
    }
  }

  /// تحديد أولوية الإشعار
  int get priority {
    switch (type) {
      case NotificationType.emergency:
        return 4; // أولوية قصوى
      case NotificationType.studentBoarded:
      case NotificationType.studentLeft:
      case NotificationType.tripStarted:
      case NotificationType.tripEnded:
        return 3; // أولوية عالية
      case NotificationType.absenceRequested:
      case NotificationType.absenceApproved:
      case NotificationType.absenceRejected:
      case NotificationType.tripDelayed:
        return 2; // أولوية متوسطة
      default:
        return 1; // أولوية منخفضة
    }
  }

  /// تحديد ما إذا كان الإشعار يتطلب صوت
  bool get requiresSound {
    switch (type) {
      case NotificationType.emergency:
      case NotificationType.studentBoarded:
      case NotificationType.studentLeft:
      case NotificationType.tripStarted:
      case NotificationType.tripEnded:
        return true;
      default:
        return false;
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
