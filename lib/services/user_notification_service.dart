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

    Query query = _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
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
    });
  }

  /// عدد الإشعارات غير المقروءة للمستخدم الحالي
  Stream<int> getUnreadNotificationsCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// عدد إشعارات الأدمن غير المقروءة
  Stream<int> getAdminUnreadNotificationsCount() {
    return _firestore
        .collection('notifications')
        .where('type', whereIn: [
          'newComplaint',
          'newStudent',
          'studentAbsence',
          'newParentAccount',
          'studentBehaviorReport'
        ])
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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
}
