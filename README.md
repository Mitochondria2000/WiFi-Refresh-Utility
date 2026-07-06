# WiFi Refresh Utility

WiFi Refresh Utility is a portable Windows helper for refreshing a wireless connection from the system tray or a hotkey. The current workflow clears the DNS cache, clears the ARP cache, disconnects from the active Wi-Fi network, reconnects to the same SSID, and optionally shows a toast notification.

## What is in this repository

- [WiFi Refresh Utility.exe](WiFi%20Refresh%20Utility.exe) — prebuilt tray launcher with menu items and hotkeys
- [scripts/wifi-refresh.ps1](scripts/wifi-refresh.ps1) — full refresh workflow for Wi-Fi and DNS
- [scripts/flush-dns.ps1](scripts/flush-dns.ps1) — DNS-only cleanup action
- [scripts/notification-enabled.ini](scripts/notification-enabled.ini) — persisted notification preference
- [scripts/Telemetry](scripts/Telemetry) — runtime log folder created automatically

## Features

- Tray menu access with a single-click refresh action
- Hotkeys: F9 for a full Wi-Fi refresh and F10 for a DNS-only flush
- Separate DNS-only workflow via its own PowerShell script
- Notification toggle from the tray menu or the INI file
- Automatic log creation for actions and failures in the Telemetry folder
- Portable design: no installation step is required beyond PowerShell dependencies

## Requirements

- Windows 10 or later
- PowerShell 5.0 or newer
- Administrator privileges are recommended for the Wi-Fi and DNS operations
- BurntToast is used for toast notifications and is installed automatically on first use when possible

## Installation Guide

### Download from Releases

1. Open the GitHub Releases page for this repository.
2. Download the latest release package or executable.
3. Extract the files if needed, then run [WiFi Refresh Utility.exe](WiFi%20Refresh%20Utility.exe) from Explorer.
4. If prompted, allow PowerShell to install the BurntToast module.
5. Use the tray menu or hotkeys to refresh the connection.

### Manual PowerShell usage

You can also invoke the scripts directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "path/to/scripts/wifi-refresh.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "path/to/scripts/flush-dns.ps1"
```

## Configuration

### Notification toggle

The notification preference is stored in [scripts/notification-enabled.ini](scripts/notification-enabled.ini):

```ini
[Settings]
Enabled=1
```

Set `Enabled=0` to disable toasts, or toggle the option from the tray menu.

### Custom icon

Replace [scripts/wifi.png](scripts/wifi.png) with your own icon if you want a different tray appearance.

## Logging

The scripts write telemetry data to [scripts/Telemetry](scripts/Telemetry):

- [scripts/Telemetry/wifi-log.txt](scripts/Telemetry/wifi-log.txt) — successful actions and script runs
- [scripts/Telemetry/wifi-toast-error.txt](scripts/Telemetry/wifi-toast-error.txt) — notification and execution errors

The tray menu also includes shortcuts to open these files and the Telemetry folder directly.

## Troubleshooting

- Check the logs in [scripts/Telemetry](scripts/Telemetry) first.
- Make sure BurntToast is available with:

```powershell
Get-Module -ListAvailable -Name BurntToast
```

- Verify that Windows notifications are enabled if toasts do not appear.
- If the Wi-Fi reconnect step fails, confirm that the active SSID matches the name reported by Windows and that the script is running with enough privileges.

## Architecture

The repository is intentionally simple:

1. [WiFi Refresh Utility.exe](WiFi%20Refresh%20Utility.exe) provides the main tray experience for most users.
2. [scripts/wifi-refresh.ps1](scripts/wifi-refresh.ps1) performs the network refresh workflow.
3. [scripts/flush-dns.ps1](scripts/flush-dns.ps1) performs a DNS-only action for lighter troubleshooting.
4. Both PowerShell scripts use BurntToast when available and log failures to the Telemetry folder.

## License

This project is distributed under the MIT License.
