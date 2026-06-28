# Changelog

All notable changes to TelemetrySlayer will be documented in this file.

## [v1.2.0] - 2026-06-28

- Added exact Undo snapshots under `%ProgramData%\TelemetrySlayer\State`.
- Restored registry values/types/absence, service startup/status, exact scheduled-task state, firewall baselines, IFEO, and autologger settings from the latest apply snapshot.
- Replaced service cmdlets with timeout-safe `sc.exe` control, retry/backoff, exit-code logging, and visible failures.
- Added static Pester safety coverage for parser validity, exact task-path use, restore snapshots, and service-control guardrails.

## [v1.1.0] - 2026-06-27

- Added: Add project icon to README
- Added: Add screenshot to README
- v1.1.0 - Pre-scan status, undo support, Nvidia/Edge/VS telemetry categories
- Initial commit - TelemetrySlayer
