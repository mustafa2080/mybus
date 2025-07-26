import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_messaging_service.dart';
import 'notification_service.dart';
import 'event_trigger_service.dart';
import 'auth_service.dart';

/// خدمة تهيئة نظام الإشعارات الشامل
class NotificationSystemInitializer {
  static final NotificationSystemInitializer _instance = NotificationSystemInitializer._internal();
  factory NotificationSystemInitializer() => _instance;
  NotificationSystemInitializer._internal();

  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final NotificationService _notificationService = NotificationService();
  final EventTriggerService _eventTriggerService = EventTriggerService();

  bool _isInitialized = false;

  /// تهيئة نظام الإشعارات الكامل
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 بدء تهيئة نظام الإشعارات الشامل...');

      // تهيئة خدمة Firebase Messaging
      await _messagingService.initialize();
      debugPrint('✅ تم تهيئة Firebase Messaging');

      // تهيئة خدمة الإشعارات الرئيسية
      await _notificationService.initialize();
      debugPrint('✅ تم تهيئة خدمة الإشعارات');

      // تهيئة خدمة مراقبة الأحداث
      await _eventTriggerService.initialize();
      debugPrint('✅ تم تهيئة خدمة مراقبة الأحداث');

      _isInitialized = true;
      debugPrint('🎉 تم تهيئة نظام الإشعارات الشامل بنجاح!');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة نظام الإشعارات: $e');
      rethrow;
    }
  }

  /// تهيئة النظام للمستخدم المسجل دخوله
  Future<void> initializeForUser(User user) async {
    try {
      debugPrint('👤 تهيئة النظام للمستخدم: ${user.email}');

      // التأكد من تهيئة النظام الأساسي
      if (!_isInitialized) {
        await initialize();
      }

      // إنشاء إعدادات افتراضية للمستخدم إذا لم تكن موجودة
      await _createUserNotificationSettingsIfNeeded(user.uid);

      debugPrint('✅ تم تهيئة النظام للمستخدم بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة النظام للمستخدم: $e');
    }
  }

  /// إنشاء إعدادات الإشعارات للمستخدم إذا لم تكن موجودة
  Future<void> _createUserNotificationSettingsIfNeeded(String userId) async {
    try {
      final existingSettings = await _notificationService.getUserNotificationSettings(userId);
      
      if (existingSettings == null) {
        debugPrint('📝 إنشاء إعدادات إشعارات افتراضية للمستخدم: $userId');
        // سيتم إنشاء الإعدادات تلقائياً في getUserNotificationSettings
      } else {
        debugPrint('✅ إعدادات الإشعارات موجودة للمستخدم: $userId');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء إعدادات الإشعارات: $e');
    }
  }

  /// إيقاف النظام
  void dispose() {
    try {
      _eventTriggerService.dispose();
      _messagingService.dispose();
      _isInitialized = false;
      debugPrint('🔄 تم إيقاف نظام الإشعارات');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف النظام: $e');
    }
  }

  /// إعادة تشغيل النظام
  Future<void> restart() async {
    try {
      debugPrint('🔄 إعادة تشغيل نظام الإشعارات...');
      dispose();
      await initialize();
      debugPrint('✅ تم إعادة تشغيل النظام بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تشغيل النظام: $e');
    }
  }

  /// التحقق من حالة النظام
  bool get isInitialized => _isInitialized;

  /// الحصول على خدمة الإشعارات
  NotificationService get notificationService => _notificationService;

  /// الحصول على خدمة Firebase Messaging
  FirebaseMessagingService get messagingService => _messagingService;

  /// الحصول على خدمة مراقبة الأحداث
  EventTriggerService get eventTriggerService => _eventTriggerService;
}

/// مساعد لتهيئة النظام مع AuthService
class NotificationSystemHelper {
  static final NotificationSystemInitializer _initializer = NotificationSystemInitializer();

  /// تهيئة النظام مع مراقبة حالة المصادقة
  static Future<void> initializeWithAuth(AuthService authService) async {
    try {
      // تهيئة النظام الأساسي
      await _initializer.initialize();

      // مراقبة تغييرات حالة المصادقة
      authService.authStateChanges.listen((user) async {
        if (user != null) {
          // المستخدم سجل دخوله
          await _initializer.initializeForUser(user);
        } else {
          // المستخدم سجل خروجه
          debugPrint('👋 المستخدم سجل خروجه - إيقاف مراقبة الأحداث الشخصية');
        }
      });

      debugPrint('🔗 تم ربط نظام الإشعارات مع خدمة المصادقة');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة النظام مع المصادقة: $e');
      rethrow;
    }
  }

  /// الحصول على المُهيئ
  static NotificationSystemInitializer get initializer => _initializer;
}

/// إضافة مساعدة لتكامل النظام مع التطبيق
extension NotificationSystemExtension on AuthService {
  /// تهيئة نظام الإشعارات مع خدمة المصادقة
  Future<void> initializeNotificationSystem() async {
    await NotificationSystemHelper.initializeWithAuth(this);
  }

  /// الحصول على خدمة الإشعارات
  NotificationService get notificationService => 
      NotificationSystemHelper.initializer.notificationService;

  /// الحصول على خدمة Firebase Messaging
  FirebaseMessagingService get messagingService => 
      NotificationSystemHelper.initializer.messagingService;

  /// الحصول على خدمة مراقبة الأحداث
  EventTriggerService get eventTriggerService => 
      NotificationSystemHelper.initializer.eventTriggerService;
}

/// دالة مساعدة للتهيئة السريعة
Future<void> initializeNotificationSystem() async {
  await NotificationSystemInitializer().initialize();
}

/// دالة مساعدة للحصول على خدمة الإشعارات
NotificationService getNotificationService() {
  return NotificationSystemInitializer().notificationService;
}

/// دالة مساعدة للحصول على خدمة Firebase Messaging
FirebaseMessagingService getMessagingService() {
  return NotificationSystemInitializer().messagingService;
}

/// دالة مساعدة للحصول على خدمة مراقبة الأحداث
EventTriggerService getEventTriggerService() {
  return NotificationSystemInitializer().eventTriggerService;
}
