# إعداد Firebase Cloud Functions لنظام الإشعارات

## نظرة عامة
هذا الملف يحتوي على إرشادات إعداد Firebase Cloud Functions لدعم نظام الإشعارات المتقدم في تطبيق كيدز باص.

## المتطلبات
- Firebase CLI
- Node.js 18+
- حساب Firebase مع خطة Blaze (للوصول للخدمات الخارجية)

## إعداد Cloud Functions

### 1. تهيئة المشروع
```bash
# تهيئة Firebase Functions
firebase init functions

# اختيار JavaScript أو TypeScript
# اختيار تثبيت التبعيات
```

### 2. تثبيت التبعيات المطلوبة
```bash
cd functions
npm install firebase-admin
npm install firebase-functions
npm install @google-cloud/firestore
```

### 3. إعداد دالة إرسال الإشعارات

#### functions/index.js
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// دالة إرسال إشعار FCM
exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    try {
      // الحصول على FCM token للمستلم
      const userTokenDoc = await admin.firestore()
        .collection('user_tokens')
        .doc(notification.recipientId)
        .get();
      
      if (!userTokenDoc.exists) {
        console.log('No FCM token found for user:', notification.recipientId);
        return null;
      }
      
      const fcmToken = userTokenDoc.data().fcmToken;
      
      // إعداد الرسالة
      const message = {
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          notificationId: context.params.notificationId,
          type: notification.type,
          priority: notification.priority,
          recipientId: notification.recipientId,
          ...notification.data
        },
        android: {
          priority: notification.priority === 'high' || notification.priority === 'urgent' ? 'high' : 'normal',
          notification: {
            channelId: getChannelId(notification.priority),
            sound: notification.requiresSound ? 'default' : undefined,
            priority: notification.priority === 'urgent' ? 'max' : 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body
              },
              sound: notification.requiresSound ? 'default' : undefined,
              badge: 1
            }
          }
        }
      };
      
      // إرسال الرسالة
      const response = await admin.messaging().send(message);
      console.log('Successfully sent message:', response);
      
      // تحديث حالة الإشعار
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return response;
    } catch (error) {
      console.error('Error sending message:', error);
      
      // تحديث حالة الإشعار إلى فشل
      await snap.ref.update({
        status: 'failed',
        errorMessage: error.message,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      throw error;
    }
  });

// دالة مساعدة لتحديد قناة الإشعار
function getChannelId(priority) {
  switch (priority) {
    case 'urgent':
    case 'high':
      return 'high_priority_channel';
    case 'medium':
      return 'medium_priority_channel';
    case 'low':
      return 'low_priority_channel';
    default:
      return 'medium_priority_channel';
  }
}

// دالة تنظيف الإشعارات القديمة
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 2 * * *') // يومياً في الساعة 2 صباحاً
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const oldNotifications = await admin.firestore()
      .collection('notifications')
      .where('createdAt', '<', thirtyDaysAgo)
      .get();
    
    const batch = admin.firestore().batch();
    oldNotifications.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log(`Deleted ${oldNotifications.size} old notifications`);
    
    return null;
  });

// دالة إحصائيات الإشعارات
exports.getNotificationStats = functions.https.onCall(async (data, context) => {
  // التحقق من صلاحيات الأدمن
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
  
  const now = new Date();
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  
  // إحصائيات اليوم
  const todayStats = await admin.firestore()
    .collection('notifications')
    .where('createdAt', '>=', startOfDay)
    .get();
  
  const stats = {
    today: {
      total: todayStats.size,
      sent: 0,
      failed: 0,
      pending: 0
    }
  };
  
  todayStats.docs.forEach(doc => {
    const status = doc.data().status;
    if (status === 'sent') stats.today.sent++;
    else if (status === 'failed') stats.today.failed++;
    else stats.today.pending++;
  });
  
  return stats;
});
```

### 4. إعداد متغيرات البيئة
```bash
# إعداد مفتاح الخادم لـ FCM
firebase functions:config:set fcm.server_key="YOUR_FCM_SERVER_KEY"

# إعداد إعدادات أخرى
firebase functions:config:set app.name="كيدز باص"
firebase functions:config:set app.environment="production"
```

### 5. نشر الدوال
```bash
# نشر جميع الدوال
firebase deploy --only functions

# أو نشر دالة محددة
firebase deploy --only functions:sendNotification
```

## الاستخدام في التطبيق

### إرسال إشعار من التطبيق
```dart
// في NotificationService
Future<bool> _sendFCMNotification(NotificationModel notification) async {
  try {
    // حفظ الإشعار في Firestore
    // Cloud Function ستتولى الإرسال تلقائياً
    await _firestore.collection('notifications').add(notification.toMap());
    return true;
  } catch (e) {
    debugPrint('❌ خطأ في إرسال FCM: $e');
    return false;
  }
}
```

### استدعاء إحصائيات الإشعارات
```dart
// في AdminNotificationsScreen
Future<Map<String, dynamic>> getNotificationStats() async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('getNotificationStats');
    final result = await callable.call();
    return result.data;
  } catch (e) {
    debugPrint('❌ خطأ في الحصول على الإحصائيات: $e');
    return {};
  }
}
```

## الأمان والخصوصية

### قواعد الأمان
- جميع الدوال تتحقق من صلاحيات المستخدم
- الإشعارات تُرسل فقط للمستلمين المحددين
- البيانات الحساسة لا تُرسل في payload الإشعار

### مراقبة الأداء
- استخدام Firebase Performance Monitoring
- تسجيل الأخطاء في Firebase Crashlytics
- مراقبة استهلاك الموارد

## استكشاف الأخطاء

### مشاكل شائعة
1. **FCM Token غير صحيح**: تحقق من تحديث التوكن
2. **أذونات مفقودة**: تأكد من إعداد قواعد Firestore
3. **حد الإرسال**: Firebase له حدود يومية للرسائل

### سجلات الأخطاء
```bash
# عرض سجلات Cloud Functions
firebase functions:log

# عرض سجلات دالة محددة
firebase functions:log --only sendNotification
```

## التطوير المستقبلي

### ميزات مقترحة
- دعم الإشعارات المجدولة
- إشعارات جماعية للمجموعات
- تحليلات متقدمة للإشعارات
- دعم الإشعارات التفاعلية

### تحسينات الأداء
- تجميع الإشعارات (Batching)
- ضغط البيانات
- تحسين استعلامات قاعدة البيانات
