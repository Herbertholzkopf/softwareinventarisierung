# Definiere den Pfad zur Ausgabedatei auf dem Desktop des aktuellen Benutzers
$outputPath = "$env:UserProfile\Desktop\Installed_Programs.csv"

# Exportiere die Daten als CSV-Datei, ohne abgeschnittene Spalten
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

# Informiere den Benutzer �ber den Speicherort der Datei
Write-Output "Die Liste der installierten Programme wurde auf dem Desktop gespeichert: $outputPath"
