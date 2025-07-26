import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// أنواع الإشعارات المختلفة في النظام
enum NotificationType {
  // إشعارات الأدمن
  newComplaint,           // شكوى جديدة
  newStudent,            // طالب جديد
  studentAbsence,        // غياب طالب
  supervisorEvaluation,  // تقييم مشرف
  profileCompleted,      // إكمال البروفايل
  newParentAccount,      // حساب ولي أمر جديد
  studentBehaviorReport, // تقرير سلوك طالب
  
  // إشعارات أولياء الأمور
  studentAssignedToBus,  // تعيين طالب في باص
  supervisorAssigned,    // تعيين مشرف
  studentBoarded,        // ركب الطالب الباص
  studentAtSchool,       // وصل للمدرسة
  studentLeftSchool,     // غادر المدرسة
  studentAtHome,         // وصل للمنزل
  studentRemoved,        // حذف الطالب
  busRouteChanged,       // تغيير خط السير
  studentDataUpdate,     // تحديث بيانات الطالب
  studentStatusUpdate,   // تحديث حالة الطالب
  
  // إشعارات المشرفين
  assignedToBus,         // تعيين في باص
  studentDataUpdated,    // تحديث بيانات طالب
  newAbsenceReport,      // تقرير غياب جديد
  
  // إشعارات عامة
  systemMaintenance,     // صيانة النظام
  generalAnnouncement,   // إعلان عام
}

/// أولوية الإشعار
enum NotificationPriority {
  low,      // منخفضة
  medium,   // متوسطة
  high,     // عالية
  urgent,   // عاجلة
}

/// حالة الإشعار
enum NotificationStatus {
  pending,    // في الانتظار
  sent,       // تم الإرسال
  delivered,  // تم التسليم
  read,       // تم القراءة
  failed,     // فشل الإرسال
}

/// قنوات توصيل الإشعار
enum NotificationChannel {
  fcm,        // Firebase Cloud Messaging
  inApp,      // داخل التطبيق
  email,      // البريد الإلكتروني
  sms,        // رسائل نصية
}

/// نموذج الإشعار الأساسي
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final String recipientId;
  final String recipientType; // admin, parent, supervisor
  final String? senderId;
  final String? senderName;
  final Map<String, dynamic> data; // بيانات إضافية
  final List<NotificationChannel> channels;
  final bool requiresSound;
  final bool requiresVibration;
  final bool isBackground;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? readAt;
  final int retryCount;
  final String? errorMessage;
  final bool isActive;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.status = NotificationStatus.pending,
    required this.recipientId,
    required this.recipientType,
    this.senderId,
    this.senderName,
    this.data = const {},
    this.channels = const [NotificationChannel.fcm, NotificationChannel.inApp],
    this.requiresSound = false,
    this.requiresVibration = false,
    this.isBackground = true,
    required this.createdAt,
    this.scheduledAt,
    this.sentAt,
    this.readAt,
    this.retryCount = 0,
    this.errorMessage,
    this.isActive = true,
  });

  /// تحويل إلى Map لحفظ في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'recipientId': recipientId,
      'recipientType': recipientType,
      'senderId': senderId,
      'senderName': senderName,
      'data': data,
      'channels': channels.map((c) => c.toString().split('.').last).toList(),
      'requiresSound': requiresSound,
      'requiresVibration': requiresVibration,
      'isBackground': isBackground,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'retryCount': retryCount,
      'errorMessage': errorMessage,
      'isActive': isActive,
    };
  }

  /// إنشاء من Map من Firestore
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: parseNotificationType(map['type']),
      priority: parseNotificationPriority(map['priority']),
      status: parseNotificationStatus(map['status']),
      recipientId: map['recipientId'] ?? '',
      recipientType: map['recipientType'] ?? '',
      senderId: map['senderId'],
      senderName: map['senderName'],
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      channels: parseChannels(map['channels']),
      requiresSound: map['requiresSound'] ?? false,
      requiresVibration: map['requiresVibration'] ?? false,
      isBackground: map['isBackground'] ?? true,
      createdAt: parseTimestamp(map['createdAt']),
      scheduledAt: map['scheduledAt'] != null ? parseTimestamp(map['scheduledAt']) : null,
      sentAt: map['sentAt'] != null ? parseTimestamp(map['sentAt']) : null,
      readAt: map['readAt'] != null ? parseTimestamp(map['readAt']) : null,
      retryCount: map['retryCount'] ?? 0,
      errorMessage: map['errorMessage'],
      isActive: map['isActive'] ?? true,
    );
  }

  /// نسخ مع تعديل بعض الخصائص
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    NotificationStatus? status,
    String? recipientId,
    String? recipientType,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? data,
    List<NotificationChannel>? channels,
    bool? requiresSound,
    bool? requiresVibration,
    bool? isBackground,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? sentAt,
    DateTime? readAt,
    int? retryCount,
    String? errorMessage,
    bool? isActive,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      recipientId: recipientId ?? this.recipientId,
      recipientType: recipientType ?? this.recipientType,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      data: data ?? this.data,
      channels: channels ?? this.channels,
      requiresSound: requiresSound ?? this.requiresSound,
      requiresVibration: requiresVibration ?? this.requiresVibration,
      isBackground: isBackground ?? this.isBackground,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods - جعل الدوال عامة للاستخدام من الملفات الأخرى
  static NotificationType parseNotificationType(String? type) {
    switch (type) {
      case 'newComplaint': return NotificationType.newComplaint;
      case 'newStudent': return NotificationType.newStudent;
      case 'studentAbsence': return NotificationType.studentAbsence;
      case 'supervisorEvaluation': return NotificationType.supervisorEvaluation;
      case 'profileCompleted': return NotificationType.profileCompleted;
      case 'newParentAccount': return NotificationType.newParentAccount;
      case 'studentBehaviorReport': return NotificationType.studentBehaviorReport;
      case 'studentAssignedToBus': return NotificationType.studentAssignedToBus;
      case 'supervisorAssigned': return NotificationType.supervisorAssigned;
      case 'studentBoarded': return NotificationType.studentBoarded;
      case 'studentAtSchool': return NotificationType.studentAtSchool;
      case 'studentLeftSchool': return NotificationType.studentLeftSchool;
      case 'studentAtHome': return NotificationType.studentAtHome;
      case 'studentRemoved': return NotificationType.studentRemoved;
      case 'busRouteChanged': return NotificationType.busRouteChanged;
      case 'assignedToBus': return NotificationType.assignedToBus;
      case 'studentDataUpdated': return NotificationType.studentDataUpdated;
      case 'newAbsenceReport': return NotificationType.newAbsenceReport;
      case 'systemMaintenance': return NotificationType.systemMaintenance;
      case 'generalAnnouncement': return NotificationType.generalAnnouncement;
      case 'studentDataUpdate': return NotificationType.studentDataUpdate;
      case 'studentStatusUpdate': return NotificationType.studentStatusUpdate;
      default: return NotificationType.generalAnnouncement;
    }
  }

  static NotificationPriority parseNotificationPriority(String? priority) {
    switch (priority) {
      case 'low': return NotificationPriority.low;
      case 'medium': return NotificationPriority.medium;
      case 'high': return NotificationPriority.high;
      case 'urgent': return NotificationPriority.urgent;
      default: return NotificationPriority.medium;
    }
  }

  static NotificationStatus parseNotificationStatus(String? status) {
    switch (status) {
      case 'pending': return NotificationStatus.pending;
      case 'sent': return NotificationStatus.sent;
      case 'delivered': return NotificationStatus.delivered;
      case 'read': return NotificationStatus.read;
      case 'failed': return NotificationStatus.failed;
      default: return NotificationStatus.pending;
    }
  }

  static List<NotificationChannel> parseChannels(dynamic channels) {
    if (channels == null) return [NotificationChannel.fcm, NotificationChannel.inApp];

    final List<String> channelStrings = List<String>.from(channels);
    return channelStrings.map((c) {
      switch (c) {
        case 'fcm': return NotificationChannel.fcm;
        case 'inApp': return NotificationChannel.inApp;
        case 'email': return NotificationChannel.email;
        case 'sms': return NotificationChannel.sms;
        default: return NotificationChannel.inApp;
      }
    }).toList();
  }

  static DateTime parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is DateTime) {
      return timestamp;
    }

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  // UI Helper methods
  String get typeDisplayName {
    switch (type) {
      case NotificationType.newComplaint: return 'شكوى جديدة';
      case NotificationType.newStudent: return 'طالب جديد';
      case NotificationType.studentAbsence: return 'غياب طالب';
      case NotificationType.supervisorEvaluation: return 'تقييم مشرف';
      case NotificationType.profileCompleted: return 'إكمال البروفايل';
      case NotificationType.newParentAccount: return 'حساب ولي أمر جديد';
      case NotificationType.studentBehaviorReport: return 'تقرير سلوك طالب';
      case NotificationType.studentAssignedToBus: return 'تعيين طالب في باص';
      case NotificationType.supervisorAssigned: return 'تعيين مشرف';
      case NotificationType.studentBoarded: return 'ركب الطالب الباص';
      case NotificationType.studentAtSchool: return 'وصل للمدرسة';
      case NotificationType.studentLeftSchool: return 'غادر المدرسة';
      case NotificationType.studentAtHome: return 'وصل للمنزل';
      case NotificationType.studentRemoved: return 'حذف الطالب';
      case NotificationType.busRouteChanged: return 'تغيير خط السير';
      case NotificationType.assignedToBus: return 'تعيين في باص';
      case NotificationType.studentDataUpdated: return 'تحديث بيانات طالب';
      case NotificationType.newAbsenceReport: return 'تقرير غياب جديد';
      case NotificationType.systemMaintenance: return 'صيانة النظام';
      case NotificationType.generalAnnouncement: return 'إعلان عام';
      case NotificationType.studentDataUpdate: return 'تحديث بيانات الطالب';
      case NotificationType.studentStatusUpdate: return 'تحديث حالة الطالب';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case NotificationPriority.low: return 'منخفضة';
      case NotificationPriority.medium: return 'متوسطة';
      case NotificationPriority.high: return 'عالية';
      case NotificationPriority.urgent: return 'عاجلة';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case NotificationStatus.pending: return 'في الانتظار';
      case NotificationStatus.sent: return 'تم الإرسال';
      case NotificationStatus.delivered: return 'تم التسليم';
      case NotificationStatus.read: return 'تم القراءة';
      case NotificationStatus.failed: return 'فشل الإرسال';
    }
  }

  bool get isUnread => status != NotificationStatus.read;
  bool get isHighPriority => priority == NotificationPriority.high || priority == NotificationPriority.urgent;
  bool get shouldPlaySound => requiresSound && isHighPriority;
  bool get shouldVibrate => requiresVibration && isHighPriority;
}
