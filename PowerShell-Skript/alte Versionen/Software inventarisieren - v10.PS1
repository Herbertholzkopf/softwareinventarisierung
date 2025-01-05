# Hole den Computernamen und Benutzernamen
$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME

# Erstelle einen Zeitstempel
$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Definiere den Pfad zur Ausgabedatei mit Zeitstempel
$outputPath = "\\amb-filer\Alle\EDV-Dateien\${computerName}_-_${userName}_$timeStamp.csv"

# Array mit Filtern für unerwünschte Software
$excludeFilters = @(
    # Standard Windows Apps
    'Calculator', 'Camera', 'Photos', 'Mail', 'Calendar', 'Weather',
    'Maps', 'News', 'Xbox', 'Groove', 'Movies', 'People', 'Phone',
    'Alarms', 'Voice', 'Sticky', 'Store', 'Cortana', 'Gaming',
    # Windows System Components
    'Microsoft WebView', 'Windows Web Experience', 'Windows Hello',
    'Microsoft Edge Update', 'Microsoft.UI.Xaml', 'Microsoft.VCLibs', 
    'Microsoft.Services.Store', 'Microsoft.WindowsAppRuntime',
    'windows.immersivecontrolpanel', 'Windows.CBSPreview',
    'Microsoft.AsyncTextService', 'Microsoft.PPIProjection',
    'Microsoft.Win32WebViewHost', 'Windows.PrintDialog',
    # Media Codecs & Extensions
    'DolbyLaboratories', 'VideoExtension', 'ImageExtension',
    'MediaExtensions', 'AV1', 'HEVC', 'HEIF', 'VP9', 'MPEG2',
    # Speech & Language
    'Speech.', 'Ink.Handwriting', 'LanguageExperiencePackde-DE',
    # Windows Features & Services
    'CloudExperienceHost', 'ContentDeliveryManager', 'ShellExperienceHost',
    'StartExperiencesApp', 'AccountsControl', 'CredDialogHost',
    'Windows.Client', 'MicrosoftWindows.Client',
    'WindowsWorkload', 'AutoSuperResolution',
    # System Tools & Utilities
    'GetHelp', 'SecHealthUI', 'ParentalControls', 'BioEnrollment',
    'DesktopAppInstaller', 'StorePurchaseApp',
    # Additional Microsoft Components
    'Microsoft.AAD.BrokerPlugin', # Azure Active Directory
    'Microsoft.ApplicationCompatibilityEnhancements', # Windows-Kompatibilität
    'Microsoft.BingSearch', # Bing Search
    'Microsoft.D3DMappingLayers',  # Direct3D
    'Microsoft.ECApp', # Windows Compliance
    'Microsoft.LockApp', # Windows Sperrbildschirm
    'Microsoft.ScreenSketch', # Windows Snipping Tool
    'Microsoft.WidgetsPlatformRuntime', # Windows Widgets
    'Microsoft.Windows.Apprep.ChxApp', # Windows App Reputation
    'Microsoft.Windows.AugLoop.CBS', # Office Connected Experiences
    'Microsoft.Windows.CapturePicker', # Windows Snipping Tool
    'Microsoft.Windows.NarratorQuickStart', # Windows Narrator (Screenreader)
    'Microsoft.Windows.OOBENetworkCaptivePortal', # Windows Network Captive Portal
    'Microsoft.Windows.OOBENetworkConnectionFlow', # Windows Network Connection Flow
    'Microsoft.Windows.PinningConfirmationDialog', # Windows Pinning Confirmation Dialog
    'Microsoft.Windows.PrintQueueActionCenter', # Windows Print Queue Action Center
    'Microsoft.Windows.StartMenuExperienceHost', # Windows Start Menu Experience Host
    'Microsoft.Windows.XGpuEjectDialog', # Windows XGPU Eject Dialog
    'Microsoft.WindowsTerminal', # Windows Terminal
    'Microsoft.WindowsSoundRecorder', # Windows Audio Recorder
    'Microsoft.Windows.AssignedAccessLockApp', # Windows Kiosk Modus Konfiguration
    'Microsoft.ZuneMusic', # Groove Music
    'MicrosoftWindows.CrossDevice', # Windows Cross Device Experience
    'MicrosoftWindows.LKG.AccountsService', # Windows Accounts Service
    'MicrosoftWindows.LKG.DesktopSpotlight', # Windows Desktop Spotlight (Hintergründe)
    'MicrosoftWindows.LKG.IrisService', # Bing Hintergrund des Tages, Vorschläge, ...
    'MicrosoftWindows.LKG.RulesEngine', 
    'MicrosoftWindows.LKG.TwinSxS', # Kompatibilität für Module älterer Windowsmodule
    'MicrosoftWindows.UndockedDevKit', # Windows Entwickler Werkzeuge
    'Microsoft.Winget.Platform.Source', # Windows WinGet Package Manager
    'microsoft.windowscommunicationsapps', # Windows Mail & Calender Komponente
    'Microsoft.Windows.CallingShellApp', # Windows Telefon / Dialer Komponente
    'MicrosoftCorporationII.QuickAssist' # Windows Remote Support
)

# Array mit allen Registry-Pfaden, die durchsucht werden sollen
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Sammle die Softwareinformationen aus allen Registry-Pfaden
$installedSoftware = @()
foreach ($path in $registryPaths) {
    $software = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
        Where-Object { 
            $_.DisplayName -ne $null -and
            ($excludeFilters | ForEach-Object { $_.DisplayName -notmatch $_ }) 
        } |
        Select-Object @{Name="DisplayName";Expression={$_.DisplayName}}, 
                      @{Name="DisplayVersion";Expression={$_.DisplayVersion}}, 
                      @{Name="Publisher";Expression={$_.Publisher}}, 
                      @{Name="InstallDate";Expression={$_.InstallDate}}
    $installedSoftware += $software
}

# Sammle Microsoft Store Apps für den aktuellen Benutzer
$storeApps = Get-AppxPackage | 
    Where-Object {
        $app = $_
        -not ($excludeFilters | Where-Object { $app.Name -match $_ })
    } |
    Select-Object @{Name="DisplayName";Expression={$_.Name}},
                  @{Name="DisplayVersion";Expression={$_.Version}},
                  @{Name="Publisher";Expression={$_.Publisher}},
                  @{Name="InstallDate";Expression={
                      if ($_.InstallDate) {
                          $_.InstallDate.ToString("yyyyMMdd")
                      } else {
                          $null
                      }
                  }}

# Kombiniere traditionelle Software und Store Apps
$allSoftware = $installedSoftware + $storeApps

# Entferne Duplikate basierend auf dem Namen und der Version
$uniqueSoftware = $allSoftware | Sort-Object DisplayName, DisplayVersion -Unique

# Exportiere die Daten als CSV-Datei
$uniqueSoftware | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8