# حل مشكلة نفاد مساحة القرص - Disk Space Solution

## 🚨 المشكلة
```
java.io.IOException: There is not enough space on the disk
```

هذا الخطأ يعني أن القرص الصلب ممتلئ ولا توجد مساحة كافية لإكمال عملية البناء.

## 🎯 المساحة المطلوبة
- **للبناء العادي:** 5-8 GB
- **للبناء مع التحسينات:** 8-12 GB
- **للأمان:** 15 GB أو أكثر

## 🛠️ الحلول السريعة

### 1. تشغيل سكريبت التنظيف
```cmd
free_space.bat
```

### 2. تنظيف يدوي سريع

#### أ) تنظيف Flutter:
```cmd
flutter clean
flutter pub cache clean
```

#### ب) حذف مجلد build:
```cmd
rmdir /s /q build
```

#### ج) تنظيف Gradle:
```cmd
rmdir /s /q "%USERPROFILE%\.gradle\caches"
rmdir /s /q "%USERPROFILE%\.android\build-cache"
```

### 3. استخدام Disk Cleanup
1. اضغط `Win + R`
2. اكتب `cleanmgr`
3. اختر القرص C:
4. حدد جميع الخيارات
5. اضغط OK

## 🗂️ الملفات والمجلدات التي يمكن حذفها بأمان

### مجلدات Flutter/Android:
- `build/` - مجلد البناء (يُعاد إنشاؤه)
- `%USERPROFILE%\.gradle\caches\` - ذاكرة Gradle التخزينية
- `%USERPROFILE%\.android\build-cache\` - ذاكرة Android التخزينية
- `%USERPROFILE%\.pub-cache\` - ذاكرة Dart packages (احذر!)

### مجلدات Windows:
- `%TEMP%\` - الملفات المؤقتة
- `C:\Windows\Temp\` - ملفات Windows المؤقتة
- سلة المحذوفات
- ملفات التحديث القديمة

## 📊 فحص المساحة

### فحص المساحة المتاحة:
```cmd
dir C:\ /-c | find "bytes free"
```

### فحص أكبر المجلدات:
```cmd
# استخدم TreeSize أو WinDirStat لفحص المجلدات الكبيرة
```

## 🔧 حلول متقدمة

### 1. نقل مجلد .gradle إلى قرص آخر
```cmd
# إنشاء رابط رمزي لنقل Gradle cache
mklink /D "%USERPROFILE%\.gradle" "D:\.gradle"
```

### 2. تغيير مكان مجلد build
في `android/gradle.properties`:
```properties
# تغيير مكان البناء إلى قرص آخر
android.buildCacheDir=D:/android_build_cache
```

### 3. استخدام بناء أقل استهلاكاً للمساحة
```cmd
# بناء debug بدلاً من release
flutter build apk --debug

# بناء بدون تحسينات
flutter build apk --release --no-shrink
```

## 🚀 خطة العمل الموصى بها

### الخطوة 1: تنظيف فوري
1. شغل `free_space.bat`
2. أفرغ سلة المحذوفات
3. احذف الملفات من Downloads إذا لم تكن مهمة

### الخطوة 2: فحص المساحة
```cmd
dir C:\ /-c | find "bytes free"
```

### الخطوة 3: اختيار نوع البناء
- **إذا كانت المساحة > 10 GB:** استخدم `build_optimized.bat`
- **إذا كانت المساحة 5-10 GB:** استخدم `build_simple.bat`
- **إذا كانت المساحة < 5 GB:** استخدم `build_safe.bat`

### الخطوة 4: البناء التدريجي
```cmd
# ابدأ بالبناء البسيط
flutter build apk --debug

# إذا نجح، جرب release
flutter build apk --release
```

## ⚠️ تحذيرات مهمة

### لا تحذف هذه المجلدات:
- `lib/` - كود التطبيق
- `android/app/src/` - كود Android
- `pubspec.yaml` - تبعيات المشروع
- `.git/` - تاريخ Git

### احذر من:
- حذف `%USERPROFILE%\.pub-cache\` كاملاً (قد يحتاج إعادة تحميل كبيرة)
- حذف ملفات النظام
- حذف برامج مهمة

## 🎯 نصائح للمستقبل

### 1. مراقبة المساحة:
- احتفظ بـ 20% من القرص فارغاً دائماً
- استخدم أدوات مراقبة المساحة

### 2. تنظيف دوري:
- شغل `free_space.bat` أسبوعياً
- نظف مجلد Downloads شهرياً
- احذف البرامج غير المستخدمة

### 3. ترقية الأجهزة:
- فكر في SSD أكبر
- استخدم قرص خارجي للملفات الكبيرة
- انقل المشاريع القديمة إلى التخزين السحابي

## 📞 إذا لم تنجح الحلول

### اتصل بالدعم مع هذه المعلومات:
1. حجم المساحة المتاحة
2. نوع القرص الصلب (HDD/SSD)
3. إصدار Windows
4. رسالة الخطأ كاملة

---

**تذكر:** مساحة القرص الكافية ضرورية لبناء التطبيقات بنجاح. الاستثمار في قرص أكبر سيوفر عليك الكثير من الوقت والمشاكل!
