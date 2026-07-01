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
