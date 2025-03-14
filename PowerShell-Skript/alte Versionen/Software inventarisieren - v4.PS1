# Hole den Computernamen
$computerName = $env:COMPUTERNAME

# �berpr�fe, ob der Computername korrekt abgerufen wird
if ($computerName) {
    # Definiere den Pfad zur Ausgabedatei auf dem Desktop des aktuellen Benutzers mit dem Computernamen
    $outputPath = "$env:UserProfile\Desktop\$computerName`_Installed_Programs.csv"
    
    # Exportiere die Daten als CSV-Datei, ohne abgeschnittene Spalten
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

    # Informiere den Benutzer �ber den Speicherort der Datei
    Write-Output "Die Liste der installierten Programme wurde auf dem Desktop gespeichert: $outputPath"
} else {
    Write-Output "Der Computername konnte nicht abgerufen werden. Die Datei wurde nicht erstellt."
}
