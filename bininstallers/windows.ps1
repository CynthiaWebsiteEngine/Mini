# Check if running on Windows
if ($Env:OS -ne "Windows_NT") {
    Write-Host "This script is for Windows only. Please use the bash script for Linux or macOS." -ForegroundColor Red
    exit 1
}

# Available environment variables to alter the behavior of the script:
# CYNTHIAWEB_MINI_INSTALL_DIR: Directory to install cynthiaweb-mini. Default is $HOME\bin\mini.
# CYNTHIAWEB_MINI_RELEASE: Release version to install. Default is the latest release.

# Define OS and architecture
$det_os = "windows"
$det_arch = if ([Environment]::Is64BitOperatingSystem) {
    if ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64) {
        "arm64"
    } else {
        "x64"
    }
} else {
    Write-Host "Your architecture is not supported." -ForegroundColor Red
    exit 1
}

# Tell the user what OS we detected
Write-Host "Detected OS: " -ForegroundColor Blue -NoNewline
Write-Host "$det_os ($det_arch)"

# Get release version (from environment variable or latest)
if ($Env:CYNTHIAWEB_MINI_RELEASE) {
    $release = $Env:CYNTHIAWEB_MINI_RELEASE.TrimStart('v')
    Write-Host "Using specified release: " -ForegroundColor Blue -NoNewline
    Write-Host "v$release" -ForegroundColor Cyan
} else {
    try {
        $release = (Invoke-RestMethod "https://api.github.com/repos/CynthiaWebsiteEngine/Mini/releases/latest").tag_name.TrimStart('v')
        if ([string]::IsNullOrWhiteSpace($release)) {
            Write-Host "Failed to fetch release information from GitHub" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "Failed to fetch latest release information" -ForegroundColor Red
        exit 1
    }
}

$url = "https://github.com/CynthiaWebsiteEngine/Mini/releases/download/v${release}/cynthiaweb-mini-${det_os}-${det_arch}.exe"

# Set install directory (from environment variable or default)
if ($Env:CYNTHIAWEB_MINI_INSTALL_DIR) {
    $installDir = $Env:CYNTHIAWEB_MINI_INSTALL_DIR
} else {
    $installDir = "$HOME\bin\mini"
}
$exePath = "$installDir\cynthiaweb-mini.exe"

Write-Host "Downloading " -ForegroundColor Blue -NoNewline
Write-Host "cynthiaweb-mini " -ForegroundColor Magenta -NoNewline
Write-Host "from " -ForegroundColor Blue -NoNewline
Write-Host $url -ForegroundColor Cyan

# Create install directory
if (-not (Test-Path $installDir)) {
    try {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    } catch {
        Write-Host "Failed to create installation directory" -ForegroundColor Red
        exit 1
    }
}

# Download the file
try {
    Invoke-WebRequest -Uri $url -OutFile $exePath
} catch {
    Write-Host "Failed to download cynthiaweb-mini" -ForegroundColor Red
    exit 1
}

# Add to PATH if not already present
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$installDir*") {
    try {
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$userPath;$installDir",
            "User"
        )
        Write-Host "`nAdded to PATH successfully!" -ForegroundColor Green
        Write-Host "Note: You'll need to restart your terminal for the PATH changes to take effect." -ForegroundColor Yellow
    } catch {
        Write-Host "`nPlease add this directory to your PATH manually:" -ForegroundColor Yellow
        Write-Host "$installDir" -ForegroundColor Cyan
        Write-Host "You can do this by adding it to your PowerShell profile or Windows Environment Variables" -ForegroundColor Yellow
    }
}

Write-Host "`ncynthiaweb-mini " -ForegroundColor Magenta -NoNewline
Write-Host "is ready to use!" -ForegroundColor Green
