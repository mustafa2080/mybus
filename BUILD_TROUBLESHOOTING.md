# دليل استكشاف أخطاء البناء - Build Troubleshooting Guide

## 🚨 المشاكل الشائعة وحلولها

### 1. مشاكل Gradle Properties المُهملة

#### المشكلة:
```
The option 'android.enableIncrementalDesugaring' is deprecated
The option 'android.bundle.enableUncompressedNativeLibs' is deprecated
```

#### الحل:
تم إصلاح هذه المشاكل في الإصدار الحالي. إذا واجهت مشاكل مشابهة:

1. **تحديث gradle.properties:**
   - إزالة الخصائص المُهملة
   - استخدام إعدادات بسيطة ومتوافقة

2. **تبسيط build.gradle:**
   - تجنب الإعدادات المعقدة
   - استخدام الإعدادات الافتراضية

### 2. مشاكل إصدارات Android Gradle Plugin

#### المشكلة:
تعارض بين إصدارات مختلفة من Android Gradle Plugin

#### الحل:
```cmd
# تنظيف شامل
flutter clean
cd android
gradlew clean
cd ..
flutter pub get
```

### 3. مشاكل الذاكرة أثناء البناء (Out of Memory)

#### المشكلة:
```
../../runtime/vm/zone.cc: 96: error: Out of memory.
OutOfMemoryError during build
Dart_DetectNullSafety crash
```

#### الحل المحدث (2025-07-15):
تم تحسين إعدادات الذاكرة في gradle.properties:
- زيادة الذاكرة من 4GB إلى 6GB
- تحسين إعدادات JVM مع G1GC
- تعطيل R8 الكامل مؤقتاً
- تعطيل البناء المتوازي
- إضافة HeapDumpOnOutOfMemoryError للتشخيص

#### الحلول السريعة:
1. **استخدم السكريبت الجديد:**
   ```cmd
   build_memory_safe.bat
   ```

2. **أو تطبيق الحل يدوياً:**
   ```cmd
   set GRADLE_OPTS=-Xmx3G -XX:MaxMetaspaceSize=512m
   flutter clean
   flutter build apk --debug --no-tree-shake-icons
   ```

3. **إذا استمرت المشكلة:**
   - أعد تشغيل الكمبيوتر
   - أغلق جميع البرامج الأخرى
   - تأكد من وجود 8GB ذاكرة على الأقل

### 4. مشاكل Firebase (google-services.json مفقود)

#### المشكلة:
```
File google-services.json is missing.
The Google Services Plugin cannot function without it.
```

#### الحل السريع:
1. **استخدم Debug mode فقط:**
   ```cmd
   build_debug_only.bat
   ```

2. **أو البناء اليدوي:**
   ```cmd
   flutter build apk --debug
   ```

#### الحل الشامل:
- راجع `FIREBASE_FIX_GUIDE.md` للحل التفصيلي
- تأكد من وجود `android/app/google-services.json`
- تحقق من إعدادات Firebase Console

## 🛠️ خيارات البناء المتاحة

### 1. البناء Debug فقط (موصى به لتجنب مشاكل Firebase)
```cmd
build_debug_only.bat
```
- يتجنب مشاكل Firebase و Release mode
- حل مشكلة google-services.json
- إعدادات ذاكرة محسنة
- مناسب للتطوير والاختبار

### 2. البناء الآمن للذاكرة (لحل مشكلة Out of Memory)
```cmd
build_memory_safe.bat
```
- حل مشكلة نفاد الذاكرة
- يحاول Debug ثم Profile ثم Release
- تنظيف شامل قبل البناء
- مراقبة استهلاك الذاكرة

### 3. البناء الآمن العادي
```cmd
build_safe.bat
```
- بناء Debug بسيط
- تجنب المشاكل المعقدة
- مناسب للاختبار

### 3. البناء البسيط
```cmd
build_simple.bat
```
- بناء Debug مع فحص الحجم
- خيار وسط بين الأمان والتحسين

### 4. البناء المحسن (بعد حل مشكلة الذاكرة)
```cmd
build_optimized.bat
```
- بناء Release مع جميع التحسينات
- للإنتاج النهائي
- يتطلب ذاكرة كافية

### 5. البناء اليدوي مع تحسين الذاكرة
```cmd
set GRADLE_OPTS=-Xmx3G -XX:MaxMetaspaceSize=512m
flutter clean
flutter pub get
flutter build apk --debug
```

## 🔍 تشخيص المشاكل

### فحص البيئة:
```cmd
flutter doctor -v
```

### فحص إعدادات Gradle:
```cmd
cd android
gradlew --version
cd ..
```

### فحص مساحة القرص:
```cmd
dir C:\ /-c | find "bytes free"
```

## 📊 مقارنة أحجام البناء

| نوع البناء | الحجم المتوقع | الاستخدام |
|------------|---------------|-----------|
| Debug | 80-120 MB | التطوير والاختبار |
| Release (بدون تحسين) | 60-90 MB | اختبار الإنتاج |
| Release (مع تحسين) | 40-70 MB | النشر النهائي |

## 🎯 نصائح لتجنب المشاكل

### 1. قبل البناء:
- تأكد من تحديث Flutter: `flutter upgrade`
- نظف المشروع: `flutter clean`
- تحقق من المساحة المتاحة (5GB على الأقل)

### 2. أثناء البناء:
- لا تشغل برامج أخرى كثيفة الاستخدام
- تأكد من اتصال الإنترنت المستقر
- راقب رسائل الخطأ بعناية

### 3. بعد البناء:
- اختبر APK على جهاز حقيقي
- تحقق من عمل جميع الميزات
- راقب الأداء والاستقرار

## 🆘 إذا فشل كل شيء

### الحل الأخير:
1. **إعادة تثبيت Flutter:**
   ```cmd
   flutter clean
   flutter pub cache repair
   flutter doctor
   ```

2. **إعادة تثبيت Android SDK:**
   - تحديث Android Studio
   - إعادة تحميل SDK Tools

3. **إنشاء مشروع جديد:**
   ```cmd
   flutter create test_project
   cd test_project
   flutter build apk
   ```

## 📞 الحصول على المساعدة

إذا واجهت مشاكل لا يمكن حلها:

1. **تحقق من السجلات:**
   ```cmd
   flutter build apk --verbose
   ```

2. **ابحث في المجتمع:**
   - [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

3. **اتصل بالدعم:**
   - البريد الإلكتروني: support@mybus.com
   - الهاتف: +966501234567

---

**تذكر:** البناء الناجح أهم من التحسينات المعقدة. ابدأ بالبناء البسيط ثم أضف التحسينات تدريجياً.
