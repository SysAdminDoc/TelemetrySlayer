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

    It 'uses SKU-aware AllowTelemetry scan and apply behavior' {
        $script:ScriptText | Should -Match 'function GetTelemetrySkuProfile'
        $script:ScriptText | Should -Match 'SupportsDiagnosticOff'
        $script:ScriptText | Should -Match 'AllowTelemetryValue'
        $script:ScriptText | Should -Match 'Set AllowTelemetry to 1 \(Required diagnostic data - SKU gated\)'
        $script:ScriptText | Should -Match '\$telemetryValue = \[int\]\$telemetryProfile\.AllowTelemetryValue'
        $script:ScriptText | Should -Match 'TelemetrySlayer will apply required diagnostic data value 1'
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
