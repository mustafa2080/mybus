# Simple Arabic Fix Script
Write-Host "Fixing Arabic encoding issues..." -ForegroundColor Green

# Get all Dart files
$files = Get-ChildItem -Path "lib" -Recurse -Include "*.dart"

$count = 0
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $modified = $false
    
    # Fix common corrupted patterns
    if ($content -match 'ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ط·ظ„ط§ط¨') {
        $content = $content -replace 'ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ط·ظ„ط§ط¨', 'إجمالي الطلاب'
        $modified = $true
    }
    
    if ($content -match 'ظپظٹ ط§ظ„ط¨ط§طµ') {
        $content = $content -replace 'ظپظٹ ط§ظ„ط¨ط§طµ', 'في الباص'
        $modified = $true
    }
    
    if ($content -match 'ظپظٹ ط§ظ„ظ…ط¯ط±ط³ط©') {
        $content = $content -replace 'ظپظٹ ط§ظ„ظ…ط¯ط±ط³ط©', 'في المدرسة'
        $modified = $true
    }
    
    if ($content -match 'ط§ظ„ظ†ط³ط® ط§ظ„ط§ط­طھظٹط§ط·ظٹ') {
        $content = $content -replace 'ط§ظ„ظ†ط³ط® ط§ظ„ط§ط­طھظٹط§ط·ظٹ', 'النسخ الاحتياطي'
        $modified = $true
    }
    
    if ($content -match 'ط¥ظ†ط´ط§ط، ظ†ط³ط®ط©') {
        $content = $content -replace 'ط¥ظ†ط´ط§ط، ظ†ط³ط®ط©', 'إنشاء نسخة'
        $modified = $true
    }
    
    if ($content -match 'ط§ط³طھط¹ط§ط¯ط©') {
        $content = $content -replace 'ط§ط³طھط¹ط§ط¯ط©', 'استعادة'
        $modified = $true
    }
    
    if ($content -match 'ط¥ط؛ظ„ط§ظ‚') {
        $content = $content -replace 'ط¥ط؛ظ„ط§ظ‚', 'إغلاق'
        $modified = $true
    }
    
    if ($content -match 'ط¥ط±ط³ط§ظ„') {
        $content = $content -replace 'ط¥ط±ط³ط§ظ„', 'إرسال'
        $modified = $true
    }
    
    if ($content -match 'ط¥ظ„ط؛ط§ط،') {
        $content = $content -replace 'ط¥ظ„ط؛ط§ط،', 'إلغاء'
        $modified = $true
    }
    
    if ($content -match 'ط¥ط­طµط§ط¦ظٹط§طھ ط³ط±ظٹط¹ط©') {
        $content = $content -replace 'ط¥ط­طµط§ط¦ظٹط§طھ ط³ط±ظٹط¹ط©', 'إحصائيات سريعة'
        $modified = $true
    }
    
    if ($content -match 'ط§ظ„ط·ظ„ط§ط¨ ط§ظ„ظ†ط´ط·ظˆظ†') {
        $content = $content -replace 'ط§ظ„ط·ظ„ط§ط¨ ط§ظ„ظ†ط´ط·ظˆظ†', 'الطلاب النشطون'
        $modified = $true
    }
    
    if ($content -match 'ظپظٹ ط§ظ„ط·ط±ظٹظ‚') {
        $content = $content -replace 'ظپظٹ ط§ظ„ط·ط±ظٹظ‚', 'في الطريق'
        $modified = $true
    }
    
    if ($content -match 'ظˆطµظ„ظˆط§ ط§ظ„ظ…ط¯ط±ط³ط©') {
        $content = $content -replace 'ظˆطµظ„ظˆط§ ط§ظ„ظ…ط¯ط±ط³ط©', 'وصلوا المدرسة'
        $modified = $true
    }
    
    if ($content -match 'ط؛ظٹط± ظ†ط´ط·ظٹظ†') {
        $content = $content -replace 'ط؛ظٹط± ظ†ط´ط·ظٹظ†', 'غير نشطين'
        $modified = $true
    }
    
    if ($content -match 'ط§ظ„ظ†ط´ط§ط· ط§ظ„ط£ط®ظٹط±') {
        $content = $content -replace 'ط§ظ„ظ†ط´ط§ط· ط§ظ„ط£ط®ظٹط±', 'النشاط الأخير'
        $modified = $true
    }
    
    if ($content -match 'ط¹ط±ط¶ ط§ظ„ظƒظ„') {
        $content = $content -replace 'ط¹ط±ط¶ ط§ظ„ظƒظ„', 'عرض الكل'
        $modified = $true
    }
    
    if ($content -match 'ط§ظ„طھظ‚ط§ط±ظٹط±') {
        $content = $content -replace 'ط§ظ„طھظ‚ط§ط±ظٹط±', 'التقارير'
        $modified = $true
    }
    
    if ($content -match 'ط§ظ„طھط­ظ„ظٹظ„ط§طھ') {
        $content = $content -replace 'ط§ظ„طھط­ظ„ظٹظ„ط§طھ', 'التحليلات'
        $modified = $true
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        $count++
        Write-Host "Fixed: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "Fixed $count files!" -ForegroundColor Cyan
