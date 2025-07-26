import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_model.dart';

/// نموذج حدث الإشعار - يحدد متى وكيف يتم إرسال الإشعارات
class NotificationEventModel {
  final String id;
  final String eventName;
  final NotificationType notificationType;
  final String triggerCollection; // المجموعة التي تحتوي على الحدث
  final String triggerField; // الحقل الذي يؤدي لتفعيل الإشعار
  final dynamic triggerValue; // القيمة التي تؤدي لتفعيل الإشعار
  final List<String> targetUserTypes; // أنواع المستخدمين المستهدفين
  final NotificationPriority defaultPriority;
  final List<NotificationChannel> defaultChannels;
  final bool requiresSound;
  final bool requiresVibration;
  final bool isBackground;
  final String titleTemplate; // قالب العنوان
  final String bodyTemplate; // قالب المحتوى
  final Map<String, dynamic> additionalData; // بيانات إضافية
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationEventModel({
    required this.id,
    required this.eventName,
    required this.notificationType,
    required this.triggerCollection,
    required this.triggerField,
    required this.triggerValue,
    required this.targetUserTypes,
    this.defaultPriority = NotificationPriority.medium,
    this.defaultChannels = const [NotificationChannel.fcm, NotificationChannel.inApp],
    this.requiresSound = false,
    this.requiresVibration = false,
    this.isBackground = true,
    required this.titleTemplate,
    required this.bodyTemplate,
    this.additionalData = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventName': eventName,
      'notificationType': notificationType.toString().split('.').last,
      'triggerCollection': triggerCollection,
      'triggerField': triggerField,
      'triggerValue': triggerValue,
      'targetUserTypes': targetUserTypes,
      'defaultPriority': defaultPriority.toString().split('.').last,
      'defaultChannels': defaultChannels.map((c) => c.toString().split('.').last).toList(),
      'requiresSound': requiresSound,
      'requiresVibration': requiresVibration,
      'isBackground': isBackground,
      'titleTemplate': titleTemplate,
      'bodyTemplate': bodyTemplate,
      'additionalData': additionalData,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory NotificationEventModel.fromMap(Map<String, dynamic> map) {
    return NotificationEventModel(
      id: map['id'] ?? '',
      eventName: map['eventName'] ?? '',
      notificationType: NotificationModel.parseNotificationType(map['notificationType']),
      triggerCollection: map['triggerCollection'] ?? '',
      triggerField: map['triggerField'] ?? '',
      triggerValue: map['triggerValue'],
      targetUserTypes: List<String>.from(map['targetUserTypes'] ?? []),
      defaultPriority: NotificationModel.parseNotificationPriority(map['defaultPriority']),
      defaultChannels: NotificationModel.parseChannels(map['defaultChannels']),
      requiresSound: map['requiresSound'] ?? false,
      requiresVibration: map['requiresVibration'] ?? false,
      isBackground: map['isBackground'] ?? true,
      titleTemplate: map['titleTemplate'] ?? '',
      bodyTemplate: map['bodyTemplate'] ?? '',
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
      isActive: map['isActive'] ?? true,
      createdAt: NotificationModel.parseTimestamp(map['createdAt']),
      updatedAt: NotificationModel.parseTimestamp(map['updatedAt']),
    );
  }

  NotificationEventModel copyWith({
    String? id,
    String? eventName,
    NotificationType? notificationType,
    String? triggerCollection,
    String? triggerField,
    dynamic triggerValue,
    List<String>? targetUserTypes,
    NotificationPriority? defaultPriority,
    List<NotificationChannel>? defaultChannels,
    bool? requiresSound,
    bool? requiresVibration,
    bool? isBackground,
    String? titleTemplate,
    String? bodyTemplate,
    Map<String, dynamic>? additionalData,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationEventModel(
      id: id ?? this.id,
      eventName: eventName ?? this.eventName,
      notificationType: notificationType ?? this.notificationType,
      triggerCollection: triggerCollection ?? this.triggerCollection,
      triggerField: triggerField ?? this.triggerField,
      triggerValue: triggerValue ?? this.triggerValue,
      targetUserTypes: targetUserTypes ?? this.targetUserTypes,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      defaultChannels: defaultChannels ?? this.defaultChannels,
      requiresSound: requiresSound ?? this.requiresSound,
      requiresVibration: requiresVibration ?? this.requiresVibration,
      isBackground: isBackground ?? this.isBackground,
      titleTemplate: titleTemplate ?? this.titleTemplate,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      additionalData: additionalData ?? this.additionalData,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// تطبيق القالب مع البيانات المحددة
  String applyTemplate(String template, Map<String, dynamic> data) {
    String result = template;
    
    data.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    
    return result;
  }

  /// إنشاء عنوان الإشعار من القالب
  String generateTitle(Map<String, dynamic> data) {
    return applyTemplate(titleTemplate, data);
  }

  /// إنشاء محتوى الإشعار من القالب
  String generateBody(Map<String, dynamic> data) {
    return applyTemplate(bodyTemplate, data);
  }
}

/// أحداث الإشعارات المحددة مسبقاً
class PredefinedNotificationEvents {
  static List<NotificationEventModel> getDefaultEvents() {
    final now = DateTime.now();
    
    return [
      // إشعارات الأدمن
      NotificationEventModel(
        id: 'complaint_created',
        eventName: 'إنشاء شكوى جديدة',
        notificationType: NotificationType.newComplaint,
        triggerCollection: 'complaints',
        triggerField: 'status',
        triggerValue: 'pending',
        targetUserTypes: ['admin'],
        defaultPriority: NotificationPriority.high,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: true,
        isBackground: true,
        titleTemplate: 'شكوى جديدة من {parentName}',
        bodyTemplate: 'تم استلام شكوى جديدة بعنوان: {title}',
        createdAt: now,
        updatedAt: now,
      ),
      
      NotificationEventModel(
        id: 'student_created',
        eventName: 'إضافة طالب جديد',
        notificationType: NotificationType.newStudent,
        triggerCollection: 'students',
        triggerField: 'isActive',
        triggerValue: true,
        targetUserTypes: ['admin'],
        defaultPriority: NotificationPriority.medium,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: false,
        isBackground: true,
        titleTemplate: 'طالب جديد: {studentName}',
        bodyTemplate: 'تم إضافة الطالب {studentName} من قبل ولي الأمر {parentName}',
        createdAt: now,
        updatedAt: now,
      ),
      
      NotificationEventModel(
        id: 'absence_reported',
        eventName: 'تبليغ غياب طالب',
        notificationType: NotificationType.studentAbsence,
        triggerCollection: 'absences',
        triggerField: 'source',
        triggerValue: 'parent',
        targetUserTypes: ['admin', 'supervisor'],
        defaultPriority: NotificationPriority.medium,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: false,
        isBackground: true,
        titleTemplate: 'تبليغ غياب: {studentName}',
        bodyTemplate: 'تم تبليغ غياب الطالب {studentName} بتاريخ {date}',
        createdAt: now,
        updatedAt: now,
      ),
      
      NotificationEventModel(
        id: 'supervisor_evaluated',
        eventName: 'تقييم مشرف',
        notificationType: NotificationType.supervisorEvaluation,
        triggerCollection: 'supervisor_evaluations',
        triggerField: 'evaluatedAt',
        triggerValue: 'not_null',
        targetUserTypes: ['admin'],
        defaultPriority: NotificationPriority.medium,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: false,
        isBackground: true,
        titleTemplate: 'تقييم جديد للمشرف {supervisorName}',
        bodyTemplate: 'تم تقييم المشرف {supervisorName} من قبل ولي الأمر {parentName}',
        createdAt: now,
        updatedAt: now,
      ),
      
      // إشعارات أولياء الأمور
      NotificationEventModel(
        id: 'student_boarded_bus',
        eventName: 'ركوب الطالب الباص',
        notificationType: NotificationType.studentBoarded,
        triggerCollection: 'trips',
        triggerField: 'action',
        triggerValue: 'boardBus',
        targetUserTypes: ['parent'],
        defaultPriority: NotificationPriority.high,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: true,
        isBackground: true,
        titleTemplate: 'ركب {studentName} الباص',
        bodyTemplate: 'ركب طفلك {studentName} الباص بأمان في تمام الساعة {time}',
        createdAt: now,
        updatedAt: now,
      ),
      
      NotificationEventModel(
        id: 'student_at_school',
        eventName: 'وصول الطالب للمدرسة',
        notificationType: NotificationType.studentAtSchool,
        triggerCollection: 'trips',
        triggerField: 'action',
        triggerValue: 'arriveAtSchool',
        targetUserTypes: ['parent'],
        defaultPriority: NotificationPriority.high,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: true,
        isBackground: true,
        titleTemplate: 'وصل {studentName} للمدرسة',
        bodyTemplate: 'وصل طفلك {studentName} للمدرسة بأمان في تمام الساعة {time}',
        createdAt: now,
        updatedAt: now,
      ),
      
      NotificationEventModel(
        id: 'student_at_home',
        eventName: 'وصول الطالب للمنزل',
        notificationType: NotificationType.studentAtHome,
        triggerCollection: 'trips',
        triggerField: 'action',
        triggerValue: 'arriveAtHome',
        targetUserTypes: ['parent'],
        defaultPriority: NotificationPriority.high,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: true,
        isBackground: true,
        titleTemplate: 'وصل {studentName} للمنزل',
        bodyTemplate: 'وصل طفلك {studentName} للمنزل بأمان في تمام الساعة {time}',
        createdAt: now,
        updatedAt: now,
      ),
      
      // إشعارات المشرفين
      NotificationEventModel(
        id: 'supervisor_assigned_to_bus',
        eventName: 'تعيين مشرف في باص',
        notificationType: NotificationType.assignedToBus,
        triggerCollection: 'supervisor_assignments',
        triggerField: 'isActive',
        triggerValue: true,
        targetUserTypes: ['supervisor'],
        defaultPriority: NotificationPriority.high,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: false,
        isBackground: true,
        titleTemplate: 'تم تعيينك في باص {busRoute}',
        bodyTemplate: 'تم تعيينك كمشرف في الباص رقم {busRoute}. يرجى مراجعة التفاصيل.',
        createdAt: now,
        updatedAt: now,
      ),

      // إشعارات إضافية مكملة
      NotificationEventModel(
        id: 'profile_completed',
        eventName: 'إكمال البروفايل',
        notificationType: NotificationType.profileCompleted,
        triggerCollection: 'users',
        triggerField: 'isProfileComplete',
        triggerValue: true,
        targetUserTypes: ['admin'],
        defaultPriority: NotificationPriority.medium,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: false,
        isBackground: true,
        titleTemplate: 'تم إكمال البروفايل: {userName}',
        bodyTemplate: 'أكمل المستخدم {userName} ({userType}) بروفايله بنجاح',
        createdAt: now,
        updatedAt: now,
      ),

      NotificationEventModel(
        id: 'student_assigned_to_bus',
        eventName: 'تعيين طالب في خط سير',
        notificationType: NotificationType.studentAssignedToBus,
        triggerCollection: 'students',
        triggerField: 'busRoute',
        triggerValue: 'not_empty',
        targetUserTypes: ['parent'],
        defaultPriority: NotificationPriority.high,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: true,
        isBackground: true,
        titleTemplate: 'تم تعيين {studentName} في الباص',
        bodyTemplate: 'تم تعيين طفلك {studentName} في خط السير {busRoute}',
        createdAt: now,
        updatedAt: now,
      ),

      NotificationEventModel(
        id: 'student_removed',
        eventName: 'حذف طالب من النظام',
        notificationType: NotificationType.studentRemoved,
        triggerCollection: 'students',
        triggerField: 'deleted',
        triggerValue: true,
        targetUserTypes: ['parent'],
        defaultPriority: NotificationPriority.high,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: true,
        isBackground: true,
        titleTemplate: 'تم حذف {studentName}',
        bodyTemplate: 'تم حذف الطالب {studentName} من النظام. {reason}',
        createdAt: now,
        updatedAt: now,
      ),

      NotificationEventModel(
        id: 'student_data_updated_parent',
        eventName: 'تحديث بيانات طالب لولي الأمر',
        notificationType: NotificationType.studentDataUpdated,
        triggerCollection: 'students',
        triggerField: 'updatedAt',
        triggerValue: 'recent',
        targetUserTypes: ['parent'],
        defaultPriority: NotificationPriority.high,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: true,
        isBackground: true,
        titleTemplate: 'تحديث بيانات {studentName}',
        bodyTemplate: 'تم تحديث بيانات طفلك {studentName} من قبل الإدارة',
        createdAt: now,
        updatedAt: now,
      ),

      NotificationEventModel(
        id: 'student_data_updated_supervisor',
        eventName: 'تحديث بيانات طالب للمشرف',
        notificationType: NotificationType.studentDataUpdated,
        triggerCollection: 'students',
        triggerField: 'updatedAt',
        triggerValue: 'recent',
        targetUserTypes: ['supervisor'],
        defaultPriority: NotificationPriority.medium,
        defaultChannels: [NotificationChannel.fcm, NotificationChannel.inApp],
        requiresSound: true,
        requiresVibration: false,
        isBackground: true,
        titleTemplate: 'تحديث بيانات: {studentName}',
        bodyTemplate: 'تم تحديث بيانات الطالب {studentName} في خط السير {busRoute}',
        createdAt: now,
        updatedAt: now,
      ),

      NotificationEventModel(
        id: 'student_data_updated_admin',
        eventName: 'تحديث بيانات طالب للأدمن',
        notificationType: NotificationType.studentDataUpdated,
        triggerCollection: 'students',
        triggerField: 'updatedAt',
        triggerValue: 'recent',
        targetUserTypes: ['admin'],
        defaultPriority: NotificationPriority.low,
        defaultChannels: [NotificationChannel.inApp],
        requiresSound: false,
        requiresVibration: false,
        isBackground: true,
        titleTemplate: 'تحديث بيانات طالب',
        bodyTemplate: 'تم تحديث بيانات الطالب {studentName} بواسطة الإدارة',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
