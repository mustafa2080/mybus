# نظام الإشعارات المحسن - Kids Bus App

## نظرة عامة

تم تطوير نظام إشعارات شامل ومحسن لتطبيق Kids Bus يدعم:
- ✅ **الصوت والاهتزاز** مع كل إشعار
- ✅ **الظهور في قائمة الإشعارات** حتى لو كان التطبيق مغلق
- ✅ **إشعارات فورية** لجميع الأحداث المهمة
- ✅ **تصنيف الإشعارات** حسب النوع والأولوية
- ✅ **إعدادات قابلة للتخصيص** لكل مستخدم

## المكونات الرئيسية

### 1. EnhancedNotificationService
خدمة الإشعارات المحسنة الجديدة:

```dart
// تهيئة الخدمة
await EnhancedNotificationService().initialize();

// إرسال إشعار مع الصوت
await service.sendNotificationToUser(
  userId: 'user123',
  title: 'إشعار مهم',
  body: 'محتوى الإشعار',
  type: 'student',
);
```

### 2. NotificationService المحدث
الخدمة الأصلية مع دوال محسنة:

```dart
// إشعار تسكين طالب مع الصوت
await NotificationService().notifyStudentAssignmentWithSound(
  studentId: 'student123',
  studentName: 'أحمد محمد',
  busId: 'bus001',
  busRoute: 'الرياض - الملز',
  parentId: 'parent123',
  supervisorId: 'supervisor123',
);
```

### 3. قنوات الإشعارات المتخصصة

#### قناة الإشعارات العامة
- **المعرف**: `general_notifications`
- **الاستخدام**: الإشعارات العامة
- **الصوت**: ✅ مفعل
- **الاهتزاز**: ✅ مفعل

#### قناة إشعارات الطلاب
- **المعرف**: `student_notifications`
- **الاستخدام**: تسكين وإلغاء تسكين الطلاب
- **الأولوية**: عالية جداً
- **الصوت**: ✅ مفعل

#### قناة إشعارات الباص
- **المعرف**: `bus_notifications`
- **الاستخدام**: ركوب ونزول الطلاب
- **الأولوية**: عالية جداً
- **الصوت**: ✅ مفعل

#### قناة إشعارات الغياب
- **المعرف**: `absence_notifications`
- **الاستخدام**: طلبات الغياب والموافقات
- **الأولوية**: عالية
- **الصوت**: ✅ مفعل

#### قناة إشعارات الإدارة
- **المعرف**: `admin_notifications`
- **الاستخدام**: إشعارات إدارية وطوارئ
- **الأولوية**: عالية جداً
- **الصوت**: ✅ مفعل

## أنواع الإشعارات المدعومة

### 1. إشعارات الطلاب 👨‍🎓

#### تسكين الطالب
```dart
await notifyStudentAssignmentWithSound(
  studentId: 'student123',
  studentName: 'أحمد محمد',
  busId: 'bus001',
  busRoute: 'الرياض - الملز',
  parentId: 'parent123',
  supervisorId: 'supervisor123',
);
```

**المستقبلون:**
- ✅ ولي الأمر: "🚌 تم تسكين أحمد محمد في الباص رقم bus001"
- ✅ المشرف: "👨‍🏫 طالب جديد في الباص - تم إضافة أحمد محمد"
- ✅ الإدارة: "📋 تم تسكين أحمد محمد في الباص bus001"

#### إلغاء تسكين الطالب
```dart
await notifyStudentUnassignmentWithSound(
  studentId: 'student123',
  studentName: 'أحمد محمد',
  busId: 'bus001',
  parentId: 'parent123',
  supervisorId: 'supervisor123',
);
```

**المستقبلون:**
- ✅ ولي الأمر: "🚫 تم إلغاء تسكين أحمد محمد من الباص"
- ✅ المشرف: "👋 مغادرة طالب - تم إزالة أحمد محمد"
- ✅ الإدارة: "📋 تم إلغاء تسكين أحمد محمد"

### 2. إشعارات الباص 🚌

#### ركوب الطالب
```dart
await notifyStudentBoardedWithSound(
  studentId: 'student123',
  studentName: 'أحمد محمد',
  busId: 'bus001',
  parentId: 'parent123',
  supervisorId: 'supervisor123',
);
```

**المستقبلون:**
- ✅ ولي الأمر: "🚌 ركب الطالب الباص - أحمد محمد ركب الباص في 07:30"
- ✅ الإدارة: "🚌 ركوب طالب - أحمد محمد ركب الباص bus001"

#### نزول الطالب
```dart
await notifyStudentAlightedWithSound(
  studentId: 'student123',
  studentName: 'أحمد محمد',
  busId: 'bus001',
  parentId: 'parent123',
  supervisorId: 'supervisor123',
);
```

**المستقبلون:**
- ✅ ولي الأمر: "🏠 نزل الطالب من الباص - أحمد محمد نزل في 14:30"
- ✅ الإدارة: "🏠 نزول طالب - أحمد محمد نزل من الباص bus001"

### 3. إشعارات الغياب 📝

#### طلب غياب جديد
```dart
await notifyAbsenceRequestWithSound(
  studentId: 'student123',
  studentName: 'أحمد محمد',
  parentId: 'parent123',
  supervisorId: 'supervisor123',
  busId: 'bus001',
  absenceDate: DateTime(2024, 12, 25),
  reason: 'مرض',
);
```

**المستقبلون:**
- ✅ المشرف: "📝 طلب غياب جديد - طلب غياب لأحمد محمد بتاريخ 25/12/2024"
- ✅ الإدارة: "📝 طلب غياب جديد - طلب غياب لأحمد محمد من الباص bus001"

#### الموافقة على الغياب
```dart
await notifyAbsenceApprovedWithSound(
  studentId: 'student123',
  studentName: 'أحمد محمد',
  parentId: 'parent123',
  absenceDate: DateTime(2024, 12, 25),
  approvedBy: 'المشرف أحمد',
);
```

**المستقبلون:**
- ✅ ولي الأمر: "✅ تم قبول طلب الغياب - تم قبول طلب غياب أحمد محمد"

#### رفض الغياب
```dart
await notifyAbsenceRejectedWithSound(
  studentId: 'student123',
  studentName: 'أحمد محمد',
  parentId: 'parent123',
  absenceDate: DateTime(2024, 12, 25),
  rejectedBy: 'المشرف أحمد',
  reason: 'السبب غير مقبول',
);
```

**المستقبلون:**
- ✅ ولي الأمر: "❌ تم رفض طلب الغياب - السبب: السبب غير مقبول"

### 4. إشعارات الشكاوى 📢

#### شكوى جديدة
```dart
await notifyNewComplaintWithSound(
  complaintId: 'complaint123',
  parentId: 'parent123',
  parentName: 'والد الطالب',
  subject: 'شكوى حول الخدمة',
  category: 'خدمة',
);
```

**المستقبلون:**
- ✅ الإدارة: "📢 شكوى جديدة - شكوى جديدة من والد الطالب"

#### رد على الشكوى
```dart
await notifyComplaintResponseWithSound(
  complaintId: 'complaint123',
  parentId: 'parent123',
  subject: 'شكوى حول الخدمة',
  response: 'تم حل المشكلة',
);
```

**المستقبلون:**
- ✅ ولي الأمر: "💬 رد على الشكوى - تم الرد على شكواك"

### 5. إشعارات الطوارئ 🚨

#### حالة طوارئ
```dart
await notifyEmergencyWithSound(
  busId: 'bus001',
  supervisorId: 'supervisor123',
  supervisorName: 'المشرف أحمد',
  emergencyType: 'عطل في الباص',
  description: 'عطل مفاجئ في المحرك',
  parentIds: ['parent1', 'parent2'],
);
```

**المستقبلون:**
- ✅ أولياء الأمور: "🚨 حالة طوارئ - حالة طوارئ في الباص bus001"
- ✅ الإدارة: "🚨 حالة طوارئ - حالة طوارئ من المشرف أحمد"

### 6. إشعارات حالة الرحلة 📍

#### تحديث حالة الرحلة
```dart
await notifyTripStatusUpdateWithSound(
  busId: 'bus001',
  busRoute: 'الرياض - الملز',
  status: 'started', // started, completed, delayed
  parentIds: ['parent1', 'parent2'],
  supervisorId: 'supervisor123',
);
```

**المستقبلون:**
- ✅ أولياء الأمور: "🚌 بدأت الرحلة - الباص bus001"
- ✅ الإدارة: "📍 تحديث حالة الرحلة - الباص bus001"

## الشاشات الجديدة

### 1. شاشة الإشعارات (`/notifications`)
- عرض جميع الإشعارات مع الأيقونات والألوان
- تحديد الإشعارات كمقروءة
- حذف الإشعارات
- فلترة حسب النوع

### 2. شاشة إعدادات الإشعارات
- تفعيل/إيقاف الصوت والاهتزاز
- تخصيص أنواع الإشعارات
- ساعات الهدوء

### 3. شاشة اختبار الإشعارات (`/test/notifications`)
- اختبار جميع أنواع الإشعارات
- التأكد من عمل الصوت والاهتزاز
- عرض معلومات الإشعار

## الإعدادات والتخصيص

### إعدادات المستخدم
```dart
class NotificationSettings {
  final bool enablePushNotifications;
  final bool enableSoundNotifications;
  final bool enableVibrationNotifications;
  final bool enableStudentNotifications;
  final bool enableBusNotifications;
  final bool enableAbsenceNotifications;
  final bool enableAdminNotifications;
  final bool enableEmergencyNotifications; // لا يمكن إيقافها
  final String quietHoursStart; // "22:00"
  final String quietHoursEnd; // "07:00"
}
```

### أولويات الإشعارات
- **🚨 طوارئ**: أولوية قصوى (4)
- **🚌 باص/طلاب**: أولوية عالية (3)
- **📝 غياب**: أولوية متوسطة (2)
- **📢 عام**: أولوية منخفضة (1)

## التكامل مع التطبيق

### تهيئة النظام في main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // تهيئة نظام الإشعارات
  await NotificationService().initialize();
  await EnhancedNotificationService().initialize();
  
  runApp(MyApp());
}
```

### حفظ FCM Token
```dart
// عند تسجيل الدخول
await NotificationService().saveFCMTokenForUser(userId);
```

### الاستماع للإشعارات
```dart
// في الشاشة الرئيسية
StreamBuilder<List<NotificationModel>>(
  stream: NotificationService().getUnreadNotificationsStream(userId),
  builder: (context, snapshot) {
    final notifications = snapshot.data ?? [];
    return Badge(
      count: notifications.length,
      child: IconButton(
        onPressed: () => context.push('/notifications'),
        icon: Icon(Icons.notifications),
      ),
    );
  },
);
```

## الملفات المهمة

```
lib/
├── services/
│   ├── enhanced_notification_service.dart  # الخدمة المحسنة الجديدة
│   └── notification_service.dart           # الخدمة الأصلية المحدثة
├── models/
│   └── notification_model.dart             # نموذج الإشعار المحسن
├── screens/
│   ├── common/
│   │   └── notifications_screen.dart       # شاشة الإشعارات
│   └── test_notifications_screen.dart      # شاشة اختبار الإشعارات
└── widgets/
    └── responsive_widgets.dart             # widgets متجاوبة للإشعارات
```

## الاختبار والتطوير

### اختبار الإشعارات
1. انتقل إلى `/test/notifications`
2. اختبر كل نوع من الإشعارات
3. تأكد من الصوت والاهتزاز
4. تحقق من ظهور الإشعار في القائمة

### إضافة إشعار جديد
1. أضف النوع الجديد في `NotificationType`
2. أنشئ دالة في `EnhancedNotificationService`
3. أضف wrapper في `NotificationService`
4. استخدم الدالة في المكان المناسب

## المزايا الجديدة

### ✅ تم تنفيذه
- [x] إشعارات مع صوت واهتزاز
- [x] ظهور في قائمة الإشعارات
- [x] إشعارات تسكين الطلاب
- [x] إشعارات ركوب/نزول الباص
- [x] إشعارات طلبات الغياب
- [x] إشعارات الشكاوى
- [x] إشعارات الطوارئ
- [x] إشعارات الإدارة
- [x] شاشة الإشعارات
- [x] شاشة إعدادات الإشعارات
- [x] شاشة اختبار الإشعارات

### 🔄 قيد التطوير
- [ ] إشعارات push عبر Firebase Functions
- [ ] إشعارات مجدولة
- [ ] إحصائيات الإشعارات
- [ ] تصدير سجل الإشعارات

النظام الآن جاهز ويدعم جميع أنواع الإشعارات المطلوبة مع الصوت والظهور في قائمة الإشعارات! 🎉
