import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_dialog_service.dart';

/// مساعد لاختبار الإشعارات
class NotificationTestHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إنشاء إشعار اختبار في قاعدة البيانات
  static Future<void> createTestNotificationInDatabase({
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No current user for test notification');
        return;
      }

      final notificationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'recipientId': currentUser.uid,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdBy': 'test_system',
        'data': additionalData ?? {},
      };

      await _firestore.collection('notifications').add(notificationData);
      
      debugPrint('✅ Test notification created in database');
      debugPrint('📋 Notification data: $notificationData');
    } catch (e) {
      debugPrint('❌ Error creating test notification: $e');
    }
  }

  /// إنشاء عدة إشعارات اختبار
  static Future<void> createMultipleTestNotifications() async {
    final notifications = [
      {
        'title': '🚌 ركب طفلك الباص',
        'body': 'ركب طفلك أحمد الباص في الساعة ${_getCurrentTime()}. الرحلة بدأت بأمان.',
        'type': 'student',
        'data': {
          'studentName': 'أحمد',
          'busRoute': 'الخط الأول',
          'action': 'boarding',
        },
      },
      {
        'title': '🏫 وصل طفلك إلى المدرسة',
        'body': 'وصل طفلك أحمد إلى المدرسة بأمان في الساعة ${_getCurrentTime()}.',
        'type': 'arrival',
        'data': {
          'studentName': 'أحمد',
          'schoolName': 'مدرسة النور',
          'action': 'arrival',
        },
      },
      {
        'title': '📢 إشعار عام',
        'body': 'تذكير: غداً إجازة رسمية، لن تعمل الباصات. يرجى ترتيب وسيلة نقل بديلة.',
        'type': 'general',
        'data': {
          'source': 'admin',
          'priority': 'high',
        },
      },
      {
        'title': '⚠️ تأخير في الرحلة',
        'body': 'تأخرت رحلة الباص رقم 123 لمدة 15 دقيقة بسبب الازدحام المروري.',
        'type': 'tripDelayed',
        'data': {
          'busId': '123',
          'delayMinutes': 15,
          'reason': 'traffic',
        },
      },
      {
        'title': '✅ تم قبول طلب الغياب',
        'body': 'تم قبول طلب غياب طفلك أحمد ليوم غد. شكراً لإبلاغنا مسبقاً.',
        'type': 'absenceApproved',
        'data': {
          'studentName': 'أحمد',
          'absenceDate': DateTime.now().add(Duration(days: 1)).toString(),
        },
      },
      {
        'title': '📝 تحديث بيانات الطالب',
        'body': 'تم تحديث بيانات الطالب أحمد من قبل الإدارة\n\nالتحديثات:\n• الاسم: من "أحمد محمد" إلى "أحمد علي"\n• الصف: من "الثاني" إلى "الثالث"\n• رقم الباص: من "غير محدد" إلى "123"',
        'type': 'student',
        'data': {
          'type': 'student_data_update',
          'studentName': 'أحمد',
          'updatedBy': 'الإدارة',
          'action': 'data_updated',
        },
      },
    ];

    for (final notification in notifications) {
      await createTestNotificationInDatabase(
        title: notification['title'] as String,
        body: notification['body'] as String,
        type: notification['type'] as String,
        additionalData: notification['data'] as Map<String, dynamic>?,
      );
      
      // تأخير قصير بين الإشعارات
      await Future.delayed(Duration(milliseconds: 500));
    }

    debugPrint('✅ Created ${notifications.length} test notifications');
  }

  /// اختبار Dialog الإشعارات مباشرة
  static void testNotificationDialog({
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) {
    final fakeMessage = FakeRemoteMessage(
      notification: FakeNotification(title: title, body: body),
      data: {'type': type, ...?data},
    );

    NotificationDialogService().showNotificationDialog(fakeMessage);
  }

  /// اختبار شامل للإشعارات
  static Future<void> runFullNotificationTest(BuildContext context) async {
    // عرض dialog تأكيد
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختبار الإشعارات'),
        content: Text('هل تريد إنشاء إشعارات اختبار؟\n\nسيتم إنشاء 5 إشعارات في قاعدة البيانات واختبار Dialog الإشعارات.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('موافق'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // إنشاء إشعارات في قاعدة البيانات
      await createMultipleTestNotifications();

      // اختبار Dialog مباشرة
      await Future.delayed(Duration(seconds: 1));
      testNotificationDialog(
        title: '🧪 اختبار Dialog',
        body: 'هذا اختبار لـ Dialog الإشعارات التفاعلي. يجب أن يظهر بتأثيرات بصرية جميلة!',
        type: 'test',
        data: {'source': 'test_helper'},
      );

      // عرض رسالة نجاح
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إنشاء الإشعارات الاختبارية بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error in full notification test: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في اختبار الإشعارات: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// حذف جميع الإشعارات الاختبارية
  static Future<void> clearTestNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUser.uid)
          .where('createdBy', isEqualTo: 'test_system')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Cleared ${snapshot.docs.length} test notifications');
    } catch (e) {
      debugPrint('❌ Error clearing test notifications: $e');
    }
  }

  /// إنشاء إشعار مباشر في قاعدة البيانات للاختبار
  static Future<void> _createDirectDatabaseNotification(BuildContext context) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No current user for direct database notification');
        return;
      }

      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
      final testBody = 'هذا نص اختبار مباشر في قاعدة البيانات. تم إنشاؤه في ${_getCurrentTime()} لاختبار عرض النص في صفحة الإشعارات.';

      // إنشاء الإشعار مباشرة في Firestore
      await _firestore.collection('notifications').doc(notificationId).set({
        'id': notificationId,
        'title': '🧪 اختبار نص الإشعار المباشر',
        'body': testBody,
        'recipientId': currentUser.uid,
        'type': 'test',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdBy': 'direct_test_system',
        'data': {
          'source': 'direct_database_test',
          'testType': 'body_display_test',
          'createdAt': DateTime.now().toIso8601String(),
        },
      });

      debugPrint('✅ Direct database notification created');
      debugPrint('📋 Notification ID: $notificationId');
      debugPrint('📋 Body: $testBody');
      debugPrint('📋 Body length: ${testBody.length}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إنشاء إشعار اختبار مباشر في قاعدة البيانات'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error creating direct database notification: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إنشاء الإشعار: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// فحص الإشعارات الموجودة في قاعدة البيانات
  static Future<void> _inspectDatabaseNotifications(BuildContext context) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No current user for database inspection');
        return;
      }

      debugPrint('🔍 Inspecting notifications in database for user: ${currentUser.uid}');

      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      debugPrint('📊 Found ${snapshot.docs.length} notifications in database');

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();

        debugPrint('📋 Notification ${i + 1}:');
        debugPrint('   - ID: ${doc.id}');
        debugPrint('   - Title: "${data['title']}"');
        debugPrint('   - Body: "${data['body']}"');
        debugPrint('   - Body length: ${(data['body'] as String?)?.length ?? 0}');
        debugPrint('   - Message: "${data['message']}"');
        debugPrint('   - Type: "${data['type']}"');
        debugPrint('   - RecipientId: "${data['recipientId']}"');
        debugPrint('   - IsRead: ${data['isRead']}');
        debugPrint('   - Timestamp: ${data['timestamp']}');
        debugPrint('   - Data: ${data['data']}');
        debugPrint('   ---');
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('فحص قاعدة البيانات'),
            content: Text('تم فحص ${snapshot.docs.length} إشعارات.\nتحقق من console للتفاصيل الكاملة.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('موافق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error inspecting database notifications: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في فحص قاعدة البيانات: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// إصلاح الإشعارات الفاسدة (التي لا تحتوي على نص)
  static Future<void> _fixCorruptedNotifications(BuildContext context) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No current user for fixing notifications');
        return;
      }

      debugPrint('🔧 Fixing corrupted notifications for user: ${currentUser.uid}');

      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUser.uid)
          .get();

      int fixedCount = 0;
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final body = data['body'] as String?;
        final message = data['message'] as String?;
        final title = data['title'] as String?;

        // إصلاح الإشعارات التي لا تحتوي على نص
        if ((body == null || body.isEmpty) && (message == null || message.isEmpty)) {
          String fixedBody = '';

          // إنشاء نص بناءً على العنوان أو النوع
          if (title != null && title.isNotEmpty) {
            if (title.contains('ركب')) {
              fixedBody = 'ركب الطالب الباص بأمان';
            } else if (title.contains('نزل')) {
              fixedBody = 'نزل الطالب من الباص بأمان';
            } else if (title.contains('وصل')) {
              fixedBody = 'وصل الطالب إلى المدرسة بأمان';
            } else if (title.contains('تحديث')) {
              fixedBody = 'تم تحديث بيانات الطالب من قبل الإدارة';
            } else if (title.contains('تسكين')) {
              fixedBody = 'تم تسكين الطالب في الباص';
            } else if (title.contains('غياب')) {
              fixedBody = 'طلب غياب للطالب';
            } else {
              fixedBody = 'إشعار من إدارة المدرسة';
            }
          } else {
            fixedBody = 'إشعار من إدارة المدرسة';
          }

          // تحديث الإشعار
          batch.update(doc.reference, {
            'body': fixedBody,
            'fixedAt': FieldValue.serverTimestamp(),
            'fixedBy': 'notification_test_helper',
          });

          fixedCount++;
          debugPrint('🔧 Fixed notification ${doc.id}: "$fixedBody"');
        }
      }

      if (fixedCount > 0) {
        await batch.commit();
        debugPrint('✅ Fixed $fixedCount corrupted notifications');
      } else {
        debugPrint('ℹ️ No corrupted notifications found');
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('إصلاح الإشعارات'),
            content: Text(fixedCount > 0
                ? 'تم إصلاح $fixedCount إشعار فاسد'
                : 'لم يتم العثور على إشعارات فاسدة'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('موافق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error fixing corrupted notifications: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إصلاح الإشعارات: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// الحصول على الوقت الحالي
  static String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// عرض زر اختبار سريع
  static Widget buildTestButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => runFullNotificationTest(context),
      icon: Icon(Icons.bug_report),
      label: Text('اختبار الإشعارات'),
      backgroundColor: Colors.orange,
    );
  }

  /// عرض قائمة اختبارات سريعة
  static void showQuickTestMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختبارات الإشعارات السريعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            ListTile(
              leading: Icon(Icons.directions_bus, color: Colors.green),
              title: Text('اختبار إشعار ركوب الطالب'),
              onTap: () {
                Navigator.pop(context);
                testNotificationDialog(
                  title: '🚌 ركب طفلك الباص',
                  body: 'ركب طفلك أحمد الباص الآن',
                  type: 'student',
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.school, color: Colors.blue),
              title: Text('اختبار إشعار وصول المدرسة'),
              onTap: () {
                Navigator.pop(context);
                testNotificationDialog(
                  title: '🏫 وصل طفلك إلى المدرسة',
                  body: 'وصل طفلك أحمد إلى المدرسة بأمان',
                  type: 'arrival',
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.notifications, color: Colors.orange),
              title: Text('اختبار إشعار عام'),
              onTap: () {
                Navigator.pop(context);
                testNotificationDialog(
                  title: '📢 إشعار عام',
                  body: 'هذا إشعار عام لجميع أولياء الأمور',
                  type: 'general',
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.edit, color: Colors.purple),
              title: Text('اختبار إشعار تعديل الطالب'),
              onTap: () {
                Navigator.pop(context);
                testNotificationDialog(
                  title: '📝 تحديث بيانات الطالب',
                  body: 'تم تحديث بيانات الطالب أحمد من قبل الإدارة\n\nالتحديثات:\n• الاسم: من "أحمد محمد" إلى "أحمد علي"\n• الصف: من "الثاني" إلى "الثالث"',
                  type: 'student',
                  data: {
                    'type': 'student_data_update',
                    'studentName': 'أحمد',
                    'updatedBy': 'الإدارة',
                  },
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.bug_report, color: Colors.teal),
              title: Text('اختبار إشعار مباشر في قاعدة البيانات'),
              onTap: () {
                Navigator.pop(context);
                _createDirectDatabaseNotification(context);
              },
            ),

            ListTile(
              leading: Icon(Icons.search, color: Colors.indigo),
              title: Text('فحص الإشعارات في قاعدة البيانات'),
              onTap: () {
                Navigator.pop(context);
                _inspectDatabaseNotifications(context);
              },
            ),

            ListTile(
              leading: Icon(Icons.build, color: Colors.brown),
              title: Text('إصلاح الإشعارات الفاسدة'),
              onTap: () {
                Navigator.pop(context);
                _fixCorruptedNotifications(context);
              },
            ),

            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('حذف الإشعارات الاختبارية'),
              onTap: () {
                Navigator.pop(context);
                clearTestNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حذف الإشعارات الاختبارية')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// فئات وهمية للاختبار
class FakeRemoteMessage {
  final FakeNotification? notification;
  final Map<String, dynamic> data;

  FakeRemoteMessage({this.notification, required this.data});
}

class FakeNotification {
  final String? title;
  final String? body;

  FakeNotification({this.title, this.body});
}
