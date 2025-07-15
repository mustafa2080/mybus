@echo off
echo 🚀 بناء بسيط للتطبيق مع التحسينات...
echo Simple build with optimizations...

echo.
echo 🧹 1. تنظيف المشروع...
flutter clean

echo.
echo 📦 2. تحديث التبعيات...
flutter pub get

echo.
echo 🏗️ 3. بناء APK للاختبار (Debug)...
flutter build apk --debug

echo.
echo 📊 4. فحص حجم APK...
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-debug.apk") do (
        echo حجم APK Debug: %%~zA bytes
        echo حجم APK Debug: %%~zA bytes / 1048576 = MB تقريباً
    )
) else (
    echo ❌ لم يتم العثور على APK
)

echo.
echo 🎯 5. إذا نجح البناء، جرب البناء المحسن:
echo    flutter build apk --release --split-per-abi

echo.
echo ✅ انتهى البناء البسيط!
echo.
echo 📍 مكان الملف: build\app\outputs\flutter-apk\app-debug.apk

pause
