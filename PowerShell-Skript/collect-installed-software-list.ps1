# Hole den Computernamen und Benutzernamen
$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME

# Erstelle einen Zeitstempel
$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Definiere den Pfad zur Ausgabedatei mit Zeitstempel
$outputPath = "C:\Users\Andreas Koller\${computerName}_-_${userName}_$timeStamp.csv"

# Array mit allen Registry-Pfaden, die durchsucht werden sollen
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Liste von Software-Namen, die aus der Registry gefiltert werden sollen
$excludeRegPatterns = @(
    "Windows SDK",
    "Windows Driver Kit",
    "Windows Software Development Kit",
    "Microsoft Update Health Tools",
    "Microsoft Edge Update",
    "Microsoft Edge WebView2 Runtime",
    "Python*Core Interpreter",
    "Python*Development Resources",
    "Python*Executables",
    "Python*pip Bootstrap",
    "Python*Utility Scripts",
    "Win.*KB*",
    "*Redistributable*"
)

# Sammle die Softwareinformationen aus allen Registry-Pfaden
$installedSoftware = @()
foreach ($path in $registryPaths) {
    $software = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
        Where-Object { 
            $displayName = $_.DisplayName
            if ($null -eq $displayName) {
                return $false
            }
            
            # Prüfe ob der Name in der Ausschlussliste ist
            foreach ($pattern in $excludeRegPatterns) {
                if ($displayName -like $pattern) {
                    return $false
                }
            }
            return $true
        } |
        Select-Object @{Name="DisplayName";Expression={$_.DisplayName}}, 
                      @{Name="DisplayVersion";Expression={$_.DisplayVersion}}, 
                      @{Name="Publisher";Expression={$_.Publisher}}, 
                      @{Name="InstallDate";Expression={$_.InstallDate}}
    $installedSoftware += $software
}

# Liste von Publishern und Paketnamen für Store Apps, die gefiltert werden sollen
$excludedPublishers = @(
    "CN=Microsoft Windows",
    "CN=Microsoft Corporation",
    "CN=Microsoft Windows Production",
    "CN=Microsoft Windows.",
    "Microsoft",
    "Microsoft Corporation"
)

# Liste von Store-App-Namen, die gefiltert werden sollen
$excludedPackagePatterns = @(
    "Microsoft.Windows*",
    "Microsoft.VCLibs*",
    "Microsoft.UI*",
    "Microsoft.Services*",
    "Microsoft.XboxApp*",
    "Microsoft.Xbox*",
    "Microsoft.WebMediaExtensions*",
    "Microsoft.VP9VideoExtensions*",
    "Microsoft.StorePurchaseApp*",
    "Microsoft.ScreenSketch*",
    "Microsoft.MSPaint*",
    "Microsoft.MicrosoftStickyNotes*",
    "Microsoft.MicrosoftOfficeHub*",
    "Microsoft.HEIFImageExtension*",
    "Microsoft.GetHelp*",
    "Microsoft.DesktopAppInstaller*",
    "Microsoft.Comms*",
    "Microsoft.Clip*",
    "Microsoft.BingWeather*",
    "Microsoft.Advertising*",
    "*Runtime*",
    "*Driver*",
    "*Extension*",
    "*.Resource*",
    "*Platform*",
    "*Language*"
)

# Sammle Microsoft Store Apps für den aktuellen Benutzer
$storeApps = Get-AppxPackage | 
    Where-Object { 
        $pkg = $_
        # Grundlegende Filter
        if ($pkg.IsFramework -or $pkg.IsBundle) {
            return $false
        }
        
        # Publisher-Filter
        foreach ($pub in $excludedPublishers) {
            if ($pkg.Publisher -like "*$pub*") {
                return $false
            }
        }
        
        # Paket-Namen-Filter
        foreach ($pattern in $excludedPackagePatterns) {
            if ($pkg.Name -like $pattern) {
                return $false
            }
        }
        
        # Wenn alle Filter passiert wurden, App einschließen
        return $true
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

# Zeige die Anzahl der gefundenen Programme an
#Write-Output "Anzahl gefundener Programme: $($uniqueSoftware.Count)"
#Write-Output "Davon klassische Programme: $($installedSoftware.Count)"
#Write-Output "Davon Microsoft Store Apps: $($storeApps.Count)"