Describe 'TelemetrySlayer action catalog' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..\TelemetrySlayer.ps1'
        $script:ScriptText = Get-Content -LiteralPath $script:ScriptPath -Raw
        . $script:ScriptPath -ActionCatalogOnly
        $script:Catalog = @(Get-TelemetrySlayerActionCatalog)
        $script:CatalogByCheckBox = @{}
        foreach ($action in $script:Catalog) {
            $script:CatalogByCheckBox[$action.CheckBox] = $action
        }
    }

    It 'catalogs every GUI checkbox exactly once' {
        $checkboxes = @(
            [regex]::Matches($script:ScriptText, 'x:Name="(chk[^"]+)"') |
                ForEach-Object { $_.Groups[1].Value } |
                Sort-Object -Unique
        )
        $catalogNames = @($script:Catalog.CheckBox | Sort-Object -Unique)

        $catalogNames | Should -Be $checkboxes
        $script:Catalog.Count | Should -Be $checkboxes.Count
    }

    It 'defines Test, Apply, Verify, and Undo phases for every hardening action' {
        foreach ($action in $script:Catalog) {
            $action.Operations.Count | Should -BeGreaterThan 0 -Because "$($action.CheckBox) needs at least one operation"
            foreach ($operation in $action.Operations) {
                @($operation.Phases) | Should -Be @('Test', 'Apply', 'Verify', 'Undo')
            }
        }
    }

    It 'matches expected operation kinds for every checkbox' {
        $expectedKinds = @{
            chkDiagTrack = @('Service')
            chkDmwAppPush = @('Service')
            chkWerSvc = @('Service')
            chkPcaSvc = @('Service')
            chkDiagSvc = @('Service')
            chkDPS = @('Service')
            chkCompatAppraiser = @('Task')
            chkProgramDataUpdater = @('Task')
            chkStartupAppTask = @('Task')
            chkProxy = @('Task')
            chkConsolidator = @('Task')
            chkUsbCeip = @('Task')
            chkKernelCeip = @('Task')
            chkDiskDiag = @('Task')
            chkSmartScreen = @('Task')
            chkPcaPatchDb = @('Task')
            chkAllowTelemetry = @('Registry', 'Registry', 'Registry')
            chkAdvertisingID = @('Registry', 'Registry', 'Registry')
            chkLinguistic = @('Registry', 'Registry')
            chkTailoredExp = @('Registry', 'Registry', 'Registry')
            chkFeedback = @('Registry', 'Registry', 'Registry')
            chkActivityFeed = @('Registry', 'Registry', 'Registry')
            chkLocationTracking = @('Registry', 'Registry', 'Registry')
            chkInputPersonalization = @('Registry', 'Registry', 'Registry', 'Registry', 'Registry', 'Registry')
            chkHandwritingTelemetry = @('Registry')
            chkInventoryCollector = @('Registry', 'Registry', 'Registry')
            chkStepsRecorder = @('Registry')
            chkWiFiSense = @('Registry', 'Registry', 'Registry')
            chkFirewallCompat = @('Firewall')
            chkFirewallCEIP = @('Firewall')
            chkFirewallDiagTrack = @('Firewall')
            chkIFEO = @('Registry')
            chkClearETL = @('File', 'Registry')
            chkOfficeTelemetry = @('Registry', 'Registry', 'Registry', 'Registry', 'Registry', 'Registry')
            chkOfficeFeedback = @('Registry', 'Registry', 'Registry', 'Registry', 'Registry')
            chkNvidiaSvc = @('Service')
            chkNvidiaTasks = @('Task', 'Task', 'Task', 'Task')
            chkNvidiaReg = @('Registry', 'Registry')
            chkEdgeDiag = @('Registry', 'Registry', 'Registry')
            chkEdgeMetrics = @('Registry', 'Registry', 'Registry', 'Registry', 'Registry', 'Registry')
            chkEdgeWebView = @('Registry', 'Registry', 'Registry')
            chkWindowsAI = @('Registry', 'Registry', 'Registry', 'Registry', 'Registry', 'Registry', 'Registry', 'Registry', 'Registry', 'Registry', 'Registry')
            chkVSTelemetry = @('Registry', 'Registry', 'Registry', 'Registry', 'Registry')
            chkVSSvc = @('Service', 'Process')
        }

        foreach ($checkbox in $expectedKinds.Keys) {
            $action = $script:CatalogByCheckBox[$checkbox]
            $action | Should -Not -BeNullOrEmpty -Because "$checkbox should exist in the catalog"
            @($action.Operations.Kind) | Should -Be $expectedKinds[$checkbox]
        }
    }

    It 'uses concrete expected targets for representative privileged operations' {
        @($script:CatalogByCheckBox.chkDiagTrack.Operations.Target) | Should -Contain 'DiagTrack'
        @($script:CatalogByCheckBox.chkCompatAppraiser.Operations.Target) | Should -Contain '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'
        @($script:CatalogByCheckBox.chkAllowTelemetry.Operations.Target) | Should -Contain 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry'
        @($script:CatalogByCheckBox.chkAllowTelemetry.Operations.Data.Value | Sort-Object -Unique) | Should -Be @('SkuGated0Or1')
        @($script:CatalogByCheckBox.chkFirewallDiagTrack.Operations.Target) | Should -Contain 'TelemetrySlayer - Block DiagTrack svchost'
        @($script:CatalogByCheckBox.chkIFEO.Operations.Target) | Should -Contain 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe\Debugger'
        @($script:CatalogByCheckBox.chkClearETL.Operations.Kind) | Should -Be @('File', 'Registry')
        @($script:CatalogByCheckBox.chkVSSvc.Operations.Target) | Should -Contain 'PerfWatson2'
    }

    It 'dispatches every catalog operation through mocked host-operation wrappers' {
        $script:Calls = @()

        Mock Invoke-TelemetrySlayerRegistryOperation { param($Operation, $Phase) $script:Calls += [pscustomobject]@{ Kind = 'Registry'; Phase = $Phase; Target = $Operation.Target } }
        Mock Invoke-TelemetrySlayerServiceOperation { param($Operation, $Phase) $script:Calls += [pscustomobject]@{ Kind = 'Service'; Phase = $Phase; Target = $Operation.Target } }
        Mock Invoke-TelemetrySlayerTaskOperation { param($Operation, $Phase) $script:Calls += [pscustomobject]@{ Kind = 'Task'; Phase = $Phase; Target = $Operation.Target } }
        Mock Invoke-TelemetrySlayerFirewallOperation { param($Operation, $Phase) $script:Calls += [pscustomobject]@{ Kind = 'Firewall'; Phase = $Phase; Target = $Operation.Target } }
        Mock Invoke-TelemetrySlayerFileOperation { param($Operation, $Phase) $script:Calls += [pscustomobject]@{ Kind = 'File'; Phase = $Phase; Target = $Operation.Target } }
        Mock Invoke-TelemetrySlayerProcessOperation { param($Operation, $Phase) $script:Calls += [pscustomobject]@{ Kind = 'Process'; Phase = $Phase; Target = $Operation.Target } }

        foreach ($action in $script:Catalog) {
            foreach ($phase in @('Test', 'Apply', 'Verify', 'Undo')) {
                Invoke-TelemetrySlayerActionPhase -Action $action -Phase $phase | Out-Null
            }
        }

        $expectedCallCount = (($script:Catalog | ForEach-Object { $_.Operations.Count } | Measure-Object -Sum).Sum * 4)
        $script:Calls.Count | Should -Be $expectedCallCount
        @($script:Calls.Kind | Sort-Object -Unique) | Should -Be @('File', 'Firewall', 'Process', 'Registry', 'Service', 'Task')
        @($script:Calls.Phase | Sort-Object -Unique) | Should -Be @('Apply', 'Test', 'Undo', 'Verify')
    }

    It 'has risk level and source metadata for every action' {
        foreach ($action in $script:Catalog) {
            $action.Risk | Should -Not -BeNullOrEmpty -Because "$($action.CheckBox) needs a risk level"
            $action.Risk | Should -BeIn @('Low', 'Medium', 'High', 'Critical') -Because "$($action.CheckBox) risk must be valid"
            $action.Source | Should -Not -BeNullOrEmpty -Because "$($action.CheckBox) needs a source reference"
            $action.SupportedOS | Should -Not -BeNullOrEmpty -Because "$($action.CheckBox) needs supported OS info"
        }
    }

    It 'has stable provenance and build metadata for every action' {
        foreach ($action in $script:Catalog) {
            $action.StableId | Should -Match '^TelemetrySlayer\.'
            $action.Category | Should -Not -BeNullOrEmpty
            $action.SourceUrl | Should -Match '^https://'
            $action.PolicyPath | Should -Not -BeNullOrEmpty
            $action.SupportedBuilds | Should -Not -BeNullOrEmpty
            $action.SupportedSKUs | Should -Not -BeNullOrEmpty
            $action.UndoType | Should -Be 'Exact pre-apply snapshot'
        }
    }

    It 'models current Windows AI and Recall policy targets' {
        $windowsAi = $script:CatalogByCheckBox.chkWindowsAI
        @($windowsAi.Operations.Target) | Should -Contain 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI\DisableAIDataAnalysis'
        @($windowsAi.Operations.Target) | Should -Contain 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI\AllowRecallEnablement'
        @($windowsAi.Operations.Target) | Should -Contain 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI\DisableClickToDo'
        @($windowsAi.Operations.Target) | Should -Contain 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI\RemoveMicrosoftCopilotApp'
        @($windowsAi.Operations | Where-Object { $_.Data.Legacy }).Count | Should -Be 1
        $windowsAi.SupportedBuilds | Should -Match 'Windows 11'
    }

    It 'labels obsolete Edge policy names as legacy compatibility fallbacks' {
        $edge = $script:CatalogByCheckBox.chkEdgeMetrics
        @($edge.LegacyPolicies) | Should -Be @('MetricsReportingEnabled', 'SendSiteInfoToImproveServices', 'DiscoverPageContextEnabled')
    }

    It 'classifies Windows build profiles for gated policy coverage' {
        (Get-TelemetrySlayerBuildProfile -Build '19045' -DisplayVersion '22H2' -ProductName 'Windows 10 Pro' -EditionId 'Professional').Name | Should -Match 'Windows 10'
        (Get-TelemetrySlayerBuildProfile -Build '22631' -DisplayVersion '23H2' -ProductName 'Windows 11 Pro' -EditionId 'Professional').SupportsWindowsAI | Should -BeFalse
        (Get-TelemetrySlayerBuildProfile -Build '26100' -DisplayVersion '24H2' -ProductName 'Windows 11 Pro' -EditionId 'Professional').SupportsWindowsAI | Should -BeTrue
        (Get-TelemetrySlayerBuildProfile -Build '26100' -DisplayVersion '24H2' -ProductName 'Windows Server 2025' -EditionId 'ServerStandard' -IsServer $true).SupportsWindowsAI | Should -BeFalse
    }

    It 'renders a command preview from selected catalog operations' {
        $preview = Get-TelemetrySlayerPreview @{ chkDiagTrack = $true; chkAllowTelemetry = $true; chkWindowsAI = $true }
        $preview | Should -Match 'sc.exe stop.*DiagTrack'
        $preview | Should -Match 'New-ItemProperty.*AllowTelemetry'
        $preview | Should -Match 'DisableAIDataAnalysis'
        $preview | Should -Match 'gpupdate.exe /force'
        (Get-TelemetrySlayerPreview @{}) | Should -Be 'No actions selected.'
    }

    It 'exports deployable policy metadata and ADMX resources' {
        $exportPath = Join-Path $TestDrive 'PolicyBundle'
        $result = Export-TelemetrySlayerPolicyBundle -Path $exportPath
        $result.RegistryEntries | Should -BeGreaterThan 0
        $result.AdmxPolicies | Should -BeGreaterThan 0
        foreach ($file in @('machine.reg', 'user.reg', 'policy.csv', 'policy.json', 'TelemetrySlayer.admx', 'en-US\TelemetrySlayer.adml')) {
            Test-Path -LiteralPath (Join-Path $exportPath $file) | Should -BeTrue
        }
        $policyJson = Get-Content -LiteralPath (Join-Path $exportPath 'policy.json') -Raw | ConvertFrom-Json
        @($policyJson.DynamicValues).Count | Should -BeGreaterThan 0
        ([xml](Get-Content -LiteralPath (Join-Path $exportPath 'TelemetrySlayer.admx') -Raw)).policyDefinitions | Should -Not -BeNullOrEmpty
        Get-Content -LiteralPath (Join-Path $exportPath 'machine.reg') -Raw | Should -Match 'Windows Registry Editor Version 5.00'
    }

    It 'builds a hidden weekly re-apply task definition and dry-run registration' {
        $definition = Get-TelemetrySlayerReapplyTaskDefinition -ScriptPath 'C:\Tools\TelemetrySlayer.ps1' -Preset 'Paranoid' -LogPath 'C:\ProgramData\TelemetrySlayer\Logs\weekly.log' -ReportPath 'C:\ProgramData\TelemetrySlayer\Reports\weekly.json'
        $definition.Frequency | Should -Be 'Weekly'
        $definition.Day | Should -Be 'Sunday'
        $definition.Time | Should -Be '03:00'
        $definition.Arguments | Should -Match '-WindowStyle Hidden'
        $definition.Arguments | Should -Match '-Silent'
        $definition.Arguments | Should -Match '-Preset Paranoid'
        $definition.Arguments | Should -Match '-ReportPath'
        $whatIf = Register-TelemetrySlayerReapplyTask -ScriptPath 'C:\Tools\TelemetrySlayer.ps1' -WhatIf:$true
        $whatIf.WhatIf | Should -BeTrue
    }

    It 'detects post-baseline policy drift' {
        $baseline = [pscustomobject]@{
            GeneratedAt = '2026-08-09T03:00:00Z'
            Actions = @([pscustomobject]@{
                StableId = 'TelemetrySlayer.Sample'
                Name = 'Sample'
                Operations = @([pscustomobject]@{ Status = 'Pass'; Actual = 0; Target = 'HKLM:\Sample\Value' })
            })
        }
        $current = [pscustomobject]@{
            GeneratedAt = '2026-08-16T03:00:00Z'
            Actions = @([pscustomobject]@{
                StableId = 'TelemetrySlayer.Sample'
                Name = 'Sample'
                Operations = @([pscustomobject]@{ Status = 'Drift'; Actual = 1; Target = 'HKLM:\Sample\Value'; Detail = 'Registry value differs' })
            })
        }
        $comparison = Compare-TelemetrySlayerAudits -Baseline $baseline -Current $current
        $comparison.ChangedCount | Should -Be 1
        $comparison.DriftCount | Should -Be 1
        $comparison.Changes[0].BeforeStatus | Should -Be 'Pass'
        $comparison.Changes[0].AfterStatus | Should -Be 'Drift'
    }

    It 'exposes preset profiles covering every catalog checkbox' {
        foreach ($presetName in @('Balanced', 'Minimal', 'Paranoid')) {
            $preset = Get-TelemetrySlayerPreset $presetName
            foreach ($action in $script:Catalog) {
                $preset.ContainsKey($action.CheckBox) | Should -Be $true -Because "$presetName preset should contain $($action.CheckBox)"
            }
        }
    }

    It 'dispatches gpupdate finalization through mocks for apply and undo' {
        $script:GpupdateCalls = @()
        Mock Invoke-TelemetrySlayerGpupdateOperation { param($Operation, $Phase) $script:GpupdateCalls += [pscustomobject]@{ Phase = $Phase; Target = $Operation.Target } }

        Invoke-TelemetrySlayerFinalizePhase -Phase Apply | Out-Null
        Invoke-TelemetrySlayerFinalizePhase -Phase Undo | Out-Null

        $script:GpupdateCalls.Count | Should -Be 2
        @($script:GpupdateCalls.Phase) | Should -Be @('Apply', 'Undo')
        @($script:GpupdateCalls.Target | Sort-Object -Unique) | Should -Be @('gpupdate.exe /force')
    }
}
