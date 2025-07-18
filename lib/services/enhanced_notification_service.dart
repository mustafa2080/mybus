import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';

// تعريف UserRole للتوافق مع الكود
enum UserRole {
  parent,
  supervisor,
  admin,
}

/// خدمة الإشعارات المحسنة مع الصوت والإشعارات المحلية
class EnhancedNotificationService {
  static final EnhancedNotificationService _instance = EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  bool _isInitialized = false;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();
      
      // تهيئة Firebase Messaging
      await _initializeFirebaseMessaging();
      
      _isInitialized = true;
      debugPrint('✅ Enhanced Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  /// تهيئة الإشعارات المحلية
  Future<void> _initializeLocalNotifications() async {
    // إعدادات Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    
    // إعدادات iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // إنشاء قناة الإشعارات لـ Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// إنشاء قنوات الإشعارات
  Future<void> _createNotificationChannels() async {
    final List<AndroidNotificationChannel> channels = [
      // قناة الإشعارات الرئيسية (متطابقة مع AndroidManifest)
      const AndroidNotificationChannel(
        'mybus_notifications',
        'إشعارات MyBus',
        description: 'إشعارات عامة لتطبيق MyBus',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      // قناة إشعارات الطلاب
      const AndroidNotificationChannel(
        'student_notifications',
        'إشعارات الطلاب',
        description: 'إشعارات متعلقة بالطلاب وأنشطتهم',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      // قناة إشعارات الباص
      const AndroidNotificationChannel(
        'bus_notifications',
        'إشعارات الباص',
        description: 'إشعارات ركوب ونزول الباص',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      // قناة إشعارات الغياب
      const AndroidNotificationChannel(
        'absence_notifications',
        'إشعارات الغياب',
        description: 'إشعارات طلبات الغياب',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      // قناة إشعارات الإدارة
      const AndroidNotificationChannel(
        'admin_notifications',
        'إشعارات الإدارة',
        description: 'إشعارات خاصة بالإدارة',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// تهيئة Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    if (kIsWeb) return;

    // طلب الأذونات
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    // الحصول على FCM token
    String? token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // معالجة الرسائل في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // معالجة الرسائل في الخلفية
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // معالجة النقر على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// معالجة الرسائل في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    
    // عرض الإشعار المحلي
    await _showLocalNotification(
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
      channelId: _getChannelId(message.data['type']),
    );
  }

  /// معالجة الرسائل في الخلفية
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Received background message: ${message.messageId}');
    // سيتم معالجة الإشعار تلقائياً بواسطة النظام
  }

  /// معالجة النقر على الإشعار
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped: ${message.messageId}');
    // يمكن إضافة منطق التنقل هنا
  }

  /// معالجة النقر على الإشعار المحلي
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // يمكن إضافة منطق التنقل هنا
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'mybus_notifications',
  }) async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification',
      color: const Color(0xFFFF6B6B),
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      autoCancel: true,
      ongoing: false,
      silent: false,
      channelShowBadge: true,
      onlyAlertOnce: false,
      visibility: NotificationVisibility.public,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.mp3',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// الحصول على معرف القناة بناءً على نوع الإشعار
  String _getChannelId(String? type) {
    switch (type) {
      case 'student':
        return 'student_notifications';
      case 'bus':
        return 'bus_notifications';
      case 'absence':
        return 'absence_notifications';
      case 'admin':
        return 'admin_notifications';
      default:
        return 'mybus_notifications';
    }
  }

  /// الحصول على اسم القناة
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'student_notifications':
        return 'إشعارات الطلاب';
      case 'bus_notifications':
        return 'إشعارات الباص';
      case 'absence_notifications':
        return 'إشعارات الغياب';
      case 'admin_notifications':
        return 'إشعارات الإدارة';
      default:
        return 'إشعارات MyBus';
    }
  }

  /// الحصول على وصف القناة
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'student_notifications':
        return 'إشعارات متعلقة بالطلاب وأنشطتهم';
      case 'bus_notifications':
        return 'إشعارات ركوب ونزول الباص';
      case 'absence_notifications':
        return 'إشعارات طلبات الغياب';
      case 'admin_notifications':
        return 'إشعارات خاصة بالإدارة';
      default:
        return 'إشعارات عامة لتطبيق MyBus';
    }
  }

  /// إرسال إشعار لمستخدم محدد
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      // حفظ الإشعار في قاعدة البيانات
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: title,
        body: body,
        recipientId: userId,
        type: NotificationType.general,
        timestamp: DateTime.now(),
        data: data ?? {},
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      // إرسال الإشعار عبر FCM
      await _sendFCMNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );

      debugPrint('✅ Notification sent to user: $userId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// إرسال إشعار FCM
  Future<void> _sendFCMNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      // الحصول على FCM token للمستخدم
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        debugPrint('No FCM token found for user: $userId');
        return;
      }

      // إعداد بيانات الإشعار
      final notificationData = {
        'title': title,
        'body': body,
        'type': type,
        'sound': 'notification_sound.mp3',
        'channel_id': _getChannelId(type),
        ...?data,
      };

      // هنا يمكن استخدام HTTP API لإرسال الإشعار
      // أو استخدام Firebase Functions
      debugPrint('FCM notification prepared for: $fcmToken');
    } catch (e) {
      debugPrint('❌ Error sending FCM notification: $e');
    }
  }

  /// إرسال إشعار لمجموعة من المستخدمين
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    for (final userId in userIds) {
      await sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );
    }
  }

  /// إرسال إشعار لجميع المستخدمين من نوع معين
  Future<void> sendNotificationToUserType({
    required UserRole userType,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: userType.toString().split('.').last)
          .get();

      final userIds = usersQuery.docs.map((doc) => doc.id).toList();

      await sendNotificationToUsers(
        userIds: userIds,
        title: title,
        body: body,
        type: type,
        data: data,
      );
    } catch (e) {
      debugPrint('❌ Error sending notification to user type: $e');
    }
  }

  /// حفظ FCM token للمستخدم
  Future<void> saveFCMToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// الحصول على الإشعارات غير المقروءة للمستخدم
  Stream<List<NotificationModel>> getUnreadNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  /// تحديد الإشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
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
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  // ==================== إشعارات متخصصة ====================

  /// إشعار تسكين الطالب
  Future<void> notifyStudentAssignment({
    required String studentId,
    required String studentName,
    required String busId,
    required String busRoute,
    required String parentId,
    required String supervisorId,
  }) async {
    // إشعار ولي الأمر
    await sendNotificationToUser(
      userId: parentId,
      title: '🚌 تم تسكين الطالب',
      body: 'تم تسكين $studentName في الباص رقم $busId - خط السير: $busRoute',
      type: 'student',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_assigned',
      },
    );

    // إشعار المشرف
    await sendNotificationToUser(
      userId: supervisorId,
      title: '👨‍🏫 طالب جديد في الباص',
      body: 'تم إضافة الطالب $studentName إلى باصك',
      type: 'student',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_assigned',
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '📋 تم تسكين طالب',
      body: 'تم تسكين $studentName في الباص $busId',
      type: 'admin',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_assigned',
      },
    );
  }

  /// إشعار إلغاء تسكين الطالب
  Future<void> notifyStudentUnassignment({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
  }) async {
    // إشعار ولي الأمر
    await sendNotificationToUser(
      userId: parentId,
      title: '🚫 تم إلغاء تسكين الطالب',
      body: 'تم إلغاء تسكين $studentName من الباص رقم $busId',
      type: 'student',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_unassigned',
      },
    );

    // إشعار المشرف
    await sendNotificationToUser(
      userId: supervisorId,
      title: '👋 مغادرة طالب',
      body: 'تم إزالة الطالب $studentName من باصك',
      type: 'student',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_unassigned',
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '📋 تم إلغاء تسكين طالب',
      body: 'تم إلغاء تسكين $studentName من الباص $busId',
      type: 'admin',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_unassigned',
      },
    );
  }

  /// إشعار ركوب الطالب الباص
  Future<void> notifyStudentBoarded({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
    required DateTime timestamp,
  }) async {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    // إشعار ولي الأمر
    await sendNotificationToUser(
      userId: parentId,
      title: '🚌 ركب الطالب الباص',
      body: '$studentName ركب الباص في الساعة $timeStr',
      type: 'bus',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_boarded',
        'timestamp': timestamp.toIso8601String(),
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '🚌 ركوب طالب',
      body: '$studentName ركب الباص $busId في $timeStr',
      type: 'bus',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_boarded',
        'timestamp': timestamp.toIso8601String(),
      },
    );
  }

  /// إشعار نزول الطالب من الباص
  Future<void> notifyStudentAlighted({
    required String studentId,
    required String studentName,
    required String busId,
    required String parentId,
    required String supervisorId,
    required DateTime timestamp,
  }) async {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    // إشعار ولي الأمر
    await sendNotificationToUser(
      userId: parentId,
      title: '🏠 نزل الطالب من الباص',
      body: '$studentName نزل من الباص في الساعة $timeStr',
      type: 'bus',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_alighted',
        'timestamp': timestamp.toIso8601String(),
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '🏠 نزول طالب',
      body: '$studentName نزل من الباص $busId في $timeStr',
      type: 'bus',
      data: {
        'studentId': studentId,
        'busId': busId,
        'action': 'student_alighted',
        'timestamp': timestamp.toIso8601String(),
      },
    );
  }

  /// إشعار طلب غياب
  Future<void> notifyAbsenceRequest({
    required String studentId,
    required String studentName,
    required String parentId,
    required String supervisorId,
    required String busId,
    required DateTime absenceDate,
    required String reason,
  }) async {
    final dateStr = '${absenceDate.day}/${absenceDate.month}/${absenceDate.year}';

    // إشعار المشرف
    await sendNotificationToUser(
      userId: supervisorId,
      title: '📝 طلب غياب جديد',
      body: 'طلب غياب للطالب $studentName بتاريخ $dateStr',
      type: 'absence',
      data: {
        'studentId': studentId,
        'parentId': parentId,
        'absenceDate': absenceDate.toIso8601String(),
        'action': 'absence_requested',
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '📝 طلب غياب جديد',
      body: 'طلب غياب للطالب $studentName من الباص $busId بتاريخ $dateStr',
      type: 'absence',
      data: {
        'studentId': studentId,
        'parentId': parentId,
        'busId': busId,
        'absenceDate': absenceDate.toIso8601String(),
        'reason': reason,
        'action': 'absence_requested',
      },
    );
  }

  /// إشعار الموافقة على طلب الغياب
  Future<void> notifyAbsenceApproved({
    required String studentId,
    required String studentName,
    required String parentId,
    required DateTime absenceDate,
    required String approvedBy,
  }) async {
    final dateStr = '${absenceDate.day}/${absenceDate.month}/${absenceDate.year}';

    // إشعار ولي الأمر
    await sendNotificationToUser(
      userId: parentId,
      title: '✅ تم قبول طلب الغياب',
      body: 'تم قبول طلب غياب $studentName بتاريخ $dateStr',
      type: 'absence',
      data: {
        'studentId': studentId,
        'absenceDate': absenceDate.toIso8601String(),
        'action': 'absence_approved',
        'approvedBy': approvedBy,
      },
    );
  }

  /// إشعار رفض طلب الغياب
  Future<void> notifyAbsenceRejected({
    required String studentId,
    required String studentName,
    required String parentId,
    required DateTime absenceDate,
    required String rejectedBy,
    required String reason,
  }) async {
    final dateStr = '${absenceDate.day}/${absenceDate.month}/${absenceDate.year}';

    // إشعار ولي الأمر
    await sendNotificationToUser(
      userId: parentId,
      title: '❌ تم رفض طلب الغياب',
      body: 'تم رفض طلب غياب $studentName بتاريخ $dateStr - السبب: $reason',
      type: 'absence',
      data: {
        'studentId': studentId,
        'absenceDate': absenceDate.toIso8601String(),
        'action': 'absence_rejected',
        'rejectedBy': rejectedBy,
        'reason': reason,
      },
    );
  }

  /// إشعار شكوى جديدة
  Future<void> notifyNewComplaint({
    required String complaintId,
    required String parentId,
    required String parentName,
    required String subject,
    required String category,
  }) async {
    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '📢 شكوى جديدة',
      body: 'شكوى جديدة من $parentName - الموضوع: $subject',
      type: 'admin',
      data: {
        'complaintId': complaintId,
        'parentId': parentId,
        'category': category,
        'action': 'complaint_submitted',
      },
    );
  }

  /// إشعار رد على الشكوى
  Future<void> notifyComplaintResponse({
    required String complaintId,
    required String parentId,
    required String subject,
    required String response,
  }) async {
    // إشعار ولي الأمر
    await sendNotificationToUser(
      userId: parentId,
      title: '💬 رد على الشكوى',
      body: 'تم الرد على شكواك: $subject',
      type: 'general',
      data: {
        'complaintId': complaintId,
        'action': 'complaint_responded',
      },
    );
  }

  /// إشعار تحديث حالة الرحلة
  Future<void> notifyTripStatusUpdate({
    required String busId,
    required String busRoute,
    required String status,
    required List<String> parentIds,
    required String supervisorId,
  }) async {
    String statusText;
    String emoji;

    switch (status) {
      case 'started':
        statusText = 'بدأت الرحلة';
        emoji = '🚌';
        break;
      case 'completed':
        statusText = 'انتهت الرحلة';
        emoji = '✅';
        break;
      case 'delayed':
        statusText = 'تأخرت الرحلة';
        emoji = '⏰';
        break;
      default:
        statusText = 'تحديث حالة الرحلة';
        emoji = '📍';
    }

    // إشعار أولياء الأمور
    await sendNotificationToUsers(
      userIds: parentIds,
      title: '$emoji $statusText',
      body: 'الباص $busId - خط السير: $busRoute',
      type: 'bus',
      data: {
        'busId': busId,
        'status': status,
        'action': 'trip_status_update',
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '$emoji تحديث حالة الرحلة',
      body: 'الباص $busId - $statusText',
      type: 'admin',
      data: {
        'busId': busId,
        'status': status,
        'supervisorId': supervisorId,
        'action': 'trip_status_update',
      },
    );
  }

  /// إشعار طوارئ
  Future<void> notifyEmergency({
    required String busId,
    required String supervisorId,
    required String supervisorName,
    required String emergencyType,
    required String description,
    required List<String> parentIds,
  }) async {
    // إشعار أولياء الأمور
    await sendNotificationToUsers(
      userIds: parentIds,
      title: '🚨 حالة طوارئ',
      body: 'حالة طوارئ في الباص $busId - $emergencyType',
      type: 'admin',
      data: {
        'busId': busId,
        'supervisorId': supervisorId,
        'emergencyType': emergencyType,
        'action': 'emergency',
      },
    );

    // إشعار الإدارة
    await sendNotificationToUserType(
      userType: UserRole.admin,
      title: '🚨 حالة طوارئ',
      body: 'حالة طوارئ من المشرف $supervisorName في الباص $busId',
      type: 'admin',
      data: {
        'busId': busId,
        'supervisorId': supervisorId,
        'emergencyType': emergencyType,
        'description': description,
        'action': 'emergency',
      },
    );
  }

  /// إشعار تحديث بيانات الطالب لولي الأمر والمشرف
  Future<void> notifyStudentDataUpdate({
    required String studentId,
    required String studentName,
    required String parentId,
    required String busId,
    required Map<String, dynamic> updatedFields,
    required String adminName,
  }) async {
    try {
      debugPrint('🔔 Sending student data update notifications for: $studentName');

      // إنشاء رسالة التحديث
      final updatedFieldsText = _formatUpdatedFields(updatedFields);

      // إشعار ولي الأمر
      await _notifyParentOfStudentUpdate(
        parentId: parentId,
        studentName: studentName,
        updatedFields: updatedFieldsText,
        adminName: adminName,
      );

      // إشعار المشرف (إذا كان الطالب مسكن في باص)
      if (busId.isNotEmpty) {
        await _notifySupervisorOfStudentUpdate(
          busId: busId,
          studentName: studentName,
          updatedFields: updatedFieldsText,
          adminName: adminName,
        );
      }

      debugPrint('✅ Student data update notifications sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending student data update notifications: $e');
    }
  }

  /// إشعار ولي الأمر بتحديث بيانات الطالب
  Future<void> _notifyParentOfStudentUpdate({
    required String parentId,
    required String studentName,
    required String updatedFields,
    required String adminName,
  }) async {
    try {
      final title = 'تحديث بيانات الطالب';
      final body = 'تم تحديث بيانات الطالب $studentName من قبل الإدارة\n\nالتحديثات:\n$updatedFields';

      await sendNotificationToUser(
        userId: parentId,
        title: title,
        body: body,
        type: 'student',
        data: {
          'type': 'student_data_update',
          'studentName': studentName,
          'updatedBy': adminName,
          'updatedFields': updatedFields,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Parent notification sent for student data update');
    } catch (e) {
      debugPrint('❌ Error sending parent notification: $e');
    }
  }

  /// إشعار المشرف بتحديث بيانات الطالب
  Future<void> _notifySupervisorOfStudentUpdate({
    required String busId,
    required String studentName,
    required String updatedFields,
    required String adminName,
  }) async {
    try {
      // الحصول على المشرف المسؤول عن الباص
      final supervisorId = await _getActiveSupervisorForBus(busId);

      if (supervisorId != null) {
        final title = 'تحديث بيانات طالب في الباص';
        final body = 'تم تحديث بيانات الطالب $studentName في الباص الخاص بك\n\nالتحديثات:\n$updatedFields';

        await sendNotificationToUser(
          userId: supervisorId,
          title: title,
          body: body,
          type: 'student',
          data: {
            'type': 'student_data_update',
            'studentName': studentName,
            'busId': busId,
            'updatedBy': adminName,
            'updatedFields': updatedFields,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        debugPrint('✅ Supervisor notification sent for student data update');
      } else {
        debugPrint('⚠️ No active supervisor found for bus: $busId');
      }
    } catch (e) {
      debugPrint('❌ Error sending supervisor notification: $e');
    }
  }

  /// الحصول على المشرف النشط للباص
  Future<String?> _getActiveSupervisorForBus(String busId) async {
    try {
      final querySnapshot = await _firestore
          .collection('supervisor_assignments')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['supervisorId'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting active supervisor for bus: $e');
      return null;
    }
  }

  /// تنسيق الحقول المحدثة لعرضها في الإشعار
  String _formatUpdatedFields(Map<String, dynamic> updatedFields) {
    final List<String> formattedFields = [];

    updatedFields.forEach((key, value) {
      final fieldName = _getFieldDisplayName(key);
      final oldValue = value['old']?.toString() ?? 'غير محدد';
      final newValue = value['new']?.toString() ?? 'غير محدد';

      if (oldValue != newValue) {
        formattedFields.add('• $fieldName: من "$oldValue" إلى "$newValue"');
      }
    });

    return formattedFields.isEmpty ? 'لا توجد تغييرات' : formattedFields.join('\n');
  }

  /// الحصول على اسم الحقل باللغة العربية
  String _getFieldDisplayName(String fieldKey) {
    switch (fieldKey) {
      case 'name':
        return 'اسم الطالب';
      case 'schoolName':
        return 'اسم المدرسة';
      case 'grade':
        return 'الصف';
      case 'busId':
        return 'الباص المخصص';
      case 'parentName':
        return 'اسم ولي الأمر';
      case 'parentPhone':
        return 'رقم هاتف ولي الأمر';
      case 'address':
        return 'العنوان';
      case 'notes':
        return 'ملاحظات';
      case 'currentStatus':
        return 'الحالة الحالية';
      default:
        return fieldKey;
    }
  }
}
