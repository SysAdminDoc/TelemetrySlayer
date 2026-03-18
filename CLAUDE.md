# CLAUDE.md - TelemetrySlayer

## Overview
WPF GUI for disabling Windows telemetry, data collection, and compatibility bloat. Categorized checkboxes with async execution and real-time log output. v1.0.1.

## Tech Stack
- PowerShell 5.1, WPF GUI
- GitHub Dark theme (#0d1117)
- Async via `[PowerShell]::Create()` + `BeginInvoke()` with `DispatcherTimer` (100ms poll)
- Console hidden via P/Invoke

## Key Details
- ~572 lines, single-file
- Categories: Services, Scheduled Tasks, Registry/Policy, Firewall/Hardening, Office Telemetry
- Services: DiagTrack, dmwappushservice, WerSvc, PcaSvc, diagsvc, DPS
- IFEO debugger redirect for CompatTelRunner.exe
- Office 15.0/16.0 telemetry agent suppression

## Build/Run
```powershell
.\TelemetrySlayer.ps1
```

## Version
1.0.1
