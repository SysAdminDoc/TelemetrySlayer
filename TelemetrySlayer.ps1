#Requires -Version 5.1
# TelemetrySlayer v1.6.0
# Disables Microsoft telemetry, data collection, and related bloat on Windows 10/11

param(
    [switch]$ActionCatalogOnly
)

function Get-TelemetrySlayerOperation {
    param(
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$Target,
        [hashtable]$Data = @{}
    )

    [pscustomobject]@{
        Kind = $Kind
        Target = $Target
        Data = [pscustomobject]$Data
        Phases = @('Test', 'Apply', 'Verify', 'Undo')
    }
}

function Get-TelemetrySlayerRegistryOperation {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    Get-TelemetrySlayerOperation -Kind 'Registry' -Target "$Path\$Name" -Data @{
        Path = $Path
        Name = $Name
        Value = $Value
        Type = $Type
        Apply = 'Set'
        Test = 'Equals'
        Verify = 'Equals'
        Undo = 'RestoreSnapshot'
    }
}

function Get-TelemetrySlayerServiceOperation {
    param([string]$Name, [string]$DisplayName)
    Get-TelemetrySlayerOperation -Kind 'Service' -Target $Name -Data @{
        Name = $Name
        DisplayName = $DisplayName
        Apply = 'Disable'
        Test = 'StartupDisabled'
        Verify = 'StartupDisabled'
        Undo = 'RestoreSnapshot'
    }
}

function Get-TelemetrySlayerTaskOperation {
    param([string]$TaskName, [string]$TaskPath)
    Get-TelemetrySlayerOperation -Kind 'Task' -Target "$TaskPath$TaskName" -Data @{
        TaskName = $TaskName
        TaskPath = $TaskPath
        Apply = 'Disable'
        Test = 'Disabled'
        Verify = 'Disabled'
        Undo = 'RestoreSnapshot'
    }
}

function Get-TelemetrySlayerFirewallOperation {
    param([string]$DisplayName, [string]$Program, [string]$Service)
    Get-TelemetrySlayerOperation -Kind 'Firewall' -Target $DisplayName -Data @{
        DisplayName = $DisplayName
        Program = $Program
        Service = $Service
        Apply = 'BlockOutbound'
        Test = 'RulePresent'
        Verify = 'RulePresent'
        Undo = 'RestoreSnapshot'
    }
}

function Get-TelemetrySlayerFileOperation {
    param([string]$Path, [string]$Action)
    Get-TelemetrySlayerOperation -Kind 'File' -Target $Path -Data @{
        Path = $Path
        Apply = $Action
        Test = 'PathState'
        Verify = 'PathState'
        Undo = 'NoFileRestore'
    }
}

function Get-TelemetrySlayerProcessOperation {
    param([string]$Name, [string]$Action)
    Get-TelemetrySlayerOperation -Kind 'Process' -Target $Name -Data @{
        Name = $Name
        Apply = $Action
        Test = 'ProcessAbsent'
        Verify = 'ProcessAbsent'
        Undo = 'NoProcessRestore'
    }
}

function Get-TelemetrySlayerAction {
    param(
        [Parameter(Mandatory = $true)][string]$CheckBox,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][object[]]$Operations
    )

    [pscustomobject]@{
        CheckBox = $CheckBox
        Name = $Name
        Operations = @($Operations)
    }
}

function Get-TelemetrySlayerActionCatalog {
    $systemRoot = if ($env:SystemRoot) { $env:SystemRoot } else { 'C:\Windows' }
    $programData = if ($env:ProgramData) { $env:ProgramData } else { 'C:\ProgramData' }
    $appExpPath = '\Microsoft\Windows\Application Experience\'
    $ceipPath = '\Microsoft\Windows\Customer Experience Improvement Program\'
    $nvidiaTaskPath = '\'

    @(
        Get-TelemetrySlayerAction 'chkDiagTrack' 'Connected User Experiences and Telemetry' @(
            Get-TelemetrySlayerServiceOperation 'DiagTrack' 'Connected User Experiences and Telemetry'
        )
        Get-TelemetrySlayerAction 'chkDmwAppPush' 'WAP Push Message Routing' @(
            Get-TelemetrySlayerServiceOperation 'dmwappushservice' 'WAP Push Message Routing'
        )
        Get-TelemetrySlayerAction 'chkWerSvc' 'Windows Error Reporting' @(
            Get-TelemetrySlayerServiceOperation 'WerSvc' 'Windows Error Reporting'
        )
        Get-TelemetrySlayerAction 'chkPcaSvc' 'Program Compatibility Assistant' @(
            Get-TelemetrySlayerServiceOperation 'PcaSvc' 'Program Compatibility Assistant'
        )
        Get-TelemetrySlayerAction 'chkDiagSvc' 'Diagnostic Service Host' @(
            Get-TelemetrySlayerServiceOperation 'diagsvc' 'Diagnostic Service Host'
        )
        Get-TelemetrySlayerAction 'chkDPS' 'Diagnostic Policy Service' @(
            Get-TelemetrySlayerServiceOperation 'DPS' 'Diagnostic Policy Service'
        )
        Get-TelemetrySlayerAction 'chkCompatAppraiser' 'Microsoft Compatibility Appraiser' @(
            Get-TelemetrySlayerTaskOperation 'Microsoft Compatibility Appraiser' $appExpPath
        )
        Get-TelemetrySlayerAction 'chkProgramDataUpdater' 'ProgramDataUpdater' @(
            Get-TelemetrySlayerTaskOperation 'ProgramDataUpdater' $appExpPath
        )
        Get-TelemetrySlayerAction 'chkStartupAppTask' 'StartupAppTask' @(
            Get-TelemetrySlayerTaskOperation 'StartupAppTask' $appExpPath
        )
        Get-TelemetrySlayerAction 'chkProxy' 'Autochk Proxy' @(
            Get-TelemetrySlayerTaskOperation 'Proxy' '\Microsoft\Windows\Autochk\'
        )
        Get-TelemetrySlayerAction 'chkConsolidator' 'CEIP Consolidator' @(
            Get-TelemetrySlayerTaskOperation 'Consolidator' $ceipPath
        )
        Get-TelemetrySlayerAction 'chkUsbCeip' 'USB CEIP' @(
            Get-TelemetrySlayerTaskOperation 'UsbCeip' $ceipPath
        )
        Get-TelemetrySlayerAction 'chkKernelCeip' 'Kernel CEIP' @(
            Get-TelemetrySlayerTaskOperation 'KernelCeipTask' $ceipPath
        )
        Get-TelemetrySlayerAction 'chkDiskDiag' 'Disk Diagnostic Data Collector' @(
            Get-TelemetrySlayerTaskOperation 'Microsoft-Windows-DiskDiagnosticDataCollector' '\Microsoft\Windows\DiskDiagnostic\'
        )
        Get-TelemetrySlayerAction 'chkSmartScreen' 'SmartScreenSpecific' @(
            Get-TelemetrySlayerTaskOperation 'SmartScreenSpecific' '\Microsoft\Windows\AppID\'
        )
        Get-TelemetrySlayerAction 'chkPcaPatchDb' 'PcaPatchDbTask' @(
            Get-TelemetrySlayerTaskOperation 'PcaPatchDbTask' $appExpPath
        )
        Get-TelemetrySlayerAction 'chkAllowTelemetry' 'AllowTelemetry policies' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 'SkuGated0Or1'
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'MaxTelemetryAllowed' 'SkuGated0Or1'
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 'SkuGated0Or1'
        )
        Get-TelemetrySlayerAction 'chkAdvertisingID' 'Advertising ID' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
        )
        Get-TelemetrySlayerAction 'chkLinguistic' 'Linguistic data collection' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput' 'AllowLinguisticDataCollection' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' 'AllowInputPersonalization' 0
        )
        Get-TelemetrySlayerAction 'chkTailoredExp' 'Tailored experiences' @(
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0
        )
        Get-TelemetrySlayerAction 'chkFeedback' 'Feedback notifications' @(
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' 'PeriodInNanoSeconds' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 1
        )
        Get-TelemetrySlayerAction 'chkActivityFeed' 'Activity history' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 0
        )
        Get-TelemetrySlayerAction 'chkLocationTracking' 'Location tracking' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableWindowsLocationProvider' 1
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocationScripting' 1
        )
        Get-TelemetrySlayerAction 'chkInputPersonalization' 'Input personalization' @(
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC' 'PreventHandwritingDataSharing' 1
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Preferences' 'ModelDownloadAllowed' 0
        )
        Get-TelemetrySlayerAction 'chkHandwritingTelemetry' 'Handwriting telemetry' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports' 'PreventHandwritingErrorReports' 1
        )
        Get-TelemetrySlayerAction 'chkInventoryCollector' 'Application inventory collector' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableInventory' 1
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'AITEnable' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableUAR' 1
        )
        Get-TelemetrySlayerAction 'chkStepsRecorder' 'Steps Recorder' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisablePCA' 1
        )
        Get-TelemetrySlayerAction 'chkWiFiSense' 'Wi-Fi Sense' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' 'AutoConnectAllowedOEM' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' 'value' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' 'value' 0
        )
        Get-TelemetrySlayerAction 'chkFirewallCompat' 'CompatTelRunner firewall block' @(
            Get-TelemetrySlayerFirewallOperation 'TelemetrySlayer - Block CompatTelRunner' "$systemRoot\System32\CompatTelRunner.exe" $null
        )
        Get-TelemetrySlayerAction 'chkFirewallCEIP' 'CEIP firewall block' @(
            Get-TelemetrySlayerFirewallOperation 'TelemetrySlayer - Block CEIP wsqmcons' "$systemRoot\System32\wsqmcons.exe" $null
        )
        Get-TelemetrySlayerAction 'chkFirewallDiagTrack' 'DiagTrack firewall block' @(
            Get-TelemetrySlayerFirewallOperation 'TelemetrySlayer - Block DiagTrack svchost' "$systemRoot\System32\svchost.exe" 'DiagTrack'
        )
        Get-TelemetrySlayerAction 'chkIFEO' 'CompatTelRunner IFEO debugger' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe' 'Debugger' "$systemRoot\System32\taskkill.exe" 'String'
        )
        Get-TelemetrySlayerAction 'chkClearETL' 'Clear DiagTrack ETL' @(
            Get-TelemetrySlayerFileOperation "$programData\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl" 'ClearFile'
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener' 'Start' 0
        )
        Get-TelemetrySlayerAction 'chkOfficeTelemetry' 'Office telemetry' @(
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\15.0\osm' 'Enablelogging' 0
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\15.0\osm' 'EnableUpload' 0
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\osm' 'Enablelogging' 0
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\osm' 'EnableUpload' 0
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\Common\ClientTelemetry' 'DisableTelemetry' 1
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\Common\ClientTelemetry' 'SendTelemetry' 3
        )
        Get-TelemetrySlayerAction 'chkOfficeFeedback' 'Office feedback' @(
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Feedback' 'Enabled' 0
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Feedback' 'SurveyEnabled' 0
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common' 'sendcustomerdata' 0
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Privacy' 'DisconnectedState' 2
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Privacy' 'ControllerConnectedServicesEnabled' 2
        )
        Get-TelemetrySlayerAction 'chkNvidiaSvc' 'Nvidia telemetry service' @(
            Get-TelemetrySlayerServiceOperation 'NvTelemetryContainer' 'Nvidia Telemetry Container'
        )
        Get-TelemetrySlayerAction 'chkNvidiaTasks' 'Nvidia telemetry tasks' @(
            Get-TelemetrySlayerTaskOperation 'NvTmMon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' $nvidiaTaskPath
            Get-TelemetrySlayerTaskOperation 'NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' $nvidiaTaskPath
            Get-TelemetrySlayerTaskOperation 'NvProfileUpdaterDaily_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' $nvidiaTaskPath
            Get-TelemetrySlayerTaskOperation 'NvProfileUpdaterOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' $nvidiaTaskPath
        )
        Get-TelemetrySlayerAction 'chkNvidiaReg' 'Nvidia telemetry registry' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' 'Optimus_EnableTelemetry' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SYSTEM\CurrentControlSet\Services\NvTelemetryContainer' 'Start' 4
        )
        Get-TelemetrySlayerAction 'chkEdgeDiag' 'Edge diagnostic data' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'DiagnosticData' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'PersonalizationReportingEnabled' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'UserFeedbackAllowed' 0
        )
        Get-TelemetrySlayerAction 'chkEdgeMetrics' 'Edge metrics and sidebar' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'MetricsReportingEnabled' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'SendSiteInfoToImproveServices' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'CopilotPageContext' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'CopilotCDPPageContext' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'DiscoverPageContextEnabled' 0
        )
        Get-TelemetrySlayerAction 'chkEdgeWebView' 'Edge WebView2 telemetry' @(
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeWebView' 'DiagnosticData' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeWebView' 'MetricsReportingEnabled' 0
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeWebView' 'PersonalizationReportingEnabled' 0
        )
        Get-TelemetrySlayerAction 'chkVSTelemetry' 'Visual Studio telemetry' @(
            Get-TelemetrySlayerRegistryOperation 'HKCU:\SOFTWARE\Microsoft\VisualStudio\Telemetry' 'TurnOffSwitch' 1
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableFeedbackDialog' 1
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableEmailInput' 1
            Get-TelemetrySlayerRegistryOperation 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableScreenshotCapture' 1
        )
        Get-TelemetrySlayerAction 'chkVSSvc' 'Visual Studio collector service' @(
            Get-TelemetrySlayerServiceOperation 'VSStandardCollectorService150' 'VS Standard Collector Service'
            Get-TelemetrySlayerProcessOperation 'PerfWatson2' 'Stop'
        )
    )
}

function Get-TelemetrySlayerFinalizeOperation {
    Get-TelemetrySlayerOperation -Kind 'Gpupdate' -Target 'gpupdate.exe /force' -Data @{
        Apply = 'RefreshPolicy'
        Test = 'NotApplicable'
        Verify = 'PolicyRefreshAttempted'
        Undo = 'RefreshPolicy'
    }
}

function Invoke-TelemetrySlayerRegistryOperation { param($Operation, [string]$Phase) [pscustomobject]@{ Kind = 'Registry'; Phase = $Phase; Target = $Operation.Target } }
function Invoke-TelemetrySlayerServiceOperation { param($Operation, [string]$Phase) [pscustomobject]@{ Kind = 'Service'; Phase = $Phase; Target = $Operation.Target } }
function Invoke-TelemetrySlayerTaskOperation { param($Operation, [string]$Phase) [pscustomobject]@{ Kind = 'Task'; Phase = $Phase; Target = $Operation.Target } }
function Invoke-TelemetrySlayerFirewallOperation { param($Operation, [string]$Phase) [pscustomobject]@{ Kind = 'Firewall'; Phase = $Phase; Target = $Operation.Target } }
function Invoke-TelemetrySlayerFileOperation { param($Operation, [string]$Phase) [pscustomobject]@{ Kind = 'File'; Phase = $Phase; Target = $Operation.Target } }
function Invoke-TelemetrySlayerProcessOperation { param($Operation, [string]$Phase) [pscustomobject]@{ Kind = 'Process'; Phase = $Phase; Target = $Operation.Target } }
function Invoke-TelemetrySlayerGpupdateOperation { param($Operation, [string]$Phase) [pscustomobject]@{ Kind = 'Gpupdate'; Phase = $Phase; Target = $Operation.Target } }

function Invoke-TelemetrySlayerOperation {
    param(
        [Parameter(Mandatory = $true)]$Operation,
        [Parameter(Mandatory = $true)][ValidateSet('Test', 'Apply', 'Verify', 'Undo')][string]$Phase
    )

    switch ($Operation.Kind) {
        'Registry' { Invoke-TelemetrySlayerRegistryOperation -Operation $Operation -Phase $Phase }
        'Service' { Invoke-TelemetrySlayerServiceOperation -Operation $Operation -Phase $Phase }
        'Task' { Invoke-TelemetrySlayerTaskOperation -Operation $Operation -Phase $Phase }
        'Firewall' { Invoke-TelemetrySlayerFirewallOperation -Operation $Operation -Phase $Phase }
        'File' { Invoke-TelemetrySlayerFileOperation -Operation $Operation -Phase $Phase }
        'Process' { Invoke-TelemetrySlayerProcessOperation -Operation $Operation -Phase $Phase }
        'Gpupdate' { Invoke-TelemetrySlayerGpupdateOperation -Operation $Operation -Phase $Phase }
        default { throw "Unknown TelemetrySlayer operation kind: $($Operation.Kind)" }
    }
}

function Invoke-TelemetrySlayerActionPhase {
    param(
        [Parameter(Mandatory = $true)]$Action,
        [Parameter(Mandatory = $true)][ValidateSet('Test', 'Apply', 'Verify', 'Undo')][string]$Phase
    )

    foreach ($operation in $Action.Operations) {
        if ($operation.Phases -contains $Phase) {
            Invoke-TelemetrySlayerOperation -Operation $operation -Phase $Phase
        }
    }
}

function Invoke-TelemetrySlayerFinalizePhase {
    param([Parameter(Mandatory = $true)][ValidateSet('Apply', 'Undo')][string]$Phase)
    Invoke-TelemetrySlayerOperation -Operation (Get-TelemetrySlayerFinalizeOperation) -Phase $Phase
}

if ($ActionCatalogOnly) {
    return
}

# --- Auto-elevate ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- Hide console ---
Add-Type -Name Win -Namespace Native -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
[Native.Win]::ShowWindow([Native.Win]::GetConsoleWindow(), 0) | Out-Null

# --- XAML ---
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="TelemetrySlayer v1.6.0" Width="820" Height="750"
        WindowStartupLocation="CenterScreen" Background="#0d1117"
        ResizeMode="CanResizeWithGrip" MinWidth="750" MinHeight="600">
    <Window.Resources>
        <Style TargetType="TextBlock"><Setter Property="Foreground" Value="#e0e0e0"/></Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#e0e0e0"/>
            <Setter Property="Margin" Value="0,3"/>
            <Setter Property="FontSize" Value="12.5"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#238636"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="20,8"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#2ea043"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="#58a6ff"/>
            <Setter Property="BorderBrush" Value="#30363d"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
        <Style TargetType="ToolTip">
            <Setter Property="Background" Value="#1c2128"/>
            <Setter Property="Foreground" Value="#c9d1d9"/>
            <Setter Property="BorderBrush" Value="#30363d"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="MaxWidth" Value="350"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#161b22" Padding="16,12" BorderBrush="#30363d" BorderThickness="0,0,0,1">
            <StackPanel>
                <TextBlock Text="TelemetrySlayer" FontSize="22" FontWeight="Bold" Foreground="#58a6ff"/>
                <TextBlock Text="Disable Microsoft telemetry, data collection, and compatibility bloat" Foreground="#8b949e" FontSize="12" Margin="0,2,0,0"/>
            </StackPanel>
        </Border>

        <!-- Scroll area with categories -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="8,4">
            <StackPanel>
                <!-- Select All / Deselect All -->
                <StackPanel Orientation="Horizontal" Margin="4,6,0,2">
                    <Button x:Name="btnSelectAll" Content="Select All" FontSize="11" Padding="10,4" Background="#21262d" Margin="0,0,6,0"/>
                    <Button x:Name="btnDeselectAll" Content="Deselect All" FontSize="11" Padding="10,4" Background="#21262d" Margin="0,0,6,0"/>
                    <Button x:Name="btnScan" Content="Re-Scan Status" FontSize="11" Padding="10,4" Background="#21262d" Margin="0,0,6,0"/>
                    <Button x:Name="btnOpenLogs" Content="Open Log Folder" FontSize="11" Padding="10,4" Background="#21262d"/>
                </StackPanel>

                <!-- Services -->
                <GroupBox Header="  Services  ">
                    <StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indDiagTrack" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkDiagTrack" IsChecked="True"
                                Content="Disable Connected User Experiences and Telemetry (DiagTrack)"
                                ToolTip="Primary telemetry service. Collects and transmits diagnostic data to Microsoft."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indDmwAppPush" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkDmwAppPush" IsChecked="True"
                                Content="Disable WAP Push Message Routing (dmwappushservice)"
                                ToolTip="Routes push messages for telemetry. Used alongside DiagTrack."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indWerSvc" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkWerSvc" IsChecked="True"
                                Content="Disable Windows Error Reporting (WerSvc)"
                                ToolTip="Sends crash/error reports to Microsoft."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indPcaSvc" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkPcaSvc" IsChecked="True"
                                Content="Disable Program Compatibility Assistant (PcaSvc)"
                                ToolTip="Monitors programs and detects compatibility issues. Triggers CompatTelRunner.exe CPU spikes."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indDiagSvc" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkDiagSvc" IsChecked="True"
                                Content="Disable Diagnostic Service Host (diagsvc)"
                                ToolTip="Hosts diagnostic scenarios triggered by the Diagnostic Policy Service."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indDPS" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkDPS" IsChecked="False"
                                Content="Disable Diagnostic Policy Service (DPS)"
                                ToolTip="Detects and troubleshoots Windows components. Disabling may reduce some auto-troubleshooting. Unchecked by default."/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <!-- Scheduled Tasks -->
                <GroupBox Header="  Scheduled Tasks  ">
                    <StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indCompatAppraiser" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkCompatAppraiser" IsChecked="True"
                                Content="Disable Microsoft Compatibility Appraiser"
                                ToolTip="Scans system files for upgrade compatibility. Primary cause of CompatTelRunner.exe high CPU/disk."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indProgramDataUpdater" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkProgramDataUpdater" IsChecked="True"
                                Content="Disable ProgramDataUpdater"
                                ToolTip="Collects program telemetry data if opted-in to the CEIP."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indStartupAppTask" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkStartupAppTask" IsChecked="True"
                                Content="Disable StartupAppTask"
                                ToolTip="Scans startup entries for telemetry purposes."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indProxy" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkProxy" IsChecked="True"
                                Content="Disable Autochk Proxy"
                                ToolTip="Collects SQM (Software Quality Management) data."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indConsolidator" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkConsolidator" IsChecked="True"
                                Content="Disable CEIP Consolidator"
                                ToolTip="Consolidates and sends Customer Experience Improvement Program data."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indUsbCeip" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkUsbCeip" IsChecked="True"
                                Content="Disable USB CEIP"
                                ToolTip="Collects USB bus statistics to send to Microsoft."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indKernelCeip" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkKernelCeip" IsChecked="True"
                                Content="Disable KernelCeipTask"
                                ToolTip="Kernel-level Customer Experience Improvement Program data collector."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indDiskDiag" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkDiskDiag" IsChecked="True"
                                Content="Disable DiskDiagnosticDataCollector"
                                ToolTip="Collects general disk/system info to send to Microsoft."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indSmartScreen" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkSmartScreen" IsChecked="False"
                                Content="Disable SmartScreenSpecific"
                                ToolTip="SmartScreen-related telemetry task. Unchecked by default as SmartScreen provides security value."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indPcaPatchDb" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkPcaPatchDb" IsChecked="True"
                                Content="Disable PcaPatchDbTask"
                                ToolTip="Updates the compatibility database. Can trigger CompatTelRunner runs."/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <!-- Registry / Policy -->
                <GroupBox Header="  Registry and Policy  ">
                    <StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indAllowTelemetry" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkAllowTelemetry" IsChecked="True"
                                Content="Set AllowTelemetry to 0 (Security/Off)"
                                ToolTip="Sets HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry to 0. The nuclear option for data collection policy."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indAdvertisingID" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkAdvertisingID" IsChecked="True"
                                Content="Disable Advertising ID"
                                ToolTip="Prevents apps from using your advertising ID for cross-app profiling."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indLinguistic" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkLinguistic" IsChecked="True"
                                Content="Disable Linguistic Data Collection"
                                ToolTip="Stops collection of inking and typing data."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indTailoredExp" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkTailoredExp" IsChecked="True"
                                Content="Disable Tailored Experiences"
                                ToolTip="Prevents Microsoft from using diagnostic data to offer personalized tips, ads, and recommendations."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indFeedback" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkFeedback" IsChecked="True"
                                Content="Disable Feedback Notifications"
                                ToolTip="Sets feedback frequency to Never. Stops Windows from nagging for feedback."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indActivityFeed" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkActivityFeed" IsChecked="True"
                                Content="Disable Activity History / Timeline"
                                ToolTip="Stops Windows from collecting activity history and sending it to Microsoft."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indLocationTracking" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkLocationTracking" IsChecked="True"
                                Content="Disable Location Tracking"
                                ToolTip="Disables the Windows location platform sensor."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indInputPersonalization" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkInputPersonalization" IsChecked="True"
                                Content="Disable Input Personalization (Cloud Speech)"
                                ToolTip="Disables online speech recognition and cloud-based typing personalization."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indHandwritingTelemetry" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkHandwritingTelemetry" IsChecked="True"
                                Content="Disable Handwriting Error Reporting"
                                ToolTip="Prevents sharing handwriting recognition error data."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indInventoryCollector" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkInventoryCollector" IsChecked="True"
                                Content="Disable Application Inventory Collector"
                                ToolTip="Stops the Inventory Collector from sending data about installed apps to Microsoft."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indStepsRecorder" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkStepsRecorder" IsChecked="True"
                                Content="Disable Steps Recorder"
                                ToolTip="Disables the Steps Recorder (psr.exe) which can capture screenshots and input."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indWiFiSense" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkWiFiSense" IsChecked="True"
                                Content="Disable Wi-Fi Sense / Hotspot Reporting"
                                ToolTip="Prevents automatic sharing of Wi-Fi network credentials and hotspot reporting."/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <!-- Firewall and Aggressive -->
                <GroupBox Header="  Firewall and Hardening  ">
                    <StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indFirewallCompat" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkFirewallCompat" IsChecked="True"
                                Content="Block CompatTelRunner.exe outbound (Firewall)"
                                ToolTip="Creates an outbound firewall rule to block CompatTelRunner.exe from phoning home even if re-enabled."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indFirewallCEIP" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkFirewallCEIP" IsChecked="True"
                                Content="Block wsqmcons.exe outbound (CEIP Firewall)"
                                ToolTip="Blocks the Customer Experience Improvement Program sender."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indFirewallDiagTrack" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkFirewallDiagTrack" IsChecked="True"
                                Content="Block DiagTrack svchost outbound (Firewall)"
                                ToolTip="Creates outbound firewall rule blocking DiagTrack service network access."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indIFEO" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkIFEO" IsChecked="True"
                                Content="Set CompatTelRunner.exe IFEO Debugger to taskkill"
                                ToolTip="Uses Image File Execution Options to instantly kill CompatTelRunner.exe whenever Windows tries to launch it. Prevents re-enablement."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indClearETL" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkClearETL" IsChecked="True"
                                Content="Clear DiagTrack ETL log files"
                                ToolTip="Empties AutoLogger-Diagtrack-Listener.etl which stores collected telemetry data waiting to be sent."/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <!-- Office Telemetry -->
                <GroupBox Header="  Office Telemetry  ">
                    <StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indOfficeTelemetry" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkOfficeTelemetry" IsChecked="True"
                                Content="Disable Office Telemetry and Logging"
                                ToolTip="Disables Office telemetry agent logging and upload for Office 15.0 and 16.0."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indOfficeFeedback" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkOfficeFeedback" IsChecked="True"
                                Content="Disable Office Feedback and Surveys"
                                ToolTip="Prevents Office from sending feedback, surveys, and connected experiences data."/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <!-- Nvidia Telemetry -->
                <GroupBox Header="  Nvidia Telemetry  ">
                    <StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indNvidiaSvc" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkNvidiaSvc" IsChecked="True"
                                Content="Disable NvTelemetryContainer service"
                                ToolTip="Stops and disables the Nvidia Telemetry Container service that collects GPU usage data."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indNvidiaTasks" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkNvidiaTasks" IsChecked="True"
                                Content="Disable Nvidia telemetry scheduled tasks"
                                ToolTip="Disables NvTmMon, NvTmRep, and NvProfileUpdater scheduled tasks."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indNvidiaReg" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkNvidiaReg" IsChecked="True"
                                Content="Disable Nvidia telemetry via registry"
                                ToolTip="Sets Optimus_EnableTelemetry=0 and NvTelemetryContainer Start=4 (Disabled)."/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <!-- Edge Telemetry -->
                <GroupBox Header="  Edge Telemetry  ">
                    <StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indEdgeDiag" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkEdgeDiag" IsChecked="True"
                                Content="Disable Edge Diagnostic Data and Feedback"
                                ToolTip="Sets DiagnosticData=0, PersonalizationReportingEnabled=0, and UserFeedbackAllowed=0 under Edge policies."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indEdgeMetrics" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkEdgeMetrics" IsChecked="True"
                                Content="Disable Edge Metrics, Sidebar, and Copilot"
                                ToolTip="Disables MetricsReportingEnabled, SendSiteInfoToImproveServices, HubsSidebarEnabled, and Copilot page context policies."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indEdgeWebView" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkEdgeWebView" IsChecked="True"
                                Content="Disable Edge WebView2 telemetry"
                                ToolTip="Disables DiagnosticData, MetricsReportingEnabled, and PersonalizationReportingEnabled for the Edge WebView2 runtime."/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>

                <!-- Visual Studio Telemetry -->
                <GroupBox Header="  Visual Studio Telemetry  ">
                    <StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indVSTelemetry" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkVSTelemetry" IsChecked="True"
                                Content="Disable Visual Studio Telemetry OptIn"
                                ToolTip="Sets HKCU\SOFTWARE\Microsoft\VisualStudio\Telemetry OptIn=0 to disable VS telemetry."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indVSSvc" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkVSSvc" IsChecked="True"
                                Content="Disable VS Telemetry and PerfWatson services"
                                ToolTip="Stops and disables VSStandardCollectorService150 and PerfWatson2 if present."/>
                        </StackPanel>
                    </StackPanel>
                </GroupBox>
            </StackPanel>
        </ScrollViewer>

        <!-- Console Panel -->
        <Border Grid.Row="2" Background="#010409" BorderBrush="#30363d" BorderThickness="0,1,0,0" Margin="0">
            <DockPanel>
                <Border DockPanel.Dock="Top" Background="#0d1117" Padding="10,5" BorderBrush="#30363d" BorderThickness="0,0,0,1">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text=">" Foreground="#4ade80" FontFamily="Consolas" FontWeight="Bold" FontSize="12" Margin="0,0,6,0"/>
                        <TextBlock Text="Console Output" Foreground="#7ee787" FontFamily="Consolas" FontSize="11.5"/>
                    </StackPanel>
                </Border>
                <TextBox x:Name="txtLog" IsReadOnly="True" Background="Transparent"
                         Foreground="#4ade80" FontFamily="Consolas" FontSize="11"
                         TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"
                         BorderThickness="0" Padding="10,6" Height="190"/>
            </DockPanel>
        </Border>

        <!-- Bottom Bar -->
        <Border Grid.Row="3" Background="#161b22" Padding="12,8" BorderBrush="#30363d" BorderThickness="0,1,0,0">
            <DockPanel>
                <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
                    <Button x:Name="btnUndo" Content="Undo All" Background="#da3633" Margin="0,0,8,0" Padding="16,8"/>
                    <Button x:Name="btnApply" Content="Apply Selected" Margin="0,0,8,0"/>
                    <Button x:Name="btnClose" Content="Close" Background="#21262d" Padding="16,8"/>
                </StackPanel>
                <TextBlock x:Name="txtStatus" Text="Scanning..." Foreground="#8b949e" VerticalAlignment="Center" FontSize="11.5"/>
            </DockPanel>
        </Border>
    </Grid>
</Window>
'@

$window = [System.Windows.Markup.XamlReader]::Parse($xaml)

                try {
                    $brandingIconPath = Join-Path $PSScriptRoot 'icon.ico'
                    if (Test-Path $brandingIconPath) {
                        $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object System.Uri($brandingIconPath)))
                    }
                } catch {
                    [System.Diagnostics.Debug]::WriteLine("TelemetrySlayer icon load failed: $($_.Exception.Message)")
                }
# --- Find controls ---
$txtLog       = $window.FindName('txtLog')
$txtStatus    = $window.FindName('txtStatus')
$btnApply     = $window.FindName('btnApply')
$btnClose     = $window.FindName('btnClose')
$btnUndo      = $window.FindName('btnUndo')
$btnSelectAll = $window.FindName('btnSelectAll')
$btnDeselectAll = $window.FindName('btnDeselectAll')
$btnScan      = $window.FindName('btnScan')
$btnOpenLogs  = $window.FindName('btnOpenLogs')
$chkAllowTelemetry = $window.FindName('chkAllowTelemetry')

# --- Log file setup ---
$script:logFolderPath = Join-Path $env:ProgramData 'TelemetrySlayer\Logs'
try {
    if (-not (Test-Path -LiteralPath $script:logFolderPath)) {
        New-Item -Path $script:logFolderPath -ItemType Directory -Force | Out-Null
    }
} catch { }
$script:currentLogPath = $null

function Start-LogFile {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $script:currentLogPath = Join-Path $script:logFolderPath "$stamp.log"
    try {
        Set-Content -LiteralPath $script:currentLogPath -Value "TelemetrySlayer v1.6.0 - $(Get-Date -Format 'o')" -Encoding UTF8 -ErrorAction Stop
    } catch {
        $script:currentLogPath = $null
    }
}

function Write-LogLine([string]$Line) {
    if ($script:currentLogPath) {
        try {
            Add-Content -LiteralPath $script:currentLogPath -Value $Line -Encoding UTF8 -ErrorAction SilentlyContinue
        } catch { }
    }
}

# All checkboxes
$allCheckboxNames = @(
    'chkDiagTrack','chkDmwAppPush','chkWerSvc','chkPcaSvc','chkDiagSvc','chkDPS',
    'chkCompatAppraiser','chkProgramDataUpdater','chkStartupAppTask','chkProxy',
    'chkConsolidator','chkUsbCeip','chkKernelCeip','chkDiskDiag','chkSmartScreen','chkPcaPatchDb',
    'chkAllowTelemetry','chkAdvertisingID','chkLinguistic','chkTailoredExp','chkFeedback',
    'chkActivityFeed','chkLocationTracking','chkInputPersonalization','chkHandwritingTelemetry',
    'chkInventoryCollector','chkStepsRecorder','chkWiFiSense',
    'chkFirewallCompat','chkFirewallCEIP','chkFirewallDiagTrack','chkIFEO','chkClearETL',
    'chkOfficeTelemetry','chkOfficeFeedback',
    'chkNvidiaSvc','chkNvidiaTasks','chkNvidiaReg',
    'chkEdgeDiag','chkEdgeMetrics','chkEdgeWebView',
    'chkVSTelemetry','chkVSSvc'
)
$allCheckboxes = $allCheckboxNames | ForEach-Object { $window.FindName($_) }

# Indicator name map (checkbox name -> indicator name)
$allIndicatorNames = @(
    'indDiagTrack','indDmwAppPush','indWerSvc','indPcaSvc','indDiagSvc','indDPS',
    'indCompatAppraiser','indProgramDataUpdater','indStartupAppTask','indProxy',
    'indConsolidator','indUsbCeip','indKernelCeip','indDiskDiag','indSmartScreen','indPcaPatchDb',
    'indAllowTelemetry','indAdvertisingID','indLinguistic','indTailoredExp','indFeedback',
    'indActivityFeed','indLocationTracking','indInputPersonalization','indHandwritingTelemetry',
    'indInventoryCollector','indStepsRecorder','indWiFiSense',
    'indFirewallCompat','indFirewallCEIP','indFirewallDiagTrack','indIFEO','indClearETL',
    'indOfficeTelemetry','indOfficeFeedback',
    'indNvidiaSvc','indNvidiaTasks','indNvidiaReg',
    'indEdgeDiag','indEdgeMetrics','indEdgeWebView',
    'indVSTelemetry','indVSSvc'
)
$allIndicators = @{}
foreach ($name in $allIndicatorNames) {
    $allIndicators[$name] = $window.FindName($name)
}

$btnSelectAll.Add_Click({ $allCheckboxes | ForEach-Object { $_.IsChecked = $true }; UpdateSelectedCount })
$btnDeselectAll.Add_Click({ $allCheckboxes | ForEach-Object { $_.IsChecked = $false }; UpdateSelectedCount })
$btnClose.Add_Click({ $window.Close() })
$btnOpenLogs.Add_Click({
    if (Test-Path -LiteralPath $script:logFolderPath) {
        Start-Process explorer.exe -ArgumentList $script:logFolderPath
    } else {
        [System.Windows.MessageBox]::Show("Log folder not found:`n$($script:logFolderPath)", 'TelemetrySlayer', 'OK', 'Information') | Out-Null
    }
})

# --- Update selected count in status bar ---
function UpdateSelectedCount {
    $selected = ($allCheckboxes | Where-Object { $_.IsChecked -eq $true }).Count
    $total = $allCheckboxes.Count
    $appliedText = ''
    if ($script:appliedCount -ge 0) {
        $appliedText = " | $($script:appliedCount) of $total already applied"
    }
    $managedText = ''
    if ($script:managedWarning) {
        $managedText = " | Managed: $($script:managedWarning)"
    }
    $txtStatus.Text = "$selected of $total selected$appliedText$managedText"
    if ($script:managedWarning) {
        $txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#d29922')
    } else {
        $txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#8b949e')
    }
}

# Track applied count from scan
$script:appliedCount = -1
$script:managedWarning = $null

# Hook checkbox changes to update count
foreach ($cb in $allCheckboxes) {
    $cb.Add_Checked({ UpdateSelectedCount })
    $cb.Add_Unchecked({ UpdateSelectedCount })
}

# --- Shared queue for real-time log streaming ---
$script:logQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

# --- Scan queue for status results ---
$script:scanQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

# --- Pre-scan function ---
function RunScan {
    $queue = $script:scanQueue

    $ps = [PowerShell]::Create()
    $ps.Runspace = [RunspaceFactory]::CreateRunspace()
    $ps.Runspace.Open()
    $ps.Runspace.SessionStateProxy.SetVariable('scanQueue', $queue)

    $ps.AddScript({
        function CheckSvc([string]$Name, [string]$IndName) {
            try {
                $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
                if (-not $svc) { $scanQueue.Enqueue("$IndName=N/A"); return }
                if ($svc.StartType -eq 'Disabled') { $scanQueue.Enqueue("$IndName=OFF") }
                else { $scanQueue.Enqueue("$IndName=ON") }
            } catch { $scanQueue.Enqueue("$IndName=N/A") }
        }

        function CheckTask([string]$TaskName, [string]$TaskPath, [string]$IndName) {
            try {
                $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
                if (-not $task) { $scanQueue.Enqueue("$IndName=N/A"); return }
                if ($task.State -eq 'Disabled') { $scanQueue.Enqueue("$IndName=OFF") }
                else { $scanQueue.Enqueue("$IndName=ON") }
            } catch { $scanQueue.Enqueue("$IndName=N/A") }
        }

        function CheckReg([string]$Path, [string]$Name, $ExpectedValue, [string]$IndName) {
            try {
                if (-not (Test-Path $Path)) { $scanQueue.Enqueue("$IndName=ON"); return }
                $val = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
                if ($null -eq $val -or $val.$Name -ne $ExpectedValue) { $scanQueue.Enqueue("$IndName=ON") }
                else { $scanQueue.Enqueue("$IndName=OFF") }
            } catch { $scanQueue.Enqueue("$IndName=ON") }
        }

        function CheckFW([string]$DisplayName, [string]$IndName) {
            try {
                $rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
                if ($rule) { $scanQueue.Enqueue("$IndName=OFF") }
                else { $scanQueue.Enqueue("$IndName=ON") }
            } catch { $scanQueue.Enqueue("$IndName=ON") }
        }

        function GetTelemetrySkuProfile {
            try {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
                $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
                $productName = if ($cv.ProductName) { $cv.ProductName } else { $os.Caption }
                $editionId = if ($cv.EditionID) { $cv.EditionID } else { 'Unknown' }
                $build = if ($cv.CurrentBuildNumber) { $cv.CurrentBuildNumber } else { $os.BuildNumber }
                $displayVersion = if ($cv.DisplayVersion) { $cv.DisplayVersion } elseif ($cv.ReleaseId) { $cv.ReleaseId } else { 'Unknown' }
                $isServer = ($os.ProductType -ne 1) -or ($productName -match 'Server') -or ($editionId -match 'Server')
                $isLTSC = ($productName -match 'LTSC|LTSB') -or ($editionId -match 'EnterpriseS|IoTEnterpriseS')
                $supportsDiagnosticOff = $isServer -or ($editionId -match 'Enterprise|Education') -or ($productName -match 'Enterprise|Education')
                $targetValue = if ($supportsDiagnosticOff) { 0 } else { 1 }
                $reason = if ($supportsDiagnosticOff) {
                    'Diagnostic data off value 0 is supported on this SKU.'
                } else {
                    'Diagnostic data off value 0 is not supported on this SKU; TelemetrySlayer will apply required diagnostic data value 1.'
                }

                return [pscustomobject]@{
                    ProductName = $productName
                    EditionId = $editionId
                    Build = $build
                    DisplayVersion = $displayVersion
                    IsServer = [bool]$isServer
                    IsLTSC = [bool]$isLTSC
                    SupportsDiagnosticOff = [bool]$supportsDiagnosticOff
                    AllowTelemetryValue = $targetValue
                    Summary = "$productName $displayVersion build $build edition $editionId"
                    Reason = $reason
                }
            } catch {
                return [pscustomobject]@{
                    ProductName = 'Unknown Windows'
                    EditionId = 'Unknown'
                    Build = 'Unknown'
                    DisplayVersion = 'Unknown'
                    IsServer = $false
                    IsLTSC = $false
                    SupportsDiagnosticOff = $false
                    AllowTelemetryValue = 1
                    Summary = 'Unknown Windows SKU'
                    Reason = "Windows SKU detection failed; using required diagnostic data value 1. $($_.Exception.Message)"
                }
            }
        }

        $telemetryProfile = GetTelemetrySkuProfile
        $scanQueue.Enqueue('SKU=' + ($telemetryProfile | ConvertTo-Json -Compress))

        $managedInfo = [ordered]@{ IsDomainJoined = $false; IsMdmEnrolled = $false; DomainName = $null }
        try {
            $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
            if ($cs.PartOfDomain) {
                $managedInfo.IsDomainJoined = $true
                $managedInfo.DomainName = $cs.Domain
            }
        } catch { }
        try {
            $mdmPath = 'HKLM:\SOFTWARE\Microsoft\Enrollments'
            if (Test-Path -LiteralPath $mdmPath) {
                $enrollments = @(Get-ChildItem -LiteralPath $mdmPath -ErrorAction SilentlyContinue | Where-Object {
                    $props = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue
                    $props -and $props.ProviderID
                })
                if ($enrollments.Count -gt 0) { $managedInfo.IsMdmEnrolled = $true }
            }
        } catch { }
        $scanQueue.Enqueue('MANAGED=' + ($managedInfo | ConvertTo-Json -Compress))

        # Services
        CheckSvc 'DiagTrack' 'indDiagTrack'
        CheckSvc 'dmwappushservice' 'indDmwAppPush'
        CheckSvc 'WerSvc' 'indWerSvc'
        CheckSvc 'PcaSvc' 'indPcaSvc'
        CheckSvc 'diagsvc' 'indDiagSvc'
        CheckSvc 'DPS' 'indDPS'

        # Scheduled Tasks
        $appExpPath = '\Microsoft\Windows\Application Experience\'
        CheckTask 'Microsoft Compatibility Appraiser' $appExpPath 'indCompatAppraiser'
        CheckTask 'ProgramDataUpdater' $appExpPath 'indProgramDataUpdater'
        CheckTask 'StartupAppTask' $appExpPath 'indStartupAppTask'
        CheckTask 'PcaPatchDbTask' $appExpPath 'indPcaPatchDb'
        CheckTask 'Proxy' '\Microsoft\Windows\Autochk\' 'indProxy'
        CheckTask 'Consolidator' '\Microsoft\Windows\Customer Experience Improvement Program\' 'indConsolidator'
        CheckTask 'UsbCeip' '\Microsoft\Windows\Customer Experience Improvement Program\' 'indUsbCeip'
        CheckTask 'KernelCeipTask' '\Microsoft\Windows\Customer Experience Improvement Program\' 'indKernelCeip'
        CheckTask 'Microsoft-Windows-DiskDiagnosticDataCollector' '\Microsoft\Windows\DiskDiagnostic\' 'indDiskDiag'
        CheckTask 'SmartScreenSpecific' '\Microsoft\Windows\AppID\' 'indSmartScreen'

        # Registry / Policy
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' $telemetryProfile.AllowTelemetryValue 'indAllowTelemetry'
        CheckReg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 'indAdvertisingID'
        CheckReg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput' 'AllowLinguisticDataCollection' 0 'indLinguistic'
        CheckReg 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1 'indTailoredExp'
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 1 'indFeedback'
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0 'indActivityFeed'
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1 'indLocationTracking'
        CheckReg 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1 'indInputPersonalization'
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports' 'PreventHandwritingErrorReports' 1 'indHandwritingTelemetry'
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableInventory' 1 'indInventoryCollector'
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisablePCA' 1 'indStepsRecorder'
        CheckReg 'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' 'AutoConnectAllowedOEM' 0 'indWiFiSense'

        # Firewall
        CheckFW 'TelemetrySlayer - Block CompatTelRunner' 'indFirewallCompat'
        CheckFW 'TelemetrySlayer - Block CEIP wsqmcons' 'indFirewallCEIP'
        CheckFW 'TelemetrySlayer - Block DiagTrack svchost' 'indFirewallDiagTrack'

        # IFEO
        CheckReg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe' 'Debugger' "$env:SystemRoot\System32\taskkill.exe" 'indIFEO'

        # ETL (check if autoLogger is disabled)
        CheckReg 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener' 'Start' 0 'indClearETL'

        # Office
        CheckReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\Common\ClientTelemetry' 'DisableTelemetry' 1 'indOfficeTelemetry'
        CheckReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Feedback' 'Enabled' 0 'indOfficeFeedback'

        # Nvidia
        CheckSvc 'NvTelemetryContainer' 'indNvidiaSvc'
        CheckTask 'NvTmMon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' '\' 'indNvidiaTasks'
        CheckReg 'HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' 'Optimus_EnableTelemetry' 0 'indNvidiaReg'

        # Edge
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'DiagnosticData' 0 'indEdgeDiag'
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'MetricsReportingEnabled' 0 'indEdgeMetrics'
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeWebView' 'DiagnosticData' 0 'indEdgeWebView'

        # Visual Studio
        CheckReg 'HKCU:\SOFTWARE\Microsoft\VisualStudio\Telemetry' 'TurnOffSwitch' 1 'indVSTelemetry'
        CheckSvc 'VSStandardCollectorService150' 'indVSSvc'

        $scanQueue.Enqueue('SCAN_DONE')
    }) | Out-Null

    $handle = $ps.BeginInvoke()

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(50)
    $timer.Add_Tick({
        $msg = $null
        while ($script:scanQueue.TryDequeue([ref]$msg)) {
            if ($msg -eq 'SCAN_DONE') {
                $timer.Stop()
                $ps.EndInvoke($handle)
                $ps.Runspace.Close()
                $ps.Dispose()

                # Count applied items
                $applied = 0
                foreach ($indName in $allIndicatorNames) {
                    $ind = $allIndicators[$indName]
                    if ($ind.Text -eq 'OFF') { $applied++ }
                }
                $script:appliedCount = $applied
                UpdateSelectedCount
                return
            }

            if ($msg -like 'SKU=*') {
                try {
                    $skuProfile = $msg.Substring(4) | ConvertFrom-Json
                    if ($chkAllowTelemetry) {
                        if ($skuProfile.SupportsDiagnosticOff) {
                            $chkAllowTelemetry.Content = 'Set AllowTelemetry to 0 (Diagnostic data off)'
                        } else {
                            $chkAllowTelemetry.Content = 'Set AllowTelemetry to 1 (Required diagnostic data - SKU gated)'
                        }
                        $chkAllowTelemetry.ToolTip = "Detected: $($skuProfile.Summary)`nLTSC: $($skuProfile.IsLTSC)  Server: $($skuProfile.IsServer)`n$($skuProfile.Reason)"
                    }
                } catch {
                    if ($chkAllowTelemetry) {
                        $chkAllowTelemetry.ToolTip = "Windows SKU detection failed: $($_.Exception.Message)"
                    }
                }
                continue
            }

            if ($msg -like 'MANAGED=*') {
                try {
                    $managed = $msg.Substring(8) | ConvertFrom-Json
                    $warnings = @()
                    if ($managed.IsDomainJoined) { $warnings += "Domain: $($managed.DomainName)" }
                    if ($managed.IsMdmEnrolled) { $warnings += 'MDM enrolled' }
                    if ($warnings.Count -gt 0) {
                        $script:managedWarning = $warnings -join ' | '
                        $txtStatus.Text = "Managed environment detected: $($script:managedWarning) - GPO/MDM may override local settings"
                        $txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#d29922')
                    } else {
                        $script:managedWarning = $null
                    }
                } catch { }
                continue
            }

            # Parse: indName=ON/OFF/N/A
            $parts = $msg -split '=', 2
            $indName = $parts[0]
            $state = $parts[1]

            $ind = $allIndicators[$indName]
            if ($ind) {
                if ($state -eq 'OFF') {
                    $ind.Text = 'OFF'
                    $ind.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#4ade80')
                } elseif ($state -eq 'ON') {
                    $ind.Text = 'ON'
                    $ind.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#f85149')
                } else {
                    $ind.Text = 'N/A'
                    $ind.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#6e7681')
                }
            }
        }
    })
    $timer.Start()
}

# Run scan on window load
$window.Add_Loaded({ RunScan })

# Re-scan button
$btnScan.Add_Click({
    # Reset all indicators
    foreach ($indName in $allIndicatorNames) {
        $ind = $allIndicators[$indName]
        if ($ind) {
            $ind.Text = '--'
            $ind.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#6e7681')
        }
    }
    $script:appliedCount = -1
    $txtStatus.Text = 'Scanning...'
    RunScan
})

# --- Main Apply ---
$btnApply.Add_Click({
    $btnApply.IsEnabled = $false
    $btnUndo.IsEnabled = $false
    $txtStatus.Text = 'Applying...'
    $txtLog.Clear()
    Start-LogFile

    # Capture checkbox states on UI thread
    $opts = @{}
    foreach ($cb in $allCheckboxes) {
        $opts[$cb.Name] = $cb.IsChecked
    }

    $queue = $script:logQueue

    $ps = [PowerShell]::Create()
    $ps.Runspace = [RunspaceFactory]::CreateRunspace()
    $ps.Runspace.Open()
    $ps.Runspace.SessionStateProxy.SetVariable('logQueue', $queue)
    $ps.Runspace.SessionStateProxy.SetVariable('opts', $opts)

    $ps.AddScript({
        function Log([string]$msg) {
            $ts = Get-Date -Format 'HH:mm:ss'
            $logQueue.Enqueue("[$ts] $msg")
        }

        function GetTelemetrySkuProfile {
            try {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
                $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
                $productName = if ($cv.ProductName) { $cv.ProductName } else { $os.Caption }
                $editionId = if ($cv.EditionID) { $cv.EditionID } else { 'Unknown' }
                $build = if ($cv.CurrentBuildNumber) { $cv.CurrentBuildNumber } else { $os.BuildNumber }
                $displayVersion = if ($cv.DisplayVersion) { $cv.DisplayVersion } elseif ($cv.ReleaseId) { $cv.ReleaseId } else { 'Unknown' }
                $isServer = ($os.ProductType -ne 1) -or ($productName -match 'Server') -or ($editionId -match 'Server')
                $isLTSC = ($productName -match 'LTSC|LTSB') -or ($editionId -match 'EnterpriseS|IoTEnterpriseS')
                $supportsDiagnosticOff = $isServer -or ($editionId -match 'Enterprise|Education') -or ($productName -match 'Enterprise|Education')
                $targetValue = if ($supportsDiagnosticOff) { 0 } else { 1 }
                $reason = if ($supportsDiagnosticOff) {
                    'Diagnostic data off value 0 is supported on this SKU.'
                } else {
                    'Diagnostic data off value 0 is not supported on this SKU; TelemetrySlayer will apply required diagnostic data value 1.'
                }

                return [pscustomobject]@{
                    ProductName = $productName
                    EditionId = $editionId
                    Build = $build
                    DisplayVersion = $displayVersion
                    IsServer = [bool]$isServer
                    IsLTSC = [bool]$isLTSC
                    SupportsDiagnosticOff = [bool]$supportsDiagnosticOff
                    AllowTelemetryValue = $targetValue
                    Summary = "$productName $displayVersion build $build edition $editionId"
                    Reason = $reason
                }
            } catch {
                return [pscustomobject]@{
                    ProductName = 'Unknown Windows'
                    EditionId = 'Unknown'
                    Build = 'Unknown'
                    DisplayVersion = 'Unknown'
                    IsServer = $false
                    IsLTSC = $false
                    SupportsDiagnosticOff = $false
                    AllowTelemetryValue = 1
                    Summary = 'Unknown Windows SKU'
                    Reason = "Windows SKU detection failed; using required diagnostic data value 1. $($_.Exception.Message)"
                }
            }
        }

        try {
        $programDataRoot = Join-Path $env:ProgramData 'TelemetrySlayer'
        $stateRoot = Join-Path $programDataRoot 'State'
        $backupRoot = Join-Path $programDataRoot 'Backups'
        try {
            if (-not (Test-Path -LiteralPath $programDataRoot)) {
                New-Item -Path $programDataRoot -ItemType Directory -Force | Out-Null
            }
            if (-not (Test-Path -LiteralPath $stateRoot)) {
                New-Item -Path $stateRoot -ItemType Directory -Force | Out-Null
            }
            if (-not (Test-Path -LiteralPath $backupRoot)) {
                New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null
            }
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $restorePath = Join-Path $stateRoot "restore-$stamp.json"
            $latestRestorePath = Join-Path $stateRoot 'restore-latest.json'
            $backupPath = Join-Path $backupRoot "backup-$stamp"
            $registryBackupPath = Join-Path $backupPath 'registry'
            New-Item -Path $registryBackupPath -ItemType Directory -Force | Out-Null
            $restoreBackupPath = Join-Path $backupPath 'restore-snapshot.json'
            $manifestPath = Join-Path $backupPath 'manifest.json'
        } catch {
            Log "  FAIL recovery workspace initialization - $($_.Exception.Message)"
            Log "DONE"
            return
        }

        $backupManifest = [ordered]@{
            SchemaVersion = 1
            ToolVersion = '1.6.0'
            CreatedAt = (Get-Date).ToString('o')
            ComputerName = $env:COMPUTERNAME
            BackupPath = $backupPath
            RestoreSnapshotPath = $restorePath
            RestoreSnapshotBackupPath = $restoreBackupPath
            RegistryExports = @()
            RestorePoint = [ordered]@{
                Attempted = $false
                Succeeded = $false
                Message = $null
            }
        }

        $restore = [ordered]@{
            SchemaVersion = 1
            ToolVersion = '1.6.0'
            CreatedAt = (Get-Date).ToString('o')
            ComputerName = $env:COMPUTERNAME
            Registry = [ordered]@{}
            Services = [ordered]@{}
            Tasks = [ordered]@{}
            Firewall = [ordered]@{}
        }

        function GetStateKey([string]$Category, [string]$Name) {
            return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$Category|$Name"))
        }

        function SaveRestoreState {
            try {
                $json = $restore | ConvertTo-Json -Depth 20
                Set-Content -LiteralPath $restorePath -Value $json -Encoding UTF8 -ErrorAction Stop
                Set-Content -LiteralPath $latestRestorePath -Value $json -Encoding UTF8 -ErrorAction Stop
                Set-Content -LiteralPath $restoreBackupPath -Value $json -Encoding UTF8 -ErrorAction Stop
                return $true
            } catch {
                Log "  WARN restore snapshot save failed - $($_.Exception.Message)"
                return $false
            }
        }

        if (-not (SaveRestoreState)) {
            Log "DONE"
            return
        }
        Log "Restore snapshot: $restorePath"

        function SaveBackupManifest {
            try {
                $json = $backupManifest | ConvertTo-Json -Depth 12
                Set-Content -LiteralPath $manifestPath -Value $json -Encoding UTF8 -ErrorAction Stop
                return $true
            } catch {
                Log "  WARN backup manifest save failed - $($_.Exception.Message)"
                return $false
            }
        }

        function ConvertRegistryProviderPath([string]$Path) {
            if ($Path -match '^HKLM:\\(.+)$') { return "HKLM\$($Matches[1])" }
            if ($Path -match '^HKCU:\\(.+)$') { return "HKCU\$($Matches[1])" }
            return $null
        }

        function GetSafeBackupFileName([string]$Value) {
            return ([regex]::Replace($Value, '[^A-Za-z0-9._-]+', '_')).Trim('_')
        }

        function AddRegistryExportResult([string]$Path, [string]$Status, [string]$FilePath, [string]$Message) {
            $backupManifest.RegistryExports += [ordered]@{
                Path = $Path
                Status = $Status
                FilePath = $FilePath
                Message = $Message
            }
        }

        function ExportRegistryPath([string]$Path) {
            $nativePath = ConvertRegistryProviderPath $Path
            if (-not $nativePath) {
                AddRegistryExportResult $Path 'Skipped' $null 'Unsupported registry hive'
                return
            }

            if (-not (Test-Path -LiteralPath $Path)) {
                AddRegistryExportResult $Path 'Missing' $null 'Registry path did not exist before apply'
                return
            }

            $fileName = (GetSafeBackupFileName $nativePath) + '.reg'
            $filePath = Join-Path $registryBackupPath $fileName
            $regExe = Join-Path $env:SystemRoot 'System32\reg.exe'
            $output = & $regExe export $nativePath $filePath /y 2>&1
            $exitCode = $LASTEXITCODE
            $message = ($output | Out-String).Trim()

            if ($exitCode -eq 0 -and (Test-Path -LiteralPath $filePath)) {
                AddRegistryExportResult $Path 'Exported' $filePath $message
                Log "  Exported registry backup: $Path"
            } else {
                AddRegistryExportResult $Path 'Failed' $filePath $message
                Log "  WARN registry export failed: $Path - $message"
            }
        }

        function TryCreateRestorePoint {
            $backupManifest.RestorePoint.Attempted = $true
            try {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
                if ($os.ProductType -ne 1) {
                    $message = 'System restore points are not supported on this Windows SKU'
                    $backupManifest.RestorePoint.Message = $message
                    Log "  Restore point skipped: $message"
                    return
                }

                Checkpoint-Computer -Description "TelemetrySlayer preflight $stamp" -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
                $backupManifest.RestorePoint.Succeeded = $true
                $backupManifest.RestorePoint.Message = 'Created'
                Log "  Created system restore point"
            } catch {
                $backupManifest.RestorePoint.Message = $_.Exception.Message
                Log "  Restore point unavailable: $($_.Exception.Message)"
            }
        }

        function RunPreflightBackup {
            Log ""
            Log "=== PREFLIGHT BACKUP ==="
            Log "  Backup bundle: $backupPath"

            TryCreateRestorePoint

            $registryTargets = @(
                'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection',
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo',
                'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo',
                'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo',
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput',
                'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization',
                'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent',
                'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent',
                'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy',
                'HKCU:\SOFTWARE\Microsoft\Siuf\Rules',
                'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System',
                'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors',
                'HKCU:\SOFTWARE\Microsoft\InputPersonalization',
                'HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore',
                'HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC',
                'HKCU:\SOFTWARE\Microsoft\Personalization\Settings',
                'HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Preferences',
                'HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports',
                'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat',
                'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config',
                'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots',
                'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting',
                'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe',
                'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener',
                'HKCU:\SOFTWARE\Policies\Microsoft\Office\Common\ClientTelemetry',
                'HKCU:\SOFTWARE\Policies\Microsoft\Office\15.0\osm',
                'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\osm',
                'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Feedback',
                'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common',
                'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Privacy',
                'HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client',
                'HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack',
                'HKLM:\SYSTEM\CurrentControlSet\Services\dmwappushservice',
                'HKLM:\SYSTEM\CurrentControlSet\Services\WerSvc',
                'HKLM:\SYSTEM\CurrentControlSet\Services\PcaSvc',
                'HKLM:\SYSTEM\CurrentControlSet\Services\diagsvc',
                'HKLM:\SYSTEM\CurrentControlSet\Services\DPS',
                'HKLM:\SYSTEM\CurrentControlSet\Services\NvTelemetryContainer',
                'HKLM:\SYSTEM\CurrentControlSet\Services\VSStandardCollectorService150',
                'HKLM:\SOFTWARE\Policies\Microsoft\Edge',
                'HKLM:\SOFTWARE\Policies\Microsoft\EdgeWebView',
                'HKCU:\SOFTWARE\Microsoft\VisualStudio\Telemetry',
                'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback'
            ) | Select-Object -Unique

            foreach ($path in $registryTargets) {
                ExportRegistryPath $path
            }

            if (-not (SaveBackupManifest)) {
                return $false
            }

            $registryExports = @(Get-ChildItem -LiteralPath $registryBackupPath -Filter '*.reg' -ErrorAction SilentlyContinue)
            $hasSnapshot = Test-Path -LiteralPath $restoreBackupPath
            $hasManifest = Test-Path -LiteralPath $manifestPath
            if (-not $hasSnapshot -and -not $hasManifest -and $registryExports.Count -eq 0) {
                Log "  FAIL no recovery artifact could be written; Apply blocked"
                return $false
            }

            Log "  Recovery artifacts ready: $($registryExports.Count) registry exports, manifest=$hasManifest, snapshot=$hasSnapshot"
            return $true
        }

        if (-not (RunPreflightBackup)) {
            Log "DONE"
            return
        }

        function OpenRegistryKeyForRead([string]$Path) {
            if ($Path -match '^HKLM:\\(.+)$') {
                $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Default)
                return $base.OpenSubKey($Matches[1], $false)
            }
            if ($Path -match '^HKCU:\\(.+)$') {
                $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::CurrentUser, [Microsoft.Win32.RegistryView]::Default)
                return $base.OpenSubKey($Matches[1], $false)
            }
            return $null
        }

        function CaptureRegValue([string]$Path, [string]$Name) {
            $id = GetStateKey 'reg' "$Path|$Name"
            if ($restore.Registry.Contains($id)) { return }

            $pathExists = Test-Path -LiteralPath $Path
            $valueExists = $false
            $value = $null
            $kind = $null
            $key = $null

            try {
                $key = OpenRegistryKeyForRead $Path
                if ($key) {
                    $valueNames = @($key.GetValueNames())
                    if ($valueNames -contains $Name) {
                        $valueExists = $true
                        $value = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                        $kind = $key.GetValueKind($Name).ToString()
                    }
                }
            } catch {
                Log "  WARN registry snapshot failed for $Path\$Name - $($_.Exception.Message)"
            } finally {
                if ($key) { $key.Close() }
            }

            $restore.Registry[$id] = [ordered]@{
                Path = $Path
                Name = $Name
                PathExisted = [bool]$pathExists
                ValueExists = [bool]$valueExists
                Kind = $kind
                Value = $value
            }
            SaveRestoreState | Out-Null
        }

        function GetServiceInfo([string]$Name) {
            $filterName = $Name.Replace("'", "''")
            return Get-CimInstance -ClassName Win32_Service -Filter "Name='$filterName'" -ErrorAction SilentlyContinue
        }

        function CaptureSvc([string]$Name) {
            $id = GetStateKey 'svc' $Name
            if ($restore.Services.Contains($id)) { return }

            $svc = GetServiceInfo $Name
            $servicePath = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
            $startValue = $null
            $delayedAutoStart = $null
            if (Test-Path -LiteralPath $servicePath) {
                $serviceProps = Get-ItemProperty -LiteralPath $servicePath -ErrorAction SilentlyContinue
                if ($serviceProps) {
                    $startValue = $serviceProps.Start
                    $delayedAutoStart = $serviceProps.DelayedAutoStart
                }
            }

            $restore.Services[$id] = [ordered]@{
                Name = $Name
                Exists = [bool]($null -ne $svc)
                DisplayName = if ($svc) { $svc.DisplayName } else { $null }
                StartMode = if ($svc) { $svc.StartMode } else { $null }
                State = if ($svc) { $svc.State } else { $null }
                Status = if ($svc) { $svc.Status } else { $null }
                StartValue = $startValue
                DelayedAutoStart = $delayedAutoStart
            }
            SaveRestoreState | Out-Null
        }

        function QuoteProcessArgument([string]$Value) {
            if ($Value -match '[\s"]') {
                return '"' + ($Value -replace '"', '\"') + '"'
            }
            return $Value
        }

        function InvokeSc([string[]]$Arguments, [int]$TimeoutSeconds = 20, [int]$Retries = 1) {
            $scExe = Join-Path $env:SystemRoot 'System32\sc.exe'
            $displayArgs = $Arguments -join ' '

            for ($attempt = 0; $attempt -le $Retries; $attempt++) {
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
                $process.StartInfo.FileName = $scExe
                $process.StartInfo.Arguments = (($Arguments | ForEach-Object { QuoteProcessArgument $_ }) -join ' ')
                $process.StartInfo.UseShellExecute = $false
                $process.StartInfo.RedirectStandardOutput = $true
                $process.StartInfo.RedirectStandardError = $true
                $process.StartInfo.CreateNoWindow = $true

                try {
                    [void]$process.Start()
                    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
                        try { $process.Kill() } catch { Log "  WARN failed to kill timed-out sc.exe - $($_.Exception.Message)" }
                        Log "  WARN sc.exe $displayArgs timed out after ${TimeoutSeconds}s"
                    } else {
                        $stdout = $process.StandardOutput.ReadToEnd()
                        $stderr = $process.StandardError.ReadToEnd()
                        $detail = (($stdout, $stderr) -join ' ').Trim()
                        if ($process.ExitCode -eq 0) { return $true }
                        if ($detail.Length -gt 180) { $detail = $detail.Substring(0, 180) + '...' }
                        Log "  WARN sc.exe $displayArgs exit $($process.ExitCode): $detail"
                    }
                } catch {
                    Log "  WARN sc.exe $displayArgs failed - $($_.Exception.Message)"
                } finally {
                    $process.Dispose()
                }

                if ($attempt -lt $Retries) {
                    Start-Sleep -Milliseconds (500 * ($attempt + 1))
                }
            }

            return $false
        }

        function WaitServiceState([string]$Name, [string]$ExpectedState, [int]$TimeoutSeconds = 20) {
            $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
            do {
                $svc = GetServiceInfo $Name
                if ($svc -and $svc.State -eq $ExpectedState) { return $true }
                Start-Sleep -Milliseconds 500
            } while ((Get-Date) -lt $deadline)
            return $false
        }

        function SetReg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
            try {
                CaptureRegValue $Path $Name
                if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
                New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
                Log "  SET $Path\$Name = $Value"
            } catch { Log "  FAIL $Path\$Name - $($_.Exception.Message)" }
        }

        function DisableSvc([string]$Name, [string]$Display) {
            try {
                CaptureSvc $Name
                $svc = GetServiceInfo $Name
                if ($svc) {
                    if ($svc.State -eq 'Running') {
                        Log "  Stopping service: $Display ($Name)..."
                        InvokeSc @('stop', $Name) 20 2 | Out-Null
                        if (-not (WaitServiceState $Name 'Stopped' 20)) {
                            Log "  WARN service did not stop within timeout: $Display ($Name)"
                        }
                    }
                    if (InvokeSc @('config', $Name, 'start=', 'disabled') 20 2) {
                        Log "  Disabled service: $Display ($Name)"
                    } else {
                        Log "  FAIL service startup change: $Display ($Name)"
                    }
                } else { Log "  Service not found: $Name (OK - may not exist on this edition)" }
            } catch { Log "  FAIL service $Name - $($_.Exception.Message)" }
        }

        function GetExactTask([string]$Name, [string]$TaskPath) {
            try {
                if ($TaskPath) {
                    return Get-ScheduledTask -TaskName $Name -TaskPath $TaskPath -ErrorAction SilentlyContinue
                }
                return Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue | Select-Object -First 1
            } catch {
                return $null
            }
        }

        function CaptureTask([string]$Name, [string]$TaskPath) {
            $id = GetStateKey 'task' "$TaskPath|$Name"
            if ($restore.Tasks.Contains($id)) { return }

            $task = GetExactTask $Name $TaskPath
            $restore.Tasks[$id] = [ordered]@{
                TaskName = $Name
                TaskPath = $TaskPath
                Exists = [bool]($null -ne $task)
                State = if ($task) { $task.State.ToString() } else { $null }
                Enabled = if ($task) { $task.State.ToString() -ne 'Disabled' } else { $false }
            }
            SaveRestoreState | Out-Null
        }

        function DisableTask([string]$Name, [string]$TaskPath) {
            try {
                CaptureTask $Name $TaskPath
                $task = GetExactTask $Name $TaskPath
                if ($task) {
                    Disable-ScheduledTask -TaskName $Name -TaskPath $TaskPath -ErrorAction Stop | Out-Null
                    Log "  Disabled task: $TaskPath$Name"
                } else { Log "  Task not found: $Name (OK)" }
            } catch { Log "  FAIL task $Name - $($_.Exception.Message)" }
        }

        function CaptureFirewallRule([string]$DisplayName) {
            $id = GetStateKey 'fw' $DisplayName
            if ($restore.Firewall.Contains($id)) { return }

            $rules = @(Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue)
            $items = @()
            foreach ($rule in $rules) {
                $app = $null
                $svc = $null
                $port = $null
                $addr = $null
                try { $app = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue | Select-Object -First 1 } catch { Log "  WARN firewall application snapshot failed - $($_.Exception.Message)" }
                try { $svc = Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue | Select-Object -First 1 } catch { Log "  WARN firewall service snapshot failed - $($_.Exception.Message)" }
                try { $port = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue | Select-Object -First 1 } catch { Log "  WARN firewall port snapshot failed - $($_.Exception.Message)" }
                try { $addr = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue | Select-Object -First 1 } catch { Log "  WARN firewall address snapshot failed - $($_.Exception.Message)" }

                $items += [ordered]@{
                    Name = $rule.Name
                    DisplayName = $rule.DisplayName
                    Description = $rule.Description
                    Group = $rule.Group
                    Enabled = $rule.Enabled.ToString()
                    Profile = $rule.Profile.ToString()
                    Direction = $rule.Direction.ToString()
                    Action = $rule.Action.ToString()
                    EdgeTraversalPolicy = $rule.EdgeTraversalPolicy.ToString()
                    Program = if ($app) { $app.Program } else { $null }
                    Service = if ($svc) { $svc.Service } else { $null }
                    Protocol = if ($port) { $port.Protocol } else { $null }
                    LocalPort = if ($port) { $port.LocalPort } else { $null }
                    RemotePort = if ($port) { $port.RemotePort } else { $null }
                    LocalAddress = if ($addr) { $addr.LocalAddress } else { $null }
                    RemoteAddress = if ($addr) { $addr.RemoteAddress } else { $null }
                }
            }

            $restore.Firewall[$id] = [ordered]@{
                DisplayName = $DisplayName
                Rules = $items
            }
            SaveRestoreState | Out-Null
        }

        function AddFW([string]$DisplayName, [string]$Program, [string]$Service) {
            try {
                CaptureFirewallRule $DisplayName
                $existing = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
                if ($existing) { Log "  Firewall rule already exists: $DisplayName"; return }
                $params = @{ DisplayName=$DisplayName; Direction='Outbound'; Action='Block'; Enabled='True'; Group='TelemetrySlayer'; Protocol='TCP'; RemotePort=@(80,443) }
                if ($Program) { $params['Program'] = $Program }
                if ($Service) { $params['Service'] = $Service }
                New-NetFirewallRule @params -ErrorAction Stop | Out-Null
                Log "  Created firewall rule: $DisplayName"
            } catch { Log "  FAIL firewall $DisplayName - $($_.Exception.Message)" }
        }

        # ========================
        #  SERVICES
        # ========================
        $isDomainJoined = $false
        $isMdmEnrolled = $false
        try {
            $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
            if ($cs.PartOfDomain) {
                $isDomainJoined = $true
                Log "WARNING: This machine is joined to domain '$($cs.Domain)'. Domain GPO may override local registry policy changes."
            }
        } catch { }
        try {
            $mdmPath = 'HKLM:\SOFTWARE\Microsoft\Enrollments'
            if (Test-Path -LiteralPath $mdmPath) {
                $enrollments = @(Get-ChildItem -LiteralPath $mdmPath -ErrorAction SilentlyContinue | Where-Object {
                    $props = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue
                    $props -and $props.ProviderID
                })
                if ($enrollments.Count -gt 0) {
                    $isMdmEnrolled = $true
                    Log "WARNING: This machine is MDM-enrolled. MDM policies may override local registry changes."
                }
            }
        } catch { }
        Log ""

        Log "=== SERVICES ==="
        if ($opts['chkDiagTrack'])   { DisableSvc 'DiagTrack' 'Connected User Experiences and Telemetry' }
        if ($opts['chkDmwAppPush'])  { DisableSvc 'dmwappushservice' 'WAP Push Message Routing' }
        if ($opts['chkWerSvc'])      { DisableSvc 'WerSvc' 'Windows Error Reporting' }
        if ($opts['chkPcaSvc'])      { DisableSvc 'PcaSvc' 'Program Compatibility Assistant' }
        if ($opts['chkDiagSvc'])     { DisableSvc 'diagsvc' 'Diagnostic Service Host' }
        if ($opts['chkDPS'])         { DisableSvc 'DPS' 'Diagnostic Policy Service' }

        # ========================
        #  SCHEDULED TASKS
        # ========================
        Log ""
        Log "=== SCHEDULED TASKS ==="
        $appExpPath = '\Microsoft\Windows\Application Experience\'
        if ($opts['chkCompatAppraiser'])   { DisableTask 'Microsoft Compatibility Appraiser' $appExpPath }
        if ($opts['chkProgramDataUpdater']){ DisableTask 'ProgramDataUpdater' $appExpPath }
        if ($opts['chkStartupAppTask'])    { DisableTask 'StartupAppTask' $appExpPath }
        if ($opts['chkPcaPatchDb'])        { DisableTask 'PcaPatchDbTask' $appExpPath }
        if ($opts['chkProxy'])             { DisableTask 'Proxy' '\Microsoft\Windows\Autochk\' }
        if ($opts['chkConsolidator'])      { DisableTask 'Consolidator' '\Microsoft\Windows\Customer Experience Improvement Program\' }
        if ($opts['chkUsbCeip'])           { DisableTask 'UsbCeip' '\Microsoft\Windows\Customer Experience Improvement Program\' }
        if ($opts['chkKernelCeip'])        { DisableTask 'KernelCeipTask' '\Microsoft\Windows\Customer Experience Improvement Program\' }
        if ($opts['chkDiskDiag'])          { DisableTask 'Microsoft-Windows-DiskDiagnosticDataCollector' '\Microsoft\Windows\DiskDiagnostic\' }
        if ($opts['chkSmartScreen'])       { DisableTask 'SmartScreenSpecific' '\Microsoft\Windows\AppID\' }

        # ========================
        #  REGISTRY / POLICY
        # ========================
        Log ""
        Log "=== REGISTRY / POLICY ==="

        if ($opts['chkAllowTelemetry']) {
            $telemetryProfile = GetTelemetrySkuProfile
            $telemetryValue = [int]$telemetryProfile.AllowTelemetryValue
            Log "  Windows SKU: $($telemetryProfile.Summary)"
            Log "  $($telemetryProfile.Reason)"
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' $telemetryValue
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'MaxTelemetryAllowed' $telemetryValue
            SetReg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' $telemetryValue
        }

        if ($opts['chkAdvertisingID']) {
            SetReg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
            SetReg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
        }

        if ($opts['chkLinguistic']) {
            SetReg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput' 'AllowLinguisticDataCollection' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' 'AllowInputPersonalization' 0
        }

        if ($opts['chkTailoredExp']) {
            SetReg 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
            SetReg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0
        }

        if ($opts['chkFeedback']) {
            SetReg 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0
            SetReg 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' 'PeriodInNanoSeconds' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 1
        }

        if ($opts['chkActivityFeed']) {
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 0
        }

        if ($opts['chkLocationTracking']) {
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableWindowsLocationProvider' 1
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocationScripting' 1
        }

        if ($opts['chkInputPersonalization']) {
            SetReg 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1
            SetReg 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1
            SetReg 'HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC' 'PreventHandwritingDataSharing' 1
            SetReg 'HKCU:\SOFTWARE\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 0
            SetReg 'HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Preferences' 'ModelDownloadAllowed' 0
        }

        if ($opts['chkHandwritingTelemetry']) {
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports' 'PreventHandwritingErrorReports' 1
        }

        if ($opts['chkInventoryCollector']) {
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableInventory' 1
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'AITEnable' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableUAR' 1
        }

        if ($opts['chkStepsRecorder']) {
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisablePCA' 1
        }

        if ($opts['chkWiFiSense']) {
            SetReg 'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' 'AutoConnectAllowedOEM' 0
            SetReg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' 'value' 0
            SetReg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' 'value' 0
        }

        # ========================
        #  FIREWALL RULES
        # ========================
        Log ""
        Log "=== FIREWALL ==="
        if ($opts['chkFirewallCompat']) {
            AddFW 'TelemetrySlayer - Block CompatTelRunner' "$env:SystemRoot\System32\CompatTelRunner.exe" $null
        }
        if ($opts['chkFirewallCEIP']) {
            AddFW 'TelemetrySlayer - Block CEIP wsqmcons' "$env:SystemRoot\System32\wsqmcons.exe" $null
        }
        if ($opts['chkFirewallDiagTrack']) {
            AddFW 'TelemetrySlayer - Block DiagTrack svchost' "$env:SystemRoot\System32\svchost.exe" 'DiagTrack'
        }

        # ========================
        #  IFEO (Image File Execution Options)
        # ========================
        Log ""
        Log "=== HARDENING ==="
        if ($opts['chkIFEO']) {
            SetReg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe' 'Debugger' "$env:SystemRoot\System32\taskkill.exe" 'String'
            Log "  IFEO set: CompatTelRunner.exe will be killed on launch"
        }

        # ========================
        #  CLEAR ETL LOGS
        # ========================
        if ($opts['chkClearETL']) {
            $etlPath = "$env:ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl"
            try {
                if (Test-Path $etlPath) {
                    & logman stop "AutoLogger-Diagtrack-Listener" -ets 2>$null
                    [System.IO.File]::WriteAllText($etlPath, '')
                    Log "  Cleared ETL log: $etlPath"
                } else {
                    Log "  ETL log not found (OK)"
                }
                SetReg 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener' 'Start' 0
            } catch { Log "  FAIL clearing ETL - $($_.Exception.Message)" }
        }

        # ========================
        #  OFFICE TELEMETRY
        # ========================
        if ($opts['chkOfficeTelemetry'] -or $opts['chkOfficeFeedback']) {
            Log ""
            Log "=== OFFICE TELEMETRY ==="
        }

        if ($opts['chkOfficeTelemetry']) {
            foreach ($ver in @('15.0','16.0')) {
                SetReg "HKCU:\SOFTWARE\Policies\Microsoft\Office\$ver\osm" 'Enablelogging' 0
                SetReg "HKCU:\SOFTWARE\Policies\Microsoft\Office\$ver\osm" 'EnableUpload' 0
            }
            SetReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\Common\ClientTelemetry' 'DisableTelemetry' 1
            SetReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\Common\ClientTelemetry' 'SendTelemetry' 3
        }

        if ($opts['chkOfficeFeedback']) {
            SetReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Feedback' 'Enabled' 0
            SetReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Feedback' 'SurveyEnabled' 0
            SetReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common' 'sendcustomerdata' 0
            SetReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Privacy' 'DisconnectedState' 2
            SetReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Privacy' 'ControllerConnectedServicesEnabled' 2
        }

        # ========================
        #  NVIDIA TELEMETRY
        # ========================
        if ($opts['chkNvidiaSvc'] -or $opts['chkNvidiaTasks'] -or $opts['chkNvidiaReg']) {
            Log ""
            Log "=== NVIDIA TELEMETRY ==="
        }

        if ($opts['chkNvidiaSvc']) {
            DisableSvc 'NvTelemetryContainer' 'Nvidia Telemetry Container'
        }

        if ($opts['chkNvidiaTasks']) {
            $nvTaskPath = '\'
            foreach ($taskName in @('NvTmMon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}',
                                     'NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}',
                                     'NvProfileUpdaterDaily_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}',
                                     'NvProfileUpdaterOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}')) {
                DisableTask $taskName $nvTaskPath
            }
        }

        if ($opts['chkNvidiaReg']) {
            SetReg 'HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' 'Optimus_EnableTelemetry' 0
            SetReg 'HKLM:\SYSTEM\CurrentControlSet\Services\NvTelemetryContainer' 'Start' 4
        }

        # ========================
        #  EDGE TELEMETRY
        # ========================
        if ($opts['chkEdgeDiag'] -or $opts['chkEdgeMetrics']) {
            Log ""
            Log "=== EDGE TELEMETRY ==="
        }

        if ($opts['chkEdgeDiag']) {
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'DiagnosticData' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'PersonalizationReportingEnabled' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'UserFeedbackAllowed' 0
        }

        if ($opts['chkEdgeMetrics']) {
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'MetricsReportingEnabled' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'SendSiteInfoToImproveServices' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'CopilotPageContext' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'CopilotCDPPageContext' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'DiscoverPageContextEnabled' 0
        }

        if ($opts['chkEdgeWebView']) {
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeWebView' 'DiagnosticData' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeWebView' 'MetricsReportingEnabled' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeWebView' 'PersonalizationReportingEnabled' 0
        }

        # ========================
        #  VISUAL STUDIO TELEMETRY
        # ========================
        if ($opts['chkVSTelemetry'] -or $opts['chkVSSvc']) {
            Log ""
            Log "=== VISUAL STUDIO TELEMETRY ==="
        }

        if ($opts['chkVSTelemetry']) {
            SetReg 'HKCU:\SOFTWARE\Microsoft\VisualStudio\Telemetry' 'TurnOffSwitch' 1
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableFeedbackDialog' 1
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableEmailInput' 1
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableScreenshotCapture' 1
        }

        if ($opts['chkVSSvc']) {
            DisableSvc 'VSStandardCollectorService150' 'VS Standard Collector Service'
            # PerfWatson2 is a process, kill it via IFEO if running
            try {
                $pw = Get-Process -Name 'PerfWatson2' -ErrorAction SilentlyContinue
                if ($pw) {
                    Stop-Process -Name 'PerfWatson2' -Force -ErrorAction SilentlyContinue
                    Log "  Killed PerfWatson2 process"
                }
            } catch { Log "  PerfWatson2 not running (OK)" }
        }

        # ========================
        #  FORCE GP UPDATE
        # ========================
        Log ""
        Log "=== FINALIZING ==="
        try {
            Log "  Running gpupdate /force..."
            & gpupdate.exe /force 2>$null | Out-Null
            Log "  Group Policy updated"
        } catch { Log "  gpupdate skipped" }

        SaveRestoreState | Out-Null
        Log ""
        Log "=== COMPLETE ==="
        $count = ($opts.Values | Where-Object { $_ -eq $true }).Count
        Log "Applied $count items successfully. A restart is recommended."
        Log "DONE"

        } catch {
            $logQueue.Enqueue("[$(Get-Date -Format 'HH:mm:ss')] FATAL unhandled exception in Apply worker: $($_.Exception.GetType().FullName)")
            $logQueue.Enqueue("[$(Get-Date -Format 'HH:mm:ss')]   $($_.Exception.Message)")
            $logQueue.Enqueue("[$(Get-Date -Format 'HH:mm:ss')]   at $($_.InvocationInfo.PositionMessage)")
            $logQueue.Enqueue("[$(Get-Date -Format 'HH:mm:ss')] DONE")
        }
    }) | Out-Null

    $handle = $ps.BeginInvoke()

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $timer.Add_Tick({
        $msg = $null
        while ($script:logQueue.TryDequeue([ref]$msg)) {
            $txtLog.AppendText("$msg`r`n")
            $txtLog.ScrollToEnd()
            Write-LogLine $msg

            if ($msg -match 'DONE$') {
                $timer.Stop()
                $ps.EndInvoke($handle)
                $ps.Runspace.Close()
                $ps.Dispose()
                $btnApply.IsEnabled = $true
                $btnUndo.IsEnabled = $true
                $txtStatus.Text = 'Complete - Restart recommended'
                $txtStatus.Foreground = [System.Windows.Media.Brushes]::LightGreen
                # Re-scan after apply
                RunScan
                return
            }
        }
    })
    $timer.Start()
})

# --- Undo All ---
$btnUndo.Add_Click({
    $btnApply.IsEnabled = $false
    $btnUndo.IsEnabled = $false
    $txtStatus.Text = 'Undoing all changes...'
    $txtLog.Clear()
    Start-LogFile

    $queue = $script:logQueue

    $ps = [PowerShell]::Create()
    $ps.Runspace = [RunspaceFactory]::CreateRunspace()
    $ps.Runspace.Open()
    $ps.Runspace.SessionStateProxy.SetVariable('logQueue', $queue)

    $ps.AddScript({
        function Log([string]$msg) {
            $ts = Get-Date -Format 'HH:mm:ss'
            $logQueue.Enqueue("[$ts] $msg")
        }

        try {
        $stateRoot = Join-Path $env:ProgramData 'TelemetrySlayer\State'
        $latestRestorePath = Join-Path $stateRoot 'restore-latest.json'
        if (-not (Test-Path -LiteralPath $latestRestorePath)) {
            Log "No restore snapshot found at $latestRestorePath. Run Apply once before exact Undo."
            Log "DONE"
            return
        }

        try {
            $restore = Get-Content -LiteralPath $latestRestorePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            Log "Using restore snapshot from $($restore.CreatedAt)"
        } catch {
            Log "  FAIL reading restore snapshot - $($_.Exception.Message)"
            Log "DONE"
            return
        }

        function GetObjectProperties($Object) {
            if ($null -eq $Object) { return @() }
            return @($Object.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' })
        }

        function ConvertJsonValueForRegistry($Value, [string]$Kind) {
            if ($null -eq $Value) { return $null }
            switch ($Kind) {
                'DWord' { return [int]$Value }
                'QWord' { return [long]$Value }
                'Binary' { return [byte[]]@($Value) }
                'MultiString' { return [string[]]@($Value) }
                default { return $Value }
            }
        }

        function TestRegistryKeyEmpty([string]$Path) {
            try {
                if (-not (Test-Path -LiteralPath $Path)) { return $false }
                $props = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
                $realProps = @($props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' })
                $children = @(Get-ChildItem -LiteralPath $Path -ErrorAction SilentlyContinue)
                return ($realProps.Count -eq 0 -and $children.Count -eq 0)
            } catch {
                return $false
            }
        }

        function RestoreRegValue($Item, [hashtable]$CreatedPaths) {
            try {
                if (-not [bool]$Item.PathExisted) {
                    $CreatedPaths[$Item.Path] = $true
                }

                if ([bool]$Item.ValueExists) {
                    if (-not (Test-Path -LiteralPath $Item.Path)) {
                        New-Item -Path $Item.Path -Force | Out-Null
                    }
                    $value = ConvertJsonValueForRegistry $Item.Value $Item.Kind
                    if ($Item.Kind) {
                        New-ItemProperty -LiteralPath $Item.Path -Name $Item.Name -Value $value -PropertyType $Item.Kind -Force -ErrorAction Stop | Out-Null
                    } else {
                        Set-ItemProperty -LiteralPath $Item.Path -Name $Item.Name -Value $value -Force -ErrorAction Stop
                    }
                    Log "  RESTORE $($Item.Path)\$($Item.Name)"
                } else {
                    if (Test-Path -LiteralPath $Item.Path) {
                        $props = Get-ItemProperty -LiteralPath $Item.Path -ErrorAction SilentlyContinue
                        $prop = $null
                        if ($props) {
                            $prop = $props.PSObject.Properties | Where-Object { $_.Name -eq $Item.Name } | Select-Object -First 1
                        }
                        if ($prop) {
                            Remove-ItemProperty -LiteralPath $Item.Path -Name $Item.Name -Force -ErrorAction Stop
                            Log "  RESTORE absent $($Item.Path)\$($Item.Name)"
                        }
                    }
                }
            } catch {
                Log "  FAIL restore registry $($Item.Path)\$($Item.Name) - $($_.Exception.Message)"
            }
        }

        function QuoteProcessArgument([string]$Value) {
            if ($Value -match '[\s"]') {
                return '"' + ($Value -replace '"', '\"') + '"'
            }
            return $Value
        }

        function InvokeSc([string[]]$Arguments, [int]$TimeoutSeconds = 20, [int]$Retries = 1) {
            $scExe = Join-Path $env:SystemRoot 'System32\sc.exe'
            $displayArgs = $Arguments -join ' '

            for ($attempt = 0; $attempt -le $Retries; $attempt++) {
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
                $process.StartInfo.FileName = $scExe
                $process.StartInfo.Arguments = (($Arguments | ForEach-Object { QuoteProcessArgument $_ }) -join ' ')
                $process.StartInfo.UseShellExecute = $false
                $process.StartInfo.RedirectStandardOutput = $true
                $process.StartInfo.RedirectStandardError = $true
                $process.StartInfo.CreateNoWindow = $true

                try {
                    [void]$process.Start()
                    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
                        try { $process.Kill() } catch { Log "  WARN failed to kill timed-out sc.exe - $($_.Exception.Message)" }
                        Log "  WARN sc.exe $displayArgs timed out after ${TimeoutSeconds}s"
                    } else {
                        $stdout = $process.StandardOutput.ReadToEnd()
                        $stderr = $process.StandardError.ReadToEnd()
                        $detail = (($stdout, $stderr) -join ' ').Trim()
                        if ($process.ExitCode -eq 0) { return $true }
                        if ($detail.Length -gt 180) { $detail = $detail.Substring(0, 180) + '...' }
                        Log "  WARN sc.exe $displayArgs exit $($process.ExitCode): $detail"
                    }
                } catch {
                    Log "  WARN sc.exe $displayArgs failed - $($_.Exception.Message)"
                } finally {
                    $process.Dispose()
                }

                if ($attempt -lt $Retries) {
                    Start-Sleep -Milliseconds (500 * ($attempt + 1))
                }
            }

            return $false
        }

        function GetServiceInfo([string]$Name) {
            $filterName = $Name.Replace("'", "''")
            return Get-CimInstance -ClassName Win32_Service -Filter "Name='$filterName'" -ErrorAction SilentlyContinue
        }

        function WaitServiceState([string]$Name, [string]$ExpectedState, [int]$TimeoutSeconds = 20) {
            $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
            do {
                $svc = GetServiceInfo $Name
                if ($svc -and $svc.State -eq $ExpectedState) { return $true }
                Start-Sleep -Milliseconds 500
            } while ((Get-Date) -lt $deadline)
            return $false
        }

        function GetScStartArgument($Item) {
            if ($null -ne $Item.StartValue) {
                switch ([int]$Item.StartValue) {
                    2 { return 'auto' }
                    3 { return 'demand' }
                    4 { return 'disabled' }
                }
            }

            switch ($Item.StartMode) {
                'Auto' { return 'auto' }
                'Manual' { return 'demand' }
                'Disabled' { return 'disabled' }
            }

            return $null
        }

        function RestoreSvc($Item) {
            if (-not [bool]$Item.Exists) {
                Log "  Service absent before apply: $($Item.Name)"
                return
            }

            try {
                $startArg = GetScStartArgument $Item
                if ($startArg) {
                    InvokeSc @('config', $Item.Name, 'start=', $startArg) 20 2 | Out-Null
                }

                $servicePath = "HKLM:\SYSTEM\CurrentControlSet\Services\$($Item.Name)"
                if (Test-Path -LiteralPath $servicePath) {
                    if ($null -ne $Item.DelayedAutoStart) {
                        New-ItemProperty -LiteralPath $servicePath -Name 'DelayedAutoStart' -Value ([int]$Item.DelayedAutoStart) -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
                    } else {
                        Remove-ItemProperty -LiteralPath $servicePath -Name 'DelayedAutoStart' -Force -ErrorAction SilentlyContinue
                    }
                }

                $current = GetServiceInfo $Item.Name
                if ($Item.State -eq 'Running') {
                    if (-not $current -or $current.State -ne 'Running') {
                        InvokeSc @('start', $Item.Name) 20 2 | Out-Null
                        WaitServiceState $Item.Name 'Running' 20 | Out-Null
                    }
                } elseif ($current -and $current.State -eq 'Running') {
                    InvokeSc @('stop', $Item.Name) 20 2 | Out-Null
                    WaitServiceState $Item.Name 'Stopped' 20 | Out-Null
                }

                Log "  Restored service: $($Item.Name) startup=$($Item.StartMode) state=$($Item.State)"
            } catch {
                Log "  FAIL restore service $($Item.Name) - $($_.Exception.Message)"
            }
        }

        function GetExactTask([string]$Name, [string]$TaskPath) {
            try {
                return Get-ScheduledTask -TaskName $Name -TaskPath $TaskPath -ErrorAction SilentlyContinue
            } catch {
                return $null
            }
        }

        function RestoreTask($Item) {
            if (-not [bool]$Item.Exists) {
                Log "  Task absent before apply: $($Item.TaskPath)$($Item.TaskName)"
                return
            }

            try {
                $task = GetExactTask $Item.TaskName $Item.TaskPath
                if (-not $task) {
                    Log "  FAIL restore task missing: $($Item.TaskPath)$($Item.TaskName)"
                    return
                }

                if ([bool]$Item.Enabled) {
                    Enable-ScheduledTask -TaskName $Item.TaskName -TaskPath $Item.TaskPath -ErrorAction Stop | Out-Null
                    Log "  Restored task enabled: $($Item.TaskPath)$($Item.TaskName)"
                } else {
                    Disable-ScheduledTask -TaskName $Item.TaskName -TaskPath $Item.TaskPath -ErrorAction Stop | Out-Null
                    Log "  Restored task disabled: $($Item.TaskPath)$($Item.TaskName)"
                }
            } catch {
                Log "  FAIL restore task $($Item.TaskPath)$($Item.TaskName) - $($_.Exception.Message)"
            }
        }

        function AddFirewallRuleFromSnapshot($Rule) {
            $params = @{
                Name = $Rule.Name
                DisplayName = $Rule.DisplayName
                Direction = $Rule.Direction
                Action = $Rule.Action
                Enabled = $Rule.Enabled
                Profile = $Rule.Profile
            }
            if ($Rule.Description) { $params['Description'] = $Rule.Description }
            if ($Rule.Group) { $params['Group'] = $Rule.Group }
            if ($Rule.EdgeTraversalPolicy -and $Rule.EdgeTraversalPolicy -ne 'Any') { $params['EdgeTraversalPolicy'] = $Rule.EdgeTraversalPolicy }
            if ($Rule.Program -and $Rule.Program -ne 'Any') { $params['Program'] = $Rule.Program }
            if ($Rule.Service -and $Rule.Service -ne 'Any') { $params['Service'] = $Rule.Service }
            if ($Rule.Protocol -and $Rule.Protocol -ne 'Any') { $params['Protocol'] = $Rule.Protocol }
            if ($Rule.LocalPort -and $Rule.LocalPort -ne 'Any') { $params['LocalPort'] = $Rule.LocalPort }
            if ($Rule.RemotePort -and $Rule.RemotePort -ne 'Any') { $params['RemotePort'] = $Rule.RemotePort }
            if ($Rule.LocalAddress -and $Rule.LocalAddress -ne 'Any') { $params['LocalAddress'] = $Rule.LocalAddress }
            if ($Rule.RemoteAddress -and $Rule.RemoteAddress -ne 'Any') { $params['RemoteAddress'] = $Rule.RemoteAddress }

            New-NetFirewallRule @params -ErrorAction Stop | Out-Null
        }

        function RestoreFirewallBaseline($Baseline) {
            try {
                $displayName = $Baseline.DisplayName
                $ruleSnapshots = @()
                if ($Baseline.Rules) { $ruleSnapshots = @($Baseline.Rules) }
                $baselineNames = @($ruleSnapshots | ForEach-Object { $_.Name })
                $current = @(Get-NetFirewallRule -DisplayName $displayName -ErrorAction SilentlyContinue)

                foreach ($rule in $current) {
                    if ($baselineNames -notcontains $rule.Name) {
                        Remove-NetFirewallRule -Name $rule.Name -ErrorAction Stop
                        Log "  Removed added firewall rule: $displayName"
                    }
                }

                foreach ($ruleSnapshot in $ruleSnapshots) {
                    $existing = Get-NetFirewallRule -Name $ruleSnapshot.Name -ErrorAction SilentlyContinue
                    if (-not $existing) {
                        AddFirewallRuleFromSnapshot $ruleSnapshot
                        Log "  Recreated firewall rule: $($ruleSnapshot.DisplayName)"
                    }
                }

                if ($ruleSnapshots.Count -eq 0 -and $current.Count -eq 0) {
                    Log "  Firewall baseline already absent: $displayName"
                } elseif ($ruleSnapshots.Count -gt 0) {
                    Log "  Preserved firewall baseline: $displayName"
                }
            } catch {
                Log "  FAIL restore firewall $($Baseline.DisplayName) - $($_.Exception.Message)"
            }
        }

        Log "=== RESTORING REGISTRY VALUES ==="
        $createdRegistryPaths = @{}
        foreach ($prop in (GetObjectProperties $restore.Registry)) {
            RestoreRegValue $prop.Value $createdRegistryPaths
        }
        foreach ($path in ($createdRegistryPaths.Keys | Sort-Object { $_.Length } -Descending)) {
            if (TestRegistryKeyEmpty $path) {
                try {
                    Remove-Item -LiteralPath $path -Force -ErrorAction Stop
                    Log "  Removed empty created key: $path"
                } catch {
                    Log "  WARN could not remove created key $path - $($_.Exception.Message)"
                }
            }
        }

        Log ""
        Log "=== RESTORING FIREWALL RULES ==="
        $firewallProps = GetObjectProperties $restore.Firewall
        if ($firewallProps.Count -eq 0) { Log "  No firewall changes captured" }
        foreach ($prop in $firewallProps) {
            RestoreFirewallBaseline $prop.Value
        }

        Log ""
        Log "=== RESTORING SCHEDULED TASKS ==="
        $taskProps = GetObjectProperties $restore.Tasks
        if ($taskProps.Count -eq 0) { Log "  No scheduled task changes captured" }
        foreach ($prop in $taskProps) {
            RestoreTask $prop.Value
        }

        Log ""
        Log "=== RESTORING SERVICES ==="
        $serviceProps = GetObjectProperties $restore.Services
        if ($serviceProps.Count -eq 0) { Log "  No service changes captured" }
        foreach ($prop in $serviceProps) {
            RestoreSvc $prop.Value
        }

        # ========================
        #  FORCE GP UPDATE
        # ========================
        Log ""
        Log "=== FINALIZING ==="
        try {
            Log "  Running gpupdate /force..."
            & gpupdate.exe /force 2>$null | Out-Null
            Log "  Group Policy updated"
        } catch { Log "  gpupdate skipped" }

        Log ""
        Log "=== UNDO COMPLETE ==="
        Log "All TelemetrySlayer changes have been reversed. A restart is recommended."
        Log "DONE"

        } catch {
            $logQueue.Enqueue("[$(Get-Date -Format 'HH:mm:ss')] FATAL unhandled exception in Undo worker: $($_.Exception.GetType().FullName)")
            $logQueue.Enqueue("[$(Get-Date -Format 'HH:mm:ss')]   $($_.Exception.Message)")
            $logQueue.Enqueue("[$(Get-Date -Format 'HH:mm:ss')]   at $($_.InvocationInfo.PositionMessage)")
            $logQueue.Enqueue("[$(Get-Date -Format 'HH:mm:ss')] DONE")
        }
    }) | Out-Null

    $handle = $ps.BeginInvoke()

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $timer.Add_Tick({
        $msg = $null
        while ($script:logQueue.TryDequeue([ref]$msg)) {
            $txtLog.AppendText("$msg`r`n")
            $txtLog.ScrollToEnd()
            Write-LogLine $msg

            if ($msg -match 'DONE$') {
                $timer.Stop()
                $ps.EndInvoke($handle)
                $ps.Runspace.Close()
                $ps.Dispose()
                $btnApply.IsEnabled = $true
                $btnUndo.IsEnabled = $true
                $txtStatus.Text = 'Undo complete - Restart recommended'
                $txtStatus.Foreground = [System.Windows.Media.Brushes]::LightGreen
                # Re-scan after undo
                RunScan
                return
            }
        }
    })
    $timer.Start()
})

$window.ShowDialog() | Out-Null
