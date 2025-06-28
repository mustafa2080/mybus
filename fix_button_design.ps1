# PowerShell Script to Fix Button Design Issues
# Replaces withValues(alpha: ...) with withAlpha(...) in all Dart files

Write-Host "🔧 Starting Button Design Fix..." -ForegroundColor Green

# Define the replacements
$replacements = @{
    'withValues\(alpha: 0\.05\)' = 'withAlpha(13)  // 0.05 * 255 = 13'
    'withValues\(alpha: 0\.08\)' = 'withAlpha(20)  // 0.08 * 255 = 20'
    'withValues\(alpha: 0\.1\)' = 'withAlpha(25)   // 0.1 * 255 = 25'
    'withValues\(alpha: 0\.15\)' = 'withAlpha(38)  // 0.15 * 255 = 38'
    'withValues\(alpha: 0\.2\)' = 'withAlpha(51)   // 0.2 * 255 = 51'
    'withValues\(alpha: 0\.3\)' = 'withAlpha(76)   // 0.3 * 255 = 76'
    'withValues\(alpha: 0\.4\)' = 'withAlpha(102)  // 0.4 * 255 = 102'
    'withValues\(alpha: 0\.5\)' = 'withAlpha(127)  // 0.5 * 255 = 127'
    'withValues\(alpha: 0\.6\)' = 'withAlpha(153)  // 0.6 * 255 = 153'
    'withValues\(alpha: 0\.7\)' = 'withAlpha(178)  // 0.7 * 255 = 178'
    'withValues\(alpha: 0\.8\)' = 'withAlpha(204)  // 0.8 * 255 = 204'
    'withValues\(alpha: 0\.9\)' = 'withAlpha(229)  // 0.9 * 255 = 229'
}

# Get all Dart files in lib directory
$dartFiles = Get-ChildItem -Path "lib" -Recurse -Include "*.dart"

$totalFiles = $dartFiles.Count
$processedFiles = 0
$modifiedFiles = 0

Write-Host "📁 Found $totalFiles Dart files to process..." -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    $processedFiles++
    $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
    
    Write-Progress -Activity "Processing Dart files" -Status "Processing $relativePath" -PercentComplete (($processedFiles / $totalFiles) * 100)
    
    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $originalContent = $content
        $fileModified = $false
        
        # Apply each replacement
        foreach ($pattern in $replacements.Keys) {
            $replacement = $replacements[$pattern]
            if ($content -match $pattern) {
                $content = $content -replace $pattern, $replacement
                $fileModified = $true
            }
        }
        
        # Write back if modified
        if ($fileModified) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
            $modifiedFiles++
            Write-Host "✅ Fixed: $relativePath" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ Error processing $relativePath : $_" -ForegroundColor Red
    }
}

Write-Progress -Activity "Processing Dart files" -Completed

Write-Host ""
Write-Host "🎉 Button Design Fix Complete!" -ForegroundColor Green
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   • Total files processed: $totalFiles" -ForegroundColor White
Write-Host "   • Files modified: $modifiedFiles" -ForegroundColor White
Write-Host "   • Files unchanged: $($totalFiles - $modifiedFiles)" -ForegroundColor White

if ($modifiedFiles -gt 0) {
    Write-Host ""
    Write-Host "🔍 Next steps:" -ForegroundColor Yellow
    Write-Host "   1. Run 'flutter analyze' to check for any issues" -ForegroundColor White
    Write-Host "   2. Test the app to ensure buttons work correctly" -ForegroundColor White
    Write-Host "   3. Check that colors and transparency look good" -ForegroundColor White
}

Write-Host ""
Write-Host "✨ All button design issues have been fixed!" -ForegroundColor Green
