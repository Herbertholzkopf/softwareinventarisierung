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

# Sammle die Softwareinformationen aus allen Registry-Pfaden
$installedSoftware = @()
foreach ($path in $registryPaths) {
    $software = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -ne $null } |
        Select-Object @{Name="DisplayName";Expression={$_.DisplayName}}, 
                      @{Name="DisplayVersion";Expression={$_.DisplayVersion}}, 
                      @{Name="Publisher";Expression={$_.Publisher}}, 
                      @{Name="InstallDate";Expression={$_.InstallDate}}
    $installedSoftware += $software
}

# Sammle Microsoft Store Apps für den aktuellen Benutzer
$storeApps = Get-AppxPackage | 
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
Write-Output "Anzahl gefundener Programme: $($uniqueSoftware.Count)"
Write-Output "Davon klassische Programme: $($installedSoftware.Count)"
Write-Output "Davon Microsoft Store Apps: $($storeApps.Count)"
