# PowerShell Script to Fix Arabic Encoding Issues
Write-Host "Fixing Arabic encoding issues..." -ForegroundColor Green

# Define the corrupted to correct Arabic mappings
$arabicMappings = @{}

# Get all Dart files
$files = Get-ChildItem -Path "lib" -Recurse -Include "*.dart"

$count = 0
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $modified = $false
    
    # Apply each Arabic mapping
    foreach ($corrupted in $arabicMappings.Keys) {
        $correct = $arabicMappings[$corrupted]
        if ($content -match [regex]::Escape($corrupted)) {
            $content = $content -replace [regex]::Escape($corrupted), $correct
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        $count++
        Write-Host "تم إصلاح: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "تم إصلاح $count ملف!" -ForegroundColor Cyan
