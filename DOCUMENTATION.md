# MyBus - دليل المطور الشامل 📚

<div align="center">

![MyBus Documentation](https://img.shields.io/badge/MyBus-Complete%20Documentation-blue?style=for-the-badge&logo=book)

[![Version](https://img.shields.io/badge/Version-2.0.0-green?style=flat-square)](https://github.com/mustafa2080/mybus)
[![Flutter](https://img.shields.io/badge/Flutter-3.29.3-blue?style=flat-square&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-orange?style=flat-square&logo=firebase)](https://firebase.google.com)
[![Arabic](https://img.shields.io/badge/Language-Arabic%20RTL-red?style=flat-square)](https://en.wikipedia.org/wiki/Right-to-left)

**دليل شامل لنظام إدارة النقل المدرسي MyBus**

</div>

---

## 📋 جدول المحتويات

1. [نظرة عامة](#overview)
2. [البنية التقنية](#architecture)
3. [الميزات التفصيلية](#features)
4. [دليل التثبيت](#installation)
5. [دليل المطور](#developer-guide)
6. [دليل المستخدم](#user-guide)
7. [قاعدة البيانات](#database)
8. [الأمان](#security)
9. [الاختبار](#testing)
10. [النشر](#deployment)

---

## 🎯 نظرة عامة {#overview}

### ما هو MyBus؟
MyBus هو نظام إدارة نقل مدرسي شامل مطور بتقنية Flutter مع Firebase، يهدف إلى:

- **تحسين السلامة**: تتبع دقيق لموقع الطلاب في الوقت الفعلي
- **تسهيل التواصل**: ربط فعال بين المدرسة وأولياء الأمور والمشرفين
- **إدارة فعالة**: أدوات شاملة لإدارة النقل المدرسي
- **الشفافية**: تقارير مفصلة وتقييمات دورية

### الجمهور المستهدف
- **👨‍💼 الإدارة المدرسية**: إدارة شاملة للنظام
- **👨‍👩‍👧‍👦 أولياء الأمور**: متابعة أطفالهم
- **👨‍🏫 المشرفين**: إدارة الطلاب في الحافلات

### الإحصائيات الرئيسية
- **📱 3 أنواع مستخدمين**: إدارة، أولياء أمور، مشرفين
- **🔧 50+ ميزة**: شاملة ومتكاملة
- **📄 100+ ملف**: كود منظم ومرتب
- **🗄️ 15+ مجموعة**: في قاعدة البيانات
- **🎨 RTL Support**: دعم كامل للعربية
- **📱 Responsive**: يعمل على جميع الأحجام

---

## 🏗️ البنية التقنية {#architecture}

### تقنيات Frontend
```yaml
Flutter Framework:
  Version: 3.29.3
  Language: Dart 3.0+
  UI: Material Design 3
  Direction: RTL (Right-to-Left)

Navigation:
  Router: GoRouter
  State Management: Provider

UI Components:
  - Custom Widgets
  - Responsive Design
  - Arabic Typography
  - Dark/Light Theme
```

### تقنيات Backend
```yaml
Firebase Services:
  Authentication: Email/Password + Custom Claims
  Database: Cloud Firestore
  Storage: Firebase Storage
  Functions: Cloud Functions
  Analytics: Firebase Analytics
  Messaging: FCM (Push Notifications)

Security:
  - Firestore Security Rules
  - Storage Security Rules
  - Custom Authentication
  - Role-based Access Control
```

### البنية المعمارية
```
┌─────────────────────────────────────┐
│           Flutter App               │
├─────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │  Admin  │ │ Parent  │ │Supervisor││
│  │Interface│ │Interface│ │Interface││
│  └─────────┘ └─────────┘ └─────────┘│
├─────────────────────────────────────┤
│           Services Layer            │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │   Auth  │ │Database │ │Notification││
│  │ Service │ │ Service │ │ Service ││
│  └─────────┘ └─────────┘ └─────────┘│
├─────────────────────────────────────┤
│           Firebase Backend          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │   Auth  │ │Firestore│ │ Storage ││
│  └─────────┘ └─────────┘ └─────────┘│
└─────────────────────────────────────┘
```

---

## ✨ الميزات التفصيلية {#features}

### 👨‍💼 واجهة الإدارة

#### 📊 لوحة التحكم الرئيسية
- **إحصائيات شاملة**: عدد الطلاب، الحافلات، المشرفين
- **مؤشرات الأداء**: معدلات الحضور، التقييمات
- **تنبيهات فورية**: للمشاكل والطوارئ
- **تقارير سريعة**: ملخصات يومية وأسبوعية

#### 👥 إدارة المستخدمين
```dart
// إدارة الطلاب
- إضافة/تعديل/حذف الطلاب
- تعيين الحافلات والمسارات
- إدارة الصور الشخصية
- تتبع الحضور والغياب

// إدارة أولياء الأمور
- ربط الطلاب بأولياء الأمور
- إدارة الصلاحيات
- تتبع النشاط

// إدارة المشرفين
- تعيين المشرفين للحافلات
- إدارة المسارات
- تقييم الأداء
```

#### 🚌 إدارة الحافلات والمسارات
- **معلومات الحافلات**: رقم اللوحة، السعة، الحالة
- **تخطيط المسارات**: نقاط التوقف، الأوقات
- **تعيين المشرفين**: ربط المشرفين بالحافلات
- **صيانة الحافلات**: جدولة وتتبع الصيانة

#### 📈 التقارير والتحليلات
- **تقارير الحضور**: يومية، أسبوعية، شهرية
- **تحليل الأداء**: للمشرفين والحافلات
- **إحصائيات الاستخدام**: للتطبيق والميزات
- **تقارير مالية**: تكاليف التشغيل

### 👨‍👩‍👧‍👦 واجهة أولياء الأمور

#### 📍 تتبع الطلاب
```dart
// تتبع في الوقت الفعلي
- موقع الحافلة الحالي
- الوقت المتوقع للوصول
- حالة الطالب (في الحافلة/خارجها)
- مسار الرحلة

// سجل الرحلات
- تاريخ جميع الرحلات
- أوقات الركوب والنزول
- تفاصيل المسار
- ملاحظات المشرف
```

#### 🔔 نظام الإشعارات
- **إشعارات فورية**: عند ركوب/نزول الطالب
- **تنبيهات الطوارئ**: للحالات الطارئة
- **تذكيرات**: للمواعيد المهمة
- **إشعارات مخصصة**: حسب تفضيلات ولي الأمر

#### ⭐ نظام التقييم
```dart
// تقييم سريع
- تقييم بالنجوم (1-5)
- تعليق سريع
- إرسال فوري

// تقييم مفصل
- 5 فئات تقييم:
  * التواصل
  * الالتزام بالمواعيد
  * السلامة
  * المهنية
  * العناية بالطلاب
- تعليقات مفصلة
- اقتراحات للتحسين
```

#### 📝 نظام الشكاوى
- **تقديم الشكاوى**: واجهة سهلة ومرنة
- **تتبع الحالة**: متابعة حالة الشكوى
- **الرد السريع**: من الإدارة
- **أرشيف الشكاوى**: سجل كامل

### 👨‍🏫 واجهة المشرفين

#### 📱 مسح QR Code
```dart
// تسجيل الطلاب
- مسح سريع وآمن
- تسجيل الوقت والموقع
- منع المسح المتكرر
- تأكيد صوتي/بصري

// العداد الخارجي
- عدد الطلاب في الحافلة
- تصميم احترافي ومبتكر
- تحديث فوري
- إنذار عند التجاوز
```

#### 👥 إدارة قائمة الطلاب
- **قائمة شاملة**: جميع الطلاب المخصصين
- **معلومات مفصلة**: الاسم، الصورة، العنوان
- **حالة الحضور**: في الوقت الفعلي
- **جهات الاتصال**: أولياء الأمور والطوارئ

#### 📊 إحصائيات المسار
- **أداء يومي**: معدلات الحضور
- **تقييمات أولياء الأمور**: ملخص شهري
- **مؤشرات الأداء**: مقارنة مع المشرفين الآخرين
- **تحسينات مقترحة**: بناءً على البيانات

---

## 🔧 دليل التثبيت {#installation}

### المتطلبات الأساسية
```bash
# Flutter SDK
Flutter 3.29.3 or higher
Dart 3.0 or higher

# Development Tools
Android Studio 2023.1+
VS Code with Flutter Extension
Xcode 15+ (for iOS)

# Firebase Project
Firebase Console Account
Google Services Configuration
```

### خطوات التثبيت التفصيلية

#### 1. إعداد البيئة
```bash
# تحقق من إصدار Flutter
flutter --version

# تحقق من صحة الإعداد
flutter doctor

# تفعيل منصات التطوير
flutter config --enable-web
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop
```

#### 2. استنساخ المشروع
```bash
# استنساخ المستودع
git clone https://github.com/mustafa2080/mybus.git

# الانتقال للمجلد
cd mybus

# التحقق من الفروع
git branch -a

# التبديل للفرع الرئيسي
git checkout main
```

#### 3. إعداد Firebase

##### إنشاء مشروع Firebase
1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. انقر على "إضافة مشروع"
3. أدخل اسم المشروع: `mybus-school-transport`
4. فعل Google Analytics (اختياري)
5. انقر على "إنشاء مشروع"

##### إعداد Authentication
```javascript
// في Firebase Console
1. اذهب إلى Authentication
2. انقر على "البدء"
3. في تبويب "Sign-in method"
4. فعل "Email/Password"
5. احفظ التغييرات
```

##### إعداد Firestore
```javascript
// في Firebase Console
1. اذهب إلى Firestore Database
2. انقر على "إنشاء قاعدة بيانات"
3. اختر "Start in test mode"
4. اختر الموقع الجغرافي
5. انقر على "تم"
```

##### إعداد Storage
```javascript
// في Firebase Console
1. اذهب إلى Storage
2. انقر على "البدء"
3. اختر "Start in test mode"
4. انقر على "تم"
```

#### 4. تكوين التطبيق

##### Android Configuration
```bash
# إضافة التطبيق في Firebase Console
1. انقر على أيقونة Android
2. أدخل package name: com.mybus.school_transport
3. أدخل App nickname: MyBus Android
4. تحميل google-services.json
5. ضع الملف في android/app/
```

##### iOS Configuration
```bash
# إضافة التطبيق في Firebase Console
1. انقر على أيقونة iOS
2. أدخل Bundle ID: com.mybus.schoolTransport
3. أدخل App nickname: MyBus iOS
4. تحميل GoogleService-Info.plist
5. ضع الملف في ios/Runner/
```

#### 5. تثبيت التبعيات
```bash
# تثبيت packages
flutter pub get

# تنظيف المشروع
flutter clean

# إعادة تثبيت
flutter pub get

# تحديث pods (iOS)
cd ios && pod install && cd ..
```

#### 6. تشغيل التطبيق
```bash
# تشغيل على Android
flutter run -d android

# تشغيل على iOS
flutter run -d ios

# تشغيل على الويب
flutter run -d chrome

# تشغيل مع hot reload
flutter run --hot
```

---

## 👨‍💻 دليل المطور {#developer-guide}

### هيكل المشروع التفصيلي
```
mybus/
├── android/                 # Android platform files
├── ios/                     # iOS platform files
├── lib/                     # Main application code
│   ├── main.dart           # Entry point
│   ├── models/             # Data models
│   │   ├── user_model.dart
│   │   ├── student_model.dart
│   │   ├── bus_model.dart
│   │   ├── trip_model.dart
│   │   ├── complaint_model.dart
│   │   ├── survey_model.dart
│   │   └── notification_model.dart
│   ├── screens/            # UI screens
│   │   ├── admin/          # Admin interface
│   │   │   ├── admin_home_screen.dart
│   │   │   ├── all_students_screen.dart
│   │   │   ├── buses_management_screen.dart
│   │   │   ├── supervisor_assignments_screen.dart
│   │   │   ├── complaints_management_screen.dart
│   │   │   └── reports_screen.dart
│   │   ├── parent/         # Parent interface
│   │   │   ├── parent_home_screen.dart
│   │   │   ├── student_tracking_screen.dart
│   │   │   ├── notifications_screen.dart
│   │   │   ├── complaints_screen.dart
│   │   │   ├── surveys_screen.dart
│   │   │   └── trip_history_screen.dart
│   │   ├── supervisor/     # Supervisor interface
│   │   │   ├── supervisor_home_screen.dart
│   │   │   ├── qr_scanner_screen.dart
│   │   │   ├── students_list_screen.dart
│   │   │   ├── emergency_contact_screen.dart
│   │   │   └── route_statistics_screen.dart
│   │   └── auth/           # Authentication screens
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── forgot_password_screen.dart
│   ├── services/           # Business logic
│   │   ├── auth_service.dart
│   │   ├── database_service.dart
│   │   ├── notification_service.dart
│   │   ├── storage_service.dart
│   │   └── connectivity_service.dart
│   ├── widgets/            # Reusable components
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── student_avatar.dart
│   │   └── admin_layout.dart
│   └── utils/              # Utilities
│       ├── constants.dart
│       ├── validators.dart
│       ├── date_helper.dart
│       └── permissions_helper.dart
├── assets/                 # Static assets
│   ├── images/
│   ├── icons/
│   └── fonts/
├── test/                   # Unit tests
├── integration_test/       # Integration tests
└── docs/                   # Documentation
```

### نماذج البيانات الأساسية

#### UserModel
```dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserType userType;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final bool isActive;

  // Constructor, fromMap, toMap methods
}

enum UserType {
  admin,
  parent,
  supervisor,
}
```

#### StudentModel
```dart
class StudentModel {
  final String id;
  final String name;
  final String parentId;
  final String busId;
  final String grade;
  final String address;
  final String? profileImageUrl;
  final String emergencyContact;
  final DateTime createdAt;
  final bool isActive;

  // Constructor, fromMap, toMap methods
}
```

#### TripModel
```dart
class TripModel {
  final String id;
  final String studentId;
  final String supervisorId;
  final String busRoute;
  final TripType tripType;
  final TripAction action;
  final DateTime timestamp;
  final String? notes;

  // Constructor, fromMap, toMap methods
}

enum TripType {
  toSchool,
  fromSchool,
}

enum TripAction {
  boardBusToSchool,
  arriveAtSchool,
  boardBusToHome,
  arriveAtHome,
}
```

### خدمات النظام الأساسية

#### AuthService
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication methods
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  });

  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);

  // User management
  User? get currentUser;
  Stream<User?> get authStateChanges;
}
```

#### DatabaseService
```dart
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student operations
  Future<void> createStudent(StudentModel student);
  Future<void> updateStudent(StudentModel student);
  Future<void> deleteStudent(String studentId);
  Stream<List<StudentModel>> getStudents();
  Stream<List<StudentModel>> getStudentsByParent(String parentId);

  // Trip operations
  Future<void> createTrip(TripModel trip);
  Future<List<TripModel>> getStudentTrips(String studentId, DateTime date);

  // Complaint operations
  Future<void> createComplaint(ComplaintModel complaint);
  Stream<List<ComplaintModel>> getComplaints();

  // Survey operations
  Future<void> createSurvey(SurveyModel survey);
  Future<void> submitSurveyResponse(SurveyResponse response);
}
```

### أنماط التصميم المستخدمة

#### Repository Pattern
```dart
abstract class StudentRepository {
  Future<List<StudentModel>> getAllStudents();
  Future<StudentModel?> getStudentById(String id);
  Future<void> createStudent(StudentModel student);
  Future<void> updateStudent(StudentModel student);
  Future<void> deleteStudent(String id);
}

class FirebaseStudentRepository implements StudentRepository {
  final DatabaseService _databaseService;

  // Implementation
}
```

#### Provider Pattern (State Management)
```dart
class StudentProvider extends ChangeNotifier {
  final StudentRepository _repository;
  List<StudentModel> _students = [];
  bool _isLoading = false;

  List<StudentModel> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _students = await _repository.getAllStudents();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

#### Factory Pattern
```dart
class ScreenFactory {
  static Widget createScreen(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return const AdminHomeScreen();
      case UserType.parent:
        return const ParentHomeScreen();
      case UserType.supervisor:
        return const SupervisorHomeScreen();
    }
  }
}
```

### إرشادات التطوير

#### معايير الكود
```dart
// تسمية الملفات: snake_case
student_model.dart
admin_home_screen.dart

// تسمية الكلاسات: PascalCase
class StudentModel {}
class AdminHomeScreen {}

// تسمية المتغيرات: camelCase
String studentName;
bool isActive;

// تسمية الثوابت: UPPER_SNAKE_CASE
const String API_BASE_URL = 'https://api.mybus.com';
```

#### التعليقات والتوثيق
```dart
/// نموذج بيانات الطالب
///
/// يحتوي على جميع المعلومات الأساسية للطالب
/// بما في ذلك الاسم والصف والعنوان
class StudentModel {
  /// معرف فريد للطالب
  final String id;

  /// اسم الطالب الكامل
  final String name;

  /// إنشاء طالب جديد
  ///
  /// [name] اسم الطالب (مطلوب)
  /// [grade] الصف الدراسي (مطلوب)
  /// [address] عنوان السكن (اختياري)
  const StudentModel({
    required this.id,
    required this.name,
    this.address,
  });
}
```

#### معالجة الأخطاء
```dart
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class AuthException extends AppException {
  const AuthException(String message) : super(message, 'AUTH_ERROR');
}

// استخدام معالجة الأخطاء
try {
  await _databaseService.createStudent(student);
} on NetworkException catch (e) {
  _showErrorMessage('خطأ في الشبكة: ${e.message}');
} on AuthException catch (e) {
  _showErrorMessage('خطأ في المصادقة: ${e.message}');
} catch (e) {
  _showErrorMessage('خطأ غير متوقع: $e');
}
```

---

## 👤 دليل المستخدم {#user-guide}

### دليل الإدارة المدرسية

#### تسجيل الدخول
1. افتح تطبيق MyBus
2. أدخل البريد الإلكتروني وكلمة المرور
3. اضغط "تسجيل الدخول"
4. ستنتقل إلى لوحة التحكم الرئيسية

#### إدارة الطلاب
```
إضافة طالب جديد:
1. اذهب إلى "إدارة الطلاب"
2. اضغط على "إضافة طالب"
3. املأ البيانات المطلوبة:
   - الاسم الكامل
   - الصف الدراسي
   - العنوان
   - رقم ولي الأمر
   - الحافلة المخصصة
4. اضغط "حفظ"

تعديل بيانات طالب:
1. ابحث عن الطالب في القائمة
2. اضغط على أيقونة التعديل
3. عدل البيانات المطلوبة
4. اضغط "حفظ التغييرات"

حذف طالب:
1. ابحث عن الطالب في القائمة
2. اضغط على أيقونة الحذف
3. أكد عملية الحذف
```

#### إدارة الحافلات
```
إضافة حافلة جديدة:
1. اذهب إلى "إدارة الحافلات"
2. اضغط على "إضافة حافلة"
3. أدخل البيانات:
   - رقم اللوحة
   - السعة
   - المسار
   - حالة الحافلة
4. اضغط "حفظ"

تعيين مشرف للحافلة:
1. اختر الحافلة من القائمة
2. اضغط على "تعيين مشرف"
3. اختر المشرف من القائمة
4. حدد نوع الرحلة (ذهاب/عودة)
5. اضغط "تأكيد التعيين"
```

### دليل أولياء الأمور

#### تتبع الطلاب
```
عرض موقع الطالب:
1. افتح التطبيق وسجل دخولك
2. ستظهر خريطة بموقع الحافلة
3. يمكنك رؤية:
   - الموقع الحالي للحافلة
   - الوقت المتوقع للوصول
   - حالة الطالب (في الحافلة/خارجها)

استقبال الإشعارات:
- ستصلك إشعارات فورية عند:
  * ركوب الطالب للحافلة
  * وصول الطالب للمدرسة
  * ركوب الطالب للعودة
  * وصول الطالب للمنزل
```

#### تقييم المشرفين
```
تقييم سريع:
1. اذهب إلى "الاستبيانات"
2. اختر "تقييم المشرفين"
3. اختر "تقييم سريع"
4. اختر المشرف
5. أعط تقييم بالنجوم (1-5)
6. أضف تعليق (اختياري)
7. اضغط "إرسال"

تقييم مفصل:
1. اذهب إلى "الاستبيانات"
2. اختر "تقييم المشرفين"
3. اختر "تقييم شامل مع تفاصيل أكثر"
4. اختر المشرف
5. قيم في 5 فئات:
   - التواصل
   - الالتزام بالمواعيد
   - السلامة
   - المهنية
   - العناية بالطلاب
6. أضف تعليقات واقتراحات
7. اضغط "إرسال التقييم"
```

### دليل المشرفين

#### مسح QR Code
```
تسجيل ركوب الطالب:
1. افتح "مسح QR"
2. وجه الكاميرا نحو QR code الطالب
3. انتظر الصوت التأكيدي
4. ستظهر رسالة تأكيد
5. سيتم تحديث العداد تلقائياً

تسجيل نزول الطالب:
1. افتح "مسح QR"
2. امسح QR code الطالب مرة أخرى
3. ستظهر رسالة "تم تسجيل النزول"
4. سيتم تحديث العداد تلقائياً
```

#### إدارة قائمة الطلاب
```
عرض قائمة الطلاب:
1. اذهب إلى "قائمة الطلاب"
2. ستظهر جميع الطلاب المخصصين لك
3. يمكنك رؤية:
   - اسم الطالب وصورته
   - حالة الحضور
   - معلومات الاتصال
   - عنوان المنزل

الاتصال بولي الأمر:
1. اضغط على اسم الطالب
2. اضغط على "اتصال بولي الأمر"
3. سيتم فتح تطبيق الهاتف
```

---

## 🗄️ قاعدة البيانات {#database}

### هيكل Firestore Collections

#### مجموعة Users
```javascript
users: {
  userId: {
    id: "string",
    name: "string",
    email: "string",
    userType: "admin|parent|supervisor",
    phoneNumber: "string",
    profileImageUrl: "string",
    createdAt: "timestamp",
    updatedAt: "timestamp",
    isActive: "boolean",
    lastLoginAt: "timestamp"
  }
}
```

#### مجموعة Students
```javascript
students: {
  studentId: {
    id: "string",
    name: "string",
    parentId: "string",
    busId: "string",
    grade: "string",
    address: "string",
    profileImageUrl: "string",
    emergencyContact: "string",
    qrCode: "string",
    createdAt: "timestamp",
    updatedAt: "timestamp",
    isActive: "boolean"
  }
}
```

#### مجموعة Buses
```javascript
buses: {
  busId: {
    id: "string",
    plateNumber: "string",
    capacity: "number",
    route: "string",
    status: "active|maintenance|inactive",
    driverName: "string",
    driverPhone: "string",
    createdAt: "timestamp",
    updatedAt: "timestamp"
  }
}
```

#### مجموعة Trips
```javascript
trips: {
  tripId: {
    id: "string",
    studentId: "string",
    studentName: "string",
    supervisorId: "string",
    supervisorName: "string",
    busRoute: "string",
    tripType: "toSchool|fromSchool",
    action: "boardBusToSchool|arriveAtSchool|boardBusToHome|arriveAtHome",
    timestamp: "timestamp",
    location: "geopoint",
    notes: "string"
  }
}
```

#### مجموعة Supervisor Assignments
```javascript
supervisor_assignments: {
  assignmentId: {
    id: "string",
    supervisorId: "string",
    supervisorName: "string",
    busId: "string",
    busRoute: "string",
    direction: "pickup|dropoff|both",
    status: "active|inactive",
    assignedBy: "string",
    assignedAt: "timestamp",
    createdAt: "timestamp"
  }
}
```

#### مجموعة Complaints
```javascript
complaints: {
  complaintId: {
    id: "string",
    parentId: "string",
    parentName: "string",
    studentId: "string",
    studentName: "string",
    title: "string",
    description: "string",
    category: "supervisor|bus|route|other",
    priority: "low|medium|high|urgent",
    status: "pending|in_progress|resolved|closed",
    attachments: ["string"],
    submittedAt: "timestamp",
    resolvedAt: "timestamp",
    adminResponse: "string"
  }
}
```

#### مجموعة Supervisor Evaluations
```javascript
supervisor_evaluations: {
  evaluationId: {
    id: "string",
    supervisorId: "string",
    supervisorName: "string",
    parentId: "string",
    parentName: "string",
    studentId: "string",
    studentName: "string",
    busId: "string",
    ratings: {
      communication: "excellent|veryGood|good|fair|poor",
      punctuality: "excellent|veryGood|good|fair|poor",
      safety: "excellent|veryGood|good|fair|poor",
      professionalism: "excellent|veryGood|good|fair|poor",
      studentCare: "excellent|veryGood|good|fair|poor"
    },
    comments: "string",
    suggestions: "string",
    evaluatedAt: "timestamp",
    month: "number",
    year: "number"
  }
}
```

### قواعد الأمان (Security Rules)

#### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }

    // Students collection
    match /students/{studentId} {
      allow read, write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin' ||
        resource.data.parentId == request.auth.uid
      );
    }

    // Trips collection
    match /trips/{tripId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType in ['admin', 'supervisor'];
    }

    // Complaints collection
    match /complaints/{complaintId} {
      allow read, write: if request.auth != null && (
        resource.data.parentId == request.auth.uid ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin'
      );
    }

    // Supervisor evaluations
    match /supervisor_evaluations/{evaluationId} {
      allow read: if request.auth != null && (
        resource.data.parentId == request.auth.uid ||
        resource.data.supervisorId == request.auth.uid ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin'
      );
      allow write: if request.auth != null && resource.data.parentId == request.auth.uid;
    }
  }
}
```

#### Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile images
    match /profile_images/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Student images
    match /student_images/{studentId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }

    // Complaint attachments
    match /complaint_attachments/{complaintId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### فهارس قاعدة البيانات

#### Firestore Indexes
```json
{
  "indexes": [
    {
      "collectionGroup": "students",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "parentId", "order": "ASCENDING"},
        {"fieldPath": "isActive", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "trips",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "studentId", "order": "ASCENDING"},
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "supervisor_assignments",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "supervisorId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "complaints",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "submittedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "supervisor_evaluations",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "supervisorId", "order": "ASCENDING"},
        {"fieldPath": "month", "order": "ASCENDING"},
        {"fieldPath": "year", "order": "ASCENDING"}
      ]
    }
  ]
}
```

---

## 🛡️ الأمان والخصوصية {#security}

### مستويات الأمان

#### 1. أمان المصادقة
```dart
// تشفير كلمات المرور
- Firebase Auth يستخدم bcrypt
- كلمات مرور قوية مطلوبة
- إعادة تعيين كلمة المرور آمنة
- جلسات محدودة الوقت

// التحقق من الهوية
- التحقق من البريد الإلكتروني
- رموز التحقق للعمليات الحساسة
- منع الحسابات المزيفة
```

#### 2. أمان البيانات
```dart
// تشفير البيانات
- جميع البيانات مشفرة في النقل (HTTPS/TLS)
- تشفير البيانات في التخزين
- مفاتيح تشفير آمنة

// صلاحيات الوصول
- نظام صلاحيات متدرج
- فصل البيانات حسب نوع المستخدم
- تدقيق جميع العمليات
```

#### 3. أمان التطبيق
```dart
// حماية من الهجمات
- حماية من SQL Injection
- حماية من XSS
- حماية من CSRF
- تحديد معدل الطلبات (Rate Limiting)

// مراقبة الأمان
- تسجيل جميع العمليات الحساسة
- تنبيهات الأمان
- مراجعة دورية للأمان
```

### سياسة الخصوصية

#### جمع البيانات
```
البيانات المجمعة:
✓ معلومات الحساب (الاسم، البريد الإلكتروني)
✓ معلومات الطلاب (الاسم، الصف، العنوان)
✓ بيانات الموقع (لتتبع الحافلات)
✓ سجلات الاستخدام (لتحسين الخدمة)

البيانات غير المجمعة:
✗ كلمات المرور (مشفرة فقط)
✗ المعلومات المالية
✗ البيانات الطبية
✗ المحادثات الخاصة
```

#### استخدام البيانات
```
الأغراض المسموحة:
✓ تقديم خدمة النقل المدرسي
✓ ضمان سلامة الطلاب
✓ التواصل مع أولياء الأمور
✓ تحسين جودة الخدمة

الأغراض غير المسموحة:
✗ بيع البيانات لأطراف ثالثة
✗ الإعلانات التجارية
✗ أغراض غير تعليمية
✗ المشاركة مع جهات غير مخولة
```

#### حقوق المستخدمين
```
حقوقك في البيانات:
✓ الوصول لبياناتك الشخصية
✓ تصحيح البيانات الخاطئة
✓ حذف البيانات (حسب القوانين)
✓ نقل البيانات
✓ الاعتراض على المعالجة
✓ سحب الموافقة
```

---

## 🧪 الاختبار والجودة {#testing}

### أنواع الاختبارات

#### 1. اختبارات الوحدة (Unit Tests)
```dart
// اختبار نماذج البيانات
test('StudentModel should create from map correctly', () {
  final map = {
    'id': 'student1',
    'name': 'أحمد محمد',
    'parentId': 'parent1',
    'busId': 'bus1',
    'grade': 'الصف الأول',
  };

  final student = StudentModel.fromMap(map);

  expect(student.id, 'student1');
  expect(student.name, 'أحمد محمد');
  expect(student.grade, 'الصف الأول');
});

// اختبار الخدمات
test('AuthService should sign in user correctly', () async {
  final authService = AuthService();

  final user = await authService.signInWithEmailAndPassword(
    email: 'test@example.com',
    password: 'password123',
  );

  expect(user, isNotNull);
  expect(user!.email, 'test@example.com');
});
```

#### 2. اختبارات الواجهة (Widget Tests)
```dart
testWidgets('LoginScreen should display correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LoginScreen(),
    ),
  );

  // التحقق من وجود العناصر
  expect(find.text('تسجيل الدخول'), findsOneWidget);
  expect(find.byType(TextField), findsNWidgets(2));
  expect(find.byType(ElevatedButton), findsOneWidget);

  // اختبار إدخال البيانات
  await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');

  // اختبار الضغط على الزر
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
});
```

#### 3. اختبارات التكامل (Integration Tests)
```dart
void main() {
  group('MyBus Integration Tests', () {
    testWidgets('Complete user flow test', (WidgetTester tester) async {
      // تشغيل التطبيق
      await tester.pumpWidget(MyApp());

      // اختبار تسجيل الدخول
      await tester.enterText(find.byKey(Key('email')), 'parent@test.com');
      await tester.enterText(find.byKey(Key('password')), 'password123');
      await tester.tap(find.text('تسجيل الدخول'));
      await tester.pumpAndSettle();

      // التحقق من الانتقال للصفحة الرئيسية
      expect(find.text('مرحباً بك'), findsOneWidget);

      // اختبار تتبع الطلاب
      await tester.tap(find.text('تتبع الطلاب'));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleMap), findsOneWidget);
    });
  });
}
```

### أدوات ضمان الجودة

#### 1. تحليل الكود الثابت
```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - prefer_single_quotes
    - sort_child_properties_last
```

#### 2. تغطية الاختبارات
```bash
# تشغيل الاختبارات مع تغطية الكود
flutter test --coverage

# إنشاء تقرير HTML
genhtml coverage/lcov.info -o coverage/html

# عرض التقرير
open coverage/html/index.html
```

#### 3. اختبار الأداء
```dart
// اختبار أداء التطبيق
void main() {
  testWidgets('Performance test for student list', (WidgetTester tester) async {
    // إنشاء قائمة كبيرة من الطلاب
    final students = List.generate(1000, (index) =>
      StudentModel(id: 'student$index', name: 'طالب $index')
    );

    // قياس وقت البناء
    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(
      MaterialApp(
        home: StudentListScreen(students: students),
      ),
    );

    stopwatch.stop();

    // التأكد من أن الوقت أقل من حد معين
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  });
}
```

---

## 🚀 النشر والإنتاج {#deployment}

### إعداد بيئة الإنتاج

#### 1. إعداد Firebase للإنتاج
```bash
# إنشاء مشروع إنتاج منفصل
firebase projects:create mybus-production

# تكوين البيئات
firebase use --add mybus-production
firebase target:apply hosting production mybus-production

# نشر قواعد الأمان
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

#### 2. بناء التطبيق للإنتاج

##### Android APK/AAB
```bash
# بناء APK للإنتاج
flutter build apk --release

# بناء Android App Bundle
flutter build appbundle --release

# تحسين الحجم
flutter build apk --release --split-per-abi
```

##### iOS IPA
```bash
# بناء للـ App Store
flutter build ios --release

# أرشفة التطبيق
xcodebuild -workspace ios/Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -archivePath build/Runner.xcarchive \
           archive
```

##### Web
```bash
# بناء للويب
flutter build web --release

# تحسين للإنتاج
flutter build web --release --web-renderer canvaskit
```

### إعدادات الأمان للإنتاج

#### 1. متغيرات البيئة
```dart
// lib/config/environment.dart
class Environment {
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isProduction => _environment == 'production';
  static bool get isDevelopment => _environment == 'development';

  static String get apiBaseUrl {
    switch (_environment) {
      case 'production':
        return 'https://api.mybus.com';
      case 'staging':
        return 'https://staging-api.mybus.com';
      default:
        return 'https://dev-api.mybus.com';
    }
  }
}
```

#### 2. إعدادات الأمان
```dart
// تفعيل الأمان في الإنتاج
void main() {
  if (Environment.isProduction) {
    // تعطيل debug prints
    debugPrint = (String? message, {int? wrapWidth}) {};

    // تفعيل crash reporting
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }

  runApp(MyApp());
}
```

### مراقبة الأداء

#### 1. Firebase Analytics
```dart
// تتبع الأحداث المهمة
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logLogin(String userType) async {
    await _analytics.logLogin(loginMethod: userType);
  }

  static Future<void> logStudentTracking(String studentId) async {
    await _analytics.logEvent(
      name: 'student_tracking',
      parameters: {'student_id': studentId},
    );
  }

  static Future<void> logComplaintSubmission() async {
    await _analytics.logEvent(name: 'complaint_submitted');
  }
}
```

#### 2. Performance Monitoring
```dart
// مراقبة أداء العمليات المهمة
class PerformanceService {
  static Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final trace = FirebasePerformance.instance.newTrace(operationName);
    await trace.start();

    try {
      final result = await operation();
      trace.setMetric('success', 1);
      return result;
    } catch (e) {
      trace.setMetric('error', 1);
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}
```

### استراتيجية النشر

#### 1. مراحل النشر
```
Development → Testing → Staging → Production

1. Development:
   - تطوير الميزات الجديدة
   - اختبارات الوحدة
   - مراجعة الكود

2. Testing:
   - اختبارات التكامل
   - اختبارات الأداء
   - اختبارات الأمان

3. Staging:
   - اختبار في بيئة مشابهة للإنتاج
   - اختبارات المستخدم النهائي
   - مراجعة نهائية

4. Production:
   - نشر تدريجي
   - مراقبة الأداء
   - استعداد للتراجع
```

#### 2. إدارة الإصدارات
```yaml
# pubspec.yaml
version: 2.1.0+15

# تفسير الترقيم:
# 2.1.0 = major.minor.patch
# +15 = build number
```

### صيانة ما بعد النشر

#### 1. مراقبة النظام
```dart
// تسجيل الأخطاء والمشاكل
class ErrorReportingService {
  static void reportError(dynamic error, StackTrace stackTrace) {
    if (Environment.isProduction) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    } else {
      debugPrint('Error: $error\nStackTrace: $stackTrace');
    }
  }

  static void reportMessage(String message) {
    if (Environment.isProduction) {
      FirebaseCrashlytics.instance.log(message);
    } else {
      debugPrint('Log: $message');
    }
  }
}
```

#### 2. تحديثات التطبيق
```dart
// فحص التحديثات المتاحة
class UpdateService {
  static Future<bool> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // فحص الإصدار الأحدث من الخادم
      final latestVersion = await _getLatestVersion();

      return _isUpdateAvailable(currentVersion, latestVersion);
    } catch (e) {
      ErrorReportingService.reportError(e, StackTrace.current);
      return false;
    }
  }

  static Future<void> showUpdateDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('تحديث متاح'),
        content: Text('يتوفر إصدار جديد من التطبيق. يرجى التحديث للحصول على أحدث الميزات.'),
        actions: [
          TextButton(
            onPressed: () => _openAppStore(),
            child: Text('تحديث'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('لاحقاً'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📞 الدعم والمساهمة

### الحصول على المساعدة

#### 1. الوثائق والموارد
- **📚 الوثائق الرسمية**: هذا الملف
- **🎥 فيديوهات تعليمية**: [قناة YouTube](https://youtube.com/mybus)
- **📖 دليل المستخدم**: [user-guide.mybus.com](https://user-guide.mybus.com)
- **❓ الأسئلة الشائعة**: [faq.mybus.com](https://faq.mybus.com)

#### 2. قنوات الدعم
- **📧 البريد الإلكتروني**: support@mybus.com
- **💬 الدردشة المباشرة**: [chat.mybus.com](https://chat.mybus.com)
- **📱 واتساب**: +20-XXX-XXX-XXXX
- **🐛 تقارير الأخطاء**: [GitHub Issues](https://github.com/mustafa2080/mybus/issues)

### المساهمة في المشروع

#### 1. إرشادات المساهمة
```markdown
قبل المساهمة:
✓ اقرأ دليل المساهمة (CONTRIBUTING.md)
✓ تأكد من عدم وجود issue مشابه
✓ اتبع معايير الكود المحددة
✓ اكتب اختبارات للميزات الجديدة

خطوات المساهمة:
1. Fork المشروع
2. إنشاء branch جديد
3. إضافة التحسينات
4. كتابة الاختبارات
5. تشغيل جميع الاختبارات
6. إرسال Pull Request
```

#### 2. أنواع المساهمات المرحب بها
- 🐛 **إصلاح الأخطاء**: تحسين الاستقرار
- ✨ **ميزات جديدة**: إضافة وظائف مفيدة
- 📚 **تحسين الوثائق**: توضيح أفضل
- 🎨 **تحسين التصميم**: واجهة أفضل
- ⚡ **تحسين الأداء**: سرعة أكبر
- 🔒 **تحسين الأمان**: حماية أقوى

### الترخيص والحقوق

#### MIT License
```
Copyright (c) 2024 MyBus Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📊 إحصائيات المشروع

### معلومات تقنية
- **📱 منصات مدعومة**: Android, iOS, Web
- **🌍 اللغات**: العربية (RTL), الإنجليزية
- **📄 عدد الملفات**: 100+ ملف
- **📝 أسطر الكود**: 15,000+ سطر
- **🧪 تغطية الاختبارات**: 85%+
- **⚡ أداء التطبيق**: 60 FPS

### ميزات المشروع
- **👥 أنواع المستخدمين**: 3 (إدارة، أولياء أمور، مشرفين)
- **🔧 الميزات الرئيسية**: 50+ ميزة
- **🗄️ مجموعات البيانات**: 15+ مجموعة
- **📱 الشاشات**: 30+ شاشة
- **🎨 المكونات المخصصة**: 25+ مكون

---

<div align="center">

## 🎉 شكراً لاستخدام MyBus!

**صنع بـ ❤️ في مصر**

[![GitHub](https://img.shields.io/badge/GitHub-mustafa2080-black?style=flat-square&logo=github)](https://github.com/mustafa2080)
[![Email](https://img.shields.io/badge/Email-support@mybus.com-blue?style=flat-square&logo=gmail)](mailto:support@mybus.com)
[![Website](https://img.shields.io/badge/Website-mybus.com-green?style=flat-square&logo=web)](https://mybus.com)

**إصدار التوثيق**: 2.0.0
**تاريخ آخر تحديث**: ديسمبر 2024
**المطور**: Mustafa Sherif & MyBus Team

</div>