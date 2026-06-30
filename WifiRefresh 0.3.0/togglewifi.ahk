; --- WiFi Refresh Tray App ---
; Portable tray utility with menu + hotkeys
; Calls PowerShell backend script for actions

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

; Tray icon and tooltip
Menu, Tray, Icon, %A_ScriptDir%\Scripts\wifi.png

; Notification toggle state file
notificationIniFile := A_ScriptDir "\Scripts\notification-enabled.ini"
IfNotExist, %notificationIniFile%
{
    FileAppend, [Settings]`nEnabled=1`n, %notificationIniFile%
}
IniRead, notificationEnabled, %notificationIniFile%, Settings, Enabled, 1
if (notificationEnabled = "")
    notificationEnabled := 1
if (notificationEnabled = 1)
{
    MenuTip := "WiFi Refresh Utility"
}
else
{
    MenuTip := "WiFi Refresh Utility (Notifications Off)"
}
Menu, Tray, Tip, %MenuTip%

; Menu items
Menu, Tray, Add, Refresh WiFi, RefreshWiFi
Menu, Tray, Add, Flush DNS Only, FlushDNS
Menu, Tray, Add, View Logs, ViewLogs
Menu, Tray, Add, Open Telemetry Folder, OpenTelemetry
Menu, Tray, Add, Notifications, ToggleNotifications
Menu, Tray, Add, Build Notification Helper, BuildHelper
Menu, Tray, Add
Menu, Tray, Add, Exit, ExitApp

if (notificationEnabled = 1)
    Menu, Tray, Check, Notifications
else
    Menu, Tray, Uncheck, Notifications

; Default action (double‑click tray icon)
Menu, Tray, Default, Refresh WiFi

; Hotkeys
F9::Gosub RefreshWiFi
F10::Gosub FlushDNS

; --- Actions ---
RefreshWiFi:
    Run, PowerShell -NoProfile -ExecutionPolicy Bypass -File "%A_ScriptDir%\Scripts\wifi-refresh.ps1",, Hide
return

BuildHelper:
    Run, PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Set-Location -Path '%A_ScriptDir%\Scripts'; dotnet publish ToastNotificationHelper.csproj -c Release -o publish",, Hide
return

ToggleNotifications:
    IniRead, currentState, %notificationIniFile%, Settings, Enabled, 1
    if (currentState = "1")
    {
        newState := 0
        Menu, Tray, Uncheck, Notifications
        Menu, Tray, Tip, WiFi Refresh Utility (Notifications Off)
    }
    else
    {
        newState := 1
        Menu, Tray, Check, Notifications
        Menu, Tray, Tip, WiFi Refresh Utility
    }
    IniWrite, %newState%, %notificationIniFile%, Settings, Enabled
return

FlushDNS:
    Run, PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Clear-DnsClientCache"
return

ViewLogs:
    Run, notepad "%A_ScriptDir%\Scripts\Telemetry\wifi-log.txt"
return

OpenTelemetry:
    Run, explorer "%A_ScriptDir%\Scripts\Telemetry"
return

ExitApp:
    ExitApp
