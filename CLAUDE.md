# CLAUDE.md - TelemetrySlayer

## Overview
WPF GUI for disabling Windows telemetry, data collection, and compatibility bloat. Categorized checkboxes with async execution, real-time log output, pre-scan status indicators, and undo support. v1.1.0.

## Tech Stack
- PowerShell 5.1, WPF GUI
- GitHub Dark theme (#0d1117)
- Async via `[PowerShell]::Create()` + `BeginInvoke()` with `DispatcherTimer` (100ms poll)
- Console hidden via P/Invoke

## Key Details
- Single-file (~900 lines)
- Categories: Services, Scheduled Tasks, Registry/Policy, Firewall/Hardening, Office Telemetry, Nvidia Telemetry, Edge Telemetry, Visual Studio Telemetry
- Pre-scan on launch: colored ON/OFF/N/A indicators next to each checkbox showing current system state
- Undo All button: reverses all changes (re-enables services/tasks, removes firewall rules/IFEO/registry policies)
- Status bar: shows selected count and applied count after scan
- Services: DiagTrack, dmwappushservice, WerSvc, PcaSvc, diagsvc, DPS, NvTelemetryContainer, VSStandardCollectorService150
- IFEO debugger redirect for CompatTelRunner.exe
- Office 15.0/16.0 telemetry agent suppression
- Nvidia: NvTelemetryContainer service, NvTmMon/NvTmRep/NvProfileUpdater tasks, registry keys
- Edge: DiagnosticData, PersonalizationReportingEnabled, MetricsReportingEnabled, SendSiteInfoToImproveServices
- Visual Studio: Telemetry OptIn, PerfWatson2, VSStandardCollectorService150, feedback policies

## Build/Run
```powershell
.\TelemetrySlayer.ps1
```

## Version
1.1.0

## Gotchas
- No emoji/unicode in PowerShell (encoding errors) - status indicators use plain text ON/OFF/N/A
- Scan runs async in background runspace, results delivered via ConcurrentQueue
- Nvidia task names include GUID suffix: {B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}
