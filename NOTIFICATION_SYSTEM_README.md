# 🔔 نظام الإشعارات المتقدم - تطبيق كيدز باص

## نظرة عامة
نظام إشعارات شامل ومتقدم مصمم خصيصاً لتطبيق كيدز باص، يوفر إشعارات ذكية وفورية لثلاثة أنواع من المستخدمين: الأدمن، أولياء الأمور، والمشرفين.

## ✨ المميزات الرئيسية

### 🎯 **إشعارات ذكية ومخصصة**
- إشعارات فورية مع دعم الصوت والاهتزاز
- إشعارات الخلفية والمقدمة
- تخصيص الإشعارات حسب نوع المستخدم
- دعم الأولويات المختلفة (منخفضة، متوسطة، عالية، عاجلة)

### 🔒 **الخصوصية والأمان**
- التحقق من الصلاحيات قبل الإرسال
- تشفير البيانات الحساسة
- حدود الإرسال لمنع الإزعاج
- تسجيل الأنشطة المشبوهة

### 📱 **دعم متعدد القنوات**
- Firebase Cloud Messaging (FCM)
- الإشعارات داخل التطبيق
- البريد الإلكتروني
- إمكانية إضافة SMS لاحقاً

### ⚙️ **إعدادات متقدمة**
- ساعات الصمت
- تخصيص أنواع الإشعارات
- إعدادات الصوت والاهتزاز
- وضع عطلة نهاية الأسبوع

## 📋 **أنواع الإشعارات المدعومة**

### 👨‍💼 **إشعارات الأدمن**
| الحدث | الوصف | الأولوية | الصوت |
|-------|-------|----------|-------|
| شكوى جديدة | عند إرسال شكوى من ولي أمر | عالية | ✅ |
| طالب جديد | عند إضافة طالب جديد | متوسطة | ✅ |
| تبليغ غياب | عند تبليغ غياب طالب | متوسطة | ✅ |
| تقييم مشرف | عند تقييم مشرف من ولي أمر | متوسطة | ✅ |
| إكمال البروفايل | عند إكمال ملف التعريف | منخفضة | ❌ |
| حساب جديد | عند إنشاء حساب ولي أمر | متوسطة | ✅ |

### 👨‍👩‍👧‍👦 **إشعارات أولياء الأمور**
| الحدث | الوصف | الأولوية | الصوت |
|-------|-------|----------|-------|
| ركب الباص | عند ركوب الطالب الباص | عالية | ✅ |
| وصل للمدرسة | عند وصول الطالب للمدرسة | عالية | ✅ |
| وصل للمنزل | عند وصول الطالب للمنزل | عالية | ✅ |
| تعيين في باص | عند تعيين الطالب في خط سير | عالية | ✅ |
| تعيين مشرف | عند تعيين مشرف للطالب | عالية | ✅ |
| حذف الطالب | عند حذف الطالب من النظام | عالية | ✅ |

### 👩‍🏫 **إشعارات المشرفين**
| الحدث | الوصف | الأولوية | الصوت |
|-------|-------|----------|-------|
| تعيين في باص | عند تعيين المشرف في باص | عالية | ✅ |
| تبليغ غياب | عند تسجيل غياب طالب | متوسطة | ❌ |
| تحديث بيانات | عند تحديث بيانات طالب | منخفضة | ❌ |

## 🏗️ **البنية التقنية**

### 📁 **هيكل الملفات**
```
lib/
├── models/
│   ├── notification_model.dart           # نموذج الإشعار الأساسي
│   ├── notification_event_model.dart     # نموذج أحداث الإشعارات
│   └── notification_settings_model.dart  # نموذج إعدادات المستخدم
├── services/
│   ├── notification_service.dart         # الخدمة الرئيسية
│   ├── firebase_messaging_service.dart   # خدمة FCM
│   ├── event_trigger_service.dart        # مراقبة الأحداث
│   ├── notification_privacy_service.dart # الخصوصية والأمان
│   └── notification_system_initializer.dart # تهيئة النظام
├── screens/
│   ├── admin/admin_notifications_management_screen.dart
│   ├── parent/parent_notifications_screen.dart
│   └── supervisor/supervisor_notifications_screen.dart
└── utils/
    └── notification_system_tester.dart   # أدوات الاختبار
```

### 🔧 **الخدمات الأساسية**

#### 1. **NotificationService** - الخدمة الرئيسية
```dart
// إرسال إشعار مخصص
await notificationService.sendCustomNotification(
  recipientId: 'user_id',
  recipientType: 'parent',
  title: 'عنوان الإشعار',
  body: 'محتوى الإشعار',
  type: NotificationType.studentBoarded,
  priority: NotificationPriority.high,
);

// إرسال إشعار من حدث
await notificationService.sendEventNotification(
  eventId: 'student_boarded_bus',
  eventData: {
    'studentName': 'أحمد محمد',
    'parentId': 'parent_id',
    'time': DateTime.now().toIso8601String(),
  },
);
```

#### 2. **FirebaseMessagingService** - خدمة FCM
```dart
// تهيئة الخدمة
await messagingService.initialize();

// الحصول على FCM Token
final token = messagingService.fcmToken;
```

#### 3. **EventTriggerService** - مراقبة الأحداث
```dart
// تهيئة مراقبة الأحداث
await eventTriggerService.initialize();

// التحقق من الحالة
final isActive = eventTriggerService.isInitialized;
```

## 🚀 **التثبيت والإعداد**

### 1. **إضافة التبعيات**
```yaml
dependencies:
  firebase_messaging: ^15.1.6
  flutter_local_notifications: ^18.0.1
  audioplayers: ^6.1.0
```

### 2. **تهيئة النظام**
```dart
// في main.dart
import 'services/notification_system_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // تهيئة نظام الإشعارات
  await initializeNotificationSystem();
  
  runApp(MyApp());
}
```

### 3. **ربط مع AuthService**
```dart
// في AuthService
import 'notification_system_initializer.dart';

class AuthService extends ChangeNotifier {
  // بعد تسجيل الدخول
  Future<void> signIn(String email, String password) async {
    // ... كود تسجيل الدخول
    
    // تهيئة النظام للمستخدم
    await NotificationSystemHelper.initializer.initializeForUser(user);
  }
}
```

## 🔧 **الاستخدام**

### إرسال إشعار بسيط
```dart
final notificationService = getNotificationService();

await notificationService.sendCustomNotification(
  recipientId: 'parent_id',
  recipientType: 'parent',
  title: 'ركب أحمد الباص',
  body: 'ركب طفلك أحمد الباص بأمان في تمام الساعة 7:30 صباحاً',
  type: NotificationType.studentBoarded,
  priority: NotificationPriority.high,
  requiresSound: true,
  requiresVibration: true,
);
```

### الحصول على الإشعارات
```dart
// الحصول على الإشعارات للمستخدم
Stream<List<NotificationModel>> notifications = 
    notificationService.getUserNotifications(userId);

// الحصول على عدد الإشعارات غير المقروءة
Stream<int> unreadCount = 
    notificationService.getUnreadNotificationsCount(userId);
```

### إدارة الإعدادات
```dart
// الحصول على إعدادات المستخدم
final settings = await notificationService.getUserNotificationSettings(userId);

// تحديث الإعدادات
final updatedSettings = settings.copyWith(
  soundEnabled: true,
  vibrationEnabled: false,
);
await notificationService.updateUserNotificationSettings(updatedSettings);
```

## 🧪 **الاختبار**

### اختبار سريع
```dart
import 'utils/notification_system_tester.dart';

// فحص سريع للنظام
final isHealthy = await quickNotificationSystemCheck();
print('حالة النظام: ${isHealthy ? "سليم" : "يحتاج مراجعة"}');
```

### اختبار شامل
```dart
// تشغيل اختبار شامل
final results = await runFullNotificationSystemTest();
print('نسبة النجاح: ${results.overallSuccess}%');

// إنشاء تقرير مفصل
final report = NotificationSystemTester().generateDetailedReport(results);
print(report);
```

## 📊 **المراقبة والإحصائيات**

### عداد الإشعارات في الأدمن
- عرض عدد الإشعارات غير المقروءة
- إحصائيات يومية وأسبوعية
- تقارير الأداء

### مراقبة الأخطاء
- تسجيل الأخطاء في Firebase Crashlytics
- مراقبة الأداء
- تنبيهات الأمان

## 🔒 **الأمان والخصوصية**

### حماية البيانات
- تشفير البيانات الحساسة
- التحقق من الصلاحيات
- حدود الإرسال

### قواعد Firestore
```javascript
// قواعد الأمان للإشعارات
match /notifications/{notificationId} {
  allow read: if isAuthenticated() && isOwner(resource.data.recipientId);
  allow update: if isAuthenticated() && isOwner(resource.data.recipientId);
}
```

## 🚀 **التطوير المستقبلي**

### ميزات مخططة
- [ ] دعم الإشعارات التفاعلية
- [ ] إشعارات جماعية للمجموعات
- [ ] تحليلات متقدمة
- [ ] دعم الإشعارات المجدولة
- [ ] تكامل مع Apple Watch

### تحسينات الأداء
- [ ] تجميع الإشعارات (Batching)
- [ ] ضغط البيانات
- [ ] تحسين استعلامات قاعدة البيانات

## 📞 **الدعم والمساعدة**

### استكشاف الأخطاء
1. تأكد من تهيئة Firebase بشكل صحيح
2. تحقق من أذونات الإشعارات
3. راجع سجلات الأخطاء
4. استخدم أدوات الاختبار المدمجة

### الحصول على المساعدة
- راجع الوثائق التقنية
- استخدم أدوات التشخيص المدمجة
- تحقق من سجلات Firebase Console

---

**تم تطوير هذا النظام بعناية فائقة لضمان تجربة مستخدم ممتازة وأمان عالي** 🛡️✨
