import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/student_model.dart';
import 'enhanced_notification_service.dart';


class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final EnhancedNotificationService _enhancedService = EnhancedNotificationService();

  // Initialize notifications
  Future<void> initialize() async {
    // Skip initialization on web to avoid service worker issues
    if (kIsWeb) {
      debugPrint('Notification service skipped on web platform');
      return;
    }

    // Initialize enhanced notification service
    await _enhancedService.initialize();

    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // Get FCM token
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Handle foreground messages with sound and system notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Received foreground message: ${message.notification?.title}');

    // عرض الإشعار في النظام حتى لو كان التطبيق مفتوح
    _showSystemNotification(message);
  }

  // Show system notification with sound
  void _showSystemNotification(RemoteMessage message) {
    try {
      // هذا سيتم التعامل معه تلقائياً بواسطة Firebase Messaging
      // لكن يمكننا إضافة معالجة إضافية هنا إذا لزم الأمر
      debugPrint('🔊 System notification displayed with sound');

      // يمكن إضافة vibration أو sound إضافي هنا إذا لزم الأمر
      // HapticFeedback.vibrate(); // يتطلب import 'package:flutter/services.dart';

    } catch (e) {
      debugPrint('❌ Error showing system notification: $e');
    }
  }

  // Handle background messages with enhanced sound and display
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Received background message with sound: ${message.notification?.title}');

    // حفظ الإشعار في قاعدة البيانات المحلية حتى لو كان التطبيق مغلق
    try {
      final firestore = FirebaseFirestore.instance;

      // إنشاء إشعار من الرسالة المستلمة مع إعدادات الصوت
      final notification = {
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'إشعار جديد',
        'body': message.notification?.body ?? '',
        'recipientId': message.data['recipientId'] ?? '',
        'type': message.data['type'] ?? 'general',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': {
          ...message.data,
          'sound_played': true,
          'background_received': true,
          'received_at': DateTime.now().toIso8601String(),
        },
        // إعدادات إضافية للصوت والعرض
        'notification_settings': {
          'sound': true,
          'vibration': true,
          'priority': 'high',
          'show_in_foreground': true,
        }
      };

      // حفظ الإشعار في Firestore
      await firestore.collection('notifications').add(notification);

      debugPrint('✅ Background notification with sound saved to database');

      // إضافة log للتتبع
      await firestore.collection('notification_logs').add({
        'message_id': message.messageId,
        'title': message.notification?.title,
        'received_at': FieldValue.serverTimestamp(),
        'type': 'background',
        'sound_enabled': true,
        'platform': 'android',
      });

    } catch (e) {
      debugPrint('❌ Error saving background notification: $e');
    }
  }

  // Send notification for student boarding
  Future<void> sendStudentBoardedNotification({
    required StudentModel student,
    required String supervisorName,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'ركب ${student.name} الباص',
        body: 'ركب ${student.name} الباص مع المشرف $supervisorName في ${_formatTime(timestamp)}',
        recipientId: student.parentId,
        studentId: student.id,
        studentName: student.name,
        type: NotificationType.studentBoarded,
        timestamp: timestamp,
        data: {
          'studentId': student.id,
          'action': 'boarded',
          'timestamp': timestamp.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار ركوب الطالب: $e');
    }
  }

  // Send notification for student leaving
  Future<void> sendStudentLeftNotification({
    required StudentModel student,
    required String supervisorName,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'نزل ${student.name} من الباص',
        body: 'نزل ${student.name} من الباص مع المشرف $supervisorName في ${_formatTime(timestamp)}',
        recipientId: student.parentId,
        studentId: student.id,
        studentName: student.name,
        type: NotificationType.studentLeft,
        timestamp: timestamp,
        data: {
          'studentId': student.id,
          'action': 'left',
          'timestamp': timestamp.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار نزول الطالب: $e');
    }
  }

  // Send general notification
  Future<void> sendGeneralNotification({
    required String title,
    required String body,
    required String recipientId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: title,
        body: body,
        recipientId: recipientId,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: data,
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال الإشعار: $e');
    }
  }

  // Send trip started notification
  Future<void> sendTripStartedNotification({
    required String recipientId,
    required String studentName,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'بدء الرحلة',
        body: 'تم بدء رحلة الباص. سيتم إشعارك عند ركوب $studentName الباص.',
        recipientId: recipientId,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'type': 'trip_started',
          'studentName': studentName,
          'timestamp': timestamp.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار بدء الرحلة: $e');
    }
  }

  // Send trip ended notification
  Future<void> sendTripEndedNotification({
    required String recipientId,
    required String studentName,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'انتهاء الرحلة',
        body: 'تم انتهاء رحلة الباص.',
        recipientId: recipientId,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'type': 'trip_ended',
          'studentName': studentName,
          'timestamp': timestamp.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار انتهاء الرحلة: $e');
    }
  }

  // Send student status update notification
  Future<void> sendStudentStatusUpdateNotification({
    required String recipientId,
    required String studentName,
    required String status,
    required String action,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'تحديث حالة $studentName',
        body: status,
        recipientId: recipientId,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'type': 'status_update',
          'studentName': studentName,
          'action': action,
          'timestamp': timestamp.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار تحديث الحالة: $e');
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotification(NotificationModel notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  // Send push notification with sound and system notification display
  Future<void> _sendPushNotification(NotificationModel notification) async {
    try {
      // حفظ الإشعار في قائمة انتظار FCM مع إعدادات محسنة للصوت والعرض
      await _firestore.collection('fcm_queue').add({
        'recipientId': notification.recipientId,
        'title': notification.title,
        'body': notification.body,
        'data': {
          ...notification.data ?? {},
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'sound': 'default',
          'priority': 'high',
          'notification_priority': 'PRIORITY_MAX',
          'importance': 'high',
          'channel_id': 'mybus_notifications',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': notification.type.toString().split('.').last,
        // إعدادات Android محسنة للصوت والعرض
        'android': {
          'priority': 'high',
          'ttl': '86400s', // 24 hours
          'notification': {
            'title': notification.title,
            'body': notification.body,
            'channel_id': 'mybus_notifications',
            'priority': 'high',
            'sound': 'default',
            'default_sound': true,
            'default_vibrate_timings': true,
            'default_light_settings': true,
            'notification_priority': 'PRIORITY_MAX',
            'visibility': 'public',
            'show_when': true,
            'local_only': false,
            'sticky': false,
            'icon': 'ic_notification',
            'color': '#FF6B6B',
            'tag': 'mybus_${notification.type.toString().split('.').last}',
          }
        },
        // إعدادات iOS محسنة
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': notification.title,
                'body': notification.body,
              },
              'badge': 1,
              'sound': 'default',
              'content-available': 1,
              'mutable-content': 1,
              'category': 'MYBUS_NOTIFICATION',
            }
          },
          'headers': {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          }
        },
        // إعدادات الويب
        'webpush': {
          'headers': {
            'Urgency': 'high',
          },
          'notification': {
            'title': notification.title,
            'body': notification.body,
            'icon': '/icons/notification-icon.png',
            'badge': '/icons/badge-icon.png',
            'sound': '/sounds/notification.mp3',
            'vibrate': [200, 100, 200],
            'requireInteraction': true,
          }
        },
      });

      debugPrint('✅ Enhanced push notification with sound queued: ${notification.title}');
    } catch (e) {
      debugPrint('❌ Error queuing push notification: $e');
    }
  }

  // Get notifications for user
  Stream<List<NotificationModel>> getNotificationsForUser(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList();

          // Sort manually to avoid index requirement
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Limit to 50 notifications
          return notifications.take(50).toList();
        });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('خطأ في تحديث حالة الإشعار: $e');
    }
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['isRead'] == false)
            .length);
  }

  // Delete test notifications
  Future<void> deleteTestNotifications(String userId) async {
    try {
      debugPrint('🧹 Cleaning up test notifications for user: $userId');

      final batch = _firestore.batch();
      final testNotifications = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .get();

      int deletedCount = 0;
      for (var doc in testNotifications.docs) {
        final data = doc.data();

        // Check if it's a test notification
        final isTestNotification =
            data['title']?.toString().contains('تجريبي') == true ||
            data['body']?.toString().contains('تجريبي') == true ||
            data['data']?['source'] == 'test' ||
            data['type'] == 'general' && data['title'] == 'إشعار تجريبي';

        if (isTestNotification) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        debugPrint('✅ Deleted $deletedCount test notifications');
      } else {
        debugPrint('ℹ️ No test notifications found to delete');
      }
    } catch (e) {
      debugPrint('❌ Error deleting test notifications: $e');
      throw Exception('خطأ في حذف الإشعارات التجريبية: $e');
    }
  }

  // Delete all test notifications from the system
  Future<void> deleteAllTestNotifications() async {
    try {
      debugPrint('🧹 Cleaning up all test notifications from system');

      final batch = _firestore.batch();
      final testNotifications = await _firestore
          .collection('notifications')
          .get();

      int deletedCount = 0;
      for (var doc in testNotifications.docs) {
        final data = doc.data();

        // Check if it's a test notification
        final isTestNotification =
            data['title']?.toString().contains('تجريبي') == true ||
            data['body']?.toString().contains('تجريبي') == true ||
            data['data']?['source'] == 'test' ||
            data['type'] == 'general' && data['title'] == 'إشعار تجريبي';

        if (isTestNotification) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        debugPrint('✅ Deleted $deletedCount test notifications from system');
      } else {
        debugPrint('ℹ️ No test notifications found in system');
      }
    } catch (e) {
      debugPrint('❌ Error deleting all test notifications: $e');
      throw Exception('خطأ في حذف جميع الإشعارات التجريبية: $e');
    }
  }

  // Format time for notification
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }



  // Mark all notifications as read for user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('✅ All notifications marked as read for user: $userId');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  // Send notification when student arrives at school
  Future<void> sendStudentArrivedAtSchoolNotification({
    required StudentModel student,
    required String supervisorName,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'وصل ${student.name} إلى المدرسة',
        body: 'وصل ${student.name} إلى المدرسة بأمان مع المشرف $supervisorName في ${_formatTime(timestamp)}',
        recipientId: student.parentId,
        studentId: student.id,
        studentName: student.name,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'studentId': student.id,
          'action': 'arrived_at_school',
          'timestamp': timestamp.toIso8601String(),
          'location': 'school',
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار وصول الطالب للمدرسة: $e');
    }
  }

  // ==================== إشعارات شاملة لجميع الأحداث ====================

  // إشعار تسكين طالب في باص
  Future<void> sendStudentBusAssignmentNotification({
    required String studentId,
    required String studentName,
    required String parentId,
    required String busPlateNumber,
    required String supervisorName,
    required String adminName,
  }) async {
    try {
      // إشعار لولي الأمر
      final parentNotification = NotificationModel(
        id: _uuid.v4(),
        title: 'تم تسكين ${studentName} في الباص',
        body: 'تم تسكين ${studentName} في الباص رقم $busPlateNumber مع المشرف $supervisorName',
        recipientId: parentId,
        studentId: studentId,
        studentName: studentName,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: {
          'type': 'bus_assignment',
          'studentId': studentId,
          'busPlateNumber': busPlateNumber,
          'supervisorName': supervisorName,
        },
      );

      await _saveNotification(parentNotification);
      await _sendPushNotification(parentNotification);

      // إشعار للمشرف
      await _sendSupervisorNotification(
        title: 'طالب جديد تم تسكينه',
        body: 'تم تسكين الطالب $studentName في باصك رقم $busPlateNumber',
        data: {
          'type': 'new_student_assigned',
          'studentId': studentId,
          'studentName': studentName,
        },
      );

      // إشعار للإدمن
      await _sendAdminNotification(
        title: 'تم تسكين طالب جديد',
        body: 'تم تسكين $studentName في الباص $busPlateNumber بواسطة $adminName',
        data: {
          'type': 'student_assignment_completed',
          'studentId': studentId,
          'busPlateNumber': busPlateNumber,
          'assignedBy': adminName,
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار تسكين الطالب: $e');
    }
  }

  // إشعار بدء الرحلة
  Future<void> sendTripStartNotification({
    required String supervisorId,
    required String supervisorName,
    required String busPlateNumber,
    required String direction,
    required List<String> studentIds,
  }) async {
    try {
      // إشعار لأولياء الأمور
      for (String studentId in studentIds) {
        final student = await _getStudentById(studentId);
        if (student != null) {
          final parentNotification = NotificationModel(
            id: _uuid.v4(),
            title: 'بدء رحلة الباص',
            body: 'بدأت رحلة الباص رقم $busPlateNumber ${direction == 'toSchool' ? 'إلى المدرسة' : 'إلى المنزل'} مع المشرف $supervisorName',
            recipientId: student.parentId,
            studentId: studentId,
            studentName: student.name,
            type: NotificationType.general,
            timestamp: DateTime.now(),
            data: {
              'type': 'trip_started',
              'direction': direction,
              'busPlateNumber': busPlateNumber,
              'supervisorName': supervisorName,
            },
          );

          await _saveNotification(parentNotification);
          await _sendPushNotification(parentNotification);
        }
      }

      // إشعار للإدمن
      await _sendAdminNotification(
        title: 'بدء رحلة جديدة',
        body: 'بدأ المشرف $supervisorName رحلة الباص $busPlateNumber ${direction == 'toSchool' ? 'إلى المدرسة' : 'إلى المنزل'}',
        data: {
          'type': 'trip_started',
          'supervisorId': supervisorId,
          'busPlateNumber': busPlateNumber,
          'direction': direction,
          'studentsCount': studentIds.length.toString(),
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار بدء الرحلة: $e');
    }
  }

  // إشعار انتهاء الرحلة
  Future<void> sendTripEndNotification({
    required String supervisorId,
    required String supervisorName,
    required String busPlateNumber,
    required String direction,
    required List<String> studentIds,
  }) async {
    try {
      // إشعار لأولياء الأمور
      for (String studentId in studentIds) {
        final student = await _getStudentById(studentId);
        if (student != null) {
          final parentNotification = NotificationModel(
            id: _uuid.v4(),
            title: 'انتهاء رحلة الباص',
            body: 'انتهت رحلة الباص رقم $busPlateNumber ${direction == 'toSchool' ? 'ووصل إلى المدرسة' : 'ووصل إلى المنطقة'}',
            recipientId: student.parentId,
            studentId: studentId,
            studentName: student.name,
            type: NotificationType.general,
            timestamp: DateTime.now(),
            data: {
              'type': 'trip_ended',
              'direction': direction,
              'busPlateNumber': busPlateNumber,
              'supervisorName': supervisorName,
            },
          );

          await _saveNotification(parentNotification);
          await _sendPushNotification(parentNotification);
        }
      }

      // إشعار للإدمن
      await _sendAdminNotification(
        title: 'انتهاء رحلة',
        body: 'انتهى المشرف $supervisorName من رحلة الباص $busPlateNumber ${direction == 'toSchool' ? 'إلى المدرسة' : 'إلى المنزل'}',
        data: {
          'type': 'trip_ended',
          'supervisorId': supervisorId,
          'busPlateNumber': busPlateNumber,
          'direction': direction,
          'studentsCount': studentIds.length.toString(),
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار انتهاء الرحلة: $e');
    }
  }

  // إشعار تغيير حالة الطالب (في الطريق، وصل، إلخ)
  Future<void> sendStudentStatusChangeNotification({
    required String studentId,
    required String studentName,
    required String parentId,
    required String oldStatus,
    required String newStatus,
    required String supervisorName,
  }) async {
    try {
      String statusMessage = _getStatusMessage(newStatus);

      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'تحديث حالة ${studentName}',
        body: '$statusMessage مع المشرف $supervisorName',
        recipientId: parentId,
        studentId: studentId,
        studentName: studentName,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: {
          'type': 'status_change',
          'oldStatus': oldStatus,
          'newStatus': newStatus,
          'supervisorName': supervisorName,
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);

      // إشعار للإدمن عن تغيير الحالة
      await _sendAdminNotification(
        title: 'تحديث حالة طالب',
        body: 'تم تحديث حالة $studentName من $oldStatus إلى $newStatus بواسطة $supervisorName',
        data: {
          'type': 'student_status_updated',
          'studentId': studentId,
          'oldStatus': oldStatus,
          'newStatus': newStatus,
          'supervisorName': supervisorName,
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار تغيير حالة الطالب: $e');
    }
  }

  // إشعار تسكين مشرف في باص
  Future<void> sendSupervisorAssignmentNotification({
    required String supervisorId,
    required String supervisorName,
    required String busId,
    required String busPlateNumber,
    required String adminName,
  }) async {
    try {
      // إشعار للمشرف
      final supervisorNotification = NotificationModel(
        id: _uuid.v4(),
        title: 'تم تسكينك في باص جديد',
        body: 'تم تسكينك في الباص رقم $busPlateNumber بواسطة $adminName',
        recipientId: supervisorId,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: {
          'type': 'supervisor_assignment',
          'busId': busId,
          'busPlateNumber': busPlateNumber,
          'assignedBy': adminName,
        },
      );

      await _saveNotification(supervisorNotification);
      await _sendPushNotification(supervisorNotification);

      // إشعار للإدمن
      await _sendAdminNotification(
        title: 'تم تسكين مشرف',
        body: 'تم تسكين المشرف $supervisorName في الباص $busPlateNumber',
        data: {
          'type': 'supervisor_assignment_completed',
          'supervisorId': supervisorId,
          'busId': busId,
          'assignedBy': adminName,
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار تسكين المشرف: $e');
    }
  }

  // إشعار غياب طالب
  Future<void> sendStudentAbsenceNotification({
    required String studentId,
    required String studentName,
    required String parentId,
    required String reason,
    required DateTime date,
    required String status,
  }) async {
    try {
      String title = status == 'approved' ? 'تم قبول طلب الغياب' :
                    status == 'rejected' ? 'تم رفض طلب الغياب' : 'طلب غياب جديد';

      String body = status == 'approved' ? 'تم قبول طلب غياب $studentName ليوم ${_formatDate(date)}' :
                   status == 'rejected' ? 'تم رفض طلب غياب $studentName ليوم ${_formatDate(date)}' :
                   'تم تسجيل طلب غياب $studentName ليوم ${_formatDate(date)} - السبب: $reason';

      final notification = NotificationModel(
        id: _uuid.v4(),
        title: title,
        body: body,
        recipientId: parentId,
        studentId: studentId,
        studentName: studentName,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: {
          'type': 'absence_notification',
          'status': status,
          'reason': reason,
          'date': date.toIso8601String(),
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);

      // إشعار للإدمن عن طلب الغياب
      if (status == 'pending') {
        await _sendAdminNotification(
          title: 'طلب غياب جديد',
          body: 'طلب غياب جديد للطالب $studentName ليوم ${_formatDate(date)} - السبب: $reason',
          data: {
            'type': 'new_absence_request',
            'studentId': studentId,
            'studentName': studentName,
            'reason': reason,
            'date': date.toIso8601String(),
          },
        );
      }

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار الغياب: $e');
    }
  }

  // إشعار شكوى جديدة
  Future<void> sendComplaintNotification({
    required String complaintId,
    required String title,
    required String description,
    required String parentId,
    required String parentName,
    required String status,
  }) async {
    try {
      // إشعار لولي الأمر
      if (status != 'pending') {
        String statusText = status == 'resolved' ? 'تم حل الشكوى' :
                           status == 'in_progress' ? 'جاري معالجة الشكوى' : 'تم رفض الشكوى';

        final parentNotification = NotificationModel(
          id: _uuid.v4(),
          title: statusText,
          body: 'تم تحديث حالة شكواك: $title',
          recipientId: parentId,
          type: NotificationType.general,
          timestamp: DateTime.now(),
          data: {
            'type': 'complaint_status_update',
            'complaintId': complaintId,
            'status': status,
          },
        );

        await _saveNotification(parentNotification);
        await _sendPushNotification(parentNotification);
      }

      // إشعار للإدمن
      await _sendAdminNotification(
        title: status == 'pending' ? 'شكوى جديدة' : 'تحديث حالة شكوى',
        body: status == 'pending' ? 'شكوى جديدة من $parentName: $title' : 'تم تحديث حالة الشكوى: $title',
        data: {
          'type': status == 'pending' ? 'new_complaint' : 'complaint_updated',
          'complaintId': complaintId,
          'parentName': parentName,
          'status': status,
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار الشكوى: $e');
    }
  }

  // إشعار تحديث معلومات الطالب
  Future<void> sendStudentInfoUpdateNotification({
    required String studentId,
    required String studentName,
    required String parentId,
    required List<String> changes,
  }) async {
    try {
      final changesText = changes.join('\n• ');

      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'تم تحديث معلومات $studentName',
        body: 'تم تحديث المعلومات التالية:\n• $changesText',
        recipientId: parentId,
        studentId: studentId,
        studentName: studentName,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: {
          'type': 'student_info_update',
          'changes': changes,
          'studentId': studentId,
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);

      // إشعار للإدمن
      await _sendAdminNotification(
        title: 'تم تحديث معلومات طالب',
        body: 'تم تحديث معلومات الطالب $studentName',
        data: {
          'type': 'student_info_updated',
          'studentId': studentId,
          'studentName': studentName,
          'changesCount': changes.length.toString(),
        },
      );

    } catch (e) {
      throw Exception('خطأ في إرسال إشعار تحديث معلومات الطالب: $e');
    }
  }

  // ==================== دوال مساعدة للإشعارات ====================

  // إرسال إشعار للمشرفين
  Future<void> _sendSupervisorNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? specificSupervisorId,
  }) async {
    try {
      if (specificSupervisorId != null) {
        // إرسال لمشرف محدد
        final notification = NotificationModel(
          id: _uuid.v4(),
          title: title,
          body: body,
          recipientId: specificSupervisorId,
          type: NotificationType.general,
          timestamp: DateTime.now(),
          data: data,
        );

        await _saveNotification(notification);
        await _sendPushNotification(notification);
      } else {
        // إرسال لجميع المشرفين
        final supervisors = await _getAllSupervisors();
        for (var supervisor in supervisors) {
          final notification = NotificationModel(
            id: _uuid.v4(),
            title: title,
            body: body,
            recipientId: supervisor['id'],
            type: NotificationType.general,
            timestamp: DateTime.now(),
            data: data,
          );

          await _saveNotification(notification);
          await _sendPushNotification(notification);
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending supervisor notification: $e');
    }
  }

  // إرسال إشعار للإدمن
  Future<void> _sendAdminNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final admins = await _getAllAdmins();
      for (var admin in admins) {
        final notification = NotificationModel(
          id: _uuid.v4(),
          title: title,
          body: body,
          recipientId: admin['id'],
          type: NotificationType.general,
          timestamp: DateTime.now(),
          data: data,
        );

        await _saveNotification(notification);
        await _sendPushNotification(notification);
      }
    } catch (e) {
      debugPrint('❌ Error sending admin notification: $e');
    }
  }

  // الحصول على جميع المشرفين
  Future<List<Map<String, dynamic>>> _getAllSupervisors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'supervisor')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting supervisors: $e');
      return [];
    }
  }

  // الحصول على جميع الإدمن
  Future<List<Map<String, dynamic>>> _getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting admins: $e');
      return [];
    }
  }

  // الحصول على بيانات طالب
  Future<StudentModel?> _getStudentById(String studentId) async {
    try {
      final doc = await _firestore.collection('students').doc(studentId).get();
      if (doc.exists) {
        return StudentModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting student: $e');
      return null;
    }
  }

  // تحويل حالة الطالب إلى رسالة
  String _getStatusMessage(String status) {
    switch (status) {
      case 'onBus':
        return 'ركب ${status} الباص';
      case 'atSchool':
        return 'وصل إلى المدرسة';
      case 'leftSchool':
        return 'غادر المدرسة';
      case 'onWayHome':
        return 'في الطريق إلى المنزل';
      case 'arrivedHome':
        return 'وصل إلى المنزل';
      case 'absent':
        return 'غائب اليوم';
      default:
        return 'تم تحديث الحالة';
    }
  }

  // تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Send notification when student arrives at home
  Future<void> sendStudentArrivedAtHomeNotification({
    required StudentModel student,
    required String supervisorName,
    required DateTime timestamp,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: 'وصل ${student.name} إلى المنزل',
        body: 'وصل ${student.name} إلى المنزل بأمان مع المشرف $supervisorName في ${_formatTime(timestamp)}',
        recipientId: student.parentId,
        studentId: student.id,
        studentName: student.name,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'studentId': student.id,
          'action': 'arrived_at_home',
          'timestamp': timestamp.toIso8601String(),
          'location': 'home',
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار وصول الطالب للمنزل: $e');
    }
  }

  // Send notification when student is on bus
  Future<void> sendStudentOnBusNotification({
    required StudentModel student,
    required String supervisorName,
    required DateTime timestamp,
    required String busRoute,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: '${student.name} في الباص',
        body: '${student.name} الآن في الباص (خط $busRoute) مع المشرف $supervisorName في ${_formatTime(timestamp)}',
        recipientId: student.parentId,
        studentId: student.id,
        studentName: student.name,
        type: NotificationType.general,
        timestamp: timestamp,
        data: {
          'studentId': student.id,
          'action': 'on_bus',
          'timestamp': timestamp.toIso8601String(),
          'location': 'bus',
          'busRoute': busRoute,
        },
      );

      await _saveNotification(notification);
      await _sendPushNotification(notification);
    } catch (e) {
      throw Exception('خطأ في إرسال إشعار وجود الطالب في الباص: $e');
    }
  }

  // ==================== إشعارات محسنة مع الصوت ====================

  /// إشعار تسكين الطالب مع الصوت
  Future<void> notifyStudentAssignmentWithSound({
    required String studentId,
    required String studentName,
    required String busId,
    required String busRoute,
    required String parentId,
    required String supervisorId,
  }) async {
    await _enhancedService.notifyStudentAssignment(
      studentId: studentId,
      studentName: studentName,
      busId: busId,
      busRoute: busRoute,
      parentId: parentId,
      supervisorId: supervisorId,
    );
  }

  /// إشعار إلغاء تسكين الطالب مع الصوت
  Future<void> notifyStudentUnassignmentWithSound({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
  }) async {
    await _enhancedService.notifyStudentUnassignment(
      studentId: studentId,
      studentName: studentName,
      busId: busId,
      parentId: parentId,
      supervisorId: supervisorId,
    );
  }

  /// إشعار ركوب الطالب مع الصوت
  Future<void> notifyStudentBoardedWithSound({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
  }) async {
    await _enhancedService.notifyStudentBoarded(
      studentId: studentId,
      studentName: studentName,
      busId: busId,
      parentId: parentId,
      supervisorId: supervisorId,
      timestamp: DateTime.now(),
    );
  }

  /// إشعار نزول الطالب مع الصوت
  Future<void> notifyStudentAlightedWithSound({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
  }) async {
    await _enhancedService.notifyStudentAlighted(
      studentId: studentId,
      studentName: studentName,
      busId: busId,
      parentId: parentId,
      supervisorId: supervisorId,
      timestamp: DateTime.now(),
    );
  }

  /// إشعار طلب غياب مع الصوت
  Future<void> notifyAbsenceRequestWithSound({
    required String studentId,
    required String studentName,
    required String parentId,
    required String supervisorId,
    required String busId,
    required DateTime absenceDate,
    required String reason,
  }) async {
    await _enhancedService.notifyAbsenceRequest(
      studentId: studentId,
      studentName: studentName,
      parentId: parentId,
      supervisorId: supervisorId,
      busId: busId,
      absenceDate: absenceDate,
      reason: reason,
    );
  }

  /// إشعار الموافقة على الغياب مع الصوت
  Future<void> notifyAbsenceApprovedWithSound({
    required String studentId,
    required String studentName,
    required String parentId,
    required DateTime absenceDate,
    required String approvedBy,
  }) async {
    await _enhancedService.notifyAbsenceApproved(
      studentId: studentId,
      studentName: studentName,
      parentId: parentId,
      absenceDate: absenceDate,
      approvedBy: approvedBy,
    );
  }

  /// إشعار رفض الغياب مع الصوت
  Future<void> notifyAbsenceRejectedWithSound({
    required String studentId,
    required String studentName,
    required String parentId,
    required DateTime absenceDate,
    required String rejectedBy,
    required String reason,
  }) async {
    await _enhancedService.notifyAbsenceRejected(
      studentId: studentId,
      studentName: studentName,
      parentId: parentId,
      absenceDate: absenceDate,
      rejectedBy: rejectedBy,
      reason: reason,
    );
  }

  /// إشعار شكوى جديدة مع الصوت
  Future<void> notifyNewComplaintWithSound({
    required String complaintId,
    required String parentId,
    required String parentName,
    required String subject,
    required String category,
  }) async {
    await _enhancedService.notifyNewComplaint(
      complaintId: complaintId,
      parentId: parentId,
      parentName: parentName,
      subject: subject,
      category: category,
    );
  }

  /// إشعار رد على الشكوى مع الصوت
  Future<void> notifyComplaintResponseWithSound({
    required String complaintId,
    required String parentId,
    required String subject,
    required String response,
  }) async {
    await _enhancedService.notifyComplaintResponse(
      complaintId: complaintId,
      parentId: parentId,
      subject: subject,
      response: response,
    );
  }

  /// إشعار تحديث حالة الرحلة مع الصوت
  Future<void> notifyTripStatusUpdateWithSound({
    required String busId,
    required String busRoute,
    required String status,
    required List<String> parentIds,
    required String supervisorId,
  }) async {
    await _enhancedService.notifyTripStatusUpdate(
      busId: busId,
      busRoute: busRoute,
      status: status,
      parentIds: parentIds,
      supervisorId: supervisorId,
    );
  }

  /// إشعار طوارئ مع الصوت
  Future<void> notifyEmergencyWithSound({
    required String busId,
    required String supervisorId,
    required String supervisorName,
    required String emergencyType,
    required String description,
    required List<String> parentIds,
  }) async {
    await _enhancedService.notifyEmergency(
      busId: busId,
      supervisorId: supervisorId,
      supervisorName: supervisorName,
      emergencyType: emergencyType,
      description: description,
      parentIds: parentIds,
    );
  }

  /// حفظ FCM token للمستخدم
  Future<void> saveFCMTokenForUser(String userId) async {
    await _enhancedService.saveFCMToken(userId);
  }

  /// الحصول على الإشعارات غير المقروءة
  Stream<List<NotificationModel>> getUnreadNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  /// تحديد الإشعار كمقروء (دالة محسنة)
  Future<void> markNotificationAsReadEnhanced(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// حذف الإشعار
  Future<void> deleteNotificationById(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }
}
