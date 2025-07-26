import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة إشعارات مبسطة تعمل مع الفهارس الموجودة
class SimpleNotificationService {
  static final SimpleNotificationService _instance = SimpleNotificationService._internal();
  factory SimpleNotificationService() => _instance;
  SimpleNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// الحصول على معرف المستخدم الحالي
  String? get currentUserId => _auth.currentUser?.uid;

  /// عدد الإشعارات غير المقروءة للمستخدم الحالي
  Stream<int> getUnreadNotificationsCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    try {
      return _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length)
          .handleError((error) {
            print('خطأ في عدد الإشعارات: $error');
            return 0;
          });
    } catch (e) {
      print('خطأ في stream الإشعارات: $e');
      return Stream.value(0);
    }
  }

  /// عدد إشعارات الأدمن (مبسط)
  Stream<int> getAdminNotificationsCount() {
    try {
      return _firestore
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
            // عد جميع الإشعارات غير المقروءة للأدمن
            return snapshot.docs.length;
          })
          .handleError((error) {
            print('خطأ في إشعارات الأدمن: $error');
            return 0;
          });
    } catch (e) {
      print('خطأ في stream إشعارات الأدمن: $e');
      return Stream.value(0);
    }
  }

  /// إنشاء إشعار بسيط
  Future<void> createSimpleNotification({
    required String recipientId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': data ?? {},
      });

      print('✅ تم إنشاء إشعار بسيط');
    } catch (e) {
      print('❌ خطأ في إنشاء الإشعار: $e');
    }
  }

  /// تحديد إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('خطأ في تحديد الإشعار كمقروء: $e');
    }
  }

  /// الحصول على الإشعارات (مبسط)
  Stream<List<Map<String, dynamic>>> getNotifications({int limit = 20}) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserId)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            final notifications = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();

            // ترتيب في الذاكرة حسب التاريخ
            notifications.sort((a, b) {
              final aTime = a['createdAt'] as Timestamp?;
              final bTime = b['createdAt'] as Timestamp?;
              
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

            return notifications;
          })
          .handleError((error) {
            print('خطأ في جلب الإشعارات: $error');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      print('خطأ في stream الإشعارات: $e');
      return Stream.value([]);
    }
  }

  /// إرسال إشعار ترحيب
  Future<void> sendWelcomeNotification(String userId, String userType) async {
    String title = '';
    String body = '';

    switch (userType) {
      case 'parent':
        title = 'مرحباً بك في MyBus';
        body = 'يمكنك الآن متابعة رحلات أطفالك';
        break;
      case 'admin':
        title = 'مرحباً بك في لوحة التحكم';
        body = 'يمكنك الآن إدارة النظام';
        break;
      case 'supervisor':
        title = 'مرحباً بك كمشرف';
        body = 'يمكنك الآن متابعة الطلاب';
        break;
      default:
        title = 'مرحباً بك';
        body = 'تم تسجيل دخولك بنجاح';
    }

    await createSimpleNotification(
      recipientId: userId,
      title: title,
      body: body,
      type: 'welcome',
      data: {
        'userType': userType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// إرسال إشعار للأدمن
  Future<void> sendAdminNotification({
    required String title,
    required String body,
    String type = 'admin',
    Map<String, dynamic>? data,
  }) async {
    try {
      // الحصول على جميع الأدمن
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'admin')
          .get();

      // إرسال إشعار لكل أدمن
      for (final adminDoc in adminsSnapshot.docs) {
        await createSimpleNotification(
          recipientId: adminDoc.id,
          title: title,
          body: body,
          type: type,
          data: data,
        );
      }

      print('✅ تم إرسال إشعار للأدمن');
    } catch (e) {
      print('❌ خطأ في إرسال إشعار الأدمن: $e');
    }
  }

  /// تنظيف الإشعارات القديمة
  Future<void> cleanOldNotifications() async {
    try {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(oneMonthAgo))
          .where('isRead', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ تم تنظيف ${oldNotifications.docs.length} إشعار قديم');
    } catch (e) {
      print('❌ خطأ في تنظيف الإشعارات: $e');
    }
  }
}
