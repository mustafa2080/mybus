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

  /// الحصول على إشعارات المستخدم الحالي (مبسط)
  Stream<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 20,
    bool unreadOnly = false,
  }) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserId)
          .snapshots()
          .map((snapshot) {
            var notifications = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();

            // فلترة في الذاكرة إذا كانت مطلوبة
            if (unreadOnly) {
              notifications = notifications.where((notification) {
                final status = notification['status'] as String?;
                return status != null && ['pending', 'sent', 'delivered'].contains(status);
              }).toList();
            }

            // ترتيب في الذاكرة حسب التاريخ
            notifications.sort((a, b) {
              final aTime = a['createdAt'];
              final bTime = b['createdAt'];

              if (aTime == null || bTime == null) return 0;

              try {
                final aDate = aTime is DateTime ? aTime : aTime.toDate();
                final bDate = bTime is DateTime ? bTime : bTime.toDate();
                return bDate.compareTo(aDate);
              } catch (e) {
                return 0;
              }
            });

            // تحديد العدد المطلوب
            if (notifications.length > limit) {
              notifications = notifications.take(limit).toList();
            }

            return notifications;
          })
          .handleError((error) {
            print('خطأ في جلب الإشعارات: $error');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      print('خطأ في إعداد stream للإشعارات: $e');
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
          .snapshots()
          .map((snapshot) {
            // فلترة في الذاكرة لتجنب مشاكل الفهارس
            return snapshot.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String?;
              return status != null && ['pending', 'sent', 'delivered'].contains(status);
            }).length;
          })
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
      // استعلام بسيط بدون فهارس معقدة
      return _firestore
          .collection('notifications')
          .snapshots()
          .map((snapshot) {
            // فلترة في الذاكرة للأنواع المطلوبة والحالة غير المقروءة
            final adminNotifications = snapshot.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] as String?;
              final status = data['status'] as String?;

              return status != null &&
                     ['pending', 'sent', 'delivered'].contains(status) &&
                     [
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
          .update({
            'status': 'read',
            'readAt': FieldValue.serverTimestamp()
          });
    } catch (e) {
      print('خطأ في تحديد الإشعار كمقروء: $e');
    }
  }

  /// تحديد جميع إشعارات المستخدم كمقروءة
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      // استعلام بسيط بدون فلترة معقدة
      final notifications = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserId)
          .get();

      // فلترة في الذاكرة للإشعارات غير المقروءة
      final unreadDocs = notifications.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        return status != null && ['pending', 'sent', 'delivered'].contains(status);
      }).toList();

      for (final doc in unreadDocs) {
        batch.update(doc.reference, {
          'status': 'read',
          'readAt': FieldValue.serverTimestamp()
        });
      }

      await batch.commit();
      print('✅ تم تحديد ${unreadDocs.length} إشعار كمقروء');
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
      // إنشاء الإشعار مباشرة كـ Map
      final notificationData = {
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'type': type.toString().split('.').last,
        'priority': priority.toString().split('.').last,
        'status': 'pending',
        'channels': channels.map((c) => c.toString().split('.').last).toList(),
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'requiresSound': false,
        'requiresVibration': false,
        'isBackground': true,
        'retryCount': 0,
        'isActive': true,
      };

      await _firestore
          .collection('notifications')
          .add(notificationData);

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
        // إنشاء الإشعار مباشرة كـ Map
        final notificationData = {
          'recipientId': recipientId,
          'title': title,
          'body': body,
          'type': type.toString().split('.').last,
          'priority': priority.toString().split('.').last,
          'status': 'pending',
          'channels': ['fcm', 'inApp'],
          'data': data ?? {},
          'createdAt': FieldValue.serverTimestamp(),
          'requiresSound': false,
          'requiresVibration': false,
          'isBackground': true,
          'retryCount': 0,
          'isActive': true,
        };

        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notificationData);
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
      // استعلام بسيط بدون فلترة معقدة
      final notifications = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserId)
          .get();

      // فلترة في الذاكرة للإشعارات المقروءة
      final readDocs = notifications.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        return status == 'read';
      }).toList();

      for (final doc in readDocs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ تم حذف ${readDocs.length} إشعار مقروء');
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
        'priority': 'low',
        'status': 'pending',
        'channels': ['fcm', 'inApp'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'requiresSound': false,
        'requiresVibration': false,
        'isBackground': true,
        'retryCount': 0,
        'isActive': true,
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
