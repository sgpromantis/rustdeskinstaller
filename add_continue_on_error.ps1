# PowerShell script to add continue-on-error: true to all Report Status steps

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
        
        # If this line starts a "Report Status" step
        if ($line -match '^\s+- name: Report Status') {
            $newLines += $line
            $i++
            # Add continue-on-error right after the name
            $indent = ($line -replace '^(\s+).*$', '$1')
            $newLines += "$indent  continue-on-error: true"
            continue
        }
        
        $newLines += $line
        $i++
    }
    
    Set-Content $filepath $newLines
    Write-Host "  ✅ Updated $filepath" -ForegroundColor Green
}

Write-Host "`n✅ All workflows updated to continue on status reporting errors!" -ForegroundColor Green
