import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/student_model.dart';


class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Initialize notifications
  Future<void> initialize() async {
    // Skip initialization on web to avoid service worker issues
    if (kIsWeb) {
      debugPrint('Notification service skipped on web platform');
      return;
    }

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

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');
    // Handle the message when app is in foreground
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Received background message: ${message.notification?.title}');
    // Handle the message when app is in background
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

  // Send push notification
  Future<void> _sendPushNotification(NotificationModel notification) async {
    try {
      // حفظ الإشعار في قائمة انتظار FCM
      await _firestore.collection('fcm_queue').add({
        'recipientId': notification.recipientId,
        'title': notification.title,
        'body': notification.body,
        'data': notification.data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': notification.type.toString().split('.').last,
      });

      debugPrint('✅ Push notification queued: ${notification.title}');
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
}
