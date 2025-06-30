# MyBus API Reference 📡

## نظرة عامة
هذا المرجع يوثق جميع الخدمات والدوال المتاحة في تطبيق MyBus.

---

## 🔐 AuthService

### تسجيل الدخول
```dart
Future<UserModel?> signInWithEmailAndPassword({
  required String email,
  required String password,
})
```
**الوصف**: تسجيل دخول المستخدم بالبريد الإلكتروني وكلمة المرور  
**المعاملات**:
- `email`: البريد الإلكتروني (مطلوب)
- `password`: كلمة المرور (مطلوب)

**القيمة المرجعة**: `UserModel?` - بيانات المستخدم أو null في حالة الفشل

### إنشاء حساب جديد
```dart
Future<UserModel?> createUserWithEmailAndPassword({
  required String email,
  required String password,
  required String name,
  required UserType userType,
})
```

### إعادة تعيين كلمة المرور
```dart
Future<void> sendPasswordResetEmail(String email)
```

### تسجيل الخروج
```dart
Future<void> signOut()
```

---

## 🗄️ DatabaseService

### إدارة الطلاب

#### إنشاء طالب جديد
```dart
Future<void> createStudent(StudentModel student)
```

#### تحديث بيانات طالب
```dart
Future<void> updateStudent(StudentModel student)
```

#### حذف طالب
```dart
Future<void> deleteStudent(String studentId)
```

#### جلب جميع الطلاب
```dart
Stream<List<StudentModel>> getStudents()
```

#### جلب طلاب ولي أمر محدد
```dart
Stream<List<StudentModel>> getStudentsByParent(String parentId)
```

### إدارة الرحلات

#### إنشاء رحلة جديدة
```dart
Future<void> createTrip(TripModel trip)
```

#### جلب رحلات طالب في تاريخ محدد
```dart
Future<List<TripModel>> getStudentTrips(String studentId, DateTime date)
```

### إدارة الشكاوى

#### إنشاء شكوى جديدة
```dart
Future<void> createComplaint(ComplaintModel complaint)
```

#### جلب جميع الشكاوى
```dart
Stream<List<ComplaintModel>> getComplaints()
```

#### تحديث حالة الشكوى
```dart
Future<void> updateComplaintStatus(String complaintId, String status)
```

### إدارة تقييمات المشرفين

#### إنشاء تقييم مشرف
```dart
Future<void> createSupervisorEvaluation(SupervisorEvaluationModel evaluation)
```

#### جلب تقييمات مشرف
```dart
Future<List<SupervisorEvaluationModel>> getSupervisorEvaluations(String supervisorId)
```

#### جلب تقييمات شهرية
```dart
Future<List<SupervisorEvaluationModel>> getSupervisorEvaluationsByMonth(int month, int year)
```

---

## 🔔 NotificationService

### إرسال إشعار
```dart
Future<void> sendNotification({
  required String userId,
  required String title,
  required String body,
  Map<String, dynamic>? data,
})
```

### إرسال إشعار جماعي
```dart
Future<void> sendBulkNotification({
  required List<String> userIds,
  required String title,
  required String body,
  Map<String, dynamic>? data,
})
```

### جلب إشعارات المستخدم
```dart
Stream<List<NotificationModel>> getUserNotifications(String userId)
```

---

## 📱 StorageService

### رفع صورة
```dart
Future<String> uploadImage({
  required File imageFile,
  required String path,
  String? fileName,
})
```

### حذف صورة
```dart
Future<void> deleteImage(String imageUrl)
```

### جلب رابط التحميل
```dart
Future<String> getDownloadUrl(String path)
```

---

## 🌐 ConnectivityService

### فحص الاتصال
```dart
Future<bool> isConnected()
```

### مراقبة حالة الاتصال
```dart
Stream<ConnectivityResult> get connectivityStream
```

---

## 📊 AnalyticsService

### تسجيل حدث
```dart
static Future<void> logEvent({
  required String name,
  Map<String, dynamic>? parameters,
})
```

### تسجيل تسجيل الدخول
```dart
static Future<void> logLogin(String userType)
```

### تسجيل تتبع الطلاب
```dart
static Future<void> logStudentTracking(String studentId)
```

---

## 🛡️ SecurityService

### تشفير البيانات
```dart
String encryptData(String data, String key)
```

### فك تشفير البيانات
```dart
String decryptData(String encryptedData, String key)
```

### التحقق من الصلاحيات
```dart
bool hasPermission(UserType userType, String action)
```

---

## 📍 LocationService

### جلب الموقع الحالي
```dart
Future<Position> getCurrentLocation()
```

### مراقبة تغيير الموقع
```dart
Stream<Position> get locationStream
```

### حساب المسافة
```dart
double calculateDistance(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
)
```

---

## 🔍 ValidationService

### التحقق من البريد الإلكتروني
```dart
static bool isValidEmail(String email)
```

### التحقق من رقم الهاتف
```dart
static bool isValidPhoneNumber(String phoneNumber)
```

### التحقق من قوة كلمة المرور
```dart
static bool isStrongPassword(String password)
```

---

## 📅 DateHelper

### تنسيق التاريخ
```dart
static String formatDate(DateTime date, {String? format})
```

### تحويل إلى تاريخ عربي
```dart
static String toArabicDate(DateTime date)
```

### حساب الفرق بين التواريخ
```dart
static int daysBetween(DateTime start, DateTime end)
```

---

## 🎨 ThemeService

### تطبيق الثيم
```dart
static ThemeData getTheme(bool isDark)
```

### تغيير الثيم
```dart
static void toggleTheme()
```

### جلب الثيم الحالي
```dart
static bool get isDarkMode
```

---

## 📱 PermissionsHelper

### طلب صلاحية الكاميرا
```dart
static Future<bool> requestCameraPermission()
```

### طلب صلاحية الموقع
```dart
static Future<bool> requestLocationPermission()
```

### طلب صلاحية الإشعارات
```dart
static Future<bool> requestNotificationPermission()
```

---

## 🔧 Constants

### ثوابت التطبيق
```dart
class AppConstants {
  static const String appName = 'MyBus';
  static const String appVersion = '2.0.0';
  static const int maxStudentsPerBus = 50;
  static const int maxComplaintLength = 500;
  static const Duration sessionTimeout = Duration(hours: 24);
}
```

### ثوابت Firebase
```dart
class FirebaseConstants {
  static const String usersCollection = 'users';
  static const String studentsCollection = 'students';
  static const String tripsCollection = 'trips';
  static const String complaintsCollection = 'complaints';
}
```

---

## 🚨 Error Handling

### أنواع الأخطاء
```dart
class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, [this.code]);
}

class NetworkException extends AppException {
  const NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class AuthException extends AppException {
  const AuthException(String message) : super(message, 'AUTH_ERROR');
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message, 'VALIDATION_ERROR');
}
```

### معالجة الأخطاء
```dart
try {
  await someOperation();
} on NetworkException catch (e) {
  showErrorMessage('خطأ في الشبكة: ${e.message}');
} on AuthException catch (e) {
  showErrorMessage('خطأ في المصادقة: ${e.message}');
} catch (e) {
  showErrorMessage('خطأ غير متوقع: $e');
}
```
