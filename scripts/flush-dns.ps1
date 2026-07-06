# --- DNS Flush Script v0.1.0 ---
# Clears the DNS cache, shows a toast notification when enabled, and logs the action
param()

$scriptRoot         = Split-Path -Parent $MyInvocation.MyCommand.Path
$telemetryFolder    = Join-Path $scriptRoot "Telemetry"
$logFile            = Join-Path $telemetryFolder "wifi-log.txt"
$wifiIcon           = Join-Path $scriptRoot "wifi.png"
$errorLog           = Join-Path $telemetryFolder "wifi-toast-error.txt"
$notificationConfig = Join-Path $scriptRoot "notification-enabled.ini"
$notificationEnabled = $true

if (Test-Path $notificationConfig) {
    try {
        $configText = Get-Content $notificationConfig -ErrorAction Stop
        $match = $configText | Select-String -Pattern '^\s*Enabled\s*=\s*([01])\s*$'
        if ($match) {
            $notificationEnabled = $match.Matches[0].Groups[1].Value -eq '1'
        }
    }
    catch {
        Add-Content -Path $errorLog -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Notification config read failed: $($_.Exception.Message)"
    }
}

if (!(Test-Path $telemetryFolder)) {
    New-Item -ItemType Directory -Path $telemetryFolder -Force | Out-Null
}

Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] --- DNS Flush Script Started ---"

function Install-BurntToastIfNeeded {
    if (Get-Module -ListAvailable -Name BurntToast) {
        return $true
    }

    try {
        if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
            Register-PSRepository -Name PSGallery -SourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        }
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue

        Install-Module -Name BurntToast -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] BurntToast module installed"
        return $true
    }
    catch {
        Add-Content -Path $errorLog -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] BurntToast install failed: $($_.Exception.Message)"
        return $false
    }
}

function Show-Notification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$IconPath
    )

    if (-not $notificationEnabled) {
        Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Notification skipped (disabled)"
        return
    }

    if (Install-BurntToastIfNeeded) {
        try {
            Import-Module BurntToast -Force -ErrorAction Stop

            $toastParams = @{
                Text = @($Title, $Message)
            }
            if ($IconPath -and (Test-Path $IconPath)) {
                $toastParams['AppLogo'] = $IconPath
            }

            & New-BurntToastNotification @toastParams -ErrorAction Stop

            Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Notification displayed (BurntToast)"
            return
        }
        catch {
            Add-Content -Path $errorLog -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] BurntToast failed, using MessageBox fallback: $($_.Exception.Message)"
        }
    }
}

try {
    Clear-DnsClientCache
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Show-Notification -Title "DNS Cache Cleared" -Message "The DNS cache was cleared successfully." -IconPath $wifiIcon

    Add-Content -Path $logFile -Value "[$time] DNS cache cleared successfully"
}
catch {
    $err = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: $($_.Exception.Message)"
    Add-Content -Path $errorLog -Value $err
    Write-Error $err
}
