@echo off
echo 🖼️ تحسين وضغط الصور لتقليل حجم التطبيق...

echo.
echo 📊 فحص أحجام الصور الحالية...
for %%f in (assets\icons\*.png) do (
    echo %%f: 
    for %%A in ("%%f") do echo   الحجم: %%~zA bytes
)

echo.
echo 🔧 تطبيق تحسينات الصور...

REM إنشاء مجلد للصور المحسنة
if not exist "assets\icons\optimized" mkdir "assets\icons\optimized"

echo.
echo ✅ تم إنشاء مجلد الصور المحسنة

echo.
echo 📝 نصائح لتحسين الصور يدوياً:
echo   1. استخدم أدوات ضغط الصور مثل TinyPNG أو ImageOptim
echo   2. قم بتحويل PNG إلى WebP عند الإمكان
echo   3. قلل دقة الصور الكبيرة غير الضرورية
echo   4. استخدم SVG للأيقونات البسيطة

echo.
echo 🎯 لتحسين أفضل، قم بما يلي:
echo   1. زر موقع tinypng.com
echo   2. ارفع الصور من مجلد assets/icons
echo   3. حمل الصور المضغوطة
echo   4. استبدل الصور الأصلية

echo.
echo ⚡ تحسينات إضافية:
echo   - استخدم flutter build apk --split-per-abi لتقليل الحجم
echo   - فعل ProGuard في إعدادات Android
echo   - احذف المكتبات غير المستخدمة

pause
