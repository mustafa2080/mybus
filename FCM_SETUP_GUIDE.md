# دليل إعداد Firebase Cloud Messaging (FCM) - Kids Bus App

## 🎯 الهدف
إعداد نظام إشعارات متكامل باستخدام Firebase Cloud Messaging يعمل في جميع حالات التطبيق:
- ✅ **التطبيق نشط** (Foreground)
- ✅ **التطبيق في الخلفية** (Background)
- ✅ **التطبيق مغلق تماماً** (Terminated)

## 🏗️ البنية المطبقة

### 1. الملفات الجديدة
```
lib/services/
├── fcm_service.dart              # خدمة FCM الرئيسية
└── fcm_background_handler.dart   # معالج الرسائل في الخلفية
```

### 2. الملفات المحدثة
```
lib/
├── main.dart                     # تهيئة FCM ومعالج الخلفية
├── services/enhanced_notification_service.dart  # دعم FCM
└── screens/test/notification_test_screen.dart   # اختبار FCM
```

## 🔧 المكونات الرئيسية

### 1. FCMService - الخدمة الرئيسية
```dart
class FCMService {
  // تهيئة شاملة للخدمة
  Future<void> initialize()
  
  // إعداد قنوات الإشعارات
  Future<void> _createNotificationChannels()
  
  // طلب الأذونات
  Future<void> _requestPermissions()
  
  // معالجة الرسائل في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message)
  
  // عرض الإشعارات المحلية
  Future<void> _showLocalNotification(RemoteMessage message)
}
```

### 2. Background Message Handler
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // معالجة الرسائل عندما يكون التطبيق مغلق أو في الخلفية
  await _showBackgroundNotification(message);
}
```

## 📱 إعدادات Android

### AndroidManifest.xml
```xml
<!-- أذونات الإشعارات -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- خدمات FCM -->
<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>

<!-- مستقبل FCM -->
<receiver
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</receiver>

<!-- إعدادات الإشعارات الافتراضية -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="mybus_notifications" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

### قنوات الإشعارات
```dart
const List<AndroidNotificationChannel> channels = [
  AndroidNotificationChannel(
    'mybus_notifications',
    'إشعارات MyBus',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('notification_sound'),
    enableVibration: true,
    playSound: true,
    showBadge: true,
  ),
  // المزيد من القنوات...
];
```

## 🍎 إعدادات iOS

### Info.plist
```xml
<!-- أذونات الإشعارات -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>

<!-- إعدادات الإشعارات -->
<key>FirebaseMessagingAutoInitEnabled</key>
<true/>
```

### AppDelegate.swift
```swift
import Firebase
import UserNotifications

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // طلب أذونات الإشعارات
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      print("Notification permission granted: \(granted)")
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 🔄 تدفق العمل

### 1. تهيئة التطبيق
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase
  await Firebase.initializeApp();
  
  // تسجيل معالج الخلفية
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // تهيئة FCM
  await FCMService().initialize();
  
  runApp(MyApp());
}
```

### 2. معالجة الرسائل

#### التطبيق نشط (Foreground)
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // عرض إشعار محلي
  _showLocalNotification(message);
});
```

#### التطبيق في الخلفية/مغلق
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // معالجة الرسالة وعرض الإشعار
  await _showBackgroundNotification(message);
}
```

#### فتح التطبيق من إشعار
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // التنقل للصفحة المناسبة
  _handleNotificationNavigation(message);
});
```

## 🧪 الاختبار

### 1. من شاشة الاختبار
```
المسار: /test/notification-system
الميزات:
- فحص حالة FCM
- عرض FCM Token
- اختبار الإشعارات المختلفة
```

### 2. اختبار يدوي
```bash
# إرسال إشعار تجريبي من Firebase Console
1. انتقل إلى Firebase Console
2. اختر المشروع
3. انتقل إلى Cloud Messaging
4. اختر "Send your first message"
5. أدخل العنوان والمحتوى
6. اختر التطبيق
7. أرسل الإشعار
```

### 3. اختبار برمجي
```dart
// إرسال إشعار لمستخدم محدد
await FCMService().sendNotificationToUser(
  userId: 'user_id',
  title: 'عنوان الإشعار',
  body: 'محتوى الإشعار',
  data: {'key': 'value'},
);
```

## 📊 أنواع الإشعارات المدعومة

### 1. إشعارات البيانات (Data Messages)
```json
{
  "data": {
    "type": "student_update",
    "studentId": "123",
    "channelId": "student_notifications"
  }
}
```

### 2. إشعارات العرض (Notification Messages)
```json
{
  "notification": {
    "title": "عنوان الإشعار",
    "body": "محتوى الإشعار",
    "sound": "notification_sound.mp3"
  }
}
```

### 3. إشعارات مختلطة (Combined)
```json
{
  "notification": {
    "title": "عنوان الإشعار",
    "body": "محتوى الإشعار"
  },
  "data": {
    "type": "emergency",
    "route": "/emergency"
  }
}
```

## 🔧 استكشاف الأخطاء

### مشكلة: الإشعارات لا تظهر في الخلفية
**الحلول**:
1. تأكد من تسجيل `firebaseMessagingBackgroundHandler`
2. تحقق من أذونات الإشعارات
3. تأكد من إعدادات قنوات الإشعارات
4. فحص سجلات التطبيق

### مشكلة: لا يوجد FCM Token
**الحلول**:
1. تحقق من اتصال الإنترنت
2. تأكد من تهيئة Firebase
3. فحص إعدادات Google Services
4. إعادة تشغيل التطبيق

### مشكلة: الإشعارات بدون صوت
**الحلول**:
1. تحقق من وجود ملف الصوت
2. تأكد من إعدادات القناة
3. فحص إعدادات الهاتف
4. تحقق من الوضع الصامت

## 📈 الأداء والتحسين

### 1. تحسين استهلاك البطارية
```dart
// استخدام أولوية مناسبة
priority: Priority.high, // فقط للإشعارات المهمة

// تجنب الإشعارات المتكررة
onlyAlertOnce: true,
```

### 2. تحسين حجم الرسائل
```dart
// تجنب البيانات الكبيرة في payload
// استخدام معرفات بدلاً من البيانات الكاملة
data: {
  'studentId': '123',
  'type': 'update'
}
```

### 3. إدارة Tokens
```dart
// حفظ Token في Firestore
await _firestore.collection('users').doc(userId).update({
  'fcmToken': token,
  'lastTokenUpdate': FieldValue.serverTimestamp(),
  'platform': Platform.operatingSystem,
});
```

## 🎉 النتيجة النهائية

بعد تطبيق هذا الإعداد:
- ✅ **الإشعارات تعمل في جميع الحالات**
- ✅ **صوت واهتزاز مع كل إشعار**
- ✅ **قنوات منظمة للإشعارات**
- ✅ **معالجة متقدمة للرسائل**
- ✅ **اختبار شامل للنظام**
- ✅ **توثيق كامل للتطوير**

---

**ملاحظة**: تأكد من تحديث `google-services.json` و `GoogleService-Info.plist` بالإعدادات الصحيحة من Firebase Console.
