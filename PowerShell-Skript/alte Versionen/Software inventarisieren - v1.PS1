# Definiere den Pfad zur Ausgabedatei auf dem Desktop des aktuellen Benutzers
$outputPath = "$env:UserProfile\Desktop\Installed_Programs.txt"

# Hol die Eigenschaften der installierten Programme und speichere sie in der Datei
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
Out-File -FilePath $outputPath

# Informiere den Benutzer über den Speicherort der Datei
Write-Output "Die Liste der installierten Programme wurde auf dem Desktop gespeichert: $outputPath"
