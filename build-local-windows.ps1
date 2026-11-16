# Local Windows build for Promantis Remote (RustDesk 1.4.6)
# Installs user-level toolchain, clones rustdesk, applies branding, builds portable exe.
# Requires Visual Studio C++ tools (MSVC). VS 2026 Professional alone is not enough.

[CmdletBinding()]
param(
    [switch]$SkipInstall,
    [switch]$SkipBuild,
    [switch]$SkipVcpkg,
    [switch]$SkipEngine
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolsRoot = Join-Path $env:USERPROFILE "rustdesk-build-tools"
$SrcDir = Join-Path $ToolsRoot "rustdesk"
$OutDir = Join-Path $RepoRoot "dist\windows"
$GitBash = "C:\Program Files\Git\bin\bash.exe"

$AppName = "Promantis Remote"
$FileName = "promantis_remote"
$CompanyName = "Promantis"
$Version = "1.4.6"
$Server = "rustdesk.promantis.de"
$ApiServer = "https://rustdesk.promantis.de"
$Key = "CctpHu85Bw1iuBwgZTATOjntfQkmqYc1yvs5m2pN+Vk="
$UrlLink = "https://promantis.de"
$DownloadLink = "https://supporttool.promantis.de"
$Slogan = "professionell. progressiv. proaktiv."

function Import-DotEnv([string]$Path) {
    if (-not (Test-Path $Path)) { return }
    Get-Content -Path $Path -Encoding UTF8 | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#") -or -not $line.Contains("=")) { return }
        $idx = $line.IndexOf("=")
        $name = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim().Trim('"').Trim("'")
        if ($name -and -not [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($name))) { return }
        Set-Item -Path "Env:$name" -Value $value
    }
}

Import-DotEnv (Join-Path $RepoRoot ".env")
$PermanentPassword = $env:PERMANENT_PASSWORD
if (-not $PermanentPassword) {
    throw "Set PERMANENT_PASSWORD in .env or the environment before building"
}
$LogoPng = Join-Path $RepoRoot "promantis_logo_2048_white.png"
$VcpkgCommit = "120deac3062162151622ca4860575a33844ba10b"
$FlutterVersion = "3.24.5"
$RustVersion = "1.75.0"
$LlvmVersion = "15.0.6"

function Write-Step([string]$Message) {
    Write-Host "`n==== $Message ====" -ForegroundColor Cyan
}

function Add-PathFront([string]$Dir) {
    if (-not (Test-Path $Dir)) { return }
    $env:Path = "$Dir;$env:Path"
}

function Test-Cmd([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-WingetInstall([string]$Id, [string]$Name) {
    if (-not (Test-Cmd "winget")) { return $false }
    Write-Host "Installing $Name via winget ($Id)..."
    $args = @(
        "install", "--id", $Id, "-e",
        "--accept-package-agreements", "--accept-source-agreements",
        "--disable-interactivity"
    )
    & winget @args
    return $LASTEXITCODE -eq 0
}

function Get-MsvcVcvars {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) { return $null }
    $path = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $path) { return $null }
    $vcvars = Join-Path $path "VC\Auxiliary\Build\vcvars64.bat"
    if (Test-Path $vcvars) { return $vcvars }
    return $null
}

function Invoke-Bash([string]$Script) {
    if (-not (Test-Path $GitBash)) {
        throw "Git Bash not found at $GitBash"
    }
    & $GitBash -lc $Script
    if ($LASTEXITCODE -ne 0) {
        throw "bash command failed ($LASTEXITCODE): $Script"
    }
}

function Invoke-BashSoft([string]$Script) {
    if (-not (Test-Path $GitBash)) { return }
    & $GitBash -lc $Script
}

function Import-VcVars64 {
    $vcvars = Get-MsvcVcvars
    if (-not $vcvars) { return $false }
    Write-Host "Loading MSVC environment from $vcvars"
    $output = cmd /c "`"$vcvars`" && set"
    foreach ($line in $output) {
        if ($line -match "^(.*?)=(.*)$") {
            $name = $matches[1]
            $value = $matches[2]
            if ($name -ieq "VCPKG_ROOT" -or $name -ieq "VCPKG_DEFAULT_HOST_TRIPLET" -or $name -ieq "VCPKG_INSTALLATION_ROOT") {
                continue
            }
            if ($value -match '(?i)\\VC\\vcpkg') {
                continue
            }
            Set-Item -Path "Env:$name" -Value $value
        }
    }
    Set-UserVcpkgEnv
    return $true
}

function Set-UserVcpkgEnv {
    $vcpkgRoot = Join-Path $ToolsRoot "vcpkg"
    $env:VCPKG_ROOT = $vcpkgRoot
    $env:VCPKG_DEFAULT_HOST_TRIPLET = "x64-windows-static"
    $env:VCPKG_DOWNLOADS = Join-Path $ToolsRoot "vcpkg-downloads"
    $env:VCPKG_DEFAULT_BINARY_CACHE = Join-Path $ToolsRoot "vcpkg-bincache"
    Remove-Item Env:VCPKG_INSTALLATION_ROOT -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $env:VCPKG_DOWNLOADS | Out-Null
    New-Item -ItemType Directory -Force -Path $env:VCPKG_DEFAULT_BINARY_CACHE | Out-Null
    $env:Path = (
        $env:Path -split ';' |
        Where-Object { $_ -and ($_ -notmatch '(?i)Visual Studio.+\\VC\\vcpkg') }
    ) -join ';'
    Add-PathFront $vcpkgRoot
    Write-Host "VCPKG_ROOT=$env:VCPKG_ROOT"
}

function Install-Rust {
    Add-PathFront (Join-Path $env:USERPROFILE ".cargo\bin")
    if (Test-Cmd "rustup") {
        Write-Host "rustup already present"
    } else {
        Write-Step "Installing rustup"
        $init = Join-Path $ToolsRoot "rustup-init.exe"
        Invoke-WebRequest "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe" -OutFile $init
        & $init -y --default-toolchain $RustVersion --profile minimal
        Add-PathFront (Join-Path $env:USERPROFILE ".cargo\bin")
    }
    rustup toolchain install $RustVersion
    rustup default $RustVersion
    rustup target add x86_64-pc-windows-msvc --toolchain $RustVersion
    rustup component add rustfmt --toolchain $RustVersion
}

function Install-CMake {
    if (Test-Cmd "cmake") { Write-Host "cmake already present"; return }
    $zip = Join-Path $ToolsRoot "cmake.zip"
    $dest = Join-Path $ToolsRoot "cmake"
    Write-Step "Installing portable CMake"
    Invoke-WebRequest "https://github.com/Kitware/CMake/releases/download/v3.30.5/cmake-3.30.5-windows-x86_64.zip" -OutFile $zip
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Expand-Archive $zip -DestinationPath $ToolsRoot -Force
    $extracted = Get-ChildItem $ToolsRoot -Directory | Where-Object { $_.Name -like "cmake-*" } | Select-Object -First 1
    if ($extracted) { Rename-Item $extracted.FullName $dest }
    Add-PathFront (Join-Path $dest "bin")
}

function Install-Nasm {
    if (Test-Cmd "nasm") { Write-Host "nasm already present"; return }
    $zip = Join-Path $ToolsRoot "nasm.zip"
    $dest = Join-Path $ToolsRoot "nasm"
    Write-Step "Installing portable NASM"
    Invoke-WebRequest "https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win64/nasm-2.16.03-win64.zip" -OutFile $zip
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Expand-Archive $zip -DestinationPath $ToolsRoot -Force
    $extracted = Get-ChildItem $ToolsRoot -Directory | Where-Object { $_.Name -like "nasm-*" } | Select-Object -First 1
    if ($extracted) { Rename-Item $extracted.FullName $dest }
    Add-PathFront $dest
}

function Set-Llvm15Env {
    $llvmBin = Join-Path $ToolsRoot "LLVM-15.0.6\bin"
    if (-not (Test-Path (Join-Path $llvmBin "libclang.dll"))) { return $false }
    $env:Path = ($env:Path -split ';' | Where-Object { $_ -and ($_ -notmatch '(?i)\\LLVM\\bin$') }) -join ';'
    $env:LIBCLANG_PATH = $llvmBin
    Add-PathFront $llvmBin
    Write-Host "LIBCLANG_PATH=$env:LIBCLANG_PATH"
    return $true
}

function Install-Llvm {
    if (Set-Llvm15Env) {
        Write-Host "LLVM 15 already present"
        return
    }
    Write-Step "Installing LLVM 15.0.6 (bindgen-compatible)"
    $llvmRoot = Join-Path $ToolsRoot "LLVM-15.0.6"
    $sevenZipDir = Join-Path $ToolsRoot "7zip"
    $sevenZip = Join-Path $sevenZipDir "7za.exe"
    New-Item -ItemType Directory -Force -Path $sevenZipDir | Out-Null
    if (-not (Test-Path $sevenZip)) {
        $nupkg = Join-Path $ToolsRoot "7zip-cmdline.nupkg"
        $nupkgDir = Join-Path $ToolsRoot "7zip-nupkg"
        Invoke-WebRequest "https://www.nuget.org/api/v2/package/7-Zip.CommandLine/18.1.0" -OutFile $nupkg
        Expand-Archive $nupkg -DestinationPath $nupkgDir -Force
        $found = Get-ChildItem $nupkgDir -Recurse -Filter "7za.exe" | Select-Object -First 1
        if (-not $found) { throw "7za.exe not found in 7-Zip.CommandLine nupkg" }
        Copy-Item $found.FullName $sevenZip -Force
    }
    $installerCandidates = @(
        (Join-Path $ToolsRoot "LLVM-15.0.6-win64.exe"),
        (Join-Path $ToolsRoot "vcpkg-downloads\LLVM-15.0.6-win64.exe")
    )
    $installer = $installerCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $installer) {
        $installer = $installerCandidates[0]
        Invoke-WebRequest "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/LLVM-15.0.6-win64.exe" -OutFile $installer
    }
    New-Item -ItemType Directory -Force -Path $llvmRoot | Out-Null
    $full7z = @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe",
        (Join-Path $ToolsRoot "7-Zip\7z.exe")
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $full7z) {
        Invoke-WingetInstall "7zip.7zip" "7-Zip" | Out-Null
        $full7z = @(
            "C:\Program Files\7-Zip\7z.exe",
            "C:\Program Files (x86)\7-Zip\7z.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
    $extracted = $false
    if ($full7z) {
        Write-Host "Extracting LLVM 15 with $full7z"
        & $full7z x -y "-o$llvmRoot" $installer
        $extracted = $LASTEXITCODE -eq 0
    }
    if (-not $extracted -or -not (Test-Path (Join-Path $llvmRoot "bin\libclang.dll"))) {
        Write-Host "Silent-installing LLVM 15 to $llvmRoot"
        $p = Start-Process -FilePath $installer -ArgumentList "/S", "/D=$llvmRoot" -Wait -PassThru
        if ($p.ExitCode -ne 0) {
            Write-Warning "LLVM silent install exit $($p.ExitCode)"
        }
    }
    if (-not (Set-Llvm15Env)) {
        $libclang = Get-ChildItem $llvmRoot -Recurse -Filter libclang.dll -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($libclang) {
            $env:LIBCLANG_PATH = $libclang.DirectoryName
            Add-PathFront $env:LIBCLANG_PATH
            Write-Host "LIBCLANG_PATH=$env:LIBCLANG_PATH"
        } else {
            throw "LLVM 15 libclang.dll not found after extract/install"
        }
    }
}

function Install-ImageMagick {
    if (Test-Cmd "magick") { Write-Host "magick already present"; return }
    Write-Step "Installing ImageMagick via winget"
    Invoke-WingetInstall "ImageMagick.ImageMagick" "ImageMagick" | Out-Null
    Add-PathFront "C:\Program Files\ImageMagick-7.1.1-Q16-HDRI"
    Get-ChildItem "C:\Program Files" -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "ImageMagick*" } |
        ForEach-Object { Add-PathFront $_.FullName }
}

function Install-Flutter {
    $flutterRoot = Join-Path $ToolsRoot "flutter"
    $flutterBat = Join-Path $flutterRoot "bin\flutter.bat"
    if (-not (Test-Path $flutterBat)) {
        Write-Step "Cloning Flutter $FlutterVersion"
        git clone --depth 1 --branch $FlutterVersion https://github.com/flutter/flutter.git $flutterRoot
    } else {
        Write-Host "Flutter already present"
    }
    Add-PathFront (Join-Path $flutterRoot "bin")
    Add-PathFront (Join-Path $flutterRoot "bin\cache\dart-sdk\bin")
    $env:FLUTTER_ROOT = $flutterRoot
    flutter config --no-analytics
    flutter precache --windows
}

function Install-Vcpkg {
    $vcpkgRoot = Join-Path $ToolsRoot "vcpkg"
    if (-not (Test-Path (Join-Path $vcpkgRoot ".git"))) {
        Write-Step "Cloning vcpkg"
        git clone https://github.com/microsoft/vcpkg.git $vcpkgRoot
    }
    Push-Location $vcpkgRoot
    git fetch --depth 1 origin $VcpkgCommit
    git checkout $VcpkgCommit
    if (-not (Test-Path ".\vcpkg.exe")) {
        Write-Host "Bootstrapping vcpkg..."
        cmd /c bootstrap-vcpkg.bat -disableMetrics
    }
    Pop-Location
    $env:VCPKG_ROOT = $vcpkgRoot
    Add-PathFront $vcpkgRoot
}

function Install-PythonPkgs {
    python -m pip install --upgrade pip
    python -m pip install pyyaml
}

function Ensure-Msvc {
    if (Import-VcVars64) { return }
    Write-Host @"

MSVC C++ tools are not installed.
Visual Studio Professional 2026 is present, but the Desktop C++ workload is missing.

Install C++ tools (run in an elevated terminal), then re-run this script:

  winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --add Microsoft.VisualStudio.Component.Windows11SDK.22621"

Or add "Desktop development with C++" to VS 2026 via Visual Studio Installer.

"@ -ForegroundColor Yellow
    throw "MSVC C++ toolchain is required"
}

function Get-CustomBase64 {
    $env:PERMANENT_PASSWORD = $PermanentPassword
    $script = Join-Path $RepoRoot "custom_config.py"
    $out = & python $script
    if ($LASTEXITCODE -ne 0) { throw "custom_config.py failed" }
    return $out
}

function Clone-RustDesk {
    if (-not (Test-Path (Join-Path $SrcDir ".git"))) {
        Write-Step "Cloning rustdesk $Version"
        git clone --depth 1 --branch $Version --recurse-submodules https://github.com/rustdesk/rustdesk.git $SrcDir
    } else {
        Write-Host "rustdesk source already present"
        Push-Location $SrcDir
        $head = (git describe --tags --exact-match 2>$null)
        if ($head -ne $Version) {
            git fetch --depth 1 origin tag $Version
            git checkout $Version
        }
        git reset --hard HEAD
        git submodule update --init --recursive
        Pop-Location
    }
}

function Apply-Branding {
    Write-Step "Applying Promantis branding"
    Push-Location $SrcDir
    try {
        Invoke-BashSoft "sed -i -e 's|2ded7f146437a761ffe6981e2f742038f85ca68d|08a471bb8ceccdd50483c81cdfa8b81b07b14b87|' ./flutter/pubspec.lock ./flutter/pubspec.yaml"

        Invoke-Bash @"
sed -i -e 's|description = \"RustDesk Remote Desktop\"|description = \"$AppName\"|' ./Cargo.toml ./libs/portable/Cargo.toml
sed -i -e 's|ProductName = \"RustDesk\"|ProductName = \"$AppName\"|' ./Cargo.toml ./libs/portable/Cargo.toml
sed -i -e 's|FileDescription = \"RustDesk Remote Desktop\"|FileDescription = \"$AppName\"|' ./Cargo.toml ./libs/portable/Cargo.toml
sed -i -e 's|OriginalFilename = \"rustdesk.exe\"|OriginalFilename = \"$AppName.exe\"|' ./Cargo.toml ./libs/portable/Cargo.toml
sed -i -e 's|\"RustDesk Remote Desktop\"|\"$AppName\"|' ./flutter/windows/runner/Runner.rc
sed -i -e 's|VALUE \"InternalName\", \"rustdesk\" \"\\0\"|VALUE \"InternalName\", \"$AppName\" \"\\0\"|' ./flutter/windows/runner/Runner.rc
sed -i -e 's|\"rustdesk.exe\"|\"$FileName\"|' ./flutter/windows/runner/Runner.rc
sed -i -e 's|\"RustDesk\"|\"$AppName\"|' ./flutter/windows/runner/Runner.rc
find ./src/lang -name '*.rs' -exec sed -i -e 's|RustDesk|$AppName|' {} \;
"@

        $quoteReg = Join-Path $RepoRoot ".github\patches\quote_windows_reg.py"
        python $quoteReg (Join-Path $SrcDir "src\platform\windows.rs")
        if ($LASTEXITCODE -ne 0) { throw "windows.rs registry quoting failed" }

        Invoke-BashSoft @"
sed -i -e 's|Purslane Ltd|$CompanyName|' ./flutter/lib/desktop/pages/desktop_setting_page.dart ./res/msi/preprocess.py ./flutter/windows/runner/Runner.rc ./Cargo.toml ./libs/portable/Cargo.toml
[ -f ./res/setup.nsi ] && sed -i -e 's|Purslane Ltd.|$CompanyName|' ./res/setup.nsi
sed -i -e 's|PURSLANE|$CompanyName|' ./res/msi/preprocess.py
"@

        Invoke-BashSoft @"
sed -i -e 's|Homepage: https://rustdesk.com|Homepage: $UrlLink|' ./build.py
sed -i -e \"s|launchUrl(Uri.parse('https://rustdesk.com'))|launchUrl(Uri.parse('$UrlLink'))|\" ./flutter/lib/common.dart
sed -i -e \"s|launchUrlString('https://rustdesk.com')|launchUrlString('$UrlLink')|\" ./flutter/lib/desktop/pages/desktop_setting_page.dart
sed -i -e 's|https://rustdesk.com/download|$DownloadLink|' ./flutter/lib/desktop/pages/desktop_home_page.dart ./flutter/lib/mobile/pages/connection_page.dart
sed -i -e 's|rs-ny.rustdesk.com|$Server|' ./libs/hbb_common/src/config.rs
sed -i -e 's|OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=|$Key|' ./libs/hbb_common/src/config.rs
sed -i -e 's|https://admin.rustdesk.com|$ApiServer|' ./src/common.rs
"@

        $allowCustom = Join-Path $RepoRoot ".github\patches\allowCustom.py"
        python $allowCustom
        if ($LASTEXITCODE -ne 0) { throw "allowCustom.py failed" }

        foreach ($diffName in @("removeSetupServerTip.diff")) {
            $diff = Join-Path $RepoRoot ".github\patches\$diffName"
            if (-not (Test-Path $diff)) { continue }
            git apply $diff --whitespace=nowarn
            if ($LASTEXITCODE -ne 0) { Write-Warning "$diffName skipped" }
        }

        $harden = Join-Path $RepoRoot ".github\patches\harden_permanent_password.py"
        python $harden
        if ($LASTEXITCODE -ne 0) { throw "password harden patch failed" }

        # Rust 1.75 does not know static_mut_refs (added later); keep the allow for newer rustc.
        Get-ChildItem -Path (Join-Path $SrcDir "libs\hbb_common") -Recurse -Filter *.rs | ForEach-Object {
            $fpText = [IO.File]::ReadAllText($_.FullName)
            $fpPatched = $fpText.Replace("#[allow(static_mut_refs)]", "#[allow(unknown_lints, static_mut_refs)]")
            if ($fpPatched -ne $fpText) { [IO.File]::WriteAllText($_.FullName, $fpPatched) }
        }

        if (Test-Path $LogoPng) {
            Copy-Item $LogoPng .\res\icon.png -Force
            if (Test-Cmd "magick") {
                if (Test-Path .\res\icon.ico) { Copy-Item .\res\icon.ico .\res\icon.ico.bak -Force }
                magick .\res\icon.png -define icon:auto-resize=256,64,48,32,16 .\res\icon.ico
                Copy-Item .\res\icon.ico .\res\tray-icon.ico -Force
                magick .\res\icon.png -resize 32x32 .\res\32x32.png
                magick .\res\icon.png -resize 64x64 .\res\64x64.png
                magick .\res\icon.png -resize 128x128 .\res\128x128.png
                magick .\res\128x128.png -resize 200% .\res\128x128@2x.png
            }
        }
    } finally {
        Pop-Location
    }
}

function Install-CustomFlutterEngine {
    Write-Step "Replacing Flutter Windows engine with RustDesk custom engine"
    $engineDir = Join-Path $ToolsRoot "flutter\bin\cache\artifacts\engine\windows-x64-release"
    $zip = Join-Path $ToolsRoot "windows-x64-release.zip"
    Invoke-WebRequest "https://github.com/rustdesk/engine/releases/download/main/windows-x64-release.zip" -OutFile $zip
    $tmp = Join-Path $ToolsRoot "windows-x64-release"
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Expand-Archive $zip -DestinationPath $tmp -Force
    New-Item -ItemType Directory -Force -Path $engineDir | Out-Null
    Copy-Item -Path (Join-Path $tmp "*") -Destination $engineDir -Recurse -Force

    Push-Location $SrcDir
    try {
        $flutterRoot = Join-Path $ToolsRoot "flutter"
        $patch = Join-Path $SrcDir ".github\patches\flutter_3.24.4_dropdown_menu_enableFilter.diff"
        if (Test-Path $patch) {
            Push-Location $flutterRoot
            git apply $patch --whitespace=nowarn
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Flutter 3.24.4 dropdown patch did not apply (safe to ignore on 3.24.5)"
            }
            Pop-Location
        }
    } catch {
        Write-Warning "Flutter dropdown patch skipped: $_"
    } finally {
        Pop-Location
    }
}

function Install-VcpkgDeps {
    Write-Step "Installing vcpkg dependencies (this takes a long time)"
    Set-UserVcpkgEnv
    $vcpkgExe = Join-Path $env:VCPKG_ROOT "vcpkg.exe"
    if (-not (Test-Path $vcpkgExe)) {
        throw "vcpkg.exe not found at $vcpkgExe"
    }
    Push-Location $SrcDir
    try {
        $installRoot = Join-Path $ToolsRoot "vcpkg\installed"
        $downloadsRoot = Join-Path $ToolsRoot "vcpkg-downloads"
        Write-Host "Using $vcpkgExe"
        Write-Host "Install root: $installRoot"
        & $vcpkgExe install `
            --vcpkg-root=$env:VCPKG_ROOT `
            --triplet x64-windows-static `
            --x-install-root=$installRoot `
            --downloads-root=$downloadsRoot
        if ($LASTEXITCODE -ne 0) {
            throw "vcpkg install failed"
        }
    } finally {
        Pop-Location
    }
}

function Generate-FlutterBridge {
    Write-Step "Generating flutter_rust_bridge"
    Push-Location $SrcDir
    try {
        $bridge = Join-Path $SrcDir "src\bridge_generated.rs"
        if ((Test-Path $bridge) -and ((Get-Item $bridge).Length -gt 0)) {
            Write-Host "bridge_generated.rs already present"
            return
        }
        cargo install cargo-expand --version 1.0.95 --locked
        if ($LASTEXITCODE -ne 0) { throw "cargo install cargo-expand failed" }
        cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid --locked
        if ($LASTEXITCODE -ne 0) { throw "cargo install flutter_rust_bridge_codegen failed" }
        Push-Location flutter
        flutter pub get
        Pop-Location
        flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/windows/runner/bridge_generated.h
        if ($LASTEXITCODE -ne 0) { throw "flutter_rust_bridge_codegen failed" }
        if (-not (Test-Path $bridge)) { throw "src/bridge_generated.rs was not generated" }
    } finally {
        Pop-Location
    }
}

function Build-RustDesk {
    Write-Step "Building RustDesk Flutter Windows client"
    Set-UserVcpkgEnv
    if (-not (Set-Llvm15Env)) {
        throw "LLVM 15 libclang.dll is required for bindgen (clang 23 cannot parse libvpx/aom headers)"
    }
    $scrapLib = Join-Path $SrcDir "libs\scrap\src\lib.rs"
    if (Test-Path $scrapLib) { (Get-Item $scrapLib).LastWriteTime = Get-Date }
    rustup override set $RustVersion --path $SrcDir
    Push-Location $SrcDir
    try {
        python .\build.py --portable --hwcodec --flutter --vram --skip-portable-pack
        if ($LASTEXITCODE -ne 0) { throw "build.py failed" }

        $release = ".\flutter\build\windows\x64\runner\Release"
        if (-not (Test-Path $release)) { throw "Flutter Release folder not found" }
        if (Test-Path ".\rustdesk") { Remove-Item ".\rustdesk" -Recurse -Force }
        Move-Item $release ".\rustdesk"

        try {
            Invoke-WebRequest "https://github.com/rustdesk-org/rdev/releases/download/usbmmidd_v2/usbmmidd_v2.zip" -OutFile "usbmmidd_v2.zip"
            Expand-Archive "usbmmidd_v2.zip" -DestinationPath . -Force
            Remove-Item ".\usbmmidd_v2\Win32" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item ".\usbmmidd_v2\deviceinstaller64.exe","usbmmidd_v2\deviceinstaller.exe","usbmmidd_v2\usbmmidd.bat" -ErrorAction SilentlyContinue
            Move-Item ".\usbmmidd_v2" ".\rustdesk" -Force
        } catch {
            Write-Warning "usbmmidd_v2 skipped: $_"
        }

        if (Test-Path $LogoPng) {
            Copy-Item $LogoPng ".\rustdesk\data\flutter_assets\assets\logo.png" -Force -ErrorAction SilentlyContinue
        }

        $customB64 = Get-CustomBase64
        Set-Content -Path ".\rustdesk\custom.txt" -Value $customB64 -NoNewline -Encoding ASCII

        $exeInBundle = Join-Path ".\rustdesk" "rustdesk.exe"
        $brandedExe = Join-Path ".\rustdesk" "$AppName.exe"
        if (Test-Path $exeInBundle) { Move-Item $exeInBundle $brandedExe -Force }

        Push-Location ".\libs\portable"
        python -m pip install -r requirements.txt
        python .\generate.py -f ..\..\rustdesk\ -o . -e "..\..\rustdesk\$AppName.exe"
        Pop-Location

        New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
        $packed = ".\target\release\rustdesk-portable-packer.exe"
        if (-not (Test-Path $packed)) { throw "portable packer output not found" }
        Copy-Item $packed (Join-Path $OutDir "$FileName.exe") -Force
        Write-Host "Built $(Join-Path $OutDir "$FileName.exe")" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

# ---------- main ----------
New-Item -ItemType Directory -Force -Path $ToolsRoot | Out-Null
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "Tools: $ToolsRoot"
Write-Host "Source: $SrcDir"
Write-Host "Output: $OutDir"

if (-not $SkipInstall) {
    Write-Step "Installing toolchain"
    Install-CMake
    Install-Nasm
    Install-Llvm
    Install-ImageMagick
    Install-Rust
    Install-Flutter
    Install-Vcpkg
    Install-PythonPkgs
}

Add-PathFront (Join-Path $env:USERPROFILE ".cargo\bin")
Add-PathFront (Join-Path $ToolsRoot "cmake\bin")
Add-PathFront (Join-Path $ToolsRoot "nasm")
Add-PathFront (Join-Path $ToolsRoot "flutter\bin")
Add-PathFront (Join-Path $ToolsRoot "vcpkg")
Install-Llvm
Set-UserVcpkgEnv

Ensure-Msvc
Set-UserVcpkgEnv
Install-Llvm

if (-not $SkipBuild) {
    Clone-RustDesk
    Apply-Branding
    if (-not $SkipEngine) { Install-CustomFlutterEngine }
    if (-not $SkipVcpkg) { Install-VcpkgDeps }
    Generate-FlutterBridge
    Build-RustDesk
}

Write-Step "Done"
Write-Host "Installer: $(Join-Path $OutDir "$FileName.exe")"
