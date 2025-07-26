import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../models/notification_settings_model.dart';

/// خدمة Firebase Cloud Messaging المتقدمة
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  String? _fcmToken;
  NotificationSettingsModel? _userSettings;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 بدء تهيئة خدمة الإشعارات...');

      // طلب الأذونات
      await _requestPermissions();

      // تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();

      // تهيئة Firebase Messaging
      await _initializeFirebaseMessaging();

      // الحصول على FCM Token
      await _getFCMToken();

      // إعداد معالجات الرسائل
      _setupMessageHandlers();

      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة الإشعارات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
      rethrow;
    }
  }

  /// طلب الأذونات المطلوبة
  Future<void> _requestPermissions() async {
    // أذونات Firebase Messaging
    final NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔐 حالة أذونات الإشعارات: ${settings.authorizationStatus}');

    // أذونات إضافية للأندرويد
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
    }
  }

  /// تهيئة الإشعارات المحلية
  Future<void> _initializeLocalNotifications() async {
    // إعدادات الأندرويد
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // إنشاء قنوات الإشعارات للأندرويد
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// إنشاء قنوات الإشعارات للأندرويد
  Future<void> _createNotificationChannels() async {
    final List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel(
        'high_priority_channel',
        'إشعارات عالية الأولوية',
        description: 'إشعارات مهمة تتطلب انتباه فوري',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        'medium_priority_channel',
        'إشعارات متوسطة الأولوية',
        description: 'إشعارات عادية',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: false,
      ),
      const AndroidNotificationChannel(
        'low_priority_channel',
        'إشعارات منخفضة الأولوية',
        description: 'إشعارات غير عاجلة',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
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
    // تفعيل التسليم التلقائي للرسائل (iOS)
    await _firebaseMessaging.setAutoInitEnabled(true);

    // إعدادات المقدمة
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// الحصول على FCM Token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $_fcmToken');

      // حفظ التوكن في قاعدة البيانات
      await _saveFCMToken();

      // مراقبة تحديث التوكن
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveFCMToken();
        debugPrint('🔄 تم تحديث FCM Token: $newToken');
      });
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على FCM Token: $e');
    }
  }

  /// حفظ FCM Token في قاعدة البيانات
  Future<void> _saveFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null || _fcmToken == null) return;

      await _firestore.collection('user_tokens').doc(user.uid).set({
        'fcmToken': _fcmToken,
        'platform': Platform.operatingSystem,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ تم حفظ FCM Token في قاعدة البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ FCM Token: $e');
    }
  }

  /// إعداد معالجات الرسائل
  void _setupMessageHandlers() {
    // معالج الرسائل في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ملاحظة: معالج الخلفية مسجل في main.dart
    // FirebaseMessaging.onBackgroundMessage يجب أن يكون في المستوى الأعلى

    // معالج فتح التطبيق من الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // معالج فتح التطبيق من الإشعار (التطبيق مغلق)
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageOpenedApp(message);
      }
    });
  }

  /// معالج الرسائل في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 استلام رسالة في المقدمة: ${message.messageId}');

    try {
      // تحويل الرسالة إلى نموذج إشعار
      final notification = _parseRemoteMessage(message);
      
      // التحقق من إعدادات المستخدم
      if (!await _canShowNotification(notification)) {
        debugPrint('🔇 تم تجاهل الإشعار بناءً على إعدادات المستخدم');
        return;
      }

      // عرض الإشعار المحلي
      await _showLocalNotification(notification, message);

      // تشغيل الصوت إذا كان مطلوباً
      if (notification.shouldPlaySound) {
        await _playNotificationSound(notification);
      }

      // حفظ الإشعار في قاعدة البيانات
      await _saveNotificationToDatabase(notification.copyWith(
        status: NotificationStatus.delivered,
        sentAt: DateTime.now(),
      ));

    } catch (e) {
      debugPrint('❌ خطأ في معالجة رسالة المقدمة: $e');
    }
  }

  /// معالج الرسائل في الخلفية (دالة عامة)
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('📱 معالجة إشعار في الخلفية: ${message.messageId}');

    try {
      // حفظ الإشعار في قاعدة البيانات
      final firestore = FirebaseFirestore.instance;

      final notificationData = {
        'messageId': message.messageId,
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'receivedAt': FieldValue.serverTimestamp(),
        'status': 'delivered_background',
        'recipientId': message.data['recipientId'] ?? '',
        'type': message.data['type'] ?? 'general',
        'priority': message.data['priority'] ?? 'medium',
      };

      await firestore.collection('notifications').add(notificationData);
      print('✅ تم حفظ الإشعار في قاعدة البيانات');

      // ملاحظة: الإشعار سيظهر تلقائياً في شريط الإشعارات
      // بواسطة Firebase Messaging بدون تدخل إضافي

    } catch (e) {
      print('❌ خطأ في معالجة رسالة الخلفية: $e');
    }
  }

  /// معالج فتح التطبيق من الإشعار
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('📱 فتح التطبيق من الإشعار: ${message.messageId}');

    try {
      // تحديث حالة الإشعار إلى مقروء
      final notification = _parseRemoteMessage(message);
      await _markNotificationAsRead(notification.id);

      // التنقل إلى الشاشة المناسبة بناءً على نوع الإشعار
      await _navigateBasedOnNotification(notification);

    } catch (e) {
      debugPrint('❌ خطأ في معالجة فتح التطبيق: $e');
    }
  }

  /// معالج النقر على الإشعار المحلي
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 تم النقر على الإشعار المحلي: ${response.id}');

    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        final notification = NotificationModel.fromMap(data);
        
        // تحديث حالة الإشعار
        _markNotificationAsRead(notification.id);
        
        // التنقل
        _navigateBasedOnNotification(notification);
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة النقر على الإشعار: $e');
    }
  }

  /// تحويل RemoteMessage إلى NotificationModel
  NotificationModel _parseRemoteMessage(RemoteMessage message) {
    final data = message.data;

    return NotificationModel(
      id: data['id'] ?? message.messageId ?? '',
      title: message.notification?.title ?? data['title'] ?? '',
      body: message.notification?.body ?? data['body'] ?? '',
      type: NotificationModel.parseNotificationType(data['type']),
      priority: NotificationModel.parseNotificationPriority(data['priority']),
      recipientId: data['recipientId'] ?? '',
      recipientType: data['recipientType'] ?? '',
      senderId: data['senderId'],
      senderName: data['senderName'],
      data: data,
      channels: [NotificationChannel.fcm],
      requiresSound: data['requiresSound'] == 'true',
      requiresVibration: data['requiresVibration'] == 'true',
      isBackground: data['isBackground'] == 'true',
      createdAt: DateTime.now(),
    );
  }

  /// التحقق من إمكانية عرض الإشعار
  Future<bool> _canShowNotification(NotificationModel notification) async {
    try {
      // تحميل إعدادات المستخدم إذا لم تكن محملة
      if (_userSettings == null) {
        await _loadUserSettings();
      }

      // التحقق من الإعدادات
      return _userSettings?.canSendNotification(notification) ?? true;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من إعدادات الإشعار: $e');
      return true; // السماح بالإشعار في حالة الخطأ
    }
  }

  /// تحميل إعدادات المستخدم
  Future<void> _loadUserSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('notification_settings').doc(user.uid).get();

      if (doc.exists) {
        _userSettings = NotificationSettingsModel.fromMap(doc.data()!);
      } else {
        // إنشاء إعدادات افتراضية
        final userData = await _firestore.collection('users').doc(user.uid).get();
        final userType = userData.data()?['userType'] ?? 'parent';

        _userSettings = NotificationSettingsModel.createDefault(
          userId: user.uid,
          userType: userType,
          fcmToken: _fcmToken ?? '',
        );

        // حفظ الإعدادات الافتراضية
        await _firestore.collection('notification_settings').doc(user.uid).set(_userSettings!.toMap());
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل إعدادات المستخدم: $e');
    }
  }

  /// عرض الإشعار المحلي
  Future<void> _showLocalNotification(NotificationModel notification, RemoteMessage message) async {
    try {
      // تحديد قناة الإشعار بناءً على الأولوية
      String channelId;
      switch (notification.priority) {
        case NotificationPriority.urgent:
        case NotificationPriority.high:
          channelId = 'high_priority_channel';
          break;
        case NotificationPriority.medium:
          channelId = 'medium_priority_channel';
          break;
        case NotificationPriority.low:
          channelId = 'low_priority_channel';
          break;
      }

      // إعدادات الأندرويد
      final androidDetails = AndroidNotificationDetails(
        channelId,
        'إشعارات كيدز باص',
        channelDescription: 'إشعارات تطبيق كيدز باص',
        importance: _getImportance(notification.priority),
        priority: _getPriority(notification.priority),
        playSound: notification.shouldPlaySound && (_userSettings?.soundEnabled ?? true),
        enableVibration: notification.shouldVibrate && (_userSettings?.vibrationEnabled ?? true),
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          notification.body,
          contentTitle: notification.title,
          summaryText: 'كيدز باص',
        ),
      );

      // إعدادات iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // عرض الإشعار
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: jsonEncode(notification.toMap()),
      );

      debugPrint('✅ تم عرض الإشعار المحلي: ${notification.title}');
    } catch (e) {
      debugPrint('❌ خطأ في عرض الإشعار المحلي: $e');
    }
  }

  /// تشغيل صوت الإشعار
  Future<void> _playNotificationSound(NotificationModel notification) async {
    try {
      if (!(_userSettings?.soundEnabled ?? true)) return;

      // تحديد ملف الصوت بناءً على الأولوية
      String soundFile;
      switch (notification.priority) {
        case NotificationPriority.urgent:
          soundFile = 'sounds/urgent_notification.mp3';
          break;
        case NotificationPriority.high:
          soundFile = 'sounds/high_notification.mp3';
          break;
        default:
          soundFile = 'sounds/default_notification.mp3';
          break;
      }

      // تشغيل الصوت
      await _audioPlayer.play(AssetSource(soundFile));
      debugPrint('🔊 تم تشغيل صوت الإشعار: $soundFile');
    } catch (e) {
      debugPrint('❌ خطأ في تشغيل صوت الإشعار: $e');
    }
  }

  /// حفظ الإشعار في قاعدة البيانات
  Future<void> _saveNotificationToDatabase(NotificationModel notification) async {
    try {
      await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
      debugPrint('✅ تم حفظ الإشعار في قاعدة البيانات: ${notification.id}');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الإشعار: $e');
    }
  }

  /// تحديث حالة الإشعار إلى مقروء
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ تم تحديث حالة الإشعار إلى مقروء: $notificationId');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة الإشعار: $e');
    }
  }

  /// التنقل بناءً على نوع الإشعار
  Future<void> _navigateBasedOnNotification(NotificationModel notification) async {
    // سيتم تنفيذ هذا لاحقاً مع نظام التوجيه
    debugPrint('🧭 التنقل إلى: ${notification.type}');
  }

  // Helper methods
  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Priority.max;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  /// تنظيف الموارد
  void dispose() {
    _audioPlayer.dispose();
  }
}
