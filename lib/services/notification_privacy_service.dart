import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';

/// خدمة الخصوصية والأمان للإشعارات
class NotificationPrivacyService {
  static final NotificationPrivacyService _instance = NotificationPrivacyService._internal();
  factory NotificationPrivacyService() => _instance;
  NotificationPrivacyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// التحقق من صلاحية إرسال الإشعار للمستلم
  Future<bool> canSendNotificationToRecipient({
    required NotificationModel notification,
    required String senderId,
  }) async {
    try {
      // التحقق الأساسي من وجود المستلم
      if (notification.recipientId.isEmpty) {
        debugPrint('❌ معرف المستلم فارغ');
        return false;
      }

      // التحقق من وجود المستلم في قاعدة البيانات
      final recipientExists = await _userExists(notification.recipientId);
      if (!recipientExists) {
        debugPrint('❌ المستلم غير موجود: ${notification.recipientId}');
        return false;
      }

      // التحقق من صلاحيات المرسل
      final senderHasPermission = await _senderHasPermission(
        senderId: senderId,
        recipientId: notification.recipientId,
        notificationType: notification.type,
      );

      if (!senderHasPermission) {
        debugPrint('❌ المرسل لا يملك صلاحية إرسال هذا النوع من الإشعارات');
        return false;
      }

      // التحقق من العلاقة بين المرسل والمستلم
      final relationshipValid = await _validateRelationship(
        senderId: senderId,
        recipientId: notification.recipientId,
        notificationType: notification.type,
        notificationData: notification.data,
      );

      if (!relationshipValid) {
        debugPrint('❌ العلاقة بين المرسل والمستلم غير صحيحة');
        return false;
      }

      // التحقق من حدود الإرسال
      final withinLimits = await _checkSendingLimits(
        senderId: senderId,
        recipientId: notification.recipientId,
        notificationType: notification.type,
      );

      if (!withinLimits) {
        debugPrint('❌ تم تجاوز حدود الإرسال');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من صلاحية الإرسال: $e');
      return false;
    }
  }

  /// التحقق من وجود المستخدم
  Future<bool> _userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists && doc.data()?['isActive'] == true;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من وجود المستخدم: $e');
      return false;
    }
  }

  /// التحقق من صلاحيات المرسل
  Future<bool> _senderHasPermission({
    required String senderId,
    required String recipientId,
    required NotificationType notificationType,
  }) async {
    try {
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      if (!senderDoc.exists) return false;

      final senderData = UserModel.fromMap(senderDoc.data()!);

      // الأدمن يمكنه إرسال جميع أنواع الإشعارات
      if (senderData.userType == UserType.admin) {
        return true;
      }

      // المشرف يمكنه إرسال إشعارات محددة
      if (senderData.userType == UserType.supervisor) {
        return _supervisorCanSendNotification(notificationType);
      }

      // ولي الأمر يمكنه إرسال إشعارات محددة
      if (senderData.userType == UserType.parent) {
        return _parentCanSendNotification(notificationType);
      }

      return false;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من صلاحيات المرسل: $e');
      return false;
    }
  }

  /// التحقق من صلاحيات المشرف
  bool _supervisorCanSendNotification(NotificationType type) {
    const allowedTypes = [
      NotificationType.studentBoarded,
      NotificationType.studentAtSchool,
      NotificationType.studentAtHome,
      NotificationType.studentBehaviorReport,
    ];
    return allowedTypes.contains(type);
  }

  /// التحقق من صلاحيات ولي الأمر
  bool _parentCanSendNotification(NotificationType type) {
    const allowedTypes = [
      NotificationType.newComplaint,
      NotificationType.studentAbsence,
      NotificationType.supervisorEvaluation,
    ];
    return allowedTypes.contains(type);
  }

  /// التحقق من صحة العلاقة بين المرسل والمستلم
  Future<bool> _validateRelationship({
    required String senderId,
    required String recipientId,
    required NotificationType notificationType,
    required Map<String, dynamic> notificationData,
  }) async {
    try {
      // إذا كان المرسل أدمن، فالعلاقة صحيحة دائماً
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      if (senderDoc.exists) {
        final senderData = UserModel.fromMap(senderDoc.data()!);
        if (senderData.userType == UserType.admin) {
          return true;
        }
      }

      // التحقق من العلاقات المحددة
      switch (notificationType) {
        case NotificationType.studentBoarded:
        case NotificationType.studentAtSchool:
        case NotificationType.studentAtHome:
          return await _validateStudentParentRelationship(
            senderId: senderId,
            recipientId: recipientId,
            studentId: notificationData['studentId'],
          );

        case NotificationType.newComplaint:
          return await _validateComplaintRelationship(
            senderId: senderId,
            recipientId: recipientId,
          );

        case NotificationType.supervisorEvaluation:
          return await _validateSupervisorEvaluationRelationship(
            senderId: senderId,
            recipientId: recipientId,
            supervisorId: notificationData['supervisorId'],
          );

        default:
          return true; // للإشعارات العامة
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من العلاقة: $e');
      return false;
    }
  }

  /// التحقق من علاقة الطالب بولي الأمر
  Future<bool> _validateStudentParentRelationship({
    required String senderId,
    required String recipientId,
    String? studentId,
  }) async {
    try {
      if (studentId == null) return false;

      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) return false;

      final studentData = StudentModel.fromMap(studentDoc.data()!);
      
      // التحقق من أن المستلم هو ولي أمر الطالب
      return studentData.parentId == recipientId;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من علاقة الطالب بولي الأمر: $e');
      return false;
    }
  }

  /// التحقق من علاقة الشكوى
  Future<bool> _validateComplaintRelationship({
    required String senderId,
    required String recipientId,
  }) async {
    try {
      // ولي الأمر يرسل شكوى للأدمن
      final recipientDoc = await _firestore.collection('users').doc(recipientId).get();
      if (!recipientDoc.exists) return false;

      final recipientData = UserModel.fromMap(recipientDoc.data()!);
      return recipientData.userType == UserType.admin;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من علاقة الشكوى: $e');
      return false;
    }
  }

  /// التحقق من علاقة تقييم المشرف
  Future<bool> _validateSupervisorEvaluationRelationship({
    required String senderId,
    required String recipientId,
    String? supervisorId,
  }) async {
    try {
      if (supervisorId == null) return false;

      // التحقق من أن ولي الأمر له طالب مع هذا المشرف
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('parentId', isEqualTo: senderId)
          .get();

      for (final studentDoc in studentsSnapshot.docs) {
        final studentData = StudentModel.fromMap(studentDoc.data());
        
        // التحقق من تعيين المشرف للطالب
        final assignmentSnapshot = await _firestore
            .collection('supervisor_assignments')
            .where('supervisorId', isEqualTo: supervisorId)
            .where('busId', isEqualTo: studentData.busId)
            .where('isActive', isEqualTo: true)
            .get();

        if (assignmentSnapshot.docs.isNotEmpty) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من علاقة تقييم المشرف: $e');
      return false;
    }
  }

  /// التحقق من حدود الإرسال
  Future<bool> _checkSendingLimits({
    required String senderId,
    required String recipientId,
    required NotificationType notificationType,
  }) async {
    try {
      final now = DateTime.now();
      final startOfHour = DateTime(now.year, now.month, now.day, now.hour);

      // حدود مختلفة لأنواع مختلفة من الإشعارات
      int hourlyLimit = _getHourlyLimit(notificationType);

      // عد الإشعارات المرسلة في الساعة الماضية
      final recentNotifications = await _firestore
          .collection('notifications')
          .where('senderId', isEqualTo: senderId)
          .where('recipientId', isEqualTo: recipientId)
          .where('type', isEqualTo: notificationType.toString().split('.').last)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startOfHour))
          .get();

      return recentNotifications.docs.length < hourlyLimit;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من حدود الإرسال: $e');
      return true; // السماح في حالة الخطأ
    }
  }

  /// الحصول على الحد الأقصى للإرسال في الساعة
  int _getHourlyLimit(NotificationType type) {
    switch (type) {
      case NotificationType.studentBoarded:
      case NotificationType.studentAtSchool:
      case NotificationType.studentAtHome:
        return 10; // إشعارات الحركة
      case NotificationType.newComplaint:
        return 3; // الشكاوى
      case NotificationType.supervisorEvaluation:
        return 2; // التقييمات
      default:
        return 5; // الافتراضي
    }
  }

  /// تسجيل محاولة إرسال مشبوهة
  Future<void> logSuspiciousActivity({
    required String senderId,
    required String recipientId,
    required NotificationType notificationType,
    required String reason,
  }) async {
    try {
      await _firestore.collection('security_logs').add({
        'type': 'suspicious_notification_attempt',
        'senderId': senderId,
        'recipientId': recipientId,
        'notificationType': notificationType.toString().split('.').last,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': 'Flutter App',
      });

      debugPrint('🚨 تم تسجيل نشاط مشبوه: $reason');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل النشاط المشبوه: $e');
    }
  }

  /// تنظيف البيانات الحساسة من الإشعار
  NotificationModel sanitizeNotification(NotificationModel notification) {
    // إزالة البيانات الحساسة من payload الإشعار
    final sanitizedData = Map<String, dynamic>.from(notification.data);
    
    // قائمة الحقول الحساسة التي يجب إزالتها
    const sensitiveFields = [
      'password',
      'token',
      'secret',
      'key',
      'phone',
      'email',
      'address',
      'nationalId',
    ];

    for (final field in sensitiveFields) {
      sanitizedData.remove(field);
    }

    return notification.copyWith(data: sanitizedData);
  }

  /// التحقق من صحة محتوى الإشعار
  bool validateNotificationContent(NotificationModel notification) {
    // التحقق من طول العنوان والمحتوى
    if (notification.title.length > 100 || notification.body.length > 500) {
      return false;
    }

    // التحقق من عدم وجود محتوى ضار
    final harmfulPatterns = [
      RegExp(r'<script.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
    ];

    final content = '${notification.title} ${notification.body}';
    for (final pattern in harmfulPatterns) {
      if (pattern.hasMatch(content)) {
        return false;
      }
    }

    return true;
  }
}
