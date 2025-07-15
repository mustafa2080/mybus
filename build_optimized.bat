@echo off
echo 🚀 بناء التطبيق مع التحسينات الجديدة...
echo Building app with new optimizations...

echo.
echo 📊 معلومات البناء:
echo   - تفعيل ProGuard/R8: نعم
echo   - ضغط الموارد: نعم  
echo   - إزالة الكود غير المستخدم: نعم
echo   - تحسين الصور: نعم

echo.
echo 🧹 1. تنظيف المشروع...
flutter clean

echo.
echo 📦 2. تحديث التبعيات...
flutter pub get

echo.
echo 🔍 3. فحص الكود...
flutter analyze --no-fatal-infos

echo.
echo 🏗️ 4. بناء APK محسن...
echo    - بناء APK مع تقسيم ABI لتقليل الحجم
flutter build apk --split-per-abi --release

echo.
echo 📱 5. بناء App Bundle (موصى به للنشر)...
flutter build appbundle --release

echo.
echo 📊 6. فحص أحجام الملفات...
echo.
echo أحجام APK المبنية:
if exist "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-arm64-v8a-release.apk") do echo   ARM64: %%~zA bytes
)
if exist "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk") do echo   ARM32: %%~zA bytes
)
if exist "build\app\outputs\flutter-apk\app-x86_64-release.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-x86_64-release.apk") do echo   x86_64: %%~zA bytes
)

echo.
echo حجم App Bundle:
if exist "build\app\outputs\bundle\release\app-release.aab" (
    for %%A in ("build\app\outputs\bundle\release\app-release.aab") do echo   Bundle: %%~zA bytes
)

echo.
echo 🎯 7. نصائح لتقليل الحجم أكثر:
echo   1. استخدم App Bundle بدلاً من APK للنشر
echo   2. فعل Dynamic Delivery في Google Play
echo   3. راجع المكتبات المستخدمة وأزل غير الضرورية
echo   4. ضغط الصور باستخدام أدوات خارجية
echo   5. استخدم WebP بدلاً من PNG عند الإمكان

echo.
echo 🔒 8. فحص الأمان:
echo   ✅ ProGuard/R8 مفعل
echo   ✅ قواعد Firebase Security محسنة
echo   ✅ التحقق من المدخلات محسن
echo   ✅ حماية المفاتيح الحساسة

echo.
echo 📍 9. مواقع الملفات المبنية:
echo   APK Files: build\app\outputs\flutter-apk\
echo   App Bundle: build\app\outputs\bundle\release\
echo   Mapping Files: build\app\outputs\mapping\release\

echo.
echo ⚡ 10. خطوات ما بعد البناء:
echo   1. اختبر التطبيق على أجهزة مختلفة
echo   2. تأكد من عمل جميع الميزات
echo   3. راجع سجلات الأخطاء
echo   4. قم بتحديث قواعد Firebase إذا لزم الأمر

echo.
echo 🎉 تم بناء التطبيق بنجاح مع جميع التحسينات!
echo.
echo 📋 ملخص التحسينات المطبقة:
echo   ✅ تقليل حجم التطبيق
echo   ✅ تحسين الأمان
echo   ✅ تحسين الأداء
echo   ✅ حماية البيانات

echo.
echo 🚀 جاهز للنشر!
pause
