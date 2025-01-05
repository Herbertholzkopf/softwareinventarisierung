# Hole den Computernamen
$computerName = $env:COMPUTERNAME

# Definiere den Pfad zur Ausgabedatei auf dem Netzlaufwerk mit dem Computernamen
$outputPath = "\\amb-filer\Alle\EDV-Dateien\${computerName}_Installed_Programs.csv"

# Exportiere die Daten als CSV-Datei, ohne abgeschnittene Spalten
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

# Zeige eine Windows-Hinweismeldung an
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show('Die auf dem Rechner installierte Software wurde erfolgreich an die EDV-Abteilung gemeldet', 'Software Inventarisierung', 'OK', 'Information')

# Informiere den Benutzer in der Konsole über den Speicherort der Datei
Write-Output "Die Liste der installierten Programme wurde auf dem Netzlaufwerk gespeichert: $outputPath"
