# Hole den Computernamen und Benutzernamen
$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME

# Erstelle einen Zeitstempel
$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Definiere den Pfad zur Ausgabedatei mit Zeitstempel
$outputPath = "\\amb-filer\Alle\EDV-Dateien\${computerName}_-_${userName}_$timeStamp.csv"

# Array mit allen Registry-Pfaden, die durchsucht werden sollen
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Sammle die Softwareinformationen aus allen Pfaden
$installedSoftware = @()
foreach ($path in $registryPaths) {
    $software = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -ne $null } |
        Select-Object @{Name="DisplayName";Expression={$_.DisplayName}}, 
                      @{Name="DisplayVersion";Expression={$_.DisplayVersion}}, 
                      @{Name="Publisher";Expression={$_.Publisher}}, 
                      @{Name="InstallDate";Expression={$_.InstallDate}},
                      @{Name="RegistryPath";Expression={$path}}
    $installedSoftware += $software
}

# Entferne Duplikate basierend auf dem Namen und der Version
$uniqueSoftware = $installedSoftware | Sort-Object DisplayName, DisplayVersion -Unique |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

# Exportiere die Daten als CSV-Datei
$uniqueSoftware | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8