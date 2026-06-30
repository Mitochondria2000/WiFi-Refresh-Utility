# --- WiFi Refresh Script v0.3.0 ---
# Flushes DNS/ARP, reconnects Wi-Fi, shows toast notification via BurntToast, logs action
param()

# Paths relative to script folder
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

# Debug: Log script start
Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] --- Script Started ---"

# Notification function: Try BurntToast module, fallback to MessageBox (guaranteed to work)
function Ensure-BurntToast {
    # Already loaded or installed?
    if (Get-Module -ListAvailable -Name BurntToast) {
        return $true
    }

    try {
        # CurrentUser scope avoids needing admin rights
        Install-Module -Name BurntToast -Scope CurrentUser -Force -ErrorAction Stop
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

    # Method 1: BurntToast (handles AUMID/shortcut registration internally,
    # so it avoids the silent failure mode the old WScript.Shell-based
    # C# helper had: that approach created a shortcut with no AppUserModelID,
    # so Windows never registered the app and toasts were dropped with no error)
    if (Ensure-BurntToast) {
        try {
            Import-Module BurntToast -ErrorAction Stop

            $toastParams = @{
                Text = @($Title, $Message)
            }
            if ($IconPath -and (Test-Path $IconPath)) {
                $toastParams['AppLogo'] = $IconPath
            }

            New-BurntToastNotification @toastParams -ErrorAction Stop

            Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Notification displayed (BurntToast)"
            return
        }
        catch {
            Add-Content -Path $errorLog -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] BurntToast failed, using MessageBox fallback: $($_.Exception.Message)"
        }
    }

    # Method 2: Fallback to PowerShell MessageBox (guaranteed to work)
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            $Message, 
            $Title, 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        
        Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Notification displayed (MessageBox)"
    }
    catch {
        $err = "Notification failed: $($_.Exception.Message)"
        Write-Error $err
        Add-Content -Path $errorLog -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $err"
    }
}

try {
    # Detect SSID
    $ssidLine = netsh wlan show interfaces | Select-String "^\s*SSID\s*:"
    $ssid = ""
    if ($ssidLine) {
        $ssid = ($ssidLine -replace "^\s*SSID\s*:\s*", "").Trim()
    }
    if ([string]::IsNullOrWhiteSpace($ssid)) {
        $ssid = "SSID unavailable"
    }

    # Flush DNS
    Clear-DnsClientCache

    # Clear ARP
    netsh interface ip delete arpcache | Out-Null

    # Disconnect Wi-Fi
    netsh wlan disconnect | Out-Null
    Start-Sleep -Seconds 2

    # Reconnect Wi-Fi
    netsh wlan connect name="$ssid" | Out-Null
    Start-Sleep -Seconds 1

    # Timestamp
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Log success
    Add-Content -Path $logFile -Value "[$time] Wi-Fi cache cleared and reconnected to SSID: $ssid"

    # Show notification
    Show-Notification -Title "Wi-Fi Refreshed" -Message "Connected to $ssid at $time" -IconPath $wifiIcon
}
catch {
    $err = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: $($_.Exception.Message)"
    Add-Content -Path $errorLog -Value $err
    Write-Error $err
}