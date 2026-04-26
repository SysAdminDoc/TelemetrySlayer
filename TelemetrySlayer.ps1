#Requires -Version 5.1
# TelemetrySlayer v1.1.0
# Disables Microsoft telemetry, data collection, and related bloat on Windows 10/11

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
        Title="TelemetrySlayer v1.1.0" Width="820" Height="750"
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
                    <Button x:Name="btnScan" Content="Re-Scan Status" FontSize="11" Padding="10,4" Background="#21262d"/>
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
                                Content="Disable Edge Diagnostic Data collection"
                                ToolTip="Sets DiagnosticData=0 and PersonalizationReportingEnabled=0 under Edge policies."/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock x:Name="indEdgeMetrics" Text="--" Width="26" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                            <CheckBox x:Name="chkEdgeMetrics" IsChecked="True"
                                Content="Disable Edge Metrics and Site Info reporting"
                                ToolTip="Sets MetricsReportingEnabled=0 and SendSiteInfoToImproveServices=0 under Edge policies."/>
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

# codex-branding:start
                try {
                    $brandingIconPath = Join-Path $PSScriptRoot 'icon.ico'
                    if (Test-Path $brandingIconPath) {
                        $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object System.Uri($brandingIconPath)))
                    }
                } catch {
                }
                # codex-branding:end
# --- Find controls ---
$txtLog       = $window.FindName('txtLog')
$txtStatus    = $window.FindName('txtStatus')
$btnApply     = $window.FindName('btnApply')
$btnClose     = $window.FindName('btnClose')
$btnUndo      = $window.FindName('btnUndo')
$btnSelectAll = $window.FindName('btnSelectAll')
$btnDeselectAll = $window.FindName('btnDeselectAll')
$btnScan      = $window.FindName('btnScan')

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
    'chkEdgeDiag','chkEdgeMetrics',
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
    'indEdgeDiag','indEdgeMetrics',
    'indVSTelemetry','indVSSvc'
)
$allIndicators = @{}
foreach ($name in $allIndicatorNames) {
    $allIndicators[$name] = $window.FindName($name)
}

$btnSelectAll.Add_Click({ $allCheckboxes | ForEach-Object { $_.IsChecked = $true }; UpdateSelectedCount })
$btnDeselectAll.Add_Click({ $allCheckboxes | ForEach-Object { $_.IsChecked = $false }; UpdateSelectedCount })
$btnClose.Add_Click({ $window.Close() })

# --- Update selected count in status bar ---
function UpdateSelectedCount {
    $selected = ($allCheckboxes | Where-Object { $_.IsChecked -eq $true }).Count
    $total = $allCheckboxes.Count
    $appliedText = ''
    if ($script:appliedCount -ge 0) {
        $appliedText = " | $($script:appliedCount) of $total already applied"
    }
    $txtStatus.Text = "$selected of $total selected$appliedText"
    $txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#8b949e')
}

# Track applied count from scan
$script:appliedCount = -1

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

        function CheckTask([string]$TaskName, [string]$IndName) {
            try {
                $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
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

        # Services
        CheckSvc 'DiagTrack' 'indDiagTrack'
        CheckSvc 'dmwappushservice' 'indDmwAppPush'
        CheckSvc 'WerSvc' 'indWerSvc'
        CheckSvc 'PcaSvc' 'indPcaSvc'
        CheckSvc 'diagsvc' 'indDiagSvc'
        CheckSvc 'DPS' 'indDPS'

        # Scheduled Tasks
        CheckTask 'Microsoft Compatibility Appraiser' 'indCompatAppraiser'
        CheckTask 'ProgramDataUpdater' 'indProgramDataUpdater'
        CheckTask 'StartupAppTask' 'indStartupAppTask'
        CheckTask 'Proxy' 'indProxy'
        CheckTask 'Consolidator' 'indConsolidator'
        CheckTask 'UsbCeip' 'indUsbCeip'
        CheckTask 'KernelCeipTask' 'indKernelCeip'
        CheckTask 'Microsoft-Windows-DiskDiagnosticDataCollector' 'indDiskDiag'
        CheckTask 'SmartScreenSpecific' 'indSmartScreen'
        CheckTask 'PcaPatchDbTask' 'indPcaPatchDb'

        # Registry / Policy
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 'indAllowTelemetry'
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
        CheckTask 'NvTmMon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' 'indNvidiaTasks'
        CheckReg 'HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' 'Optimus_EnableTelemetry' 0 'indNvidiaReg'

        # Edge
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'DiagnosticData' 0 'indEdgeDiag'
        CheckReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'MetricsReportingEnabled' 0 'indEdgeMetrics'

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
                $total = $allIndicatorNames.Count
                foreach ($indName in $allIndicatorNames) {
                    $ind = $allIndicators[$indName]
                    if ($ind.Text -eq 'OFF') { $applied++ }
                }
                $script:appliedCount = $applied
                UpdateSelectedCount
                return
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

        function SetReg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
            try {
                if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
                Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type -Force
                Log "  SET $Path\$Name = $Value"
            } catch { Log "  FAIL $Path\$Name - $($_.Exception.Message)" }
        }

        function DisableSvc([string]$Name, [string]$Display) {
            try {
                $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
                if ($svc) {
                    if ($svc.Status -eq 'Running') {
                        Log "  Stopping service: $Display ($Name)..."
                        Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
                    }
                    Set-Service -Name $Name -StartupType Disabled -ErrorAction Stop
                    Log "  Disabled service: $Display ($Name)"
                } else { Log "  Service not found: $Name (OK - may not exist on this edition)" }
            } catch { Log "  FAIL service $Name - $($_.Exception.Message)" }
        }

        function DisableTask([string]$Name, [string]$TaskPath) {
            try {
                $task = Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
                if ($task) {
                    Disable-ScheduledTask -TaskName $Name -TaskPath $TaskPath -ErrorAction Stop | Out-Null
                    Log "  Disabled task: $Name"
                } else { Log "  Task not found: $Name (OK)" }
            } catch { Log "  FAIL task $Name - $($_.Exception.Message)" }
        }

        function AddFW([string]$DisplayName, [string]$Program, [string]$Service) {
            try {
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
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'MaxTelemetryAllowed' 0
            SetReg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 0
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
                try {
                    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                    if ($task) {
                        Disable-ScheduledTask -TaskName $taskName -ErrorAction Stop | Out-Null
                        Log "  Disabled task: $taskName"
                    } else { Log "  Task not found: $taskName (OK)" }
                } catch { Log "  FAIL task $taskName - $($_.Exception.Message)" }
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
        }

        if ($opts['chkEdgeMetrics']) {
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'MetricsReportingEnabled' 0
            SetReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'SendSiteInfoToImproveServices' 0
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

        Log ""
        Log "=== COMPLETE ==="
        $count = ($opts.Values | Where-Object { $_ -eq $true }).Count
        Log "Applied $count items successfully. A restart is recommended."
        Log "DONE"

    }) | Out-Null

    $handle = $ps.BeginInvoke()

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $timer.Add_Tick({
        # Drain all queued messages to the console
        $msg = $null
        while ($script:logQueue.TryDequeue([ref]$msg)) {
            $txtLog.AppendText("$msg`r`n")
            $txtLog.ScrollToEnd()

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

        function DelReg([string]$Path, [string]$Name) {
            try {
                if (Test-Path $Path) {
                    $val = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
                    if ($null -ne $val -and $null -ne $val.$Name) {
                        Remove-ItemProperty -LiteralPath $Path -Name $Name -Force -ErrorAction Stop
                        Log "  DEL $Path\$Name"
                    }
                }
            } catch { Log "  FAIL del $Path\$Name - $($_.Exception.Message)" }
        }

        function EnableSvc([string]$Name, [string]$Display) {
            try {
                $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
                if ($svc) {
                    Set-Service -Name $Name -StartupType Manual -ErrorAction Stop
                    Log "  Re-enabled service: $Display ($Name) -> Manual"
                } else { Log "  Service not found: $Name (OK)" }
            } catch { Log "  FAIL enable service $Name - $($_.Exception.Message)" }
        }

        function EnableTask([string]$Name) {
            try {
                $task = Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
                if ($task -and $task.State -eq 'Disabled') {
                    Enable-ScheduledTask -TaskName $Name -ErrorAction Stop | Out-Null
                    Log "  Re-enabled task: $Name"
                } elseif (-not $task) { Log "  Task not found: $Name (OK)" }
                else { Log "  Task already enabled: $Name" }
            } catch { Log "  FAIL enable task $Name - $($_.Exception.Message)" }
        }

        # ========================
        #  RE-ENABLE SERVICES
        # ========================
        Log "=== RE-ENABLING SERVICES ==="
        EnableSvc 'DiagTrack' 'Connected User Experiences and Telemetry'
        EnableSvc 'dmwappushservice' 'WAP Push Message Routing'
        EnableSvc 'WerSvc' 'Windows Error Reporting'
        EnableSvc 'PcaSvc' 'Program Compatibility Assistant'
        EnableSvc 'diagsvc' 'Diagnostic Service Host'
        EnableSvc 'DPS' 'Diagnostic Policy Service'
        EnableSvc 'NvTelemetryContainer' 'Nvidia Telemetry Container'
        EnableSvc 'VSStandardCollectorService150' 'VS Standard Collector Service'

        # ========================
        #  RE-ENABLE TASKS
        # ========================
        Log ""
        Log "=== RE-ENABLING SCHEDULED TASKS ==="
        EnableTask 'Microsoft Compatibility Appraiser'
        EnableTask 'ProgramDataUpdater'
        EnableTask 'StartupAppTask'
        EnableTask 'PcaPatchDbTask'
        EnableTask 'Proxy'
        EnableTask 'Consolidator'
        EnableTask 'UsbCeip'
        EnableTask 'KernelCeipTask'
        EnableTask 'Microsoft-Windows-DiskDiagnosticDataCollector'
        EnableTask 'SmartScreenSpecific'
        EnableTask 'NvTmMon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}'
        EnableTask 'NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}'
        EnableTask 'NvProfileUpdaterDaily_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}'
        EnableTask 'NvProfileUpdaterOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}'

        # ========================
        #  REMOVE FIREWALL RULES
        # ========================
        Log ""
        Log "=== REMOVING FIREWALL RULES ==="
        try {
            $rules = Get-NetFirewallRule -Group 'TelemetrySlayer' -ErrorAction SilentlyContinue
            if ($rules) {
                $rules | Remove-NetFirewallRule -ErrorAction Stop
                Log "  Removed all TelemetrySlayer firewall rules"
            } else { Log "  No TelemetrySlayer firewall rules found" }
        } catch { Log "  FAIL removing firewall rules - $($_.Exception.Message)" }

        # ========================
        #  REMOVE IFEO
        # ========================
        Log ""
        Log "=== REMOVING IFEO ==="
        $ifeoPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe'
        try {
            if (Test-Path $ifeoPath) {
                Remove-Item -LiteralPath $ifeoPath -Recurse -Force -ErrorAction Stop
                Log "  Removed IFEO entry for CompatTelRunner.exe"
            } else { Log "  No IFEO entry found (OK)" }
        } catch { Log "  FAIL removing IFEO - $($_.Exception.Message)" }

        # ========================
        #  REMOVE REGISTRY POLICIES
        # ========================
        Log ""
        Log "=== REMOVING REGISTRY POLICIES ==="

        # Windows telemetry
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'MaxTelemetryAllowed'
        DelReg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications'

        # Advertising ID
        DelReg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled'
        DelReg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy'

        # Linguistic
        DelReg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput' 'AllowLinguisticDataCollection'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' 'AllowInputPersonalization'

        # Tailored Experiences
        DelReg 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures'
        DelReg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled'

        # Feedback
        DelReg 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod'
        DelReg 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' 'PeriodInNanoSeconds'

        # Activity Feed
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities'

        # Location
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableWindowsLocationProvider'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocationScripting'

        # Input Personalization
        DelReg 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection'
        DelReg 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection'
        DelReg 'HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC' 'PreventHandwritingDataSharing'
        DelReg 'HKCU:\SOFTWARE\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy'
        DelReg 'HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Preferences' 'ModelDownloadAllowed'

        # Handwriting
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports' 'PreventHandwritingErrorReports'

        # App Compat
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableInventory'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'AITEnable'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisableUAR'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisablePCA'

        # Wi-Fi
        DelReg 'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' 'AutoConnectAllowedOEM'
        DelReg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' 'value'
        DelReg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' 'value'

        # ETL AutoLogger
        try {
            Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener' -Name 'Start' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Log "  Restored AutoLogger-Diagtrack-Listener Start=1"
        } catch { Log "  AutoLogger restore skipped" }

        # Office
        DelReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\Common\ClientTelemetry' 'DisableTelemetry'
        DelReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\Common\ClientTelemetry' 'SendTelemetry'
        foreach ($ver in @('15.0','16.0')) {
            DelReg "HKCU:\SOFTWARE\Policies\Microsoft\Office\$ver\osm" 'Enablelogging'
            DelReg "HKCU:\SOFTWARE\Policies\Microsoft\Office\$ver\osm" 'EnableUpload'
        }
        DelReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Feedback' 'Enabled'
        DelReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Feedback' 'SurveyEnabled'
        DelReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common' 'sendcustomerdata'
        DelReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Privacy' 'DisconnectedState'
        DelReg 'HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Privacy' 'ControllerConnectedServicesEnabled'

        # Nvidia
        DelReg 'HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' 'Optimus_EnableTelemetry'
        try {
            Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\NvTelemetryContainer' -Name 'Start' -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
            Log "  Restored NvTelemetryContainer Start=2"
        } catch { Log "  NvTelemetryContainer restore skipped" }

        # Edge
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'DiagnosticData'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'PersonalizationReportingEnabled'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'MetricsReportingEnabled'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'SendSiteInfoToImproveServices'

        # Visual Studio
        DelReg 'HKCU:\SOFTWARE\Microsoft\VisualStudio\Telemetry' 'TurnOffSwitch'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableFeedbackDialog'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableEmailInput'
        DelReg 'HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' 'DisableScreenshotCapture'

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

    }) | Out-Null

    $handle = $ps.BeginInvoke()

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $timer.Add_Tick({
        $msg = $null
        while ($script:logQueue.TryDequeue([ref]$msg)) {
            $txtLog.AppendText("$msg`r`n")
            $txtLog.ScrollToEnd()

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
