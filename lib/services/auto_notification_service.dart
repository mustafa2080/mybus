import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_notification_service.dart';
import '../services/database_service.dart';
import '../models/notification_model.dart';

/// خدمة الإشعارات التلقائية
class AutoNotificationService {
  static final AutoNotificationService _instance = AutoNotificationService._internal();
  factory AutoNotificationService() => _instance;
  AutoNotificationService._internal();

  final UserNotificationService _notificationService = UserNotificationService();
  final DatabaseService _databaseService = DatabaseService();

  /// إرسال إشعار عند تسجيل دخول المستخدم
  Future<void> sendWelcomeNotification(String userId, String userType) async {
    try {
      String title = '';
      String body = '';

      switch (userType) {
        case 'parent':
          title = 'مرحباً بك في تطبيق MyBus';
          body = 'يمكنك الآن متابعة رحلات أطفالك والتواصل مع المدرسة بسهولة';
          break;
        case 'admin':
          title = 'مرحباً بك في لوحة التحكم';
          body = 'يمكنك الآن إدارة النظام ومتابعة جميع العمليات';
          break;
        case 'supervisor':
          title = 'مرحباً بك كمشرف';
          body = 'يمكنك الآن متابعة الطلاب وإدارة الرحلات';
          break;
        default:
          title = 'مرحباً بك';
          body = 'تم تسجيل دخولك بنجاح';
      }

      await _notificationService.createNotification(
        recipientId: userId,
        title: title,
        body: body,
        type: NotificationType.generalAnnouncement,
        priority: NotificationPriority.low,
        data: {
          'type': 'welcome',
          'userType': userType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ تم إرسال إشعار الترحيب للمستخدم: $userId');
    } catch (e) {
      print('❌ خطأ في إرسال إشعار الترحيب: $e');
    }
  }

  /// إرسال إشعار عند إضافة طالب جديد
  Future<void> sendNewStudentNotification({
    required String studentId,
    required String studentName,
    required String parentId,
    String? adminId,
  }) async {
    try {
      // إشعار لولي الأمر
      await _notificationService.createNotification(
        recipientId: parentId,
        title: 'تم إضافة طالب جديد',
        body: 'تم إضافة الطالب $studentName إلى حسابك بنجاح',
        type: NotificationType.newStudent,
        priority: NotificationPriority.high,
        data: {
          'studentId': studentId,
          'studentName': studentName,
          'type': 'student_added',
        },
      );

      // إشعار للأدمن (إذا لم يكن هو من أضاف الطالب)
      if (adminId != null) {
        final admins = await _databaseService.getAllAdmins();
        final adminIds = admins
            .where((admin) => admin.id != adminId)
            .map((admin) => admin.id)
            .toList();

        if (adminIds.isNotEmpty) {
          await _notificationService.createBulkNotifications(
            recipientIds: adminIds,
            title: 'طالب جديد تم إضافته',
            body: 'تم إضافة الطالب $studentName إلى النظام',
            type: NotificationType.newStudent,
            priority: NotificationPriority.medium,
            data: {
              'studentId': studentId,
              'studentName': studentName,
              'addedBy': adminId,
            },
          );
        }
      }

      print('✅ تم إرسال إشعارات الطالب الجديد');
    } catch (e) {
      print('❌ خطأ في إرسال إشعارات الطالب الجديد: $e');
    }
  }

  /// إرسال إشعار عند إنشاء شكوى جديدة
  Future<void> sendNewComplaintNotification({
    required String complaintId,
    required String complaintTitle,
    required String parentId,
    required String studentName,
  }) async {
    try {
      // إشعار لجميع الأدمن
      final admins = await _databaseService.getAllAdmins();
      final adminIds = admins.map((admin) => admin.id).toList();

      if (adminIds.isNotEmpty) {
        await _notificationService.createBulkNotifications(
          recipientIds: adminIds,
          title: 'شكوى جديدة',
          body: 'تم إرسال شكوى جديدة من ولي أمر $studentName',
          type: NotificationType.newComplaint,
          priority: NotificationPriority.high,
          data: {
            'complaintId': complaintId,
            'complaintTitle': complaintTitle,
            'parentId': parentId,
            'studentName': studentName,
          },
        );
      }

      // إشعار تأكيد لولي الأمر
      await _notificationService.createNotification(
        recipientId: parentId,
        title: 'تم إرسال شكواك',
        body: 'تم إرسال شكواك بنجاح وسيتم الرد عليها قريباً',
        type: NotificationType.generalAnnouncement,
        priority: NotificationPriority.medium,
        data: {
          'complaintId': complaintId,
          'type': 'complaint_confirmation',
        },
      );

      print('✅ تم إرسال إشعارات الشكوى الجديدة');
    } catch (e) {
      print('❌ خطأ في إرسال إشعارات الشكوى: $e');
    }
  }

  /// إرسال إشعار عند تسجيل غياب
  Future<void> sendAbsenceNotification({
    required String studentId,
    required String studentName,
    required String parentId,
    required DateTime absenceDate,
    required String reason,
  }) async {
    try {
      // إشعار للأدمن والمشرفين
      final admins = await _databaseService.getAllAdmins();
      final supervisors = await _databaseService.getAllSupervisors();
      
      final recipientIds = [
        ...admins.map((admin) => admin.id),
        ...supervisors.map((supervisor) => supervisor.id),
      ];

      if (recipientIds.isNotEmpty) {
        await _notificationService.createBulkNotifications(
          recipientIds: recipientIds,
          title: 'إشعار غياب',
          body: 'أبلغ ولي أمر $studentName عن غياب الطالب',
          type: NotificationType.studentAbsence,
          priority: NotificationPriority.medium,
          data: {
            'studentId': studentId,
            'studentName': studentName,
            'parentId': parentId,
            'absenceDate': absenceDate.toIso8601String(),
            'reason': reason,
          },
        );
      }

      // إشعار تأكيد لولي الأمر
      await _notificationService.createNotification(
        recipientId: parentId,
        title: 'تم تسجيل الغياب',
        body: 'تم تسجيل غياب $studentName بنجاح',
        type: NotificationType.generalAnnouncement,
        priority: NotificationPriority.low,
        data: {
          'studentId': studentId,
          'type': 'absence_confirmation',
        },
      );

      print('✅ تم إرسال إشعارات الغياب');
    } catch (e) {
      print('❌ خطأ في إرسال إشعارات الغياب: $e');
    }
  }

  /// إرسال إشعار عند ركوب/نزول الطالب
  Future<void> sendTripNotification({
    required String studentId,
    required String studentName,
    required String parentId,
    required String action, // 'boarded' أو 'alighted'
    required String location, // 'school' أو 'home'
  }) async {
    try {
      String title = '';
      String body = '';

      if (action == 'boarded') {
        if (location == 'school') {
          title = 'ركب الطالب الباص';
          body = '$studentName ركب الباص متوجهاً إلى المدرسة';
        } else {
          title = 'ركب الطالب الباص';
          body = '$studentName ركب الباص متوجهاً إلى المنزل';
        }
      } else {
        if (location == 'school') {
          title = 'وصل الطالب للمدرسة';
          body = '$studentName وصل إلى المدرسة بأمان';
        } else {
          title = 'وصل الطالب للمنزل';
          body = '$studentName وصل إلى المنزل بأمان';
        }
      }

      await _notificationService.createNotification(
        recipientId: parentId,
        title: title,
        body: body,
        type: action == 'boarded' ? NotificationType.studentBoarded : 
              (location == 'school' ? NotificationType.studentAtSchool : NotificationType.studentAtHome),
        priority: NotificationPriority.high,
        data: {
          'studentId': studentId,
          'studentName': studentName,
          'action': action,
          'location': location,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ تم إرسال إشعار الرحلة');
    } catch (e) {
      print('❌ خطأ في إرسال إشعار الرحلة: $e');
    }
  }
}
