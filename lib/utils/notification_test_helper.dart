import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/event_trigger_service.dart';
import '../services/firebase_messaging_service.dart';

/// مساعد اختبار الإشعارات السريع
class NotificationTestHelper {
  static final NotificationService _notificationService = NotificationService();
  static final EventTriggerService _eventTriggerService = EventTriggerService();
  static final FirebaseMessagingService _messagingService = FirebaseMessagingService();

  /// اختبار سريع للنظام
  static Future<bool> quickTest() async {
    try {
      debugPrint('🧪 بدء الاختبار السريع للإشعارات...');

      // التحقق من تهيئة الخدمات
      if (!_notificationService.isInitialized) {
        debugPrint('❌ NotificationService غير مُهيأ');
        return false;
      }

      if (!_eventTriggerService.isInitialized) {
        debugPrint('❌ EventTriggerService غير مُهيأ');
        return false;
      }

      if (!_messagingService.isInitialized) {
        debugPrint('❌ FirebaseMessagingService غير مُهيأ');
        return false;
      }

      // اختبار إرسال إشعار تجريبي
      final testSent = await _notificationService.sendEventNotification(
        eventId: 'test_notification',
        eventData: {
          'message': 'اختبار النظام',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (!testSent) {
        debugPrint('❌ فشل في إرسال الإشعار التجريبي');
        return false;
      }

      debugPrint('✅ النظام يعمل بشكل طبيعي!');
      debugPrint('📊 إحصائيات:');
      debugPrint('   - الاشتراكات النشطة: ${_eventTriggerService.activeSubscriptions}');
      debugPrint('   - خدمة الإشعارات: مُهيأة');
      debugPrint('   - خدمة Firebase: مُهيأة');
      debugPrint('   - مراقبة الأحداث: نشطة');

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في الاختبار السريع: $e');
      return false;
    }
  }

  /// اختبار إشعار تحديث بيانات طالب
  static Future<bool> testStudentUpdateNotification() async {
    try {
      debugPrint('🧪 اختبار إشعار تحديث بيانات طالب...');

      final sent = await _notificationService.sendEventNotification(
        eventId: 'student_data_updated_parent',
        eventData: {
          'studentId': 'test_student_123',
          'studentName': 'أحمد محمد',
          'parentId': 'test_parent_456',
          'schoolName': 'مدرسة النور',
          'grade': 'الصف الثالث',
          'busRoute': 'خط الرياض',
          'updatedAt': DateTime.now().toIso8601String(),
          'updatedBy': 'admin',
        },
        specificRecipientId: 'test_parent_456',
      );

      if (sent) {
        debugPrint('✅ تم إرسال إشعار تحديث البيانات بنجاح');
        return true;
      } else {
        debugPrint('❌ فشل في إرسال إشعار تحديث البيانات');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختبار إشعار تحديث البيانات: $e');
      return false;
    }
  }

  /// طباعة حالة النظام
  static void printSystemStatus() {
    debugPrint('📊 حالة نظام الإشعارات:');
    debugPrint('   🔔 NotificationService: ${_notificationService.isInitialized ? "✅ مُهيأ" : "❌ غير مُهيأ"}');
    debugPrint('   🔍 EventTriggerService: ${_eventTriggerService.isInitialized ? "✅ مُهيأ" : "❌ غير مُهيأ"}');
    debugPrint('   📱 FirebaseMessagingService: ${_messagingService.isInitialized ? "✅ مُهيأ" : "❌ غير مُهيأ"}');
    debugPrint('   📡 الاشتراكات النشطة: ${_eventTriggerService.activeSubscriptions}');
  }

  /// اختبار شامل سريع
  static Future<void> runQuickTests() async {
    debugPrint('🚀 بدء الاختبارات السريعة...');
    
    printSystemStatus();
    
    final systemTest = await quickTest();
    final updateTest = await testStudentUpdateNotification();
    
    debugPrint('📋 نتائج الاختبارات:');
    debugPrint('   🔧 اختبار النظام: ${systemTest ? "✅ نجح" : "❌ فشل"}');
    debugPrint('   📝 اختبار تحديث البيانات: ${updateTest ? "✅ نجح" : "❌ فشل"}');
    
    if (systemTest && updateTest) {
      debugPrint('🎉 جميع الاختبارات نجحت - النظام يعمل بشكل مثالي!');
    } else {
      debugPrint('⚠️ بعض الاختبارات فشلت - يحتاج النظام لمراجعة');
    }
  }
}
