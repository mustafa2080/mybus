import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة Firebase Cloud Messaging المتكاملة
/// تدعم الإشعارات في جميع حالات التطبيق: نشط، خلفية، مغلق
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Flutter Local Notifications instance
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Token الحالي
  String? _currentToken;
  
  // حالة التهيئة
  bool _isInitialized = false;

  /// تهيئة خدمة FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔥 Initializing FCM Service...');

      // 1. تهيئة Flutter Local Notifications
      await _initializeLocalNotifications();

      // 2. طلب أذونات الإشعارات
      await _requestPermissions();

      // 3. إعداد معالجات الرسائل
      await _setupMessageHandlers();

      // 4. الحصول على FCM Token وحفظه
      await _getAndSaveToken();

      // 5. الاستماع لتحديثات Token
      _listenToTokenRefresh();

      _isInitialized = true;
      debugPrint('✅ FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FCM Service: $e');
      rethrow;
    }
  }

  /// تهيئة Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    // إعدادات Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_notification');

    // إعدادات iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
    );

    // إعدادات التهيئة
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // تهيئة المكون الإضافي
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // إنشاء قنوات الإشعارات لأندرويد
    await _createNotificationChannels();

    debugPrint('✅ Local notifications initialized');
  }

  /// إنشاء قنوات الإشعارات لأندرويد
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final List<AndroidNotificationChannel> channels = [
      // القناة الرئيسية
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
      // قناة إشعارات الطوارئ
      const AndroidNotificationChannel(
        'emergency_notifications',
        'تنبيهات الطوارئ',
        description: 'تنبيهات طوارئ مهمة وعاجلة',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
    ];

    // إنشاء القنوات
    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    debugPrint('✅ Notification channels created');
  }

  /// طلب أذونات الإشعارات
  Future<void> _requestPermissions() async {
    // طلب أذونات FCM
    final NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📱 FCM Permission status: ${settings.authorizationStatus}');

    // طلب أذونات إضافية لأندرويد 13+
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// إعداد معالجات الرسائل
  Future<void> _setupMessageHandlers() async {
    // معالج الرسائل عندما يكون التطبيق في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // معالج الرسائل عندما يكون التطبيق في الخلفية أو مغلق
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // التحقق من رسالة فتح التطبيق (إذا تم فتح التطبيق من إشعار)
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    debugPrint('✅ Message handlers setup complete');
  }

  /// معالج الرسائل في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Received foreground message: ${message.messageId}');
    
    // عرض الإشعار محلياً
    await _showLocalNotification(message);
  }

  /// معالج الرسائل عند فتح التطبيق من إشعار
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('🔔 App opened from notification: ${message.messageId}');
    
    // يمكن إضافة منطق التنقل هنا
    _handleNotificationNavigation(message);
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final String channelId = message.data['channelId'] ?? 'mybus_notifications';
      final String title = message.notification?.title ?? 'إشعار جديد';
      final String body = message.notification?.body ?? '';
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
        ticker: title,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.mp3',
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: jsonEncode(message.data),
      );

      debugPrint('✅ Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// معالج النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationNavigation(RemoteMessage(data: data));
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// معالج التنقل من الإشعارات
  void _handleNotificationNavigation(RemoteMessage message) {
    final String? type = message.data['type'];
    final String? route = message.data['route'];
    
    debugPrint('🧭 Handling navigation - Type: $type, Route: $route');
    
    // يمكن إضافة منطق التنقل هنا حسب نوع الإشعار
    // مثال: التنقل لصفحة معينة حسب نوع الإشعار
  }

  /// الحصول على FCM Token وحفظه
  Future<void> _getAndSaveToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveTokenToFirestore(token);
        debugPrint('✅ FCM Token obtained and saved');
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// الاستماع لتحديثات Token
  void _listenToTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      _currentToken = token;
      _saveTokenToFirestore(token);
      debugPrint('🔄 FCM Token refreshed');
    });
  }

  /// حفظ Token في Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': Platform.operatingSystem,
        });
        debugPrint('✅ FCM Token saved to Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error saving token to Firestore: $e');
    }
  }

  /// الحصول على اسم القناة
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'student_notifications':
        return 'إشعارات الطلاب';
      case 'bus_notifications':
        return 'إشعارات الباص';
      case 'emergency_notifications':
        return 'تنبيهات الطوارئ';
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
      case 'emergency_notifications':
        return 'تنبيهات طوارئ مهمة وعاجلة';
      default:
        return 'إشعارات عامة لتطبيق MyBus';
    }
  }

  /// الحصول على Token الحالي
  String? get currentToken => _currentToken;

  /// التحقق من حالة التهيئة
  bool get isInitialized => _isInitialized;
}
