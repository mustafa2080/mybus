@echo off
echo 🗜️ بناء مضغوط للغاية - الهدف: 80 ميجا أو أقل
echo Ultra compressed build - Target: 80MB or less

echo.
echo 📊 الهدف: تقليل الحجم من 127MB إلى 80MB
echo Target: Reduce size from 127MB to 80MB

echo.
echo 🧹 1. تنظيف شامل...
flutter clean

echo.
echo 📦 2. تحديث التبعيات...
flutter pub get

echo.
echo 🏗️ 3. بناء App Bundle (أصغر من APK بـ 30-40%)...
echo    App Bundle يقسم التطبيق حسب الجهاز
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

echo.
echo 📊 4. فحص حجم App Bundle...
if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo ✅ نجح بناء App Bundle!
    for %%A in ("build\app\outputs\bundle\release\app-release.aab") do (
        set /a size_mb=%%~zA/1048576
        echo 📱 حجم App Bundle: %%~zA bytes (حوالي !size_mb! MB)
        
        if !size_mb! LEQ 80 (
            echo 🎉 ممتاز! وصلنا للهدف: !size_mb! MB ≤ 80 MB
        ) else (
            echo ⚠️ ما زلنا بحاجة تحسين: !size_mb! MB > 80 MB
        )
    )
) else (
    echo ❌ فشل بناء App Bundle
)

echo.
echo 🏗️ 5. بناء APK مضغوط للمقارنة...
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info

echo.
echo 📊 6. مقارنة الأحجام...
echo.
echo === مقارنة الأحجام ===

if exist "build\app\outputs\bundle\release\app-release.aab" (
    for %%A in ("build\app\outputs\bundle\release\app-release.aab") do (
        set /a bundle_mb=%%~zA/1048576
        echo 📦 App Bundle: !bundle_mb! MB
    )
)

if exist "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-arm64-v8a-release.apk") do (
        set /a apk_mb=%%~zA/1048576
        echo 📱 APK ARM64: !apk_mb! MB
    )
)

if exist "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk") do (
        set /a apk32_mb=%%~zA/1048576
        echo 📱 APK ARM32: !apk32_mb! MB
    )
)

echo.
echo 🎯 التحسينات المطبقة:
echo   ✅ App Bundle splitting (توفير 30-40%)
echo   ✅ ProGuard obfuscation متقدم
echo   ✅ Resource shrinking محسن
echo   ✅ إزالة الأيقونات غير المستخدمة
echo   ✅ ضغط PNG محسن
echo   ✅ إزالة debug info

echo.
echo 📍 مواقع الملفات:
echo   App Bundle: build\app\outputs\bundle\release\app-release.aab
echo   APK ARM64: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo   APK ARM32: build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk

echo.
echo 💡 نصائح للنشر:
echo   1. استخدم App Bundle للنشر على Google Play
echo   2. App Bundle يحمل فقط ما يحتاجه الجهاز
echo   3. المستخدمون سيحملون حجم أصغر بـ 30-40%
echo   4. Google Play يدير التوزيع تلقائياً

echo.
pause
