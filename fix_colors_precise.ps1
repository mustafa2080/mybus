# Precise PowerShell Script to Fix Color Issues
Write-Host "Fixing color transparency issues precisely..." -ForegroundColor Green

# Get all Dart files
$files = Get-ChildItem -Path "lib" -Recurse -Include "*.dart"

$count = 0
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $modified = $false
    
    # Replace patterns with exact matches
    $newContent = $content
    
    # Replace withAlpha(25) // 0.1 * 255 back to withAlpha(25)
    $newContent = $newContent -replace 'withAlpha\(25\) // 0\.1 \* 255', 'withAlpha(25)'
    $newContent = $newContent -replace 'withAlpha\(51\) // 0\.2 \* 255', 'withAlpha(51)'
    $newContent = $newContent -replace 'withAlpha\(76\) // 0\.3 \* 255', 'withAlpha(76)'
    $newContent = $newContent -replace 'withAlpha\(13\) // 0\.05 \* 255', 'withAlpha(13)'
    $newContent = $newContent -replace 'withAlpha\(20\) // 0\.08 \* 255', 'withAlpha(20)'
    $newContent = $newContent -replace 'withAlpha\(38\) // 0\.15 \* 255', 'withAlpha(38)'
    $newContent = $newContent -replace 'withAlpha\(102\) // 0\.4 \* 255', 'withAlpha(102)'
    $newContent = $newContent -replace 'withAlpha\(127\) // 0\.5 \* 255', 'withAlpha(127)'
    $newContent = $newContent -replace 'withAlpha\(153\) // 0\.6 \* 255', 'withAlpha(153)'
    $newContent = $newContent -replace 'withAlpha\(178\) // 0\.7 \* 255', 'withAlpha(178)'
    $newContent = $newContent -replace 'withAlpha\(204\) // 0\.8 \* 255', 'withAlpha(204)'
    $newContent = $newContent -replace 'withAlpha\(229\) // 0\.9 \* 255', 'withAlpha(229)'
    
    if ($newContent -ne $content) {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
        $count++
        Write-Host "Cleaned: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "Cleaned $count files!" -ForegroundColor Cyan
