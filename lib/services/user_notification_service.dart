import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

/// خدمة الإشعارات المخصصة لكل مستخدم
class UserNotificationService {
  static final UserNotificationService _instance = UserNotificationService._internal();
  factory UserNotificationService() => _instance;
  UserNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// الحصول على معرف المستخدم الحالي
  String? get currentUserId => _auth.currentUser?.uid;

  /// الحصول على إشعارات المستخدم الحالي
  Stream<List<NotificationModel>> getUserNotifications({
    int limit = 20,
    bool unreadOnly = false,
  }) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    try {
      Query query = _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserId);

      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }

      // ترتيب بسيط بدون فهرس مركب
      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        final notifications = snapshot.docs.map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return NotificationModel.fromMap(data);
          } catch (e) {
            print('خطأ في تحويل الإشعار: $e');
            return null;
          }
        }).where((notification) => notification != null)
          .cast<NotificationModel>()
          .toList();

        // ترتيب في الذاكرة
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notifications;
      });
    } catch (e) {
      print('خطأ في جلب الإشعارات: $e');
      return Stream.value([]);
    }
  }

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
            print('خطأ في عدد الإشعارات غير المقروءة: $error');
            return 0;
          });
    } catch (e) {
      print('خطأ في إعداد stream للإشعارات: $e');
      return Stream.value(0);
    }
  }

  /// عدد إشعارات الأدمن غير المقروءة (مبسط)
  Stream<int> getAdminUnreadNotificationsCount() {
    try {
      // استعلام مبسط يعمل مع الفهارس الموجودة
      return _firestore
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
            // فلترة في الذاكرة للأنواع المطلوبة
            final adminNotifications = snapshot.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] as String?;
              return [
                'newComplaint',
                'newStudent',
                'studentAbsence',
                'newParentAccount',
                'studentBehaviorReport'
              ].contains(type);
            }).toList();

            return adminNotifications.length;
          })
          .handleError((error) {
            print('خطأ في عدد إشعارات الأدمن: $error');
            return 0;
          });
    } catch (e) {
      print('خطأ في إعداد stream لإشعارات الأدمن: $e');
      return Stream.value(0);
    }
  }

  /// تحديد إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('خطأ في تحديد الإشعار كمقروء: $e');
    }
  }

  /// تحديد جميع إشعارات المستخدم كمقروءة
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp()
        });
      }

      await batch.commit();
    } catch (e) {
      print('خطأ في تحديد جميع الإشعارات كمقروءة: $e');
    }
  }

  /// إنشاء إشعار جديد
  Future<void> createNotification({
    required String recipientId,
    required String title,
    required String body,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
    List<NotificationChannel> channels = const [
      NotificationChannel.fcm,
      NotificationChannel.inApp
    ],
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // سيتم تعيينه تلقائياً
        recipientId: recipientId,
        title: title,
        body: body,
        type: type,
        priority: priority,
        status: NotificationStatus.pending,
        channels: channels,
        data: data ?? {},
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('notifications')
          .add(notification.toMap());

      print('✅ تم إنشاء إشعار جديد للمستخدم: $recipientId');
    } catch (e) {
      print('❌ خطأ في إنشاء الإشعار: $e');
    }
  }

  /// إنشاء إشعار لعدة مستخدمين
  Future<void> createBulkNotifications({
    required List<String> recipientIds,
    required String title,
    required String body,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
  }) async {
    try {
      final batch = _firestore.batch();
      
      for (final recipientId in recipientIds) {
        final notification = NotificationModel(
          id: '', // سيتم تعيينه تلقائياً
          recipientId: recipientId,
          title: title,
          body: body,
          type: type,
          priority: priority,
          status: NotificationStatus.pending,
          channels: [NotificationChannel.fcm, NotificationChannel.inApp],
          data: data ?? {},
          isRead: false,
          createdAt: DateTime.now(),
        );

        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notification.toMap());
      }

      await batch.commit();
      print('✅ تم إنشاء ${recipientIds.length} إشعار جديد');
    } catch (e) {
      print('❌ خطأ في إنشاء الإشعارات المتعددة: $e');
    }
  }

  /// حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('خطأ في حذف الإشعار: $e');
    }
  }

  /// حذف جميع الإشعارات المقروءة للمستخدم
  Future<void> deleteReadNotifications() async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: true)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('خطأ في حذف الإشعارات المقروءة: $e');
    }
  }

  /// إنشاء إشعار ترحيب بسيط
  static Future<void> createWelcomeNotification(String userId, String userType) async {
    try {
      String title = '';
      String body = '';

      switch (userType) {
        case 'parent':
          title = 'مرحباً بك في MyBus';
          body = 'يمكنك الآن متابعة رحلات أطفالك والتواصل مع المدرسة';
          break;
        case 'admin':
          title = 'مرحباً بك في لوحة التحكم';
          body = 'يمكنك الآن إدارة النظام ومتابعة جميع العمليات';
          break;
        case 'supervisor':
          title = 'مرحباً بك كمشرف';
          body = 'يمكنك الآن متابعة الطلاب وإدارة الرحلات';
          break;
        default:
          title = 'مرحباً بك';
          body = 'تم تسجيل دخولك بنجاح';
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': userId,
        'title': title,
        'body': body,
        'type': 'welcome',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'userType': userType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });

      print('✅ تم إنشاء إشعار الترحيب للمستخدم: $userId');
    } catch (e) {
      print('❌ خطأ في إنشاء إشعار الترحيب: $e');
    }
  }
}
