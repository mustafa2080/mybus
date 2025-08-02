# دليل إعداد Firebase Cloud Messaging (FCM) للإشعارات الخارجية

## 📱 نظام الإشعارات المحدث

تم تطوير نظام إشعارات متقدم يدعم إرسال الإشعارات خارج التطبيق (Push Notifications) لجميع أنواع المستخدمين:
- 👨‍💻 **الأدمن** - إشعارات الشكاوى والرسائل الإدارية
- 👨‍💼 **المشرف** - إشعارات الرحلات وحالة الطلاب
- 👨‍👩‍👧‍👦 **ولي الأمر** - إشعارات حالة الطالب والرسائل

## 🔧 الملفات المضافة/المحدثة

### الخدمات الجديدة:
- `lib/services/notification_sender_service.dart` - خدمة إرسال الإشعارات المستهدفة
- `lib/screens/admin/send_notification_screen.dart` - صفحة إرسال الإشعارات الإدارية

### الخدمات المحدثة:
- `lib/services/fcm_service.dart` - تحسين حفظ الـ tokens وإضافة دوال الإرسال
- `lib/screens/parent/add_complaint_screen.dart` - إضافة إرسال إشعار للأدمن عند الشكوى
- `lib/screens/supervisor/absence_management_screen.dart` - إضافة إرسال إشعار لولي الأمر عند الغياب
- `lib/screens/admin/student_management_screen.dart` - إضافة دوال تحديث حالة الطالب مع الإشعارات

## 🚀 كيفية العمل حالياً

### 1. حفظ الـ Tokens:
- يتم حفظ FCM Token لكل مستخدم مع نوعه في مجموعتين:
  - `users/{userId}` - بيانات المستخدم مع الـ token
  - `fcm_tokens/{userId}` - tokens منفصلة للبحث السريع

### 2. إرسال الإشعارات:
- **للنوع المحدد**: `sendNotificationToUserType(userType: 'admin')`
- **لمستخدم محدد**: `sendNotificationToUser(userId: 'user123')`
- **طوارئ لجميع المستخدمين**: `sendEmergencyNotification()`

### 3. أمثلة الاستخدام:

```dart
// إرسال شكوى جديدة للأدمن
await _notificationSender.sendComplaintNotificationToAdmin(
  complaintId: 'complaint123',
  studentName: 'أحمد محمد',
  complaintType: 'شكوى من السائق',
);

// إرسال تحديث حالة الطالب لولي الأمر
await _notificationSender.sendStudentStatusNotificationToParent(
  parentId: 'parent123',
  studentName: 'أحمد محمد',
  status: 'boarded',
  busNumber: '123',
  location: 'المدرسة',
);

// إرسال رسالة إدارية
await _notificationSender.sendAdminMessage(
  title: 'إعلان مهم',
  message: 'سيتم تغيير مواعيد الحافلات غداً',
  targetUserType: 'parent', // أو null لجميع المستخدمين
);
```

## ⚠️ للحصول على إشعارات حقيقية خارج التطبيق

حالياً النظام يحفظ الإشعارات في قاعدة البيانات فقط. للحصول على إشعارات push حقيقية، تحتاج إلى:

### 1. الحصول على Server Key من Firebase:
1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك
3. اذهب إلى Project Settings > Cloud Messaging
4. انسخ الـ Server Key

### 2. تحديث دالة `_sendPushNotification` في `fcm_service.dart`:

```dart
Future<void> _sendPushNotification({
  required String token,
  required String title,
  required String body,
  required Map<String, String> data,
  required String channelId,
}) async {
  try {
    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=YOUR_SERVER_KEY_HERE', // ضع Server Key هنا
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
        },
        'data': data,
        'android': {
          'notification': {
            'channel_id': channelId,
            'sound': 'default',
            'priority': 'high',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default',
              'badge': 1,
            },
          },
        },
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ Push notification sent successfully');
    } else {
      debugPrint('❌ Failed to send push notification: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ Error sending push notification: $e');
  }
}
```

### 3. إضافة import للـ http:
```dart
import 'package:http/http.dart' as http;
```

## 🔔 أنواع الإشعارات المدعومة

### للأدمن:
- 📝 شكاوى جديدة من أولياء الأمور
- 🚨 تنبيهات النظام والطوارئ
- 📊 تقارير وإحصائيات

### للمشرف:
- 🚌 بداية وانتهاء الرحلات
- 👨‍🎓 تحديثات حالة الطلاب
- ⚠️ تنبيهات الطوارئ

### لولي الأمر:
- 🚌 ركوب/نزول الطالب من الحافلة
- ❌ تسجيل غياب الطالب
- ⏰ تأخير الحافلة
- 📝 رسائل إدارية
- ⭐ تقييمات سلوك الطالب

## 📱 قنوات الإشعارات

- `mybus_notifications` - الإشعارات العامة
- `student_notifications` - إشعارات الطلاب
- `bus_notifications` - إشعارات الحافلات
- `emergency_notifications` - إشعارات الطوارئ

## 🎯 الميزات المتقدمة

### 1. تصفية الإشعارات:
- إرسال للمستخدم الصحيح فقط
- تجنب الإشعارات المكررة
- دعم الإشعارات المستهدفة

### 2. إدارة الـ Tokens:
- تحديث تلقائي للـ tokens
- حذف الـ tokens غير النشطة
- دعم منصات متعددة (Android/iOS)

### 3. أولويات الإشعارات:
- عادية للرسائل الإدارية
- عالية لتحديثات الطلاب
- طوارئ للحالات الحرجة

## 🔧 استكشاف الأخطاء

### إذا لم تصل الإشعارات:
1. تأكد من أن الـ Server Key صحيح
2. تحقق من أن الـ Token محفوظ بشكل صحيح
3. تأكد من أن المستخدم لديه صلاحيات الإشعارات
4. راجع logs التطبيق للأخطاء

### للاختبار:
1. استخدم صفحة "إرسال إشعار إداري" في لوحة الأدمن
2. جرب إرسال شكوى من حساب ولي أمر
3. سجل غياب طالب من حساب المشرف

## 📞 الدعم

النظام جاهز للعمل ويدعم جميع أنواع الإشعارات. فقط أضف الـ Server Key للحصول على إشعارات push حقيقية خارج التطبيق.
