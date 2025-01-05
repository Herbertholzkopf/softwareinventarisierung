# Hole den Computernamen
$computerName = $env:COMPUTERNAME

# Definiere den Pfad zur Ausgabedatei auf dem Desktop des aktuellen Benutzers mit dem Computernamen
$outputPath = "$env:UserProfile\Desktop\$computerName_Installed_Programs.csv"

# Exportiere die Daten als CSV-Datei, ohne abgeschnittene Spalten
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

# Informiere den Benutzer über den Speicherort der Datei
Write-Output "Die Liste der installierten Programme wurde auf dem Desktop gespeichert: $outputPath"
