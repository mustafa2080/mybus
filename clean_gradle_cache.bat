@echo off
echo 🗑️ تنظيف Gradle Cache لتوفير المساحة...

echo.
echo 1. إيقاف Gradle daemon...
cd android
call gradlew --stop
cd ..

echo.
echo 2. حذف Gradle caches...
if exist "%USERPROFILE%\.gradle\caches" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches"
    echo ✅ تم حذف Gradle caches
) else (
    echo ⚠️ Gradle caches غير موجود
)

echo.
echo 3. حذف Gradle wrapper downloads...
if exist "%USERPROFILE%\.gradle\wrapper" (
    rmdir /s /q "%USERPROFILE%\.gradle\wrapper"
    echo ✅ تم حذف Gradle wrapper
) else (
    echo ⚠️ Gradle wrapper غير موجود
)

echo.
echo 4. حذف Android build cache...
if exist "%USERPROFILE%\.android\build-cache" (
    rmdir /s /q "%USERPROFILE%\.android\build-cache"
    echo ✅ تم حذف Android build cache
) else (
    echo ⚠️ Android build cache غير موجود
)

echo.
echo 5. فحص المساحة المتوفرة...
echo المساحة المتوفرة على القرص C:
dir C:\ /-c | find "bytes free"

echo.
echo ✅ انتهى تنظيف Gradle Cache!
echo الآن جرب تشغيل clean_and_run.bat
pause
