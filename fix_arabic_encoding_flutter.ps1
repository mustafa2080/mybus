# Fix Arabic Encoding in Flutter Files
# This script fixes Arabic text encoding issues in Dart files

Write-Host "🔧 Starting Arabic encoding fix for Flutter files..." -ForegroundColor Green

# Function to decode HTML entities to proper Arabic text
function Convert-HtmlEntitiesToArabic {
    param([string]$text)
    
    # Comprehensive Arabic encoding mapping
    $arabicMap = @{
        # Basic Arabic letters
        'ط§' = 'ا'  # alef
        'ط¨' = 'ب'  # beh
        'طھ' = 'ت'  # teh
        'ط«' = 'ث'  # theh
        'ط¬' = 'ج'  # jeem
        'ط­' = 'ح'  # hah
        'ط®' = 'خ'  # khah
        'ط¯' = 'د'  # dal
        'ط°' = 'ذ'  # thal
        'ط±' = 'ر'  # reh
        'ط²' = 'ز'  # zain
        'ط³' = 'س'  # seen
        'ط´' = 'ش'  # sheen
        'طµ' = 'ص'  # sad
        'ط¶' = 'ض'  # dad
        'ط·' = 'ط'  # tah
        'ط¸' = 'ظ'  # zah
        'ط¹' = 'ع'  # ain
        'ط؛' = 'غ'  # ghain
        'ظپ' = 'ف'  # feh
        'ظ‚' = 'ق'  # qaf
        'ظƒ' = 'ك'  # kaf
        'ظ„' = 'ل'  # lam
        'ظ…' = 'م'  # meem
        'ظ†' = 'ن'  # noon
        'ظ‡' = 'ه'  # heh
        'ظˆ' = 'و'  # waw
        'ظٹ' = 'ي'  # yeh
        'ط©' = 'ة'  # teh marbuta
        'ط¤' = 'ؤ'  # waw with hamza
        'ط¦' = 'ئ'  # yeh with hamza
        'ط£' = 'أ'  # alef with hamza above
        'ط¥' = 'إ'  # alef with hamza below
        'ط¢' = 'آ'  # alef with madda
        'ظ‰' = 'ى'  # alef maksura

        # Common words and phrases
        'ط§ظ„ظƒظ„' = 'الكل'
        'ط§ظ„ط±ظˆط¶ط©' = 'الروضة'
        'ط§ظ„ط£ظˆظ„' = 'الأول'
        'ط§ظ„ط«ط§ظ†ظٹ' = 'الثاني'
        'ط§ظ„ط«ط§ظ„ط«' = 'الثالث'
        'ط§ظ„ط±ط§ط¨ط¹' = 'الرابع'
        'ط§ظ„ط®ط§ظ…ط³' = 'الخامس'
        'ط§ظ„ط³ط§ط¯ط³' = 'السادس'
        'ط§ظ„ط³ط§ط¨ط¹' = 'السابع'
        'ط§ظ„ط«ط§ظ…ظ†' = 'الثامن'
        'ط§ظ„طھط§ط³ط¹' = 'التاسع'
        'ط§ظ„ط¹ط§ط´ط±' = 'العاشر'
        'ط§ظ„ط­ط§ط¯ظٹ ط¹ط´ط±' = 'الحادي عشر'
        'ط§ظ„ط«ط§ظ†ظٹ ط¹ط´ط±' = 'الثاني عشر'

        # Status words
        'ظپظٹ ط§ظ„ظ…ظ†ط²ظ„' = 'في المنزل'
        'ظپظٹ ط§ظ„ط¨ط§طµ' = 'في الباص'
        'ظپظٹ ط§ظ„ظ…ط¯ط±ط³ط©' = 'في المدرسة'
        'ط§ظ„ط­ط§ظ„ط©' = 'الحالة'
        'ط§ظ„طµظپ' = 'الصف'

        # Common UI text
        'ط¬ظ…ظٹط¹ ط§ظ„ط·ظ„ط§ط¨' = 'جميع الطلاب'
        'ط§ظ„ط¨ط­ط« ط¹ظ† ط·ط§ظ„ط¨' = 'البحث عن طالب'
        'ط¥ط¶ط§ظپط© ط·ط§ظ„ط¨ ط¬ط¯ظٹط¯' = 'إضافة طالب جديد'
        'ط®ط·ط£ ظپظٹ طھط­ظ…ظٹظ„ ط§ظ„ط¨ظٹط§ظ†ط§طھ' = 'خطأ في تحميل البيانات'
        'ظ„ط§ ظٹظˆط¬ط¯ ط·ظ„ط§ط¨ ظ…ط³ط¬ظ„ظٹظ†' = 'لا يوجد طلاب مسجلين'
        'ظ„ط§ طھظˆط¬ط¯ ظ†طھط§ط¦ط¬ ظ„ظ„ط¨ط­ط«' = 'لا توجد نتائج للبحث'
        'ط¹ط¯ط¯ ط§ظ„ظ†طھط§ط¦ط¬' = 'عدد النتائج'
        'ظ…ظ† ' = 'من '
        'طھط¹ط¯ظٹظ„' = 'تعديل'
        'ط¹ط±ط¶ ط§ظ„طھظپط§طµظٹظ„' = 'عرض التفاصيل'
        'ط­ط°ظپ' = 'حذف'
        'ط®ط· ط§ظ„ط¨ط§طµ' = 'خط الباص'
        'ظˆظ„ظٹ ط§ظ„ط£ظ…ط±' = 'ولي الأمر'
        'ظ‡ط§طھظپ ظˆظ„ظٹ ط§ظ„ط£ظ…ط±' = 'هاتف ولي الأمر'
        'ط±ظ…ط² QR' = 'رمز QR'
        'ط¥ط؛ظ„ط§ظ‚' = 'إغلاق'
        'طھط£ظƒظٹط¯ ط§ظ„ط­ط°ظپ' = 'تأكيد الحذف'
        'ظ‡ظ„ ط£ظ†طھ ظ…طھط£ظƒط¯ ظ…ظ† ط­ط°ظپ ط§ظ„ط·ط§ظ„ط¨' = 'هل أنت متأكد من حذف الطالب'
        'ط¥ظ„ط؛ط§ط،' = 'إلغاء'
        'طھظ… ط­ط°ظپ ط§ظ„ط·ط§ظ„ط¨ ط¨ظ†ط¬ط§ط­' = 'تم حذف الطالب بنجاح'
        'ط®ط·ط£ ظپظٹ ط­ط°ظپ ط§ظ„ط·ط§ظ„ط¨' = 'خطأ في حذف الطالب'

        # Complaints management
        'ط¥ط¯ط§ط±ط© ط§ظ„ط´ظƒط§ظˆظ‰' = 'إدارة الشكاوى'
        'ط§ظ„ظƒظ„' = 'الكل'
        'ط¬ط¯ظٹط¯ط©' = 'جديدة'
        'ظ‚ظٹط¯ ط§ظ„ظ…ط¹ط§ظ„ط¬ط©' = 'قيد المعالجة'
        'ظ…ط­ظ„ظˆظ„ط©' = 'محلولة'
        'ط¹ط§ط¬ظ„ط©' = 'عاجلة'
        'ط¹ط§ظ„ظٹط©' = 'عالية'
        'ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ' = 'الإجمالي'
        'ط®ط·ط£ ظپظٹ طھط­ظ…ظٹظ„ ط§ظ„ط´ظƒط§ظˆظ‰' = 'خطأ في تحميل الشكاوى'
        'ط¥ط¹ط§ط¯ط© ط§ظ„ظ…ط­ط§ظˆظ„ط©' = 'إعادة المحاولة'
        'ظ„ط§ طھظˆط¬ط¯ ط´ظƒط§ظˆظ‰ ط¬ط¯ظٹط¯ط©' = 'لا توجد شكاوى جديدة'
        'ظ„ط§ طھظˆط¬ط¯ ط´ظƒط§ظˆظ‰ ظ‚ظٹط¯ ط§ظ„ظ…ط¹ط§ظ„ط¬ط©' = 'لا توجد شكاوى قيد المعالجة'
        'ظ„ط§ طھظˆط¬ط¯ ط´ظƒط§ظˆظ‰ ظ…ط­ظ„ظˆظ„ط©' = 'لا توجد شكاوى محلولة'
        'ظ„ط§ طھظˆط¬ط¯ ط´ظƒط§ظˆظ‰' = 'لا توجد شكاوى'
        'ط¨ط¯ط، ط§ظ„ظ…ط¹ط§ظ„ط¬ط©' = 'بدء المعالجة'
        'ط¥ط¶ط§ظپط© ط±ط¯' = 'إضافة رد'
        'ظ…ط±ظپظ‚' = 'مرفق'
        'ظ…ط؛ظ„ظ‚ط©' = 'مغلقة'

        # Add student screen
        'ط¥ط¶ط§ظپط© ط·ط§ظ„ط¨ ط¬ط¯ظٹط¯' = 'إضافة طالب جديد'
        'ط£ط¶ظپ ط¨ظٹط§ظ†ط§طھ ط·ظپظ„ظƒ ظ„طھطھظ…ظƒظ† ظ…ظ† ظ…طھط§ط¨ط¹ط© ط±ط­ظ„طھظ‡ ط§ظ„ظٹظˆظ…ظٹط©' = 'أضف بيانات طفلك لتتمكن من متابعة رحلته اليومية'
        'طµظˆط±ط© ط§ظ„ط·ط§ظ„ط¨' = 'صورة الطالب'
        'ط§ط¶ط؛ط· ظ„ط¥ط¶ط§ظپط© طµظˆط±ط©' = 'اضغط لإضافة صورة'
        'ط§ط®طھظٹط§ط±ظٹ' = 'اختياري'
        'طھط؛ظٹظٹط±' = 'تغيير'
        'ط¨ظٹط§ظ†ط§طھ ط§ظ„ط·ط§ظ„ط¨' = 'بيانات الطالب'
        'ط§ط³ظ… ط§ظ„ط·ط§ظ„ط¨' = 'اسم الطالب'
        'ط£ط¯ط®ظ„ ط§ط³ظ… ط§ظ„ط·ط§ظ„ط¨ ظƒط§ظ…ظ„ط§ظ‹' = 'أدخل اسم الطالب كاملاً'
        'ظٹط±ط¬ظ‰ ط¥ط¯ط®ط§ظ„ ط§ط³ظ… ط§ظ„ط·ط§ظ„ط¨' = 'يرجى إدخال اسم الطالب'
        'ط§ط³ظ… ط§ظ„ط·ط§ظ„ط¨ ظٹط¬ط¨ ط£ظ† ظٹظƒظˆظ† ط£ظƒط«ط± ظ…ظ† ط­ط±ظپظٹظ†' = 'اسم الطالب يجب أن يكون أكثر من حرفين'
        'ط§ظ„طµظپ ط§ظ„ط¯ط±ط§ط³ظٹ' = 'الصف الدراسي'
        'ط§ط®طھط± ط§ظ„طµظپ ط§ظ„ط¯ط±ط§ط³ظٹ' = 'اختر الصف الدراسي'
        'ظٹط±ط¬ظ‰ ط§ط®طھظٹط§ط± ط§ظ„طµظپ ط§ظ„ط¯ط±ط§ط³ظٹ' = 'يرجى اختيار الصف الدراسي'
        'ط§ط³ظ… ط§ظ„ظ…ط¯ط±ط³ط©' = 'اسم المدرسة'
        'ط§ط®طھط± ط§ظ„ظ…ط¯ط±ط³ط©' = 'اختر المدرسة'
        'ط£ط®ط±ظ‰' = 'أخرى'

        # Punctuation and symbols
        'طں' = '؟'  # Arabic question mark
        'ط،' = '،'  # Arabic comma
        'ط؛' = '؛'  # Arabic semicolon
        'ظ„ط§' = 'لا' # lam alef
        'ظ' = 'ً'   # fathatan
        'ظŒ' = 'ٌ'   # dammatan
        'ظ' = 'ٍ'   # kasratan
        'ظژ' = 'َ'   # fatha
        'ظڈ' = 'ُ'   # damma
        'ظگ' = 'ِ'   # kasra
        'ظ'' = 'ّ'   # shadda
        'ظ'' = 'ْ'   # sukun
        'ظ°' = 'ـ'  # tatweel
    }
    
    $result = $text
    foreach ($entity in $arabicMap.Keys) {
        $result = $result -replace [regex]::Escape($entity), $arabicMap[$entity]
    }
    
    return $result
}

# Function to fix a single file
function Fix-ArabicInFile {
    param([string]$filePath)
    
    try {
        Write-Host "📝 Processing: $filePath" -ForegroundColor Yellow
        
        # Read file content with UTF-8 encoding
        $content = Get-Content -Path $filePath -Raw -Encoding UTF8
        
        if ($null -eq $content) {
            Write-Host "⚠️  File is empty or could not be read: $filePath" -ForegroundColor Yellow
            return
        }
        
        # Convert HTML entities to proper Arabic
        $fixedContent = Convert-HtmlEntitiesToArabic -text $content
        
        # Check if any changes were made
        if ($content -ne $fixedContent) {
            # Create backup
            $backupPath = "$filePath.backup"
            Copy-Item -Path $filePath -Destination $backupPath -Force
            
            # Write fixed content back to file with UTF-8 encoding (no BOM)
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($filePath, $fixedContent, $utf8NoBom)
            
            Write-Host "✅ Fixed Arabic encoding in: $filePath" -ForegroundColor Green
            Write-Host "📋 Backup created: $backupPath" -ForegroundColor Cyan
        } else {
            Write-Host "✨ No Arabic encoding issues found in: $filePath" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "❌ Error processing $filePath : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Get all Dart files in the lib directory
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

Write-Host "🔍 Found $($dartFiles.Count) Dart files to process..." -ForegroundColor Cyan

foreach ($file in $dartFiles) {
    Fix-ArabicInFile -filePath $file.FullName
}

Write-Host ""
Write-Host "🎉 Arabic encoding fix completed!" -ForegroundColor Green
Write-Host "📁 Backup files created with .backup extension" -ForegroundColor Cyan
Write-Host "🔄 You may need to restart your IDE to see the changes" -ForegroundColor Yellow
