@echo off
echo 🛡️ بناء آمن للتطبيق - تجنب مشاكل Gradle...
echo Safe build - avoiding Gradle compatibility issues...

echo.
echo 🧹 1. تنظيف شامل...
flutter clean

echo.
echo 🗑️ 2. حذف مجلد build...
if exist "build" (
    rmdir /s /q "build"
    echo ✅ تم حذف مجلد build
)

echo.
echo 📦 3. تحديث التبعيات...
flutter pub get

echo.
echo 🔍 4. فحص Flutter Doctor...
flutter doctor

echo.
echo 🏗️ 5. بناء APK بسيط (بدون تحسينات معقدة)...
echo    هذا البناء يتجنب المشاكل المعقدة ويركز على النجاح
flutter build apk --debug --verbose

echo.
echo 📊 6. فحص النتائج...
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo ✅ نجح البناء!
    for %%A in ("build\app\outputs\flutter-apk\app-debug.apk") do (
        set /a size_mb=%%~zA/1048576
        echo 📱 حجم APK: %%~zA bytes (حوالي !size_mb! MB)
    )
    echo.
    echo 📍 مكان الملف: build\app\outputs\flutter-apk\app-debug.apk
    echo.
    echo 🎯 إذا نجح هذا البناء، يمكنك تجربة:
    echo    flutter build apk --release
) else (
    echo ❌ فشل البناء
    echo.
    echo 🔧 جرب الحلول التالية:
    echo    1. flutter upgrade
    echo    2. flutter clean && flutter pub get
    echo    3. تحقق من إعدادات Android SDK
    echo    4. تأكد من إعدادات Java
)

echo.
echo 📋 معلومات مفيدة:
echo    - هذا بناء Debug (للاختبار)
echo    - لا يحتوي على تحسينات ProGuard
echo    - حجم أكبر لكن أكثر استقراراً
echo    - مناسب للتطوير والاختبار

echo.
pause
