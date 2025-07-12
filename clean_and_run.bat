@echo off
echo 🧹 تنظيف شامل لحل مشكلة المساحة...

echo.
echo 1. تنظيف Flutter build...
flutter clean

echo.
echo 2. تنظيف Android build...
cd android
call gradlew clean
cd ..

echo.
echo 3. حذف APK التالف...
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    del "build\app\outputs\flutter-apk\app-release.apk"
    echo ✅ تم حذف APK التالف
)

echo.
echo 4. حذف مجلد build بالكامل...
if exist "build" (
    rmdir /s /q "build"
    echo ✅ تم حذف مجلد build
)

echo.
echo 5. تحديث المكتبات...
flutter pub get

echo.
echo 6. تشغيل في وضع Debug (أسرع وأقل مساحة)...
flutter run --debug

echo.
echo ✅ انتهى التنظيف والتشغيل!
pause
