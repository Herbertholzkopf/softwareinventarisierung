# Hole den Computernamen und Benutzernamen
$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME

# Erstelle einen Zeitstempel
$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Definiere den Pfad zur Ausgabedatei mit Zeitstempel
$outputPath = "\\amb-filer\Alle\EDV-Dateien\${computerName}_-_${userName}_$timeStamp.csv"

# Exportiere die Daten als CSV-Datei, ohne abgeschnittene Spalten
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8