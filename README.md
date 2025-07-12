# تطبيق MyBus - نظام إدارة النقل المدرسي 🚌

## نظرة عامة
تطبيق MyBus هو نظام شامل لإدارة النقل المدرسي مطور باستخدام Flutter مع تكامل Firebase. يوفر التطبيق حلولاً متكاملة لإدارة الطلاب والحافلات والمشرفين وأولياء الأمور.

## ✅ آخر التحديثات (تم اليوم)
- **تم تنظيم وتحسين ملف main.dart** مع إضافة Provider pattern
- **تم إنشاء نظام توجيه شامل** باستخدام GoRouter
- **تم إصلاح جميع مشاكل الاستيراد والربط** بين الملفات
- **تم تحسين وتنظيم الخدمات** مع إضافة ChangeNotifier للـ AuthService
- **تم تحسين تجربة المستخدم والتنقل** مع إضافة مساعدات UI
- **تم إضافة نظام فحص التطبيق** للتأكد من عمل جميع المكونات
- **المشروع منظم ومحسن بالكامل** وجاهز للرفع على GitHub
- **تاريخ آخر تحديث**: 11 يوليو 2025

## المميزات الرئيسية

### للإدارة
- إدارة شاملة للطلاب والحافلات
- نظام تتبع الحضور والغياب
- إدارة الشكاوى والاقتراحات
- تقارير وإحصائيات متقدمة
- إدارة المشرفين وأولياء الأمور
- نظام الإشعارات

### لأولياء الأمور
- تتبع موقع الحافلة في الوقت الفعلي
- الإبلاغ عن غياب الطلاب
- تقديم الشكاوى والاقتراحات
- استقبال الإشعارات المهمة
- عرض معلومات الطلاب والحافلة

### للمشرفين
- مسح رموز QR للطلاب
- تسجيل الحضور والانصراف
- إدارة قائمة الطلاب
- التواصل مع الإدارة

## التقنيات المستخدمة
- **Flutter**: إطار العمل الأساسي للتطبيق
- **Firebase**: قاعدة البيانات والمصادقة والتخزين
- **Dart**: لغة البرمجة
- **Material Design**: تصميم واجهة المستخدم

## متطلبات التشغيل
- Flutter SDK 3.0 أو أحدث
- Dart SDK 2.17 أو أحدث
- Android Studio أو VS Code
- حساب Firebase مُعد

## التثبيت والإعداد

### 1. استنساخ المشروع
```bash
git clone https://github.com/mustafa2080/mybus.git
cd mybus
```

### 2. تثبيت التبعيات
```bash
flutter pub get
```

### 3. إعداد Firebase
1. إنشاء مشروع جديد في Firebase Console
2. إضافة تطبيق Android/iOS
3. تحميل ملف `google-services.json` ووضعه في `android/app/`
4. تحميل ملف `GoogleService-Info.plist` ووضعه في `ios/Runner/`

### 4. تشغيل التطبيق
```bash
flutter run
```

## 🚀 التحسينات الجديدة

### 🏗️ البنية المحسنة
- **نظام Provider**: تم تطبيق Provider pattern لإدارة الحالة بشكل أفضل
- **نظام التوجيه المتقدم**: استخدام GoRouter لتوجيه أكثر مرونة وقوة
- **مساعدات UI**: إضافة UIHelper و NavigationHelper لتحسين تجربة المطور
- **فحص التطبيق**: نظام شامل لفحص صحة التطبيق والتأكد من عمل جميع المكونات

### 🎨 تحسينات واجهة المستخدم
- **ثيم موحد**: نظام ثيم شامل يدعم الوضع الفاتح والداكن
- **مكونات قابلة لإعادة الاستخدام**: مكونات UI محسنة ومنظمة
- **تجربة مستخدم محسنة**: تنقل أسهل ورسائل خطأ أوضح

### ⚡ تحسينات الأداء
- **خدمات محسنة**: AuthService مع ChangeNotifier لتحديثات فورية
- **إدارة حالة أفضل**: استخدام Provider لإدارة الحالة بكفاءة
- **تحميل ذكي**: مؤشرات تحميل وإدارة أخطاء محسنة

## هيكل المشروع المحسن
```
lib/
├── models/          # نماذج البيانات
├── screens/         # شاشات التطبيق
│   ├── admin/       # شاشات الإدارة
│   ├── parent/      # شاشات أولياء الأمور
│   ├── supervisor/  # شاشات المشرفين
│   └── auth/        # شاشات المصادقة
├── services/        # خدمات التطبيق (محسنة)
├── routes/          # نظام التوجيه (جديد)
├── widgets/         # مكونات واجهة المستخدم
└── utils/           # أدوات مساعدة (محسنة ومطورة)
    ├── app_constants.dart    # ثوابت التطبيق
    ├── app_validator.dart    # فحص التطبيق (جديد)
    ├── navigation_helper.dart # مساعد التنقل (جديد)
    └── ui_helper.dart        # مساعد واجهة المستخدم (جديد)
```

## المساهمة
نرحب بالمساهمات! يرجى:
1. عمل Fork للمشروع
2. إنشاء فرع جديد للميزة
3. تنفيذ التغييرات
4. إرسال Pull Request

## الترخيص
هذا المشروع مرخص تحت رخصة MIT.

## التواصل
للاستفسارات والدعم، يرجى التواصل عبر GitHub Issues.

---

## 🔧 إصلاحات حديثة (يوليو 2025)

### تم إصلاح المشاكل التالية:
- ✅ **Firebase Configuration**: تم إعداد Firebase بشكل صحيح لجميع المنصات
- ✅ **Google Services**: تم نقل ملف `google-services.json` إلى المكان الصحيح
- ✅ **iOS Configuration**: تم إنشاء ملف `GoogleService-Info.plist` و `Podfile`
- ✅ **Web Configuration**: تم تحديث إعدادات Firebase للويب
- ✅ **Build Configuration**: تم تحديث ملفات Gradle وإضافة Firebase plugins
- ✅ **Permissions**: تم إضافة صلاحيات الكاميرا والإشعارات
- ✅ **Arabic Support**: تم تحسين دعم اللغة العربية في جميع الملفات

### ملفات تم إنشاؤها/تحديثها:
- `android/app/google-services.json` - إعدادات Firebase للأندرويد
- `ios/Runner/GoogleService-Info.plist` - إعدادات Firebase لـ iOS
- `ios/Podfile` - إعدادات CocoaPods
- `web/index.html` - تحديث إعدادات Firebase للويب
- `web/firebase-messaging-sw.js` - تحديث Service Worker
- `web/manifest.json` - تحديث معلومات التطبيق
- `run_project.sh` - سكريبت تشغيل سريع

### كيفية التشغيل بعد الإصلاحات:
```bash
# تشغيل سريع
./run_project.sh

# أو خطوة بخطوة
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
flutter run
```

### متطلبات النظام المحدثة:
- Flutter SDK: 3.29.3
- Dart SDK: 3.6.0+
- Android: API 21+
- iOS: 12.0+
- Web: متصفحات حديثة

تم تطوير هذا المشروع بعناية لتوفير حل شامل وموثوق لإدارة النقل المدرسي.

## 🔧 استكشاف الأخطاء

### إذا واجهت مشاكل في البناء:
```bash
# تنظيف شامل
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub get

# إعادة بناء المشروع
flutter build apk --debug
```

### اختبار التطبيق البسيط:
```bash
# تشغيل تطبيق اختبار بسيط
flutter run lib/test_app.dart
```

### فحص المشروع:
```bash
# فحص الأخطاء
flutter analyze

# فحص حالة Flutter
flutter doctor

# فحص التبعيات
flutter pub deps
```

### مشاكل شائعة وحلولها:

#### 1. مشكلة Gradle Build Failed:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

#### 2. مشكلة Firebase:
- تأكد من وجود `google-services.json` في `android/app/`
- تأكد من إعدادات Firebase في `lib/firebase_options.dart`

#### 3. مشكلة التبعيات:
```bash
flutter pub cache repair
flutter pub get
```

#### 4. مشكلة Java/Kotlin:
- تأكد من استخدام Java JDK 17
- تأكد من إعدادات Gradle الصحيحة

## 📞 الدعم والمساعدة

إذا واجهت أي مشاكل أو لديك اقتراحات، يرجى فتح issue في GitHub أو التواصل معنا.

---

**تم تطوير هذا التطبيق بعناية لضمان سلامة وأمان الأطفال في رحلتهم المدرسية** 🚌👨‍👩‍👧‍👦

<!-- تم إصلاح جميع مشاكل Firebase والبناء - Fixed all Firebase and build issues -->
