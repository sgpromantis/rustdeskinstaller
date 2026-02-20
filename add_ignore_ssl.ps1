# PowerShell script to add ignoreSsl: true to all http-request-action calls

$files = @(
    ".github/workflows/generator-macos.yml",
    ".github/workflows/generator-windows.yml",
    ".github/workflows/generator-linux.yml"
)

foreach ($filepath in $files) {
    Write-Host "Processing $filepath..." -ForegroundColor Cyan
    
    $lines = Get-Content $filepath
    $newLines = @()
    $i = 0
    
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        $newLines += $line
        
        # If this line contains a data: field with JSON
        if ($line -match "^\s+data: '.*'$") {
            # Check if next line already has ignoreSsl
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -notmatch "ignoreSsl") {
                # Add ignoreSsl with same indentation
                $indent = ($line -replace '^(\s+).*$', '$1')
                $newLines += "$indent  ignoreSsl: true"
            }
        }
        
        $i++
    }
    
    Set-Content $filepath $newLines
    Write-Host "  ✅ Updated $filepath" -ForegroundColor Green
}

Write-Host "`n✅ All workflows updated!" -ForegroundColor Green
