# Kick VOD Resume installer.
# Usage (one line, in PowerShell):
#   irm https://raw.githubusercontent.com/lx50ak-source/kick-vod-resume-releases/main/install.ps1 | iex
#
# - Downloads the latest release into %LOCALAPPDATA%\KickVodResume (no admin rights).
# - Registers a scheduled task that keeps those files up to date.
# - Opens Brave's extensions page with the folder path on the clipboard for the one-time
#   "Load unpacked". Brave's own profile files are never read or written by this script.
#
# Test overrides (environment variables): KVR_INSTALL_DIR, KVR_TASK_NAME, KVR_NO_LAUNCH=1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # the progress bar makes Invoke-WebRequest very slow on Windows PowerShell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo     = 'lx50ak-source/kick-vod-resume-releases'
$dir      = if ($env:KVR_INSTALL_DIR) { $env:KVR_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'KickVodResume' }
$taskName = if ($env:KVR_TASK_NAME) { $env:KVR_TASK_NAME } else { 'KickVodResume Update' }
$extDir   = Join-Path $dir 'extension'
$zip      = Join-Path $env:TEMP 'KickVodResume.zip'
$staging  = Join-Path $env:TEMP 'KickVodResume-staging'

# 1. Download and unpack the latest release.
Write-Host 'Kick VOD Resume: downloading the latest version...'
Invoke-WebRequest "https://github.com/$repo/releases/latest/download/KickVodResume.zip" -OutFile $zip -UseBasicParsing
Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive -Path $zip -DestinationPath $staging -Force

New-Item -ItemType Directory -Force -Path $dir | Out-Null
Remove-Item $extDir -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $staging 'extension') $extDir -Recurse
Copy-Item (Join-Path $staging 'update.ps1') $dir -Force
Remove-Item $zip, $staging -Recurse -Force

$version = (Get-Content (Join-Path $extDir 'manifest.json') -Raw | ConvertFrom-Json).version
Write-Host "Kick VOD Resume: version $version installed in $extDir"

# 2. Keep it updated: at logon and every 6 hours, for the current user only.
$updater = Join-Path $dir 'update.ps1'
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$updater`""
$triggers = @(
    (New-ScheduledTaskTrigger -AtLogOn -User ([Security.Principal.WindowsIdentity]::GetCurrent().Name)),
    (New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Hours 6))
)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggers -Settings $settings `
    -Description 'Keeps the Kick VOD Resume extension files up to date.' -Force | Out-Null
Write-Host "Kick VOD Resume: auto-update registered ('$taskName')."

# 3. One-time step in your own Brave. Scripts cannot add an extension to your profile
#    without editing Brave's data files, so this part stays a manual click.
#    Nothing is opened: Brave and its tabs are left exactly as they are.
if (-not $env:KVR_NO_LAUNCH) { Set-Clipboard -Value $extDir }
Write-Host ''
Write-Host 'First time only, in your Brave:' -ForegroundColor Yellow
Write-Host '  1. Type  brave://extensions  in the address bar'
Write-Host '  2. Turn on  Developer mode  (top right)'
Write-Host '  3. Click  Load unpacked , press Ctrl+V , then  Select Folder'
Write-Host '  4. Pin it: puzzle icon in the toolbar -> pin "Kick VOD Resume"'
Write-Host "  (the folder path is already on the clipboard: $extDir)"
Write-Host ''
Write-Host 'Already done before? Nothing else to do - just restart Brave to get the new version.'
