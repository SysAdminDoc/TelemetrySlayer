# Research - TelemetrySlayer

## Executive Summary
TelemetrySlayer is a single-file PowerShell 5.1 WPF privacy hardening tool for Windows 10/11 that disables telemetry services, scheduled tasks, registry policies, firewall paths, Office/Nvidia/Edge/Visual Studio telemetry, and restores exact pre-apply state from `%ProgramData%\TelemetrySlayer`. Its strongest current shape is trust through visible, granular Windows-object changes plus recent exact undo, recovery bundle, SKU-aware diagnostic data, and mocked catalog coverage. Highest-value direction: make the action catalog the runtime source of truth, prove every apply with a persistent verification ledger, detect domain/MDM policy ownership, update stale policy coverage, harden the download/release trust path, and finish the existing logging, RMM, accessibility, network-validation, GPO/export, and packaging roadmap items.

Top opportunities in priority order:
- Make `Get-TelemetrySlayerActionCatalog` drive GUI scan/apply/verify/undo, not only mocked tests.
- Persist per-action Test/Apply/Verify results and summarize partial failures.
- Detect domain GPO/MDM ownership before writing local policy keys.
- Add a verify-before-run signed/checksummed download path instead of relying on `irm | iex`.
- Finish the existing Microsoft Edge/WebView2/WindowsAI policy refresh.
- Add policy provenance metadata for every toggle.
- Complete Visual Studio CEIP policy coverage.
- Add restore history browsing and retention controls.
- Add local Windows Sandbox/VM smoke testing for Apply/Undo.
- Prepare i18n by separating invariant action IDs from display/log strings, without translating yet.

## Product Map
- Core workflows: launch elevated WPF GUI; scan current service/task/registry/firewall state; select toggles; apply hardening asynchronously; review live log; undo from latest exact restore snapshot.
- User personas: Windows privacy power users; MSP/RMM operators; IT admins hardening unmanaged endpoints; technicians troubleshooting CompatTelRunner, DiagTrack, Office, Edge, Nvidia, or Visual Studio telemetry.
- Platforms and distribution: Windows 10/11, PowerShell 5.1, WPF/PresentationFramework, administrator rights; currently raw `.ps1` via README quick start or manual download, with packaged/signed distribution still planned.
- Key integrations and data flows: Windows services, Task Scheduler, registry policy hives, Windows Firewall, IFEO debugger, WMI autologger ETL, `gpupdate.exe`, Office/Edge/Nvidia/Visual Studio policy keys, `%ProgramData%\TelemetrySlayer\State`, `%ProgramData%\TelemetrySlayer\Backups`.

## Competitive Landscape
- Raphire/Win11Debloat: strong modern Windows 11 coverage, WhatIf support, GPO override warnings, timestamped backups, and recent runspace-error fixes. Learn from version-gated features and visible safety warnings; avoid broad app-removal scope.
- ChrisTitusTech/winutil: strong automation/config workflow and broad tweak catalog. Learn from JSON-driven RMM use and per-tweak discoverability; avoid preset/network changes that can break connectivity or hang automation.
- Sophia Script: deep PowerShell policy coverage, parameterized enable/disable symmetry, transcripts, restore points, and SKU checks. Learn from reversible function pairs and gpedit-visible policy handling; avoid interactive complexity and oversized surface area.
- O&O ShutUp10++: commercial UX baseline for recommended tiers, portable config export/import, and conservative privacy framing. Learn from clear risk/recommendation levels; avoid closed-source unverifiable rule logic.
- Privatezilla and privacy.sexy: strong privacy-check/test-first model and transparent generated scripts. Learn from auditable rule metadata and test/pass/fail presentation; avoid public third-party rule packs until TelemetrySlayer has a complete internal catalog executor.
- W4RH4WK/Debloat-Windows-10 and WindowsSpyBlocker: useful historical telemetry endpoint and script references. Learn from opt-in network proof/export patterns; avoid default hosts/IP blocking because community reports show breakage risk.
- Microsoft platform docs: the authoritative source for WindowsAI, diagnostic data, Edge, Office, and Visual Studio policy semantics. Treat Microsoft Learn as the acceptance oracle even when competitor scripts use older registry values.

## Security, Privacy, and Reliability
- [Verified] `README.md:18` promotes `irm ... | iex`; Microsoft PowerShell guidance says `Invoke-Expression` should be a last-resort pattern. Add a signed/checksummed verify-before-run path while keeping raw PS1 distribution.
- [Verified] `TelemetrySlayer.ps1:269-275`, `TelemetrySlayer.ps1:1002-1004`, and `TelemetrySlayer.ps1:1878-1885` still use Edge `MetricsReportingEnabled`; Microsoft marks that policy obsolete. The existing Edge/WebView2 roadmap item remains correct and should include legacy labeling.
- [Verified] `TelemetrySlayer.ps1:299-305` catalog dispatchers return mock objects, while `TelemetrySlayer.ps1:862-1010` and `TelemetrySlayer.ps1:1671-1890` run separate hard-coded scan/apply logic. Tests can pass while GUI behavior drifts.
- [Verified] `TelemetrySlayer.ps1:1919-1931` runs `gpupdate` and logs completion, then rescans, but does not persist a per-operation verification ledger or machine-readable result bundle.
- [Verified] `TelemetrySlayer.ps1:1546-1665` writes registry/firewall/service state locally with no domain join, MDM enrollment, `registry.pol`, or managed-policy ownership warning. Win11Debloat added a GPO override alert in its latest release for this failure mode.
- [Verified] `TelemetrySlayer.ps1:277-285` and `TelemetrySlayer.ps1:1892-1912` cover Visual Studio feedback and `TurnOffSwitch`, but not Microsoft-documented `HKLM:\Software\Policies\Microsoft\VisualStudio\SQM\OptIn=0`.
- [Verified] The current repo has no third-party runtime dependency manifest; supply-chain risk is low. Future Pester/PSScriptAnalyzer/PS2EXE/LGPO/PolicyFileEditor work should stay optional, pinned, and locally documented.
- [Likely] Existing roadmap items for durable transcript/support bundle, silent mode, accessibility, network validation, GPO/export, and signed packaging are still high-value; none are duplicated below.

## Architecture Assessment
- `TelemetrySlayer.ps1` should keep single-file delivery but make the action catalog include stable ID, display text, policy/source URL, supported OS/SKU/app gates, risk level, undo strategy, and Test/Apply/Verify/Undo executor metadata.
- The GUI scan worker, apply worker, undo worker, and Pester dispatch path should share one executor pipeline. Current duplicated blocks are the main root-cause maintenance risk.
- Test coverage is useful but narrow: `tests/TelemetrySlayer.Tests.ps1` validates catalog shape and mocked dispatch, and `tests/TelemetrySlayer.Static.Tests.ps1` validates parser/safety patterns; neither exercises elevated GUI runspace behavior or an Apply/Undo round trip on a disposable host.
- UI/accessibility gaps remain: no `AutomationProperties`, no high-contrast branch, color/status text is tightly coupled to fixed dark colors, and button/checkbox metadata is embedded in XAML instead of action metadata.
- Documentation gaps: README documents interactive GUI and RMM adaptation, but not a shipped silent command surface, signed/hash verification, source provenance per setting, or support-bundle/result-ledger locations.
- Upgrade strategy should be policy-catalog driven: Windows build/SKU gates, Edge policy obsolescence, WindowsAI/Recall changes, Office/Visual Studio policy drift, and WebView2 policy additions should be captured as data and verified by tests.
- Offline/resilience path should stay local-first: backups, restore history, result ledgers, signed/checksummed artifacts, and optional blocklist exports should work after download without a service dependency.

## Rejected Ideas
- Broad app removal/debloat from Win11Debloat, winutil, and winscript: rejected because TelemetrySlayer's trust promise is telemetry/privacy hardening, not app cleanup.
- Default hosts/IP blocklists from W4RH4WK and WindowsSpyBlocker: rejected as a default because connectivity failures are a recurring community complaint; keep blocklists opt-in and validation-focused.
- Public plugin ecosystem from privacy.sexy-style extensibility: rejected until the internal action catalog is a real audited execution engine.
- Full C#/Electron rewrite from adjacent Windows GUI tools: rejected because raw single-file PowerShell is the current deployment advantage.
- Disabling Defender or SmartScreen by default: rejected because README explicitly avoids weakening core security controls.
- Mobile app or remote multi-user dashboard: rejected because meaningful operations require local Windows administrator execution; RMM/silent mode covers fleet use better.
- Immediate full translation pack: rejected because PowerShell 5.1 encoding and WPF layout risk are higher than the value today; prepare i18n boundaries first.
- Forced PS2EXE-only delivery: rejected because PowerShell-script transparency is a trust advantage and packaged wrappers can create reputation/false-positive friction.
- Importing O&O, DoNotSpy, or winutil profiles now: rejected until TelemetrySlayer ships its own native JSON preset schema; avoid lossy migrations from closed or broader-scoped tools.

## Sources
### OSS Competitors and Analogous Projects
- https://github.com/Raphire/Win11Debloat
- https://github.com/Raphire/Win11Debloat/releases/tag/2026.06.24
- https://github.com/ChrisTitusTech/winutil
- https://github.com/farag2/Sophia-Script-for-Windows
- https://github.com/builtbybel/privatezilla
- https://github.com/W4RH4WK/Debloat-Windows-10
- https://github.com/undergroundwires/privacy.sexy
- https://github.com/TemporalAgent7/awesome-windows-privacy

### Commercial and Community Signals
- https://www.oo-software.com/en/shutup10
- https://wpd.app/
- https://pxc-coding.com/donotspy11/
- https://discuss.privacyguides.net/t/windows-11-privacy-and-security/12303
- https://github.com/Raphire/Win11Debloat/issues/61
- https://github.com/ChrisTitusTech/winutil/issues/4710
- https://github.com/ChrisTitusTech/winutil/issues/4376

### Standards, Platform Docs, and Field Notes
- https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowsai
- https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization
- https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-system
- https://learn.microsoft.com/en-us/deployedge/microsoft-edge-enterprise-privacy-settings
- https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/metricsreportingenabled
- https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/enterprise
- https://learn.microsoft.com/en-us/microsoft-365-apps/privacy/manage-privacy-controls
- https://learn.microsoft.com/en-us/previous-versions/office/office-2013-resource-kit/jj863580(v=office.15)
- https://learn.microsoft.com/en-us/visualstudio/ide/visual-studio-experience-improvement-program?view=vs-2022
- https://phinit.de/en/2026/01/03/windows-11-disable-copilot-recall-ai-via-gpo

### Tooling, Dependencies, and Security
- https://techcommunity.microsoft.com/blog/microsoft-security-baselines/lgpo-exe---local-group-policy-object-utility-v1-0/701045
- https://github.com/dsccommunity/PolicyFileEditor
- https://github.com/pester/Pester/releases
- https://github.com/PowerShell/PSScriptAnalyzer/releases
- https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/avoidusinginvokeexpression?view=ps-modules

## Open Questions
- None.
