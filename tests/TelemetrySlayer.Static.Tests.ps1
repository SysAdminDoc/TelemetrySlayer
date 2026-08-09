Describe 'TelemetrySlayer static safety checks' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..\TelemetrySlayer.ps1'
        $script:ScriptText = Get-Content -LiteralPath $script:ScriptPath -Raw
        $script:Tokens = $null
        $script:ParseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$script:Tokens, [ref]$script:ParseErrors) | Out-Null
    }

    It 'parses as valid PowerShell' {
        $script:ParseErrors | Should -BeNullOrEmpty
    }

    It 'uses timeout-safe sc.exe service control instead of service cmdlets' {
        $script:ScriptText | Should -Match 'function InvokeSc'
        $script:ScriptText | Should -Match 'WaitServiceState'
        $script:ScriptText | Should -Not -Match '\b(Stop|Start|Set|Restart)-Service\b'
    }

    It 'captures exact restore state before mutable action classes' {
        $script:ScriptText | Should -Match 'restore-latest\.json'
        $script:ScriptText | Should -Match 'Join-Path \$programDataRoot ''Backups'''
        $script:ScriptText | Should -Match 'function RunPreflightBackup'
        $script:ScriptText | Should -Match 'Checkpoint-Computer'
        $script:ScriptText | Should -Match 'reg\.exe'
        $script:ScriptText | Should -Match 'no recovery artifact could be written; Apply blocked'
        $script:ScriptText | Should -Match 'function CaptureRegValue'
        $script:ScriptText | Should -Match 'function CaptureSvc'
        $script:ScriptText | Should -Match 'function CaptureTask'
        $script:ScriptText | Should -Match 'function CaptureFirewallRule'
        $script:ScriptText | Should -Match 'New-ItemProperty -LiteralPath \$Path'
        $script:ScriptText | Should -Match 'function CheckTask\(\[string\]\$TaskName, \[string\]\$TaskPath, \[string\]\$IndName\)'
        $script:ScriptText | Should -Match 'Get-ScheduledTask -TaskName \$TaskName -TaskPath \$TaskPath'
    }

    It 'supports silent mode with presets and WhatIf' {
        $script:ScriptText | Should -Match '\[switch\]\$Silent'
        $script:ScriptText | Should -Match "ValidateSet\('Balanced','Minimal','Paranoid'\)"
        $script:ScriptText | Should -Match '\[switch\]\$WhatIf'
        $script:ScriptText | Should -Match 'function Get-TelemetrySlayerPreset'
        $script:ScriptText | Should -Match 'function SilentLog'
        $script:ScriptText | Should -Match 'if \(\$Silent\)'
    }

    It 'writes durable transcript log files' {
        $script:ScriptText | Should -Match 'function Start-LogFile'
        $script:ScriptText | Should -Match 'function Write-LogLine'
        $script:ScriptText | Should -Match 'TelemetrySlayer\\Logs'
        $script:ScriptText | Should -Match 'btnOpenLogs'
    }

    It 'supports catalog-derived policy export and paired registry recovery' {
        $script:ScriptText | Should -Match '\[string\]\$ExportPolicyPath'
        $script:ScriptText | Should -Match 'function Export-TelemetrySlayerPolicyBundle'
        $script:ScriptText | Should -Match 'TelemetrySlayer\.admx'
        $script:ScriptText | Should -Match 'policy\.csv'
        $script:ScriptText | Should -Match 'function SavePairedRegistryRestore'
        $script:ScriptText | Should -Match 'restore-registry\.reg'
        $script:ScriptText | Should -Match 'PairedRegistryRestore'
    }

    It 'supports weekly hidden re-apply scheduling with a local report' {
        $script:ScriptText | Should -Match '\[switch\]\$RegisterReapplyTask'
        $script:ScriptText | Should -Match '\[switch\]\$UnregisterReapplyTask'
        $script:ScriptText | Should -Match 'function Get-TelemetrySlayerReapplyTaskDefinition'
        $script:ScriptText | Should -Match 'New-ScheduledTaskTrigger -Weekly'
        $script:ScriptText | Should -Match 'SaveSilentReport'
        $script:ScriptText | Should -Match 'scheduled-reapply\.json'
        $script:ScriptText | Should -Match 'WindowStyle Hidden'
    }

    It 'supports read-only audit baselines and drift comparisons' {
        $script:ScriptText | Should -Match '\[string\]\$AuditPath'
        $script:ScriptText | Should -Match '\[string\]\$CompareAuditPath'
        $script:ScriptText | Should -Match 'function Get-TelemetrySlayerAudit'
        $script:ScriptText | Should -Match 'function Compare-TelemetrySlayerAudits'
        $script:ScriptText | Should -Match "Status = 'NotApplicable'"
        $script:ScriptText | Should -Match 'exit 2'
    }

    It 'writes post-apply verification ledger' {
        $script:ScriptText | Should -Match 'function AddActionResult'
        $script:ScriptText | Should -Match 'function SaveRunResults'
        $script:ScriptText | Should -Match 'results\.json'
        $script:ScriptText | Should -Match "programDataRoot 'Runs'"
    }

    It 'catches unhandled worker exceptions' {
        $script:ScriptText | Should -Match 'FATAL unhandled exception in Apply worker'
        $script:ScriptText | Should -Match 'FATAL unhandled exception in Undo worker'
    }

    It 'uses SKU-aware AllowTelemetry scan and apply behavior' {
        $script:ScriptText | Should -Match 'function GetTelemetrySkuProfile'
        $script:ScriptText | Should -Match 'SupportsDiagnosticOff'
        $script:ScriptText | Should -Match 'AllowTelemetryValue'
        $script:ScriptText | Should -Match 'Set AllowTelemetry to 1 \(Required diagnostic data - SKU gated\)'
        $script:ScriptText | Should -Match '\$telemetryValue = \[int\]\$telemetryProfile\.AllowTelemetryValue'
        $script:ScriptText | Should -Match 'TelemetrySlayer will apply required diagnostic data value 1'
    }

    It 'gates current Windows AI policy coverage by build profile' {
        $script:ScriptText | Should -Match 'function Get-TelemetrySlayerBuildProfile'
        $script:ScriptText | Should -Match 'SupportsWindowsAI'
        $script:ScriptText | Should -Match 'DisableAIDataAnalysis'
        $script:ScriptText | Should -Match 'AllowRecallEnablement'
        $script:ScriptText | Should -Match 'RemoveMicrosoftCopilotApp'
        $script:ScriptText | Should -Match 'indWindowsAI=N/A'
    }

    It 'exposes searchable previews and transcript history in the GUI' {
        $script:ScriptText | Should -Match 'x:Name="txtSearch"'
        $script:ScriptText | Should -Match 'x:Name="btnPreview"'
        $script:ScriptText | Should -Match 'x:Name="lstHistory"'
        $script:ScriptText | Should -Match 'x:Name="txtHistory"'
        $script:ScriptText | Should -Match 'ms-settings:privacy-feedback'
        $script:ScriptText | Should -Match 'Get-TelemetrySlayerPreview'
    }

    It 'restores undo state from the saved snapshot instead of broad defaults' {
        $script:ScriptText | Should -Match 'ConvertFrom-Json'
        $script:ScriptText | Should -Match 'function RestoreSvc'
        $script:ScriptText | Should -Match 'function RestoreTask'
        $script:ScriptText | Should -Match 'function RestoreFirewallBaseline'
        $script:ScriptText | Should -Not -Match 'function DelReg'
        $script:ScriptText | Should -Not -Match 'Get-NetFirewallRule -Group ''TelemetrySlayer'''
        $script:ScriptText | Should -Not -Match 'Remove-Item -LiteralPath \$ifeoPath'
    }
}
