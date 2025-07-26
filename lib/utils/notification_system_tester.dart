import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/event_trigger_service.dart';
import '../services/notification_privacy_service.dart';
import '../models/notification_model.dart';
import '../models/notification_settings_model.dart';

/// أداة اختبار نظام الإشعارات الشامل
class NotificationSystemTester {
  static final NotificationSystemTester _instance = NotificationSystemTester._internal();
  factory NotificationSystemTester() => _instance;
  NotificationSystemTester._internal();

  final NotificationService _notificationService = NotificationService();
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final EventTriggerService _eventTriggerService = EventTriggerService();
  final NotificationPrivacyService _privacyService = NotificationPrivacyService();

  /// تشغيل اختبار شامل للنظام
  Future<TestResults> runComprehensiveTest() async {
    final results = TestResults();
    
    try {
      debugPrint('🧪 بدء الاختبار الشامل لنظام الإشعارات...');

      // اختبار تهيئة الخدمات
      results.serviceInitialization = await _testServiceInitialization();
      
      // اختبار إنشاء الإشعارات
      results.notificationCreation = await _testNotificationCreation();
      
      // اختبار إعدادات المستخدم
      results.userSettings = await _testUserSettings();
      
      // اختبار الخصوصية والأمان
      results.privacySecurity = await _testPrivacyAndSecurity();
      
      // اختبار مراقبة الأحداث
      results.eventMonitoring = await _testEventMonitoring();
      
      // اختبار الأداء
      results.performance = await _testPerformance();

      results.overallSuccess = _calculateOverallSuccess(results);
      
      debugPrint('✅ انتهى الاختبار الشامل - النجاح العام: ${results.overallSuccess}%');
      
    } catch (e) {
      debugPrint('❌ خطأ في الاختبار الشامل: $e');
      results.overallSuccess = 0;
    }

    return results;
  }

  /// اختبار تهيئة الخدمات
  Future<bool> _testServiceInitialization() async {
    try {
      debugPrint('🔧 اختبار تهيئة الخدمات...');

      // اختبار تهيئة NotificationService
      await _notificationService.initialize();
      if (!_notificationService.isInitialized) {
        debugPrint('❌ فشل في تهيئة NotificationService');
        return false;
      }

      // اختبار تهيئة FirebaseMessagingService
      await _messagingService.initialize();
      if (!_messagingService.isInitialized) {
        debugPrint('❌ فشل في تهيئة FirebaseMessagingService');
        return false;
      }

      // اختبار تهيئة EventTriggerService
      await _eventTriggerService.initialize();
      if (!_eventTriggerService.isInitialized) {
        debugPrint('❌ فشل في تهيئة EventTriggerService');
        return false;
      }

      debugPrint('✅ تم تهيئة جميع الخدمات بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في اختبار تهيئة الخدمات: $e');
      return false;
    }
  }

  /// اختبار إنشاء الإشعارات
  Future<bool> _testNotificationCreation() async {
    try {
      debugPrint('📝 اختبار إنشاء الإشعارات...');

      // اختبار إنشاء إشعار مخصص
      final customNotificationSent = await _notificationService.sendCustomNotification(
        recipientId: 'test_user_id',
        recipientType: 'parent',
        title: 'اختبار الإشعار',
        body: 'هذا إشعار تجريبي للاختبار',
        type: NotificationType.generalAnnouncement,
        priority: NotificationPriority.medium,
      );

      if (!customNotificationSent) {
        debugPrint('❌ فشل في إرسال الإشعار المخصص');
        return false;
      }

      // اختبار إنشاء إشعار من حدث
      final eventNotificationSent = await _notificationService.sendEventNotification(
        eventId: 'student_boarded_bus',
        eventData: {
          'studentName': 'طالب تجريبي',
          'studentId': 'test_student_id',
          'parentId': 'test_parent_id',
          'time': DateTime.now().toIso8601String(),
        },
      );

      if (!eventNotificationSent) {
        debugPrint('❌ فشل في إرسال إشعار الحدث');
        return false;
      }

      debugPrint('✅ تم إنشاء الإشعارات بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في اختبار إنشاء الإشعارات: $e');
      return false;
    }
  }

  /// اختبار إعدادات المستخدم
  Future<bool> _testUserSettings() async {
    try {
      debugPrint('⚙️ اختبار إعدادات المستخدم...');

      // إنشاء إعدادات تجريبية
      final testSettings = NotificationSettingsModel.createDefault(
        userId: 'test_user_id',
        userType: 'parent',
      );

      // اختبار حفظ الإعدادات
      final saveSuccess = await _notificationService.updateUserNotificationSettings(testSettings);
      if (!saveSuccess) {
        debugPrint('❌ فشل في حفظ إعدادات المستخدم');
        return false;
      }

      // اختبار استرجاع الإعدادات
      final retrievedSettings = await _notificationService.getUserNotificationSettings('test_user_id');
      if (retrievedSettings == null) {
        debugPrint('❌ فشل في استرجاع إعدادات المستخدم');
        return false;
      }

      // اختبار منطق التحقق من الإعدادات
      final testNotification = NotificationModel(
        id: 'test_notification',
        title: 'اختبار',
        body: 'اختبار',
        type: NotificationType.studentBoarded,
        recipientId: 'test_user_id',
        recipientType: 'parent',
        createdAt: DateTime.now(),
      );

      final canSend = retrievedSettings.canSendNotification(testNotification);
      if (!canSend) {
        debugPrint('❌ منطق التحقق من الإعدادات لا يعمل بشكل صحيح');
        return false;
      }

      debugPrint('✅ إعدادات المستخدم تعمل بشكل صحيح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في اختبار إعدادات المستخدم: $e');
      return false;
    }
  }

  /// اختبار الخصوصية والأمان
  Future<bool> _testPrivacyAndSecurity() async {
    try {
      debugPrint('🔒 اختبار الخصوصية والأمان...');

      // اختبار التحقق من صلاحية الإرسال
      final testNotification = NotificationModel(
        id: 'test_notification',
        title: 'اختبار الأمان',
        body: 'اختبار الأمان',
        type: NotificationType.studentBoarded,
        recipientId: 'test_recipient',
        recipientType: 'parent',
        data: {'studentId': 'test_student'},
        createdAt: DateTime.now(),
      );

      final canSend = await _privacyService.canSendNotificationToRecipient(
        notification: testNotification,
        senderId: 'test_sender',
      );

      // اختبار تنظيف البيانات الحساسة
      final sanitizedNotification = _privacyService.sanitizeNotification(testNotification);
      if (sanitizedNotification.data.containsKey('password') || 
          sanitizedNotification.data.containsKey('secret')) {
        debugPrint('❌ فشل في تنظيف البيانات الحساسة');
        return false;
      }

      // اختبار التحقق من صحة المحتوى
      final validContent = _privacyService.validateNotificationContent(testNotification);
      if (!validContent) {
        debugPrint('❌ فشل في التحقق من صحة المحتوى');
        return false;
      }

      debugPrint('✅ الخصوصية والأمان تعمل بشكل صحيح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في اختبار الخصوصية والأمان: $e');
      return false;
    }
  }

  /// اختبار مراقبة الأحداث
  Future<bool> _testEventMonitoring() async {
    try {
      debugPrint('👁️ اختبار مراقبة الأحداث...');

      // التحقق من عدد الاشتراكات النشطة
      final activeSubscriptions = _eventTriggerService.activeSubscriptions;
      if (activeSubscriptions == 0) {
        debugPrint('❌ لا توجد اشتراكات نشطة لمراقبة الأحداث');
        return false;
      }

      debugPrint('✅ مراقبة الأحداث تعمل بشكل صحيح - $activeSubscriptions اشتراك نشط');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في اختبار مراقبة الأحداث: $e');
      return false;
    }
  }

  /// اختبار الأداء
  Future<bool> _testPerformance() async {
    try {
      debugPrint('⚡ اختبار الأداء...');

      final stopwatch = Stopwatch()..start();

      // اختبار سرعة إنشاء الإشعارات
      for (int i = 0; i < 10; i++) {
        await _notificationService.sendCustomNotification(
          recipientId: 'test_user_$i',
          recipientType: 'parent',
          title: 'اختبار الأداء $i',
          body: 'اختبار الأداء رقم $i',
        );
      }

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      // يجب أن يكون الوقت أقل من 5 ثوانٍ لإنشاء 10 إشعارات
      if (elapsedMs > 5000) {
        debugPrint('❌ الأداء بطيء - استغرق ${elapsedMs}ms لإنشاء 10 إشعارات');
        return false;
      }

      debugPrint('✅ الأداء جيد - استغرق ${elapsedMs}ms لإنشاء 10 إشعارات');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في اختبار الأداء: $e');
      return false;
    }
  }

  /// حساب النجاح العام
  int _calculateOverallSuccess(TestResults results) {
    int passedTests = 0;
    int totalTests = 6;

    if (results.serviceInitialization) passedTests++;
    if (results.notificationCreation) passedTests++;
    if (results.userSettings) passedTests++;
    if (results.privacySecurity) passedTests++;
    if (results.eventMonitoring) passedTests++;
    if (results.performance) passedTests++;

    return ((passedTests / totalTests) * 100).round();
  }

  /// اختبار سريع للنظام
  Future<bool> quickHealthCheck() async {
    try {
      debugPrint('🏥 فحص سريع لصحة النظام...');

      // التحقق من تهيئة الخدمات الأساسية
      if (!_notificationService.isInitialized) {
        debugPrint('❌ NotificationService غير مُهيأ');
        return false;
      }

      if (!_messagingService.isInitialized) {
        debugPrint('❌ FirebaseMessagingService غير مُهيأ');
        return false;
      }

      if (!_eventTriggerService.isInitialized) {
        debugPrint('❌ EventTriggerService غير مُهيأ');
        return false;
      }

      debugPrint('✅ النظام يعمل بشكل طبيعي');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في الفحص السريع: $e');
      return false;
    }
  }

  /// إنشاء تقرير مفصل
  String generateDetailedReport(TestResults results) {
    final buffer = StringBuffer();
    
    buffer.writeln('📊 تقرير اختبار نظام الإشعارات');
    buffer.writeln('=' * 50);
    buffer.writeln('النجاح العام: ${results.overallSuccess}%');
    buffer.writeln('');
    
    buffer.writeln('تفاصيل الاختبارات:');
    buffer.writeln('- تهيئة الخدمات: ${results.serviceInitialization ? "✅ نجح" : "❌ فشل"}');
    buffer.writeln('- إنشاء الإشعارات: ${results.notificationCreation ? "✅ نجح" : "❌ فشل"}');
    buffer.writeln('- إعدادات المستخدم: ${results.userSettings ? "✅ نجح" : "❌ فشل"}');
    buffer.writeln('- الخصوصية والأمان: ${results.privacySecurity ? "✅ نجح" : "❌ فشل"}');
    buffer.writeln('- مراقبة الأحداث: ${results.eventMonitoring ? "✅ نجح" : "❌ فشل"}');
    buffer.writeln('- الأداء: ${results.performance ? "✅ نجح" : "❌ فشل"}');
    
    buffer.writeln('');
    buffer.writeln('التوصيات:');
    if (results.overallSuccess < 100) {
      buffer.writeln('- راجع الاختبارات الفاشلة وأصلح المشاكل');
      buffer.writeln('- تأكد من إعداد Firebase بشكل صحيح');
      buffer.writeln('- تحقق من الأذونات والصلاحيات');
    } else {
      buffer.writeln('- النظام يعمل بشكل ممتاز! 🎉');
    }
    
    return buffer.toString();
  }
}

/// نتائج الاختبار
class TestResults {
  bool serviceInitialization = false;
  bool notificationCreation = false;
  bool userSettings = false;
  bool privacySecurity = false;
  bool eventMonitoring = false;
  bool performance = false;
  int overallSuccess = 0;
}

/// دالة مساعدة لتشغيل الاختبار السريع
Future<bool> quickNotificationSystemCheck() async {
  return await NotificationSystemTester().quickHealthCheck();
}

/// دالة مساعدة لتشغيل الاختبار الشامل
Future<TestResults> runFullNotificationSystemTest() async {
  return await NotificationSystemTester().runComprehensiveTest();
}
