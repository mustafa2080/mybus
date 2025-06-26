# Simple PowerShell Script to Fix Color Issues
Write-Host "Fixing color transparency issues..." -ForegroundColor Green

# Get all Dart files
$files = Get-ChildItem -Path "lib" -Recurse -Include "*.dart"

$count = 0
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $modified = $false
    
    # Replace common patterns
    if ($content -match 'withValues\(alpha: 0\.1\)') {
        $content = $content -replace 'withValues\(alpha: 0\.1\)', 'withAlpha(25) // 0.1 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.2\)') {
        $content = $content -replace 'withValues\(alpha: 0\.2\)', 'withAlpha(51) // 0.2 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.3\)') {
        $content = $content -replace 'withValues\(alpha: 0\.3\)', 'withAlpha(76) // 0.3 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.05\)') {
        $content = $content -replace 'withValues\(alpha: 0\.05\)', 'withAlpha(13) // 0.05 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.08\)') {
        $content = $content -replace 'withValues\(alpha: 0\.08\)', 'withAlpha(20) // 0.08 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.15\)') {
        $content = $content -replace 'withValues\(alpha: 0\.15\)', 'withAlpha(38) // 0.15 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.4\)') {
        $content = $content -replace 'withValues\(alpha: 0\.4\)', 'withAlpha(102) // 0.4 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.5\)') {
        $content = $content -replace 'withValues\(alpha: 0\.5\)', 'withAlpha(127) // 0.5 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.6\)') {
        $content = $content -replace 'withValues\(alpha: 0\.6\)', 'withAlpha(153) // 0.6 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.7\)') {
        $content = $content -replace 'withValues\(alpha: 0\.7\)', 'withAlpha(178) // 0.7 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.8\)') {
        $content = $content -replace 'withValues\(alpha: 0\.8\)', 'withAlpha(204) // 0.8 * 255'
        $modified = $true
    }
    
    if ($content -match 'withValues\(alpha: 0\.9\)') {
        $content = $content -replace 'withValues\(alpha: 0\.9\)', 'withAlpha(229) // 0.9 * 255'
        $modified = $true
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        $count++
        Write-Host "Fixed: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "Fixed $count files!" -ForegroundColor Cyan
