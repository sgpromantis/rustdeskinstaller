$ErrorActionPreference = "Stop"
$src = Join-Path $env:USERPROFILE "rustdesk-build-tools\rustdesk"
$bundle = Join-Path $src "rustdesk"
$custom = Join-Path $bundle "custom.txt"
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path

Set-Location $repo
python test_custom_config.py
if ($LASTEXITCODE -ne 0) { throw "tests failed" }
python custom_config.py | Set-Content -Path $custom -Encoding Ascii -NoNewline
if ($LASTEXITCODE -ne 0) { throw "custom_config.py failed" }
Write-Host "custom.txt bytes=$((Get-Item $custom).Length)"

Set-Location (Join-Path $src "libs\portable")
$exeName = "Promantis Support Tool.exe"
if (-not (Test-Path (Join-Path $bundle $exeName))) {
    $exeName = "Promantis Remote.exe"
}
python .\generate.py -f ..\..\rustdesk\ -o . -e "..\..\rustdesk\$exeName"
if ($LASTEXITCODE -ne 0) { throw "portable packer failed" }

$packed = Join-Path $src "target\release\rustdesk-portable-packer.exe"
if (-not (Test-Path $packed)) {
    $packed = Join-Path (Get-Location) "target\release\rustdesk-portable-packer.exe"
}
$dest = Join-Path $repo "dist\windows\promantis_support_tool.exe"
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
Copy-Item $packed $dest -Force
Write-Host "Updated $dest ($((Get-Item $dest).Length) bytes)"
