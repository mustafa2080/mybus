@echo off
setlocal enabledelayedexpansion
echo ========================================
echo     MyBus - Memory-Safe Build Script
echo     حل مشكلة Out of Memory
echo ========================================
echo.

echo [1/7] فحص الذاكرة المتاحة...
for /f "tokens=2 delims=:" %%a in ('wmic OS get TotalVisibleMemorySize /value ^| find "="') do set /a totalMem=%%a/1024
for /f "tokens=2 delims=:" %%a in ('wmic OS get FreePhysicalMemory /value ^| find "="') do set /a freeMem=%%a/1024
echo إجمالي الذاكرة: %totalMem% MB
echo الذاكرة المتاحة: %freeMem% MB

if %freeMem% LSS 3000 (
    echo ⚠️ تحذير: الذاكرة المتاحة قليلة!
    echo يُنصح بإغلاق البرامج الأخرى قبل المتابعة
    echo اضغط أي مفتاح للمتابعة أو Ctrl+C للإلغاء...
    pause >nul
)

echo.
echo [2/7] تنظيف شامل للمشروع...
flutter clean
if %errorlevel% neq 0 (
    echo ❌ خطأ: فشل في تنظيف Flutter!
    pause
    exit /b 1
)

echo.
echo [3/7] حذف مجلد build...
if exist "build" (
    rmdir /s /q "build"
    echo ✅ تم حذف مجلد build
)

echo.
echo [4/7] تنظيف ذاكرة Gradle التخزينية...
if exist "%USERPROFILE%\.gradle\caches" (
    echo تنظيف ذاكرة Gradle...
    rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
    echo ✅ تم تنظيف ذاكرة Gradle
)

echo.
echo [5/7] تحديث التبعيات...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ خطأ: فشل في تحديث التبعيات!
    pause
    exit /b 1
)

echo.
echo [6/7] بناء APK مع تحسينات الذاكرة...
echo تطبيق إعدادات ذاكرة محسنة...

REM تعيين متغيرات بيئة لتحسين الذاكرة
set GRADLE_OPTS=-Xmx3G -XX:MaxMetaspaceSize=512m -XX:+UseG1GC
set JAVA_OPTS=-Xmx2G -XX:MaxMetaspaceSize=256m

echo بدء البناء مع إعدادات الذاكرة المحسنة...
flutter build apk --debug --verbose

if %errorlevel% neq 0 (
    echo ⚠️ فشل البناء الأول، محاولة بإعدادات أقل...
    echo تجربة بناء بدون تحسينات...
    
    REM تقليل استهلاك الذاكرة أكثر
    set GRADLE_OPTS=-Xmx2G -XX:MaxMetaspaceSize=256m
    flutter build apk --debug --no-tree-shake-icons --no-shrink
    
    if %errorlevel% neq 0 (
        echo ❌ فشل البناء نهائياً!
        echo.
        echo 🔧 الحلول المقترحة:
        echo 1. أعد تشغيل الكمبيوتر لتحرير الذاكرة
        echo 2. أغلق جميع البرامج الأخرى
        echo 3. شغل free_space.bat لتحرير مساحة القرص
        echo 4. تأكد من وجود 8GB ذاكرة على الأقل
        pause
        exit /b 1
    )
)

echo.
echo [7/7] فحص النتائج...
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo ✅ نجح البناء!
    for %%A in ("build\app\outputs\flutter-apk\app-debug.apk") do (
        set size=%%~zA
        set /a sizeMB=!size!/1024/1024
        echo 📱 حجم APK: !sizeMB! MB
    )
    echo.
    echo 📍 مكان الملف: build\app\outputs\flutter-apk\app-debug.apk
    echo.
    echo 🎯 الخطوات التالية:
    echo 1. اختبر التطبيق على الجهاز
    echo 2. إذا عمل بشكل صحيح، يمكنك تجربة البناء المحسن
    echo 3. لبناء الإصدار النهائي: flutter build apk --release
) else (
    echo ❌ لم يتم العثور على ملف APK!
)

echo.
echo ========================================
echo        اكتمل البناء الآمن للذاكرة
echo ========================================
echo.
echo 💡 نصائح لتجنب مشاكل الذاكرة:
echo - احتفظ بـ 4GB ذاكرة متاحة على الأقل
echo - أغلق المتصفحات والبرامج الثقيلة أثناء البناء
echo - استخدم SSD بدلاً من HDD إن أمكن
echo - نظف ذاكرة Gradle بانتظام
echo.
pause
