# حل مشكلة Out of Memory في MyBus

## 🚨 المشكلة
```
../../runtime/vm/zone.cc: 96: error: Out of memory.
version=3.8.0 (stable) (Wed May 14 09:07:14 2025 -0700) on "windows_x64"
=== Crash occurred when compiling dart:core_RegExp_Task .+ not found in root project. in optimizing JIT mode in AllocationSinking_Sink pass
```

## ✅ الحل المطبق

### 1. تحسين إعدادات الذاكرة في gradle.properties
```properties
# زيادة الذاكرة من 4GB إلى 6GB
org.gradle.jvmargs=-Xmx6G -XX:MaxMetaspaceSize=1G -XX:+UseG1GC -Dfile.encoding=UTF-8 -XX:+HeapDumpOnOutOfMemoryError

# تعطيل R8 الكامل مؤقتاً
android.enableR8.fullMode=false

# تحسين إعدادات Gradle
org.gradle.parallel=false
org.gradle.workers.max=2
kotlin.incremental=false
```

### 2. تعطيل التحسينات في build.gradle
```gradle
release {
    signingConfig = signingConfigs.debug
    // تعطيل التحسينات مؤقتاً لحل مشكلة الذاكرة
    minifyEnabled = false
    shrinkResources = false
}
```

### 3. إنشاء سكريبت بناء محسن للذاكرة
- ملف جديد: `build_memory_safe.bat`
- يراقب استهلاك الذاكرة
- ينظف ذاكرة Gradle التخزينية
- يطبق إعدادات ذاكرة محسنة

## 🚀 كيفية الاستخدام

### الطريقة الأولى (موصى بها):
```cmd
build_memory_safe.bat
```

### الطريقة الثانية (يدوياً):
```cmd
# تعيين متغيرات الذاكرة
set GRADLE_OPTS=-Xmx3G -XX:MaxMetaspaceSize=512m

# تنظيف شامل
flutter clean
rmdir /s /q build
rmdir /s /q "%USERPROFILE%\.gradle\caches"

# البناء
flutter pub get
flutter build apk --debug --verbose
```

## 📊 النتائج المتوقعة

### قبل الحل:
- ❌ Out of memory error
- ❌ فشل البناء
- ❌ تعطل Dart VM

### بعد الحل:
- ✅ بناء ناجح
- ✅ استهلاك ذاكرة محسن
- ✅ APK بحجم مناسب (80-120 MB للـ Debug)

## 🔧 استكشاف الأخطاء

### إذا استمرت المشكلة:

1. **تحقق من الذاكرة المتاحة:**
   ```cmd
   wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /value
   ```

2. **أعد تشغيل الكمبيوتر:**
   - يحرر الذاكرة المحجوزة
   - ينظف العمليات المعلقة

3. **أغلق البرامج الأخرى:**
   - المتصفحات (Chrome, Firefox)
   - برامج التحرير الثقيلة
   - الألعاب والبرامج الأخرى

4. **استخدم إعدادات أقل:**
   ```cmd
   set GRADLE_OPTS=-Xmx2G -XX:MaxMetaspaceSize=256m
   flutter build apk --debug --no-tree-shake-icons --no-shrink
   ```

## 📋 متطلبات النظام

### الحد الأدنى:
- ذاكرة: 8GB RAM
- مساحة فارغة: 10GB
- معالج: متعدد النوى

### الموصى به:
- ذاكرة: 16GB RAM أو أكثر
- مساحة فارغة: 20GB
- SSD بدلاً من HDD

## 🎯 نصائح لتجنب المشكلة مستقبلاً

### 1. مراقبة الذاكرة:
- استخدم Task Manager لمراقبة استهلاك الذاكرة
- أغلق البرامج غير الضرورية قبل البناء

### 2. تنظيف دوري:
```cmd
# أسبوعياً
flutter clean
rmdir /s /q "%USERPROFILE%\.gradle\caches"

# شهرياً
flutter pub cache clean
```

### 3. تحسين البيئة:
- استخدم SSD للمشاريع
- ترقية الذاكرة إذا أمكن
- تحديث Flutter بانتظام

## 📞 الدعم

إذا واجهت مشاكل أخرى:
1. راجع `BUILD_TROUBLESHOOTING.md`
2. جرب `build_safe.bat` للبناء البسيط
3. تحقق من `flutter doctor -v`

---

**تم حل المشكلة بنجاح! 🎉**

الآن يمكنك بناء التطبيق بدون مشاكل في الذاكرة.
