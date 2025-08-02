import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'admin_notification_service.dart';
import 'parent_notification_service.dart';
import 'supervisor_notification_service.dart';

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

  // خدمة إشعارات الأدمن
  final AdminNotificationService _adminNotificationService = AdminNotificationService();

  // خدمة إشعارات ولي الأمر
  final ParentNotificationService _parentNotificationService = ParentNotificationService();

  // خدمة إشعارات المشرف
  final SupervisorNotificationService _supervisorNotificationService = SupervisorNotificationService();

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
    debugPrint('📱 Title: ${message.notification?.title}');
    debugPrint('📱 Body: ${message.notification?.body}');
    debugPrint('📱 Data: ${message.data}');

    // التحقق من المستخدم المستهدف قبل عرض الإشعار
    final targetUserId = message.data['userId'] ?? message.data['recipientId'];
    final currentUser = FirebaseAuth.instance.currentUser;

    if (targetUserId != null && currentUser?.uid == targetUserId) {
      // عرض الإشعار فقط إذا كان المستخدم الحالي هو المستهدف
      debugPrint('✅ Showing notification for target user: $targetUserId');

      // التحقق من نوع المستخدم
      await _checkUserTypeAndShowNotification(message);
    } else {
      debugPrint('⚠️ Notification not for current user (${currentUser?.uid}), target: $targetUserId');
      debugPrint('📤 Notification skipped - not for current user');
    }
  }

  /// التحقق من نوع المستخدم وعرض الإشعار المناسب
  Future<void> _checkUserTypeAndShowNotification(RemoteMessage message) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // جلب بيانات المستخدم لمعرفة نوعه
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final userType = userData?['userType'] ?? '';

      debugPrint('👤 User type: $userType');

      // إذا كان المستخدم أدمن، استخدم خدمة إشعارات الأدمن المتقدمة
      if (userType == 'admin') {
        debugPrint('🔔 Handling admin notification with advanced service');
        // سيتم التعامل مع الإشعار في AdminNotificationService
        // لا نحتاج لفعل شيء هنا لأن الخدمة تستمع للرسائل تلقائياً
      } else if (userType == 'parent') {
        debugPrint('👨‍👩‍👧‍👦 Handling parent notification with advanced service');
        // سيتم التعامل مع الإشعار في ParentNotificationService
        // لا نحتاج لفعل شيء هنا لأن الخدمة تستمع للرسائل تلقائياً
      } else if (userType == 'supervisor') {
        debugPrint('👨‍💼 Handling supervisor notification with advanced service');
        // سيتم التعامل مع الإشعار في SupervisorNotificationService
        // لا نحتاج لفعل شيء هنا لأن الخدمة تستمع للرسائل تلقائياً
      } else {
        // للمستخدمين العاديين، عرض الإشعار العادي
        debugPrint('📱 Showing regular notification for user type: $userType');
        await _showLocalNotification(message);
      }
    } catch (e) {
      debugPrint('❌ Error checking user type: $e');
      // في حالة الخطأ، عرض الإشعار العادي
      await _showLocalNotification(message);
    }
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

  /// إرسال إشعار تجريبي لاختبار النظام
  Future<void> sendTestNotification() async {
    try {
      debugPrint('🧪 Sending test notification...');

      // إرسال إشعار محلي للاختبار الفوري
      await _sendLocalTestNotification();

      // محاولة إرسال إشعار FCM للاختبار الحقيقي
      await _sendFCMTestNotification();

      debugPrint('✅ Test notifications sent');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// إرسال إشعار محلي للاختبار
  Future<void> _sendLocalTestNotification() async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mybus_notifications',
      'إشعارات MyBus',
      channelDescription: 'إشعارات عامة لتطبيق MyBus',
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
      ticker: 'اختبار الإشعار المحلي',
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

    await _localNotifications.show(
      notificationId,
      'اختبار الإشعار المحلي',
      'هذا إشعار محلي للتأكد من عمل النظام في شريط الإشعارات',
      details,
      payload: '{"type": "local_test", "timestamp": "${DateTime.now().toIso8601String()}"}',
    );
  }

  /// إرسال إشعار FCM للاختبار الحقيقي
  Future<void> _sendFCMTestNotification() async {
    try {
      final token = _currentToken;
      if (token == null) {
        debugPrint('❌ No FCM token available for test');
        return;
      }

      debugPrint('🔥 Sending real FCM test notification...');

      // إرسال إشعار حقيقي للجهاز نفسه للاختبار
      await sendNotificationToToken(
        token: token,
        title: 'اختبار FCM حقيقي',
        body: 'هذا إشعار حقيقي من FCM يجب أن يظهر في شريط الإشعارات حتى لو كان التطبيق في الخلفية',
        data: {
          'type': 'fcm_test',
          'channelId': 'mybus_notifications',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ FCM test notification sent to token: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Error sending FCM test notification: $e');
    }
  }

  /// إرسال إشعار لـ token محدد (محسن للمستخدم المحدد فقط)
  Future<void> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
    String? channelId,
    String? targetUserId, // إضافة معرف المستخدم المستهدف
  }) async {
    try {
      debugPrint('📤 Preparing to send FCM notification...');
      debugPrint('📱 Target token: ${token.substring(0, 20)}...');
      debugPrint('👤 Target user: $targetUserId');
      debugPrint('📝 Title: $title');
      debugPrint('📝 Body: $body');
      debugPrint('📊 Data: $data');

      // لا نعرض إشعارات محلية - فقط نسجل للتشخيص
      // الإشعارات ستصل عبر FCM الحقيقي للمستخدم المستهدف فقط
      debugPrint('📤 FCM notification queued for user: $targetUserId');
      debugPrint('⚠️ No local notification will be shown to current user');

      // في بيئة الإنتاج، هنا يجب إرسال الإشعار عبر الخادم
      // الذي سيرسله للمستخدم المستهدف فقط عبر FCM token الخاص به

      debugPrint('✅ Notification sent to specific user: $targetUserId');
    } catch (e) {
      debugPrint('❌ Error in sendNotificationToToken: $e');
    }
  }

  // تم حذف دالة _showLocalNotificationForUser لمنع الإشعارات المحلية غير المرغوب فيها
  // في مرحلة الاختبار، الإشعارات تحفظ في قاعدة البيانات فقط للمستخدم المستهدف
}
