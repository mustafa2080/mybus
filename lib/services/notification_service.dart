import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/notification_settings_model.dart';
import '../models/notification_event_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import 'firebase_messaging_service.dart';
import 'email_service.dart';

/// خدمة إدارة الإشعارات الرئيسية مع منطق التوجيه والتوزيع الذكي
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final EmailService _emailService = EmailService();
  final Uuid _uuid = const Uuid();

  bool _isInitialized = false;
  Map<String, NotificationEventModel> _eventTemplates = {};

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 بدء تهيئة خدمة الإشعارات الرئيسية...');

      // تهيئة خدمة Firebase Messaging
      await _messagingService.initialize();

      // تحميل قوالب الأحداث
      await _loadEventTemplates();

      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة الإشعارات الرئيسية بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
      rethrow;
    }
  }

  /// تحميل قوالب الأحداث من قاعدة البيانات
  Future<void> _loadEventTemplates() async {
    try {
      final snapshot = await _firestore.collection('notification_events').get();
      
      if (snapshot.docs.isEmpty) {
        // إنشاء القوالب الافتراضية
        await _createDefaultEventTemplates();
      } else {
        // تحميل القوالب الموجودة
        for (final doc in snapshot.docs) {
          final event = NotificationEventModel.fromMap(doc.data());
          _eventTemplates[event.id] = event;
        }
      }

      debugPrint('✅ تم تحميل ${_eventTemplates.length} قالب حدث');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل قوالب الأحداث: $e');
    }
  }

  /// إنشاء القوالب الافتراضية
  Future<void> _createDefaultEventTemplates() async {
    try {
      final defaultEvents = PredefinedNotificationEvents.getDefaultEvents();
      
      for (final event in defaultEvents) {
        await _firestore.collection('notification_events').doc(event.id).set(event.toMap());
        _eventTemplates[event.id] = event;
      }

      debugPrint('✅ تم إنشاء ${defaultEvents.length} قالب افتراضي');
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء القوالب الافتراضية: $e');
    }
  }

  /// إرسال إشعار مخصص
  Future<bool> sendCustomNotification({
    required String recipientId,
    required String recipientType,
    required String title,
    required String body,
    NotificationType type = NotificationType.generalAnnouncement,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic> data = const {},
    List<NotificationChannel> channels = const [NotificationChannel.fcm, NotificationChannel.inApp],
    bool requiresSound = false,
    bool requiresVibration = false,
    String? senderId,
    String? senderName,
  }) async {
    try {
      final notification = NotificationModel(
        id: _uuid.v4(),
        title: title,
        body: body,
        type: type,
        priority: priority,
        recipientId: recipientId,
        recipientType: recipientType,
        senderId: senderId,
        senderName: senderName,
        data: data,
        channels: channels,
        requiresSound: requiresSound,
        requiresVibration: requiresVibration,
        createdAt: DateTime.now(),
      );

      return await _sendNotification(notification);
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار المخصص: $e');
      return false;
    }
  }

  /// إرسال إشعار بناءً على حدث
  Future<bool> sendEventNotification({
    required String eventId,
    required Map<String, dynamic> eventData,
    String? specificRecipientId,
  }) async {
    try {
      final eventTemplate = _eventTemplates[eventId];
      if (eventTemplate == null) {
        debugPrint('❌ لم يتم العثور على قالب الحدث: $eventId');
        return false;
      }

      // تحديد المستلمين
      List<String> recipientIds;
      if (specificRecipientId != null) {
        recipientIds = [specificRecipientId];
      } else {
        recipientIds = await _getEventRecipients(eventTemplate, eventData);
      }

      bool allSent = true;
      for (final recipientId in recipientIds) {
        final notification = await _createNotificationFromEvent(
          eventTemplate,
          eventData,
          recipientId,
        );

        if (notification != null) {
          final sent = await _sendNotification(notification);
          if (!sent) allSent = false;
        }
      }

      return allSent;
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار الحدث: $e');
      return false;
    }
  }

  /// تحديد المستلمين بناءً على الحدث
  Future<List<String>> _getEventRecipients(
    NotificationEventModel eventTemplate,
    Map<String, dynamic> eventData,
  ) async {
    try {
      final List<String> recipients = [];

      for (final userType in eventTemplate.targetUserTypes) {
        switch (userType) {
          case 'admin':
            final admins = await _getAdminUsers();
            recipients.addAll(admins);
            break;

          case 'parent':
            if (eventData.containsKey('parentId')) {
              recipients.add(eventData['parentId']);
            } else if (eventData.containsKey('studentId')) {
              final parentId = await _getParentIdFromStudent(eventData['studentId']);
              if (parentId != null) recipients.add(parentId);
            }
            break;

          case 'supervisor':
            if (eventData.containsKey('supervisorId')) {
              recipients.add(eventData['supervisorId']);
            } else if (eventData.containsKey('busId') || eventData.containsKey('busRoute')) {
              final supervisors = await _getSupervisorsForBus(
                eventData['busId'] ?? eventData['busRoute'],
              );
              recipients.addAll(supervisors);
            }
            break;
        }
      }

      return recipients.toSet().toList(); // إزالة المكررات
    } catch (e) {
      debugPrint('❌ خطأ في تحديد المستلمين: $e');
      return [];
    }
  }

  /// إنشاء إشعار من قالب الحدث
  Future<NotificationModel?> _createNotificationFromEvent(
    NotificationEventModel eventTemplate,
    Map<String, dynamic> eventData,
    String recipientId,
  ) async {
    try {
      // الحصول على نوع المستلم
      final recipientType = await _getUserType(recipientId);
      if (recipientType == null) return null;

      // تطبيق القوالب
      final title = eventTemplate.generateTitle(eventData);
      final body = eventTemplate.generateBody(eventData);

      // إنشاء الإشعار
      return NotificationModel(
        id: _uuid.v4(),
        title: title,
        body: body,
        type: eventTemplate.notificationType,
        priority: eventTemplate.defaultPriority,
        recipientId: recipientId,
        recipientType: recipientType,
        senderId: eventData['senderId'],
        senderName: eventData['senderName'],
        data: {...eventData, ...eventTemplate.additionalData},
        channels: eventTemplate.defaultChannels,
        requiresSound: eventTemplate.requiresSound,
        requiresVibration: eventTemplate.requiresVibration,
        isBackground: eventTemplate.isBackground,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الإشعار من القالب: $e');
      return null;
    }
  }

  /// إرسال الإشعار عبر القنوات المحددة
  Future<bool> _sendNotification(NotificationModel notification) async {
    try {
      // التحقق من إعدادات المستلم
      final canSend = await _canSendToRecipient(notification);
      if (!canSend) {
        debugPrint('🔇 تم تجاهل الإشعار بناءً على إعدادات المستلم');
        return false;
      }

      // حفظ الإشعار في قاعدة البيانات
      await _saveNotification(notification);

      bool sentSuccessfully = false;

      // إرسال عبر القنوات المختلفة
      for (final channel in notification.channels) {
        switch (channel) {
          case NotificationChannel.fcm:
            final sent = await _sendFCMNotification(notification);
            if (sent) sentSuccessfully = true;
            break;

          case NotificationChannel.email:
            final sent = await _sendEmailNotification(notification);
            if (sent) sentSuccessfully = true;
            break;

          case NotificationChannel.inApp:
            // الإشعارات داخل التطبيق تُحفظ في قاعدة البيانات فقط
            sentSuccessfully = true;
            break;

          case NotificationChannel.sms:
            // يمكن إضافة خدمة SMS لاحقاً
            break;
        }
      }

      // تحديث حالة الإشعار
      if (sentSuccessfully) {
        await _updateNotificationStatus(
          notification.id,
          NotificationStatus.sent,
          sentAt: DateTime.now(),
        );
      } else {
        await _updateNotificationStatus(
          notification.id,
          NotificationStatus.failed,
          errorMessage: 'فشل في الإرسال عبر جميع القنوات',
        );
      }

      return sentSuccessfully;
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار: $e');
      
      // تحديث حالة الإشعار إلى فشل
      await _updateNotificationStatus(
        notification.id,
        NotificationStatus.failed,
        errorMessage: e.toString(),
      );
      
      return false;
    }
  }

  /// إرسال إشعار FCM
  Future<bool> _sendFCMNotification(NotificationModel notification) async {
    try {
      // الحصول على FCM token للمستلم
      final token = await _getFCMToken(notification.recipientId);
      if (token == null) {
        debugPrint('❌ لم يتم العثور على FCM token للمستلم: ${notification.recipientId}');
        return false;
      }

      // إعداد الرسالة
      final message = {
        'to': token,
        'notification': {
          'title': notification.title,
          'body': notification.body,
          'sound': notification.shouldPlaySound ? 'default' : null,
        },
        'data': {
          ...notification.data,
          'id': notification.id,
          'type': notification.type.toString().split('.').last,
          'priority': notification.priority.toString().split('.').last,
          'recipientId': notification.recipientId,
          'recipientType': notification.recipientType,
          'requiresSound': notification.requiresSound.toString(),
          'requiresVibration': notification.requiresVibration.toString(),
          'isBackground': notification.isBackground.toString(),
        },
        'android': {
          'priority': notification.isHighPriority ? 'high' : 'normal',
          'notification': {
            'channel_id': _getChannelId(notification.priority),
            'sound': notification.shouldPlaySound ? 'default' : null,
            'vibrate_timings': notification.shouldVibrate ? [0, 500, 250, 500] : null,
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': notification.title,
                'body': notification.body,
              },
              'sound': notification.shouldPlaySound ? 'default' : null,
              'badge': 1,
            },
          },
        },
      };

      // إرسال الإشعار عبر Firebase Legacy API (أكثر استقراراً)
      final serverKey = await _getServerKeyFromRemoteConfig();
      if (serverKey.isEmpty) {
        debugPrint('⚠️ Server Key غير متوفر - سيتم إرسال الإشعار محلياً فقط');

        // إرسال إشعار محلي بدلاً من FCM
        await _messagingService.showLocalNotification(notification);

        // تحديث حالة الإشعار
        await _updateNotificationStatus(
          notification.id,
          NotificationStatus.sent,
          sentAt: DateTime.now(),
        );
        return true;
      }

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': notification.title,
            'body': notification.body,
            'sound': notification.shouldPlaySound ? 'default' : null,
          },
          'data': {
            'notificationId': notification.id,
            'type': notification.type.toString().split('.').last,
            'priority': notification.priority.toString().split('.').last,
            'recipientId': notification.recipientId,
            'timestamp': DateTime.now().toIso8601String(),
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            ...notification.data.map((key, value) => MapEntry(key, value.toString())),
          },
          'android': {
            'priority': notification.priority == NotificationPriority.urgent ||
                       notification.priority == NotificationPriority.high ? 'high' : 'normal',
            'notification': {
              'channel_id': _getChannelId(notification.priority),
              'sound': notification.shouldPlaySound ? 'default' : null,
              'icon': '@mipmap/launcher_icon',
              'color': '#FFD700',
              'tag': notification.type.toString().split('.').last,
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {
                  'title': notification.title,
                  'body': notification.body,
                },
                'sound': notification.shouldPlaySound ? 'default' : null,
                'badge': await _getUnreadCount(notification.recipientId),
              }
            }
          },
          'priority': notification.priority == NotificationPriority.urgent ||
                     notification.priority == NotificationPriority.high ? 'high' : 'normal',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('✅ تم إرسال FCM بنجاح: ${responseData['name']}');

        // تحديث حالة الإشعار في قاعدة البيانات
        await _updateNotificationStatus(
          notification.id,
          NotificationStatus.sent,
          sentAt: DateTime.now(),
        );
        return true;
      } else {
        debugPrint('❌ فشل إرسال FCM: ${response.statusCode} - ${response.body}');
        await _updateNotificationStatus(
          notification.id,
          NotificationStatus.failed,
          errorMessage: response.body,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال FCM: $e');
      return false;
    }
  }

  /// الحصول على Access Token لـ Firebase Admin API
  Future<String> _getAccessToken() async {
    try {
      // استخدام Server Key مباشرة للاختبار
      // في بيئة الإنتاج، يجب استخدام Firebase Functions أو Service Account
      return await _getServerKeyFromRemoteConfig();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على Access Token: $e');
      return '';
    }
  }

  /// الحصول على Server Key من Remote Config
  Future<String> _getServerKeyFromRemoteConfig() async {
    try {
      // في التطبيق الحقيقي، يجب حفظ Server Key في Firebase Remote Config
      // أو استخدام Firebase Functions للأمان

      // للاختبار: يمكن إضافة Server Key هنا مؤقتاً
      // احصل على Server Key من Firebase Console > Project Settings > Cloud Messaging
      const serverKey = ''; // ضع Server Key هنا للاختبار

      if (serverKey.isNotEmpty) {
        return serverKey;
      }

      // محاولة الحصول من Remote Config
      // final remoteConfig = FirebaseRemoteConfig.instance;
      // return remoteConfig.getString('fcm_server_key');

      debugPrint('⚠️ Server Key غير متوفر - يجب إضافته للاختبار');
      return '';
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على Server Key: $e');
      return '';
    }
  }

  /// الحصول على عدد الإشعارات غير المقروءة
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



  /// إرسال إشعار بريد إلكتروني
  Future<bool> _sendEmailNotification(NotificationModel notification) async {
    try {
      // الحصول على بيانات المستلم
      final recipientData = await _getUserData(notification.recipientId);
      if (recipientData == null) return false;

      await _emailService.sendParentNotification(
        parentEmail: recipientData['email'] ?? '',
        parentName: recipientData['name'] ?? '',
        title: notification.title,
        message: notification.body,
      );

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في إرسال البريد الإلكتروني: $e');
      return false;
    }
  }

  // Helper methods للحصول على البيانات

  /// الحصول على قائمة المديرين
  Future<List<String>> _getAdminUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على المديرين: $e');
      return [];
    }
  }

  /// الحصول على معرف ولي الأمر من معرف الطالب
  Future<String?> _getParentIdFromStudent(String studentId) async {
    try {
      final doc = await _firestore.collection('students').doc(studentId).get();
      return doc.data()?['parentId'];
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على ولي الأمر: $e');
      return null;
    }
  }

  /// الحصول على المشرفين للباص
  Future<List<String>> _getSupervisorsForBus(String busIdentifier) async {
    try {
      final snapshot = await _firestore
          .collection('supervisor_assignments')
          .where('busId', isEqualTo: busIdentifier)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()['supervisorId'] as String).toList();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على مشرفي الباص: $e');
      return [];
    }
  }

  /// الحصول على نوع المستخدم
  Future<String?> _getUserType(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['userType'];
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على نوع المستخدم: $e');
      return null;
    }
  }

  /// الحصول على بيانات المستخدم
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على بيانات المستخدم: $e');
      return null;
    }
  }

  /// الحصول على FCM token للمستخدم
  Future<String?> _getFCMToken(String userId) async {
    try {
      final doc = await _firestore.collection('user_tokens').doc(userId).get();
      return doc.data()?['fcmToken'];
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على FCM token: $e');
      return null;
    }
  }

  /// التحقق من إمكانية الإرسال للمستلم
  Future<bool> _canSendToRecipient(NotificationModel notification) async {
    try {
      final doc = await _firestore
          .collection('notification_settings')
          .doc(notification.recipientId)
          .get();

      if (!doc.exists) return true; // السماح إذا لم توجد إعدادات

      final settings = NotificationSettingsModel.fromMap(doc.data()!);
      return settings.canSendNotification(notification);
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من إعدادات المستلم: $e');
      return true; // السماح في حالة الخطأ
    }
  }

  /// حفظ الإشعار في قاعدة البيانات
  Future<void> _saveNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الإشعار: $e');
      rethrow;
    }
  }

  /// تحديث حالة الإشعار
  Future<void> _updateNotificationStatus(
    String notificationId,
    NotificationStatus status, {
    DateTime? sentAt,
    DateTime? readAt,
    String? errorMessage,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (sentAt != null) updateData['sentAt'] = Timestamp.fromDate(sentAt);
      if (readAt != null) updateData['readAt'] = Timestamp.fromDate(readAt);
      if (errorMessage != null) updateData['errorMessage'] = errorMessage;

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update(updateData);
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة الإشعار: $e');
    }
  }

  /// الحصول على معرف القناة بناءً على الأولوية
  String _getChannelId(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
      case NotificationPriority.high:
        return 'high_priority_channel';
      case NotificationPriority.medium:
        return 'medium_priority_channel';
      case NotificationPriority.low:
        return 'low_priority_channel';
    }
  }

  // Public methods للاستخدام من الخارج

  /// تحديث إعدادات الإشعارات للمستخدم
  Future<bool> updateUserNotificationSettings(NotificationSettingsModel settings) async {
    try {
      await _firestore
          .collection('notification_settings')
          .doc(settings.userId)
          .set(settings.toMap());
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث إعدادات الإشعارات: $e');
      return false;
    }
  }

  /// الحصول على إعدادات الإشعارات للمستخدم
  Future<NotificationSettingsModel?> getUserNotificationSettings(String userId) async {
    try {
      final doc = await _firestore.collection('notification_settings').doc(userId).get();

      if (doc.exists) {
        return NotificationSettingsModel.fromMap(doc.data()!);
      } else {
        // إنشاء إعدادات افتراضية
        final userData = await _getUserData(userId);
        if (userData == null) return null;

        final settings = NotificationSettingsModel.createDefault(
          userId: userId,
          userType: userData['userType'] ?? 'parent',
          fcmToken: await _getFCMToken(userId) ?? '',
        );

        await updateUserNotificationSettings(settings);
        return settings;
      }
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على إعدادات الإشعارات: $e');
      return null;
    }
  }

  /// الحصول على عدد الإشعارات غير المقروءة
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
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
          debugPrint('❌ خطأ في عدد الإشعارات غير المقروءة: $error');
          return 0;
        });
  }

  /// الحصول على الإشعارات للمستخدم
  Stream<List<NotificationModel>> getUserNotifications(String userId, {int limit = 50}) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          // تحويل البيانات وفلترة الحديثة فقط
          var notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .where((notification) {
                // عرض الإشعارات من آخر 30 يوم فقط
                final daysDifference = DateTime.now().difference(notification.createdAt).inDays;
                return daysDifference <= 30;
              })
              .toList();

          // ترتيب حسب التاريخ (الأحدث أولاً)
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // تحديد العدد المطلوب
          if (notifications.length > limit) {
            notifications = notifications.take(limit).toList();
          }

          return notifications;
        })
        .handleError((error) {
          debugPrint('❌ خطأ في تحميل إشعارات المستخدم: $error');
          return <NotificationModel>[];
        });
  }

  /// تحديد الإشعار كمقروء
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _updateNotificationStatus(
        notificationId,
        NotificationStatus.read,
        readAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديد الإشعار كمقروء: $e');
      return false;
    }
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      // استعلام بسيط بدون whereIn لتجنب مشاكل الفهارس
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .get();

      // فلترة في الذاكرة للحالات المطلوبة
      final docsToUpdate = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        return status != null && ['pending', 'sent', 'delivered'].contains(status);
      }).toList();

      for (final doc in docsToUpdate) {
        batch.update(doc.reference, {
          'status': 'read',
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ تم تحديد ${docsToUpdate.length} إشعار كمقروء');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديد جميع الإشعارات كمقروءة: $e');
      return false;
    }
  }

  /// تنظيف الإشعارات القديمة (أكثر من 30 يوم)
  Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final oldNotifications = await _firestore
          .collection('notifications')
          .where('createdAt', isLessThan: thirtyDaysAgo)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('🧹 تم حذف ${oldNotifications.docs.length} إشعار قديم');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف الإشعارات القديمة: $e');
    }
  }
}
