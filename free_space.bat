@echo off
echo 🗑️ تحرير مساحة القرص لحل مشكلة البناء...
echo Freeing disk space to fix build issue...

echo.
echo 📊 فحص المساحة المتاحة حالياً...
dir C:\ /-c | find "bytes free"

echo.
echo 🧹 1. تنظيف مجلد build Flutter...
if exist "build" (
    echo حذف مجلد build...
    rmdir /s /q "build"
    echo ✅ تم حذف مجلد build
) else (
    echo ℹ️ مجلد build غير موجود
)

echo.
echo 🗑️ 2. تنظيف Gradle cache...
if exist "%USERPROFILE%\.gradle\caches" (
    echo حذف Gradle caches...
    rmdir /s /q "%USERPROFILE%\.gradle\caches"
    echo ✅ تم حذف Gradle caches
) else (
    echo ℹ️ Gradle caches غير موجود
)

echo.
echo 🗑️ 3. تنظيف Flutter cache...
flutter clean

echo.
echo 🗑️ 4. تنظيف pub cache...
flutter pub cache clean

echo.
echo 🗑️ 5. تنظيف Android build cache...
if exist "%USERPROFILE%\.android\build-cache" (
    echo حذف Android build cache...
    rmdir /s /q "%USERPROFILE%\.android\build-cache"
    echo ✅ تم حذف Android build cache
) else (
    echo ℹ️ Android build cache غير موجود
)

echo.
echo 🗑️ 6. تنظيف temp files...
if exist "%TEMP%" (
    echo حذف الملفات المؤقتة...
    del /q /f "%TEMP%\*.*" 2>nul
    for /d %%i in ("%TEMP%\*") do rmdir /s /q "%%i" 2>nul
    echo ✅ تم تنظيف الملفات المؤقتة
)

echo.
echo 📊 فحص المساحة بعد التنظيف...
dir C:\ /-c | find "bytes free"

echo.
echo 💡 نصائح إضافية لتحرير المساحة:
echo.
echo 1. احذف الملفات غير المهمة من سطح المكتب والتحميلات
echo 2. أفرغ سلة المحذوفات
echo 3. استخدم Disk Cleanup:
echo    - اضغط Win+R
echo    - اكتب cleanmgr
echo    - اختر القرص C:
echo.
echo 4. احذف البرامج غير المستخدمة من Control Panel
echo 5. انقل الملفات الكبيرة إلى قرص خارجي
echo.
echo 🎯 المساحة المطلوبة للبناء: 5-10 GB على الأقل
echo.
echo ⚠️ إذا لم تكن المساحة كافية بعد التنظيف:
echo    - استخدم build_safe.bat بدلاً من build_optimized.bat
echo    - جرب البناء على قرص آخر إذا أمكن
echo    - فكر في ترقية القرص الصلب

echo.
pause
