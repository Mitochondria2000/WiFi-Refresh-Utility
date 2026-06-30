# WiFi Refresh Utility

A lightweight Windows utility to refresh your WiFi connection with a single click or hotkey. Automatically flushes DNS cache, clears ARP table, disconnects and reconnects to your current network, and displays a toast notification when complete.

## Features

- **One-click WiFi refresh** — Clears DNS/ARP cache and reconnects automatically
- **Tray menu interface** — Minimalist, always-accessible menu in your system tray
- **Hotkey support** — Default hotkeys: `F9` (refresh WiFi), `F10` (flush DNS only)
- **Toast notifications** — Get notified when your connection is refreshed (via BurntToast)
- **Toggle notifications** — Turn alerts on/off without editing config files
- **Detailed logging** — All actions logged to `Telemetry/` folder for troubleshooting
- **Portable** — No installation required; runs as a standalone script

## Prerequisites

- **Windows 10 or later** (tested on build 19045+)
- **PowerShell 5.0+** (usually built-in)
- **Administrator privileges** (required for WiFi/DNS operations)
- **BurntToast module** (auto-installed on first run)

## Installation

### Quick Start

1. **Download the files:**
   ```
   togglewifi.ahk          (main launcher)
   Scripts/
     ├── wifi-refresh.ps1  (core script)
     ├── wifi.png          (tray icon)
     └── notification-enabled.ini
   ```

2. **Install AutoHotkey v1.1** (if not already installed)
   - Download from [autohotkey.com](https://www.autohotkey.com/)
   - Run `togglewifi.ahk`

3. **On first run:**
   - Right-click → "Run with PowerShell" to allow BurntToast module installation
   - Or pre-install manually in PowerShell:
     ```powershell
     Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
     Install-Module -Name BurntToast -Scope CurrentUser -Force
     ```

### File Structure

```
WiFi-Refresh/
├── togglewifi.ahk                    # AHK launcher (tray menu)
├── Scripts/
│   ├── wifi-refresh.ps1              # PowerShell core script
│   ├── wifi.png                      # Tray icon
│   ├── notification-enabled.ini      # Notification toggle config
│   └── ToastNotificationHelper.csproj # (Optional) Legacy C# helper
├── Telemetry/                        # Auto-created logs folder
│   ├── wifi-log.txt                  # Success/action log
│   └── wifi-toast-error.txt          # Notification errors
└── README.md
```

## Usage

### Via AutoHotkey Tray Menu

1. Run `togglewifi.ahk` (right-click the `.ahk` file → "Run with AutoHotkey")
2. A WiFi icon appears in your system tray
3. **Left-click menu:**
   - **Refresh WiFi** — Clear cache and reconnect
   - **Flush DNS Only** — Just clear DNS cache
   - **View Logs** — Open the log file in Notepad
   - **Open Telemetry Folder** — View all logs
   - **Notifications** — Toggle toast alerts on/off
   - **Build Notification Helper** — (Legacy) Compile C# helper
   - **Exit** — Close the utility

4. **Double-click tray icon** — Quick refresh (default action)

### Hotkeys

- **`F9`** — Refresh WiFi (disconnect/reconnect)
- **`F10`** — Flush DNS cache only

(Edit `togglewifi.ahk` to customize these)

### Via PowerShell (Manual)

Run the script directly:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "path/to/wifi-refresh.ps1"
```

## Configuration

### Toggle Notifications

Edit `Scripts/notification-enabled.ini`:
```ini
[Settings]
Enabled=1   # 1 = on, 0 = off
```

Or use the AHK tray menu: **Notifications** → toggle on/off

### Custom WiFi Icon

Replace `Scripts/wifi.png` with your own 16×16 or 32×32 PNG icon.

## Troubleshooting

### Notifications Not Showing

**Check 1: Is BurntToast installed?**
```powershell
Get-Module -ListAvailable -Name BurntToast
```

**Check 2: Are toasts enabled in Settings?**
Go to `Settings → System → Notifications & actions` and verify notifications are on.

**Check 3: Is Focus Assist blocking them?**
`Settings → System → Focus assist` — set to **Off** while testing.

**Check 4: Are you running as Admin?**
Admin processes can't display toasts. Run PowerShell as a normal user:
```powershell
Import-Module BurntToast
New-BurntToastNotification -Text "Test", "Can you see me?"
```

If the toast appears, your system is fine. If not, see the "Windows Toast System Broken?" section below.

### WiFi Won't Reconnect

**Check the logs:**
```powershell
notepad "Scripts/Telemetry/wifi-log.txt"
```

Common issues:
- SSID doesn't match your actual network name (check with `netsh wlan show interfaces`)
- Your WiFi adapter isn't recognized (run as admin)
- The script lacks permissions (ensure AutoHotkey runs elevated)

### Windows Toast System Broken?

If even native Windows notifications don't work:

1. **Check the notification service:**
   ```powershell
   Get-Service -Name "WpnService" | Select-Object Status, StartType
   ```
   Should show `Running` and `Automatic`.

2. **Repair notification packages:**
   ```powershell
   Get-AppxPackage -Name "Microsoft.Windows.ShellExperienceHost" | Remove-AppxPackage
   Add-AppxPackage -RegisterByFamilyName -MainPackage "Microsoft.Windows.ShellExperienceHost_cw5n1h2txyewy"
   ```

3. **As a last resort, repair Windows:**
   ```powershell
   DISM /Online /Cleanup-Image /RestoreHealth
   ```

## Logging

All actions are logged automatically:

- **`wifi-log.txt`** — Successful connections, script runs, actions taken
- **`wifi-toast-error.txt`** — Notification errors, debug info

View logs via the tray menu or manually:
```powershell
notepad "Scripts/Telemetry/wifi-log.txt"
```

## Architecture

### How It Works

1. **AutoHotkey launcher** (`togglewifi.ahk`)
   - Manages system tray menu
   - Spawns PowerShell scripts on user action
   - Toggles notification config file

2. **PowerShell core** (`wifi-refresh.ps1`)
   - Detects current SSID
   - Flushes DNS cache (`Clear-DnsClientCache`)
   - Clears ARP table (`netsh interface ip delete arpcache`)
   - Disconnects and reconnects WiFi (`netsh wlan disconnect/connect`)
   - Calls BurntToast to display toast notification
   - Logs all actions and errors

3. **BurntToast module**
   - PowerShell wrapper for Windows toast notifications
   - Handles AUMID registration internally (no COM interop needed)
   - Auto-installs on first run

### Legacy: C# Toast Helper

The repo includes `ToastNotificationHelper.csproj` and `toastnotificationhelper.cs` for reference, but it's **no longer used**. The original C# helper had a bug: `WScript.Shell` doesn't expose the `AppUserModelID` property, so AUMID registration silently failed and toasts were dropped.

BurntToast fixes this by handling registration internally. If you want to use the C# helper anyway, compile it and modify `wifi-refresh.ps1` to call it instead of BurntToast.

## Performance

- **Initial run:** ~5 seconds (BurntToast module download if not cached)
- **Subsequent runs:** ~2-3 seconds (WiFi reconnect only)
- **Memory footprint:** ~50 MB (AutoHotkey process)

## Security Notes

- Requires **administrator privileges** to modify network settings
- Scripts run locally; no data is sent anywhere
- Log files contain WiFi SSIDs (keep `Telemetry/` folder private if on shared machines)
- Consider running as a scheduled task under a dedicated account if deploying to managed systems

## Contributing & Issues

Found a bug? Have a feature request?

- Check the **logs** first (`Telemetry/wifi-toast-error.txt`, `wifi-log.txt`)
- Run troubleshooting steps in the "Troubleshooting" section above
- Open an issue with:
  - Your Windows version (`[System.Environment]::OSVersion.Version`)
  - The exact error message
  - Relevant log entries

## License

MIT License — Feel free to use, modify, and distribute.

## Acknowledgments

- [BurntToast](https://github.com/Windos/BurntToast) — PowerShell toast notification module
- Windows `netsh` — Network shell utilities
- AutoHotkey v1.1 — Script launcher

---

**Questions? Issues?** Open a GitHub issue and include your logs.