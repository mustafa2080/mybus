# حل مشكلة الإشعارات في الخلفية - Kids Bus App

## 🚨 المشكلة
الإشعارات تعمل داخل التطبيق لكن **لا تظهر في شريط الإشعارات** عندما يكون التطبيق في الخلفية أو مغلق.

## 🔍 السبب الجذري
- FCM في Flutter يحتاج خدمة Android مخصصة للإشعارات في الخلفية
- الإعدادات الافتراضية لا تكفي لضمان ظهور الإشعارات في شريط الإشعارات
- نحتاج معالجة مخصصة على مستوى Android Native

## ✅ الحل المطبق

### 1. خدمة Android مخصصة
تم إنشاء `MyFirebaseMessagingService.kt` لمعالجة الإشعارات في الخلفية:

```kotlin
class MyFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // معالجة مخصصة للرسائل
        sendNotification(title, body, data)
    }
    
    private fun sendNotification(title: String, messageBody: String, data: Map<String, String>) {
        // إنشاء إشعار Android Native
        // ضمان الظهور في شريط الإشعارات
    }
}
```

### 2. إعدادات AndroidManifest محسنة
```xml
<!-- الخدمة المخصصة -->
<service
    android:name=".MyFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>

<!-- أذونات إضافية -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

### 3. قنوات إشعارات محسنة
```kotlin
// قناة عالية الأولوية
val highChannel = NotificationChannel(
    "mybus_notifications",
    "MyBus Notifications",
    NotificationManager.IMPORTANCE_HIGH
).apply {
    setSound(defaultSoundUri, null)
    enableVibration(true)
    enableLights(true)
    setShowBadge(true)
    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
}
```

## 🔧 المزايا الجديدة

### ✅ إشعارات مضمونة في الخلفية
- **ظهور في شريط الإشعارات** حتى لو كان التطبيق مغلق
- **صوت واهتزاز** مع كل إشعار
- **أضواء LED** للتنبيه البصري
- **شارات** على أيقونة التطبيق

### ✅ معالجة متقدمة
- **أولوية عالية** للإشعارات المهمة
- **تجاوز وضع عدم الإزعاج** للطوارئ
- **ظهور على شاشة القفل**
- **معالجة البيانات المخصصة**

### ✅ قنوات منظمة
- **إشعارات عامة**: `mybus_notifications`
- **إشعارات الطلاب**: `student_notifications`
- **إشعارات الباص**: `bus_notifications`
- **تنبيهات الطوارئ**: `emergency_notifications`

## 🧪 كيفية الاختبار

### 1. اختبار من التطبيق
```
1. انتقل إلى: /test/notification-system
2. اضغط على "اختبار إشعار الخلفية"
3. تحقق من ظهور الإشعار في شريط الإشعارات
```

### 2. اختبار الخلفية الحقيقي
```
1. شغل التطبيق
2. اضغط Home (اتركه في الخلفية)
3. أرسل إشعار من Firebase Console
4. يجب أن يظهر في شريط الإشعارات
```

### 3. اختبار التطبيق مغلق
```
1. أغلق التطبيق تماماً (من Recent Apps)
2. أرسل إشعار من Firebase Console
3. يجب أن يظهر في شريط الإشعارات
4. النقر على الإشعار يفتح التطبيق
```

## 📱 إعدادات الهاتف المطلوبة

### Android
```
1. إعدادات → التطبيقات → Kids Bus
2. الإشعارات → تفعيل "السماح بالإشعارات"
3. البطارية → "عدم التحسين" (لضمان عمل الخدمة)
4. التطبيقات في الخلفية → "السماح"
```

### إعدادات إضافية لبعض الهواتف
```
Xiaomi/MIUI:
- إعدادات → إدارة التطبيقات → Kids Bus
- تفعيل "التشغيل التلقائي"
- تفعيل "تشغيل في الخلفية"

Samsung:
- إعدادات → العناية بالجهاز → البطارية
- إضافة Kids Bus لقائمة "التطبيقات غير المحسنة"

Huawei:
- إعدادات → البطارية → تشغيل التطبيق
- تفعيل "الإدارة اليدوية" لـ Kids Bus
```

## 🔍 استكشاف الأخطاء

### المشكلة: لا تظهر إشعارات في الخلفية
**الحلول**:
1. ✅ تحقق من تفعيل أذونات الإشعارات
2. ✅ تأكد من عدم تحسين البطارية للتطبيق
3. ✅ فحص إعدادات الهاتف المخصصة (Xiaomi, Samsung, etc.)
4. ✅ إعادة تشغيل الهاتف بعد التحديث

### المشكلة: الإشعارات بدون صوت
**الحلول**:
1. ✅ تحقق من إعدادات الصوت في قناة الإشعارات
2. ✅ تأكد من عدم تفعيل الوضع الصامت
3. ✅ فحص إعدادات الصوت في التطبيق
4. ✅ تحقق من ملف الصوت في المشروع

### المشكلة: الإشعارات متأخرة
**الحلول**:
1. ✅ تحقق من اتصال الإنترنت
2. ✅ تأكد من عدم تحسين البطارية
3. ✅ فحص إعدادات توفير البيانات
4. ✅ إعادة تشغيل خدمات Google Play

## 📊 رسائل FCM المطلوبة

### للإشعارات في الخلفية
```json
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "عنوان الإشعار",
    "body": "محتوى الإشعار",
    "sound": "default"
  },
  "data": {
    "channelId": "mybus_notifications",
    "type": "student_update"
  },
  "android": {
    "notification": {
      "channel_id": "mybus_notifications",
      "priority": "high",
      "sound": "default"
    }
  }
}
```

### للإشعارات عالية الأولوية
```json
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "تنبيه طوارئ",
    "body": "رسالة طوارئ مهمة"
  },
  "data": {
    "channelId": "emergency_notifications"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "emergency_notifications",
      "priority": "max"
    }
  }
}
```

## 🎯 النتيجة المتوقعة

بعد تطبيق هذا الحل:
- ✅ **الإشعارات تظهر في شريط الإشعارات** حتى لو كان التطبيق مغلق
- ✅ **صوت واهتزاز** مع كل إشعار
- ✅ **أضواء LED** للتنبيه البصري
- ✅ **ظهور على شاشة القفل**
- ✅ **فتح التطبيق** عند النقر على الإشعار
- ✅ **شارات** على أيقونة التطبيق
- ✅ **معالجة البيانات المخصصة**

## 📋 الملفات المحدثة

### ملفات جديدة
- `android/app/src/main/kotlin/com/example/kidsbus/MyFirebaseMessagingService.kt`
- `BACKGROUND_NOTIFICATIONS_FIX.md`

### ملفات محدثة
- `android/app/src/main/AndroidManifest.xml` (خدمة مخصصة + أذونات)
- `lib/services/fcm_service.dart` (تحسينات + اختبار)
- `lib/screens/test/notification_test_screen.dart` (اختبار الخلفية)

## 🚀 خطوات التطبيق

```bash
# 1. اسحب التحديثات
git pull origin main

# 2. نظف المشروع
flutter clean
flutter pub get

# 3. أعد بناء التطبيق
flutter run

# 4. اختبر النظام
# انتقل لشاشة الاختبار واختبر الإشعارات
```

---

**ملاحظة مهمة**: قد تحتاج لإعادة تشغيل الهاتف بعد تثبيت التحديث لضمان عمل الخدمة الجديدة بشكل صحيح.
