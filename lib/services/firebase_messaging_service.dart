import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

  /// إنشاء قنوات الإشعارات الاحترافية للأندرويد
  Future<void> _createNotificationChannels() async {
    final List<AndroidNotificationChannel> channels = [
      // قناة الإشعارات العاجلة - مثل WhatsApp للمكالمات
      const AndroidNotificationChannel(
        'urgent_channel',
        'إشعارات عاجلة',
        description: 'إشعارات عاجلة تتطلب انتباه فوري - حالات الطوارئ',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        ledColor: Color(0xFFFF0000), // أحمر للطوارئ
        // vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]), // نمط اهتزاز قوي
      ),

      // قناة الإشعارات عالية الأولوية - مثل WhatsApp للرسائل المهمة
      const AndroidNotificationChannel(
        'high_priority_channel',
        'إشعارات مهمة',
        description: 'إشعارات مهمة تتعلق بسلامة الطلاب',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        ledColor: Color(0xFFFFD700), // ذهبي للمهم
        // vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      ),

      // قناة الإشعارات المتوسطة - مثل WhatsApp للرسائل العادية
      const AndroidNotificationChannel(
        'medium_priority_channel',
        'إشعارات عادية',
        description: 'إشعارات عادية حول أنشطة الطلاب',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        ledColor: Color(0xFF4A90E2), // أزرق للعادي
        // vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      ),

      // قناة الإشعارات المنخفضة - للتحديثات البسيطة
      const AndroidNotificationChannel(
        'low_priority_channel',
        'تحديثات بسيطة',
        description: 'تحديثات وإشعارات غير مهمة',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        enableLights: false,
        showBadge: true,
        ledColor: Color(0xFF808080), // رمادي للبسيط
      ),

      // قناة إشعارات الخلفية - للعمليات الصامتة
      const AndroidNotificationChannel(
        'background_channel',
        'عمليات الخلفية',
        description: 'إشعارات صامتة للعمليات في الخلفية',
        importance: Importance.min,
        playSound: false,
        enableVibration: false,
        enableLights: false,
        showBadge: false,
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

      // إعدادات الأندرويد الاحترافية - مثل WhatsApp
      final androidDetails = AndroidNotificationDetails(
        channelId,
        'إشعارات كيدز باص',
        channelDescription: 'إشعارات تطبيق كيدز باص للنقل المدرسي',
        importance: _getImportance(notification.priority),
        priority: _getPriority(notification.priority),
        playSound: notification.shouldPlaySound && (_userSettings?.soundEnabled ?? true),
        enableVibration: notification.shouldVibrate && (_userSettings?.vibrationEnabled ?? true),
        enableLights: true,
        ledColor: _getLedColor(notification.priority),
        ledOnMs: 1000,
        ledOffMs: 500,
        icon: '@mipmap/launcher_icon',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        color: const Color(0xFFFFD700), // لون ذهبي مميز
        colorized: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        usesChronometer: false,
        chronometerCountDown: false,
        showProgress: false,
        maxProgress: 0,
        progress: 0,
        indeterminate: false,
        channelShowBadge: true,
        onlyAlertOnce: false,
        ongoing: notification.priority == NotificationPriority.urgent,
        autoCancel: true,
        silent: !notification.shouldPlaySound,
        fullScreenIntent: notification.priority == NotificationPriority.urgent,
        shortcutId: 'mybus_shortcut',
        // additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT للإشعارات العاجلة
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        timeoutAfter: notification.priority == NotificationPriority.low ? 10000 : null,
        groupKey: 'mybus_notifications',
        setAsGroupSummary: false,
        groupAlertBehavior: GroupAlertBehavior.all,
        styleInformation: BigTextStyleInformation(
          notification.body,
          htmlFormatBigText: true,
          contentTitle: notification.title,
          htmlFormatContentTitle: true,
          summaryText: 'كيدز باص • ${_getTimeAgo(notification.createdAt)}',
          htmlFormatSummaryText: true,
        ),
        actions: _getNotificationActions(notification),
      );

      // إعدادات iOS الاحترافية - مثل WhatsApp
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: notification.shouldPlaySound && (_userSettings?.soundEnabled ?? true),
        sound: notification.shouldPlaySound ? 'default' : null,
        badgeNumber: await _getUnreadCount(notification.recipientId),
        subtitle: _getNotificationSubtitle(notification),
        threadIdentifier: notification.recipientId, // تجميع الإشعارات حسب المستخدم
        categoryIdentifier: notification.type.toString().split('.').last,
        interruptionLevel: notification.priority == NotificationPriority.urgent
            ? InterruptionLevel.critical
            : InterruptionLevel.active,
        attachments: _getIOSAttachments(notification),
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

  /// الحصول على لون LED حسب الأولوية
  Color _getLedColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return const Color(0xFFFF0000); // أحمر للطوارئ
      case NotificationPriority.high:
        return const Color(0xFFFFD700); // ذهبي للمهم
      case NotificationPriority.medium:
        return const Color(0xFF4A90E2); // أزرق للعادي
      case NotificationPriority.low:
        return const Color(0xFF808080); // رمادي للبسيط
    }
  }

  /// الحصول على نص الوقت المنقضي
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  /// الحصول على إجراءات الإشعار
  List<AndroidNotificationAction> _getNotificationActions(NotificationModel notification) {
    final actions = <AndroidNotificationAction>[];

    // إجراء "قراءة" لجميع الإشعارات
    actions.add(const AndroidNotificationAction(
      'mark_read',
      'تم القراءة',
      showsUserInterface: false,
    ));

    // إجراءات خاصة حسب نوع الإشعار
    switch (notification.type) {
      case NotificationType.studentBoarded:
      case NotificationType.studentAtSchool:
      case NotificationType.studentAtHome:
        actions.add(const AndroidNotificationAction(
          'view_location',
          'عرض الموقع',
          showsUserInterface: true,
        ));
        break;

      case NotificationType.newComplaint:
        actions.add(const AndroidNotificationAction(
          'call_school',
          'اتصال بالمدرسة',
          showsUserInterface: true,
        ));
        break;

      default:
        actions.add(const AndroidNotificationAction(
          'open_app',
          'فتح التطبيق',
          showsUserInterface: true,
        ));
    }

    return actions;
  }

  /// الحصول على عنوان فرعي للإشعار (iOS)
  String _getNotificationSubtitle(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.studentBoarded:
        return 'ركب الحافلة';
      case NotificationType.studentAtSchool:
        return 'وصل للمدرسة';
      case NotificationType.studentAtHome:
        return 'وصل للمنزل';
      case NotificationType.newComplaint:
        return 'تنبيه عاجل';
      case NotificationType.studentDataUpdate:
        return 'تحديث البيانات';
      default:
        return 'كيدز باص';
    }
  }

  /// الحصول على مرفقات iOS
  List<DarwinNotificationAttachment> _getIOSAttachments(NotificationModel notification) {
    final attachments = <DarwinNotificationAttachment>[];

    // يمكن إضافة صور أو ملفات صوتية حسب نوع الإشعار
    // مثلاً: صورة الطالب، خريطة الموقع، إلخ

    return attachments;
  }

  /// الحصول على عدد الإشعارات غير المقروءة (مساعدة)
  Future<int> _getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'sent', 'delivered'])
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ خطأ في حساب الإشعارات غير المقروءة: $e');
      return 0;
    }
  }

  /// تنظيف الموارد
  void dispose() {
    _audioPlayer.dispose();
  }
}
