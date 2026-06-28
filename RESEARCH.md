# Research - TelemetrySlayer

## Executive Summary
TelemetrySlayer is a single-file PowerShell 5.1 WPF tool for disabling Windows telemetry services, scheduled tasks, registry policies, firewall paths, and vendor-specific telemetry with async execution, status scan indicators, and broad undo. Its strongest current shape is transparency: every toggle maps to concrete Windows objects and the GUI already exposes granular control. Highest-value direction: make every destructive change testable, reversible to the exact prior state, build/SKU-aware, and deployable for IT use without losing the single-file trust model. Top opportunities: state-based undo, service/task execution hardening, preflight backups, Pester-based mocked tests, SKU/build gating, current Microsoft policy coverage, durable logs, RMM/silent mode, accessibility pass, and documentation/version repair.

## Product Map
- Core workflows: launch elevated GUI, scan current system state, select telemetry toggles, apply async hardening, review live log, undo changes.
- User personas: privacy-focused Windows power users; small MSP/RMM operators; IT admins hardening unmanaged endpoints; advanced users troubleshooting CompatTelRunner, DiagTrack, Office, Edge, Nvidia, or Visual Studio telemetry.
- Platforms and distribution: Windows 10/11 with PowerShell 5.1 and WPF; currently raw `.ps1` via download or `irm ... | iex`; no packaged EXE/MSIX/winget release yet.
- Key integrations and data flows: Windows services, Task Scheduler, registry policy hives, Windows Firewall, IFEO, WMI autologger ETL, `gpupdate.exe`, Office/Edge/Nvidia/Visual Studio policy keys.

## Competitive Landscape
- Raphire/Win11Debloat does modern Windows 10/11 debloat with presets, registry backup, logs, app removal, and 24H2/25H2 AI/Copilot/Recall coverage. Learn from its config/preset model and backup-before-apply flow; avoid broad debloat/app-removal scope and restore-point failures on unsupported SKUs.
- ChrisTitusTech/winutil does a large WPF tweak surface with JSON automation, links per tweak, and advanced categories. Learn from JSON-driven tweak definitions and automation mode; avoid network/search-breaking bundled presets and UI hangs during automated runs.
- Sophia Script is a large PowerShell module with parameterized enable/disable functions, transcript logging, restore-point support, SKU checks, and Local Group Policy scanning. Learn from per-function `Disable`/`Enable` parity and policy visibility; avoid its complexity and interactive dialog sprawl.
- Privatezilla/Bloatynosy focus on privacy checking and clear pass/fail status rather than only applying changes. Learn from test-first privacy assertions; avoid abandoned or opaque rule sets.
- O&O ShutUp10++ is the commercial UX baseline: recommendation tiers, portable config export, and conservative privacy framing. Learn from recommendation severity and export/import; avoid closed-source unverifiability.
- W4RH4WK/Debloat-Windows-10 is the canonical script reference for hosts/firewall/task telemetry blocking. Learn from granular scripts and caveat comments for breakage-prone domains; avoid stale endpoint lists and hosts entries that break Store, NCSI, Skype, DRM, or Defender cloud protection.
- privacy.sexy and winscript are adjacent script builders. Learn from generated auditable scripts and category filtering; avoid turning TelemetrySlayer into a broad generic system tweaker.
- WindowsSpyBlocker/pihole-style blocklists prove network validation value. Learn from before/after DNS evidence; avoid hardcoding broad host/IP blocks without user-visible risk labels.

## Security, Privacy, and Reliability
- `TelemetrySlayer.ps1:728` and `TelemetrySlayer.ps1:1091` use `Stop-Service`/`Set-Service`, which conflicts with the PowerShell stack convention to avoid service cmdlets in silent automation because they can block or surface unmanaged progress UI.
- `TelemetrySlayer.ps1:714` writes registry values without capturing prior value/type/absence, while `TelemetrySlayer.ps1:1075` deletes values during undo. Undo is not a true restore and can erase pre-existing admin policy.
- `TelemetrySlayer.ps1:736` and `TelemetrySlayer.ps1:1097` find scheduled tasks primarily by task name. Duplicate task names across paths or vendor task variants need exact `TaskPath` capture in both apply and undo.
- `TelemetrySlayer.ps1:746` creates firewall rules but there is no preflight/validation that target executables exist, rules were added, or traffic is actually blocked.
- `TelemetrySlayer.ps1:970` relies on Edge `MetricsReportingEnabled`; Microsoft Edge docs now mark that policy obsolete, so current Edge coverage needs a policy refresh.
- `TelemetrySlayer.ps1:795` sets `AllowTelemetry=0` unconditionally. Microsoft and Sophia Script behavior indicate edition-specific handling is needed because "off/security" semantics differ by Windows SKU.
- `README.md:5`, `TelemetrySlayer.ps1:2`, and `CLAUDE.md:4` disagree on version (`1.0.1` vs `1.1.0`); `CHANGELOG.md:5` has a corrupted date token. Trust-sensitive tools need synchronized version/docs.
- Missing guardrails: no restore point or registry snapshot, no exact rollback bundle, no transcript/crash log file, no dry-run/preview execution, no blocked-endpoint validation, no high-contrast/a11y verification, no tests.

## Architecture Assessment
- `TelemetrySlayer.ps1` should move from checkbox-specific imperative blocks toward a data manifest of actions with `Test`, `Apply`, `Verify`, and `Undo` definitions while preserving single-file delivery.
- The scan worker, apply worker, and undo worker currently duplicate embedded helper functions; shared in-file helpers would reduce drift without changing distribution.
- Add Pester tests with mocked registry/service/task/firewall cmdlets. The parser check passed locally with `[System.Management.Automation.Language.Parser]::ParseFile`, but there are no behavioral tests.
- Add a `-Silent`, `-Preset`, `-Config`, `-WhatIf`, and `-LogPath` command surface for RMM while leaving the WPF GUI as the default.
- Add an internal policy catalog with build/SKU/app-presence gates: Windows 10 22H2, Windows 11 23H2/24H2/25H2, LTSC 2024, Server 2022/2025, Home/Pro/Enterprise/Education.
- Keep i18n/l10n conservative: use invariant internal action IDs, ASCII-safe logs, localized Windows output capture, and avoid icon fonts that render inconsistently across Windows 10/11.
- Documentation gaps: README still claims the GUI can be adapted for silent mode instead of shipping it, and version/changelog badges are stale.

## Rejected Ideas
- Broad Windows debloat/app removal from Win11Debloat/winutil: rejected because TelemetrySlayer's narrower trust promise is telemetry/privacy hardening, not app cleanup.
- Hosts-file mass blocking from W4RH4WK/Debloat-Windows-10: rejected as a default because documented caveats include Windows Update, Store, NCSI, DRM, Skype, and Defender cloud side effects; keep as an opt-in export only.
- WMI class deletion/MOF tampering from older debloaters: rejected because persistence gains do not justify Secure Boot, servicing, and recovery risk.
- Disabling Defender or SmartScreen by default: rejected because the README explicitly avoids weakening core security controls.
- Full C# rewrite now: rejected because the single-file PowerShell GUI is the project's stated distribution advantage; refactor in place first.
- Packaged PS2EXE-only distribution: rejected as the only channel because PS2EXE can trigger Defender/script-wrapper suspicion; keep raw signed PS1 plus packaged builds.
- Public plugin ecosystem: rejected for now because the trust model depends on auditable built-in actions; use an internal action catalog before allowing third-party rule packs.
- Mobile app or remote multi-user dashboard: rejected because all meaningful operations require local Windows administrator access; RMM/silent mode covers fleet execution without adding a server.

## Sources
### OSS Competitors
- https://github.com/Raphire/Win11Debloat
- https://github.com/ChrisTitusTech/winutil
- https://github.com/farag2/Sophia-Script-for-Windows
- https://github.com/builtbybel/privatezilla
- https://github.com/builtbybel/Bloatynosy
- https://github.com/W4RH4WK/Debloat-Windows-10
- https://github.com/undergroundwires/privacy.sexy
- https://github.com/flick9000/winscript
- https://github.com/crazy-max/WindowsSpyBlocker
- https://github.com/TemporalAgent7/awesome-windows-privacy

### Commercial and Platform Docs
- https://www.oo-software.com/en/shutup10
- https://wpd.app/
- https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services
- https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowsai
- https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/diagnosticdata
- https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/metricsreportingenabled
- https://techcommunity.microsoft.com/blog/microsoft-security-baselines/lgpo-exe---local-group-policy-object-utility-v1-0/701045

### Community Signals
- https://github.com/Raphire/Win11Debloat/issues/675
- https://github.com/Raphire/Win11Debloat/issues/560
- https://github.com/Raphire/Win11Debloat/issues/384
- https://github.com/ChrisTitusTech/winutil/issues/4710
- https://github.com/ChrisTitusTech/winutil/issues/4376
- https://github.com/ChrisTitusTech/winutil/issues/4389
- https://github.com/ChrisTitusTech/winutil/issues/2541
- https://github.com/ChrisTitusTech/winutil/issues/4360

## Open Questions
- Which Windows SKUs should be first-class support targets for acceptance testing: Home/Pro only, or Enterprise/Education/LTSC/Server as well?
- Should packaged releases require Authenticode signing before any EXE/MSIX/winget work ships, or is signed PS1 plus checksum acceptable for the first distribution pass?
