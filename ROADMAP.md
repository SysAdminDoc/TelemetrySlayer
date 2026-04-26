# Roadmap

Forward-looking plans for TelemetrySlayer — a single-file PowerShell WPF tool that disables Windows telemetry/data-collection and hardens the policies against Windows Update re-enablement.

## Planned Features

### Detection & Coverage
- Per-Windows-build profile system (22H2 / 23H2 / 24H2 / 25H2 / Server 2022/2025 / LTSC 2024) with version-gated toggles
- Microsoft 365 / Office telemetry (`OfficeTelemetryAgent`, Office Diagnostic Data) as a dedicated category
- Edge + Edge WebView2 telemetry registry keys (`MetricsReportingEnabled`, `UserFeedbackAllowed`, Copilot-on-Edge)
- Copilot / Recall / AI Explorer toggles — 24H2+ surfaces several new registry paths; track them explicitly
- Network hardening: LLMNR, NetBIOS, WPAD, mDNS, SSDP disable toggles (audit before killing — clinic environments need mDNS)

### Policy Persistence
- "Survives Windows Update" regression suite — snapshot every applied key, re-run audit after a cumulative update, diff
- GPO mode: export equivalent ADMX-based policy bundle so IT can push via AD/Intune
- Scheduled re-apply task (weekly) that silently re-asserts the expected state and emails a report
- Rollback bundle — every apply writes a paired `.reg` restore file keyed by timestamp

### UX
- Grouped categories (Services, Tasks, Registry, WMI, Firewall) with impact badges (Critical / High / Medium / Low)
- Live preview of the exact commands that will run before Apply
- "Paranoid / Balanced / Minimal" presets so non-experts pick one button
- Rich search across every toggle (name, description, registry path, service name)
- Transcript viewer tab (live + history of past runs)

### Distribution
- PS2EXE + Authenticode-signed release with VirusTotal clean report badge
- Winget + Chocolatey manifests
- MSIX sideload option for locked-down endpoints

## Competitive Research

- **O&O ShutUp10++**: the gold standard — hundreds of toggles, recommended presets, profile export. Borrow their color-coded recommendation tiers.
- **WPD (Windows Privacy Dashboard)**: Russian-authored, feature-rich, but opaque. Our audit-log transparency (every change recorded, restorable) is the differentiator.
- **DoNotSpy / Debotnet / Privatezilla**: each covers a subset. None of them survive 24H2's re-enablement passes well — that's the TelemetrySlayer pitch.
- **Microsoft Diagnostic Data Viewer**: the official "what is being sent" tool. Ship a companion button that launches it so users can verify.

## Nice-to-Haves

- Cloud-free Recall killswitch with post-check (confirms `Start-Service WPNUSERSERVICE` doesn't spawn a Recall child)
- Event Viewer filter preset that highlights telemetry-related events for forensics
- `winget settings` + `DoSvc` BITS-over-metered toggles
- Integration with pi-hole / NextDNS — export the Microsoft-telemetry hostnames as a blocklist
- Side-by-side "before / after" network capture (pktmon) to prove traffic reduction
- Portable USB "deploy to 50 PCs" companion that runs unattended with a signed config

## Open-Source Research (Round 2)

### Related OSS Projects
- https://github.com/builtbybel/privatezilla — Windows 10/11 privacy + debloat with scriptable tests
- https://github.com/W4RH4WK/Debloat-Windows-10 — canonical `block-telemetry.ps1` reference
- https://github.com/mirinsoft/spydish — telemetry state verifier (cross-check tool results)
- https://github.com/bitlogik/HushWin — one-shot shell disable, GPL-3.0
- https://github.com/adolfintel/Windows10-Privacy — comprehensive guide + scripts
- https://github.com/Sycnex/Windows10Debloater — popular all-in-one debloat script
- https://github.com/Raphire/Win11Debloat — modern Win11-focused, GUI + silent modes
- https://github.com/TemporalAgent7/awesome-windows-privacy — curated list for cross-referencing
- https://github.com/W4RH4WK/Debloat-Windows-10/tree/master/scripts — granular script decomposition pattern
- https://github.com/teknologist/bitwarden — nope, skip. Use this instead: https://github.com/ChrisTitusTech/winutil — ChrisTitusTech's winutil patterns

### Features to Borrow
- Scriptable "test" definitions (privatezilla) — each privacy setting has a `Test-` function that returns current state, enabling before/after verification
- Cross-tool verification: re-run spydish-style assertions after TelemetrySlayer runs to prove hardening stuck
- Granular script decomposition: `block-telemetry.ps1`, `disable-services.ps1`, `block-hosts.ps1` (W4RH4WK pattern) — enables partial runs
- Reversibility: every action emits a matching undo script to a per-run folder (Win10-Initial-Setup-Script pattern)
- Hosts-file + firewall blocklist of Microsoft telemetry FQDNs as a separate exportable artifact (HushWin)
- "Appraiser.dll" DiagTrack forensic toggles — deep registry keys beyond the usual group policies (privatezilla)
- WinGet-compatible package list for the debloat inverse (reinstall on rollback) (ChrisTitusTech/winutil)
- CI job that boots a Windows VM, runs the script, then `spydish`-style assertion to prove CI coverage
- GPO ADMX template export so domain admins can deploy via Group Policy (privatezilla)
- Settings-drift detector: scheduled task that re-asserts hardening after Windows Update (W4RH4WK)

### Patterns & Architectures Worth Studying
- Test-Do-Verify triad: each hardening step is `Test-Setting`, `Set-Setting`, `Test-Setting` (idempotent, observable)
- Per-feature `.ps1` modules discovered dynamically — GUI lists available modules from `modules/` folder
- Dual delivery: standalone portable PS1 + MSI that registers a scheduled task for drift-correction
- Export/import "config profile" — JSON of desired state that survives reinstalls
- pktmon before/after capture as shippable evidence (already in roadmap; proven pattern in privatezilla audits)

## Implementation Deep Dive (Round 3)

### Reference Implementations to Study
- **W4RH4WK/Debloat-Windows-10** — https://github.com/W4RH4WK/Debloat-Windows-10 — the historical reference PowerShell debloater; its per-service/task/registry list format is the pattern to mirror for the toggle grid
- **ChrisTitusTech/winutil** — https://github.com/ChrisTitusTech/winutil — the current most-watched Windows tweak tool; copy the category grouping + preset system ("Standard/Minimal/Paranoid") idiom
- **Raphire/Win11Debloat** — https://github.com/Raphire/Win11Debloat — modern Win11 24H2/25H2 coverage including Copilot/Recall keys; concrete registry paths to port (`HKLM\Software\Policies\Microsoft\Windows\WindowsAI`)
- **Microsoft Learn — WindowsAI Policy CSP** — https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowsai — authoritative reference for the Recall/Copilot policy keys; the ADMX-equivalent for the GPO export mode
- **phinit.de — Windows 11 Disable Copilot, Recall & AI via GPO** — https://phinit.de/en/2026/01/03/windows-11-disable-copilot-recall-ai-via-gpo — "belt-and-braces" machine+user scope strategy including Edge v141+ Copilot sidebar keys
- **O&O ShutUp10++ reg export format** — https://www.oo-software.com/en/shutup10 — closed source but its `.cfg` export pattern is worth emulating for portable presets
- **dsccommunity/PolicyFileEditor** — https://github.com/dsccommunity/PolicyFileEditor — Lithnet's registry.pol reader; wire this in for emitting Local Group Policy files (not just HKLM keys) so Gpedit reflects the settings
- **StartAllBack / ExplorerPatcher issue trackers** — https://github.com/valinet/ExplorerPatcher/issues — community-maintained record of which cumulative updates flip which registry values; reference for the "regression suite" task

### Known Pitfalls from Similar Projects
- **24H2 Copilot auto-reinstalls** — https://learn.microsoft.com/en-us/answers/questions/2237635/remove-copilot-form-windows-11-24h2 — policy alone doesn't stop reinstall on some SKUs; pair with AppLocker/SRP rule targeting `ms-copilot:` URI and `Microsoft.Copilot_*` package
- **GPO "Turn off Windows Copilot" only hides the taskbar button** — phinit.de writeup — does not block the app; STIG hardening requires AppLocker too
- **Machine vs user scope confusion** — Microsoft Learn WindowsAI CSP — Recall DLP policies only honor machine-scope on Enterprise/Education SKUs; must detect SKU and warn on Pro/Home
- **ADMX drift** — phinit.de — stale SYSVOL PolicyDefinitions hide new 24H2 settings; ship the latest ADMX with the tool and offer to copy to Central Store
- **Edge 141+ sidebar policy split** — same source — "Show or hide side panel" no longer controls the Copilot icon alone; needs the new per-icon policy
- **WMI class deletion persistence** — common in debloaters — removing `MSFT_MpPreference` etc. requires `mofcomp` after CU, and unsigned MOF changes can fail Secure Boot policy audit
- **Scheduled-Task re-enablement** — https://github.com/ChrisTitusTech/winutil/issues — `Microsoft\Windows\Feedback\Siuf\DmClient` etc. reappear after CU; the roadmap's weekly re-apply task must also delete, not just disable
- **PS2EXE + Defender** — https://github.com/MScholtes/PS2EXE — PS2EXE outputs commonly flagged by Defender's `VirTool:Win32/ScriptWrapper`; submit to MS via Partner Center before public release

### Library Integration Checklist
- **PowerShell 5.1 target** (WPF `Add-Type -AssemblyName PresentationFramework`) — single-file ps1 is the constraint; gotcha: 5.1 default encoding is UTF-16LE BOM — sources must force `[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)` for ASCII-only logs per user's PowerShell stack rules
- **PresentationFramework.Aero2** — Windows 11 visual style compatibility; gotcha: dark theme for WPF 5.1 requires manual ControlTemplate override (see stack-powershell.md) — no built-in dark theme
- **Microsoft.Win32.TaskScheduler 2.11** (if porting parts to C#) — for scheduled re-apply task; pure PS can use `Register-ScheduledTask -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 03:00)` without deps
- **PSReflect** (inline module) — for accessing WMI ROOT\SecurityCenter2 classes not exposed via `Get-CimInstance`; gotcha: some `MSFT_MpPreference` props are set-only
- **LGPO.exe** from Microsoft Security Compliance Toolkit — for reading/writing `registry.pol` directly (Local Group Policy); gotcha: LGPO parses CSV, not JSON — emit both
- **PolicyFileEditor PowerShell module** — cross-check alternative to LGPO.exe for the GPO export mode; safer than bundling a Microsoft EXE
- **PSScriptAnalyzer 1.23** — CI lint; gotcha: rule `PSAvoidUsingWriteHost` will flag the live log panel — disable per-file, not project-wide
- **PS2EXE 0.5.0.30** — for the EXE build; pass `-iconFile assets\slayer.ico -title "TelemetrySlayer" -product "TelemetrySlayer" -version "X.Y.Z.0"`; gotcha: WPF apps need `-noConsole` or a stray console window flashes at launch
- **signtool** + Authenticode — follow the CI/CD Standard in CLAUDE.md; add VirusTotal badge auto-refresh in README on each release
- **winget manifest 1.6** + Chocolatey `chocolateyInstall.ps1` — same package shape used in MavenWinUtil; keep manifest schema pinned

