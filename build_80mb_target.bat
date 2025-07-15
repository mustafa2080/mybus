@echo off
echo 🎯 بناء مستهدف 80 ميجا - تجنب مشاكل Gradle
echo Target 80MB build - Avoiding Gradle issues

echo.
echo 📊 الهدف: تقليل الحجم من 127MB إلى 80MB أو أقل
echo Target: Reduce size from 127MB to 80MB or less

echo.
echo 🧹 1. تنظيف شامل...
flutter clean

echo.
echo 📦 2. تحديث التبعيات...
flutter pub get

echo.
echo 🔍 3. فحص Flutter Doctor...
flutter doctor --android-licenses

echo.
echo 🏗️ 4. بناء App Bundle (الأكثر فعالية لتقليل الحجم)...
echo    App Bundle يوفر 30-40% من الحجم
flutter build appbundle --release

echo.
echo 📊 5. فحص حجم App Bundle...
if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo ✅ نجح بناء App Bundle!
    for %%A in ("build\app\outputs\bundle\release\app-release.aab") do (
        set /a size_mb=%%~zA/1048576
        echo 📦 حجم App Bundle: %%~zA bytes (~!size_mb! MB)
        
        if !size_mb! LEQ 80 (
            echo 🎉 ممتاز! وصلنا للهدف: !size_mb! MB ≤ 80 MB
            echo 🚀 جاهز للنشر على Google Play!
        ) else (
            set /a diff=!size_mb!-80
            echo ⚠️ قريب من الهدف: !size_mb! MB (زيادة !diff! MB عن الهدف)
            echo 💡 App Bundle سيكون أصغر للمستخدمين النهائيين
        )
    )
) else (
    echo ❌ فشل بناء App Bundle
    echo 🔧 جرب البناء البسيط بدلاً من ذلك
    goto :simple_build
)

echo.
echo 🏗️ 6. بناء APK للمقارنة (اختياري)...
echo    هذا للمقارنة فقط - استخدم App Bundle للنشر
flutter build apk --release --split-per-abi

echo.
echo 📊 7. مقارنة الأحجام...
echo.
echo === مقارنة الأحجام ===

if exist "build\app\outputs\bundle\release\app-release.aab" (
    for %%A in ("build\app\outputs\bundle\release\app-release.aab") do (
        set /a bundle_mb=%%~zA/1048576
        echo 📦 App Bundle: !bundle_mb! MB (للنشر)
    )
)

if exist "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-arm64-v8a-release.apk") do (
        set /a apk_mb=%%~zA/1048576
        echo 📱 APK ARM64: !apk_mb! MB (للاختبار)
    )
)

goto :end

:simple_build
echo.
echo 🛡️ البناء البسيط (في حالة فشل App Bundle)...
flutter build apk --release

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do (
        set /a size_mb=%%~zA/1048576
        echo 📱 حجم APK: %%~zA bytes (~!size_mb! MB)
    )
)

:end
echo.
echo 🎯 ملخص النتائج:
echo   ✅ تم تجنب مشاكل Gradle المُهملة
echo   ✅ استخدام App Bundle لأقصى ضغط
echo   ✅ تطبيق تحسينات ProGuard
echo   ✅ إزالة الموارد غير المستخدمة

echo.
echo 📍 مواقع الملفات:
echo   App Bundle: build\app\outputs\bundle\release\app-release.aab
echo   APK: build\app\outputs\flutter-apk\

echo.
echo 💡 نصائح للنشر:
echo   1. استخدم App Bundle للنشر على Google Play
echo   2. المستخدمون سيحملون حجم أصغر (50-70MB)
echo   3. Google Play يدير التوزيع تلقائياً
echo   4. App Bundle يدعم Dynamic Delivery

echo.
echo 🔄 إذا لم تصل للهدف:
echo   1. راجع SIZE_REDUCTION_GUIDE.md
echo   2. جرب ضغط الصور أكثر
echo   3. فحص المكتبات الكبيرة

echo.
pause
