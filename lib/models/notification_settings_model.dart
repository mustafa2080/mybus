import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_model.dart';

/// نموذج إعدادات الإشعارات للمستخدم
class NotificationSettingsModel {
  final String id;
  final String userId;
  final String userType; // admin, parent, supervisor
  final bool isEnabled; // تفعيل/إلغاء تفعيل الإشعارات
  final bool soundEnabled; // تفعيل الصوت
  final bool vibrationEnabled; // تفعيل الاهتزاز
  final bool backgroundEnabled; // إشعارات الخلفية
  final bool emailEnabled; // إشعارات البريد الإلكتروني
  final Map<NotificationType, bool> typeSettings; // إعدادات لكل نوع إشعار
  final Map<NotificationPriority, bool> prioritySettings; // إعدادات لكل أولوية
  final List<String> mutedChannels; // القنوات المكتومة
  final DateTime? quietHoursStart; // بداية ساعات الصمت
  final DateTime? quietHoursEnd; // نهاية ساعات الصمت
  final bool weekendQuietMode; // وضع الصمت في عطلة نهاية الأسبوع
  final String fcmToken; // رمز FCM للجهاز
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationSettingsModel({
    required this.id,
    required this.userId,
    required this.userType,
    this.isEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.backgroundEnabled = true,
    this.emailEnabled = false,
    this.typeSettings = const {},
    this.prioritySettings = const {},
    this.mutedChannels = const [],
    this.quietHoursStart,
    this.quietHoursEnd,
    this.weekendQuietMode = false,
    this.fcmToken = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userType': userType,
      'isEnabled': isEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'backgroundEnabled': backgroundEnabled,
      'emailEnabled': emailEnabled,
      'typeSettings': _typeSettingsToMap(),
      'prioritySettings': _prioritySettingsToMap(),
      'mutedChannels': mutedChannels,
      'quietHoursStart': quietHoursStart != null ? Timestamp.fromDate(quietHoursStart!) : null,
      'quietHoursEnd': quietHoursEnd != null ? Timestamp.fromDate(quietHoursEnd!) : null,
      'weekendQuietMode': weekendQuietMode,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userType: map['userType'] ?? '',
      isEnabled: map['isEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      backgroundEnabled: map['backgroundEnabled'] ?? true,
      emailEnabled: map['emailEnabled'] ?? false,
      typeSettings: _parseTypeSettings(map['typeSettings']),
      prioritySettings: _parsePrioritySettings(map['prioritySettings']),
      mutedChannels: List<String>.from(map['mutedChannels'] ?? []),
      quietHoursStart: map['quietHoursStart'] != null ? _parseTimestamp(map['quietHoursStart']) : null,
      quietHoursEnd: map['quietHoursEnd'] != null ? _parseTimestamp(map['quietHoursEnd']) : null,
      weekendQuietMode: map['weekendQuietMode'] ?? false,
      fcmToken: map['fcmToken'] ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  NotificationSettingsModel copyWith({
    String? id,
    String? userId,
    String? userType,
    bool? isEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? backgroundEnabled,
    bool? emailEnabled,
    Map<NotificationType, bool>? typeSettings,
    Map<NotificationPriority, bool>? prioritySettings,
    List<String>? mutedChannels,
    DateTime? quietHoursStart,
    DateTime? quietHoursEnd,
    bool? weekendQuietMode,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      isEnabled: isEnabled ?? this.isEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      typeSettings: typeSettings ?? this.typeSettings,
      prioritySettings: prioritySettings ?? this.prioritySettings,
      mutedChannels: mutedChannels ?? this.mutedChannels,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      weekendQuietMode: weekendQuietMode ?? this.weekendQuietMode,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  Map<String, bool> _typeSettingsToMap() {
    final Map<String, bool> result = {};
    typeSettings.forEach((type, enabled) {
      result[type.toString().split('.').last] = enabled;
    });
    return result;
  }

  Map<String, bool> _prioritySettingsToMap() {
    final Map<String, bool> result = {};
    prioritySettings.forEach((priority, enabled) {
      result[priority.toString().split('.').last] = enabled;
    });
    return result;
  }

  static Map<NotificationType, bool> _parseTypeSettings(dynamic settings) {
    if (settings == null) return {};
    
    final Map<NotificationType, bool> result = {};
    final Map<String, dynamic> settingsMap = Map<String, dynamic>.from(settings);
    
    settingsMap.forEach((key, value) {
      final type = NotificationModel._parseNotificationType(key);
      result[type] = value ?? true;
    });
    
    return result;
  }

  static Map<NotificationPriority, bool> _parsePrioritySettings(dynamic settings) {
    if (settings == null) return {};
    
    final Map<NotificationPriority, bool> result = {};
    final Map<String, dynamic> settingsMap = Map<String, dynamic>.from(settings);
    
    settingsMap.forEach((key, value) {
      final priority = NotificationModel._parseNotificationPriority(key);
      result[priority] = value ?? true;
    });
    
    return result;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
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

  /// التحقق من إمكانية إرسال إشعار بناءً على الإعدادات
  bool canSendNotification(NotificationModel notification) {
    // التحقق من التفعيل العام
    if (!isEnabled) return false;
    
    // التحقق من إعدادات النوع
    if (typeSettings.containsKey(notification.type)) {
      if (!typeSettings[notification.type]!) return false;
    }
    
    // التحقق من إعدادات الأولوية
    if (prioritySettings.containsKey(notification.priority)) {
      if (!prioritySettings[notification.priority]!) return false;
    }
    
    // التحقق من ساعات الصمت
    if (isInQuietHours()) {
      // السماح فقط بالإشعارات العاجلة في ساعات الصمت
      return notification.priority == NotificationPriority.urgent;
    }
    
    // التحقق من وضع الصمت في عطلة نهاية الأسبوع
    if (weekendQuietMode && _isWeekend()) {
      return notification.priority == NotificationPriority.urgent;
    }
    
    return true;
  }

  /// التحقق من وجودنا في ساعات الصمت
  bool isInQuietHours() {
    if (quietHoursStart == null || quietHoursEnd == null) return false;
    
    final now = DateTime.now();
    final currentTime = DateTime(1970, 1, 1, now.hour, now.minute);
    final startTime = DateTime(1970, 1, 1, quietHoursStart!.hour, quietHoursStart!.minute);
    final endTime = DateTime(1970, 1, 1, quietHoursEnd!.hour, quietHoursEnd!.minute);
    
    if (startTime.isBefore(endTime)) {
      // نفس اليوم
      return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
    } else {
      // عبر منتصف الليل
      return currentTime.isAfter(startTime) || currentTime.isBefore(endTime);
    }
  }

  /// التحقق من كون اليوم عطلة نهاية أسبوع
  bool _isWeekend() {
    final now = DateTime.now();
    return now.weekday == DateTime.friday || now.weekday == DateTime.saturday;
  }

  /// إنشاء إعدادات افتراضية للمستخدم
  static NotificationSettingsModel createDefault({
    required String userId,
    required String userType,
    String fcmToken = '',
  }) {
    final now = DateTime.now();
    
    // إعدادات افتراضية مختلفة حسب نوع المستخدم
    Map<NotificationType, bool> defaultTypeSettings = {};
    Map<NotificationPriority, bool> defaultPrioritySettings = {
      NotificationPriority.low: true,
      NotificationPriority.medium: true,
      NotificationPriority.high: true,
      NotificationPriority.urgent: true,
    };
    
    switch (userType) {
      case 'admin':
        // الأدمن يستقبل جميع الإشعارات
        defaultTypeSettings = {
          NotificationType.newComplaint: true,
          NotificationType.newStudent: true,
          NotificationType.studentAbsence: true,
          NotificationType.supervisorEvaluation: true,
          NotificationType.profileCompleted: true,
          NotificationType.newParentAccount: true,
          NotificationType.studentBehaviorReport: true,
        };
        break;
        
      case 'parent':
        // أولياء الأمور يستقبلون إشعارات أطفالهم
        defaultTypeSettings = {
          NotificationType.studentAssignedToBus: true,
          NotificationType.supervisorAssigned: true,
          NotificationType.studentBoarded: true,
          NotificationType.studentAtSchool: true,
          NotificationType.studentLeftSchool: true,
          NotificationType.studentAtHome: true,
          NotificationType.studentRemoved: true,
          NotificationType.busRouteChanged: true,
        };
        break;
        
      case 'supervisor':
        // المشرفون يستقبلون إشعارات عملهم
        defaultTypeSettings = {
          NotificationType.assignedToBus: true,
          NotificationType.studentDataUpdated: true,
          NotificationType.newAbsenceReport: true,
        };
        break;
    }
    
    return NotificationSettingsModel(
      id: userId, // نفس معرف المستخدم
      userId: userId,
      userType: userType,
      isEnabled: true,
      soundEnabled: userType == 'admin', // الصوت مفعل للأدمن فقط افتراضياً
      vibrationEnabled: true,
      backgroundEnabled: true,
      emailEnabled: userType == 'admin', // البريد الإلكتروني للأدمن فقط
      typeSettings: defaultTypeSettings,
      prioritySettings: defaultPrioritySettings,
      mutedChannels: [],
      quietHoursStart: DateTime(1970, 1, 1, 22, 0), // 10 مساءً
      quietHoursEnd: DateTime(1970, 1, 1, 7, 0), // 7 صباحاً
      weekendQuietMode: false,
      fcmToken: fcmToken,
      createdAt: now,
      updatedAt: now,
    );
  }
}
