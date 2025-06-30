# دليل المساهمة في MyBus 🤝

نرحب بمساهماتكم في تطوير MyBus! هذا الدليل سيساعدكم على فهم كيفية المساهمة بفعالية.

---

## 📋 جدول المحتويات

1. [قواعد السلوك](#code-of-conduct)
2. [كيفية المساهمة](#how-to-contribute)
3. [معايير الكود](#coding-standards)
4. [عملية المراجعة](#review-process)
5. [الإبلاغ عن الأخطاء](#bug-reports)
6. [طلب الميزات](#feature-requests)

---

## 📜 قواعد السلوك {#code-of-conduct}

### التزاماتنا
- **الاحترام**: نعامل جميع المساهمين باحترام
- **التعاون**: نعمل معاً لتحقيق أهداف مشتركة
- **الشمولية**: نرحب بالجميع بغض النظر عن الخلفية
- **التعلم**: نساعد بعضنا البعض على التطور

### السلوكيات المقبولة ✅
- استخدام لغة ترحيبية وشاملة
- احترام وجهات النظر المختلفة
- قبول النقد البناء بصدر رحب
- التركيز على ما هو أفضل للمجتمع
- إظهار التعاطف مع أعضاء المجتمع الآخرين

### السلوكيات غير المقبولة ❌
- استخدام لغة أو صور جنسية
- التنمر أو التعليقات المهينة
- المضايقة العامة أو الخاصة
- نشر معلومات خاصة للآخرين دون إذن
- أي سلوك غير مهني

---

## 🚀 كيفية المساهمة {#how-to-contribute}

### 1. إعداد البيئة التطويرية

#### متطلبات النظام
```bash
# Flutter SDK
Flutter 3.29.3+
Dart 3.0+

# أدوات التطوير
Git 2.30+
Android Studio 2023.1+
VS Code (اختياري)
```

#### خطوات الإعداد
```bash
# 1. Fork المشروع على GitHub
# 2. استنساخ المشروع محلياً
git clone https://github.com/YOUR_USERNAME/mybus.git
cd mybus

# 3. إضافة المستودع الأصلي كـ upstream
git remote add upstream https://github.com/mustafa2080/mybus.git

# 4. تثبيت التبعيات
flutter pub get

# 5. تشغيل الاختبارات للتأكد من سلامة الإعداد
flutter test
```

### 2. سير العمل للمساهمة

#### إنشاء فرع جديد
```bash
# تحديث الفرع الرئيسي
git checkout main
git pull upstream main

# إنشاء فرع جديد للميزة/الإصلاح
git checkout -b feature/new-feature-name
# أو
git checkout -b fix/bug-description
```

#### تطوير التغييرات
```bash
# إجراء التغييرات المطلوبة
# كتابة الاختبارات
# تشغيل الاختبارات
flutter test

# تحليل الكود
flutter analyze

# تنسيق الكود
dart format .
```

#### إرسال التغييرات
```bash
# إضافة التغييرات
git add .

# كتابة رسالة commit واضحة
git commit -m "feat: add new student tracking feature"

# رفع التغييرات
git push origin feature/new-feature-name
```

#### إنشاء Pull Request
1. اذهب إلى صفحة المشروع على GitHub
2. اضغط على "New Pull Request"
3. اختر الفرع الذي أنشأته
4. اكتب وصفاً واضحاً للتغييرات
5. اربط أي Issues ذات صلة
6. اضغط "Create Pull Request"

---

## 📝 معايير الكود {#coding-standards}

### تسمية الملفات والمجلدات
```dart
// الملفات: snake_case
student_model.dart
admin_home_screen.dart
database_service.dart

// المجلدات: snake_case
lib/screens/admin/
lib/services/
lib/models/
```

### تسمية الكلاسات والمتغيرات
```dart
// الكلاسات: PascalCase
class StudentModel {}
class AdminHomeScreen extends StatefulWidget {}

// المتغيرات والدوال: camelCase
String studentName;
bool isActive;
void loadStudents() {}

// الثوابت: UPPER_SNAKE_CASE
const String API_BASE_URL = 'https://api.mybus.com';
const int MAX_STUDENTS_PER_BUS = 50;

// الـ enums: PascalCase
enum UserType { admin, parent, supervisor }
enum TripStatus { pending, inProgress, completed }
```

### هيكل الملفات
```dart
// ترتيب الـ imports
import 'package:flutter/material.dart';           // Flutter packages
import 'package:firebase_core/firebase_core.dart'; // External packages

import '../models/student_model.dart';             // Relative imports
import '../services/database_service.dart';

// ترتيب محتويات الكلاس
class ExampleWidget extends StatefulWidget {
  // 1. الثوابت
  static const String routeName = '/example';
  
  // 2. المتغيرات النهائية
  final String title;
  final VoidCallback? onPressed;
  
  // 3. Constructor
  const ExampleWidget({
    super.key,
    required this.title,
    this.onPressed,
  });
  
  // 4. Override methods
  @override
  State<ExampleWidget> createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  // 1. المتغيرات
  bool _isLoading = false;
  String _errorMessage = '';
  
  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    // تنظيف الموارد
    super.dispose();
  }
  
  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI code
    );
  }
  
  // 4. Private methods
  Future<void> _loadData() async {
    // Implementation
  }
  
  void _handleError(String error) {
    // Error handling
  }
}
```

### التعليقات والتوثيق
```dart
/// نموذج بيانات الطالب
/// 
/// يحتوي على جميع المعلومات الأساسية للطالب
/// بما في ذلك الاسم والصف والعنوان ومعلومات الاتصال
class StudentModel {
  /// معرف فريد للطالب
  final String id;
  
  /// اسم الطالب الكامل
  final String name;
  
  /// إنشاء طالب جديد
  /// 
  /// [name] اسم الطالب (مطلوب)
  /// [grade] الصف الدراسي (مطلوب)
  /// [parentId] معرف ولي الأمر (مطلوب)
  /// 
  /// مثال:
  /// ```dart
  /// final student = StudentModel(
  ///   id: 'student123',
  ///   name: 'أحمد محمد',
  ///   grade: 'الصف الأول',
  ///   parentId: 'parent456',
  /// );
  /// ```
  const StudentModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.parentId,
  });
}
```

### معالجة الأخطاء
```dart
// استخدام try-catch مع أنواع أخطاء محددة
try {
  await _databaseService.createStudent(student);
  _showSuccessMessage('تم إضافة الطالب بنجاح');
} on NetworkException catch (e) {
  _showErrorMessage('خطأ في الشبكة: ${e.message}');
} on ValidationException catch (e) {
  _showErrorMessage('خطأ في البيانات: ${e.message}');
} catch (e) {
  _showErrorMessage('خطأ غير متوقع: $e');
  // تسجيل الخطأ للمراجعة
  ErrorReportingService.reportError(e, StackTrace.current);
}
```

### الاختبارات
```dart
// اختبار وحدة
test('StudentModel should create from map correctly', () {
  // Arrange
  final map = {
    'id': 'student1',
    'name': 'أحمد محمد',
    'grade': 'الصف الأول',
  };
  
  // Act
  final student = StudentModel.fromMap(map);
  
  // Assert
  expect(student.id, 'student1');
  expect(student.name, 'أحمد محمد');
  expect(student.grade, 'الصف الأول');
});

// اختبار widget
testWidgets('LoginScreen should display correctly', (WidgetTester tester) async {
  // Arrange
  await tester.pumpWidget(
    MaterialApp(home: LoginScreen()),
  );
  
  // Assert
  expect(find.text('تسجيل الدخول'), findsOneWidget);
  expect(find.byType(TextField), findsNWidgets(2));
});
```

---

## 🔍 عملية المراجعة {#review-process}

### معايير المراجعة
- **الوظائف**: هل الكود يعمل كما هو متوقع؟
- **الأداء**: هل الكود محسن للأداء؟
- **الأمان**: هل هناك ثغرات أمنية؟
- **القابلية للقراءة**: هل الكود واضح ومفهوم؟
- **الاختبارات**: هل الاختبارات شاملة وتمر؟

### قائمة المراجعة
- [ ] الكود يتبع معايير التسمية
- [ ] التعليقات واضحة ومفيدة
- [ ] الاختبارات موجودة وتمر
- [ ] لا توجد تحذيرات من المحلل
- [ ] الكود منسق بشكل صحيح
- [ ] معالجة الأخطاء مناسبة
- [ ] الأداء محسن
- [ ] لا توجد ثغرات أمنية

---

## 🐛 الإبلاغ عن الأخطاء {#bug-reports}

### قبل الإبلاغ
1. تأكد من أن الخطأ قابل للتكرار
2. ابحث في Issues الموجودة
3. جرب أحدث إصدار من التطبيق

### معلومات مطلوبة
```markdown
**وصف الخطأ**
وصف واضح ومختصر للخطأ

**خطوات التكرار**
1. اذهب إلى '...'
2. اضغط على '...'
3. انتقل إلى '...'
4. شاهد الخطأ

**السلوك المتوقع**
وصف واضح لما كان يجب أن يحدث

**لقطات الشاشة**
إذا كان ذلك مناسباً، أضف لقطات شاشة

**معلومات البيئة**
- نظام التشغيل: [مثل iOS 17.0, Android 14]
- إصدار التطبيق: [مثل 2.0.0]
- نوع الجهاز: [مثل iPhone 15, Samsung Galaxy S24]

**معلومات إضافية**
أي معلومات أخرى مفيدة حول المشكلة
```

---

## ✨ طلب الميزات {#feature-requests}

### قبل الطلب
1. ابحث في Issues الموجودة
2. تأكد من أن الميزة تتماشى مع أهداف المشروع
3. فكر في التأثير على المستخدمين الآخرين

### معلومات مطلوبة
```markdown
**هل طلبك مرتبط بمشكلة؟**
وصف واضح للمشكلة. مثال: أشعر بالإحباط عندما [...]

**وصف الحل المطلوب**
وصف واضح ومختصر لما تريده أن يحدث

**وصف البدائل المفكر فيها**
وصف واضح لأي حلول أو ميزات بديلة فكرت فيها

**معلومات إضافية**
أي معلومات أخرى أو لقطات شاشة حول طلب الميزة
```

---

## 🏆 الاعتراف بالمساهمين

نقدر جميع المساهمات ونعترف بها في:
- ملف CONTRIBUTORS.md
- صفحة About في التطبيق
- ملاحظات الإصدار
- وسائل التواصل الاجتماعي

---

## 📞 التواصل

إذا كان لديك أسئلة حول المساهمة:
- **GitHub Discussions**: للنقاشات العامة
- **GitHub Issues**: للأخطاء وطلبات الميزات
- **Email**: contribute@mybus.com
- **Discord**: [MyBus Community](https://discord.gg/mybus)

---

**شكراً لمساهمتكم في جعل MyBus أفضل! 🚌❤️**
