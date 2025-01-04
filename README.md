# softwareinventarisierung

Dieses Projekt soll helfen die installierte Software auf Windows Clients zu lesen und in eine CSV-Datei auf einem Netzlaufwerk abzulegen. 
Diese CSV-Dateien werden dann über ein Python Skript ausgelesen und in eine Datenbank übertragen. 
Über ein Webinterface sollen dann alle Clients aufgelistet werden können und bei einem Klick auf die Clients die installierte Software angezeigt und über ein einfaches Menü auch "in der Zeit zurückgesprungen" werden können.

Da Software möglicherweise auch nur im Usermode installiert worden sein könnte, muss auch eine Spalte für die Benutzer, die diese Software auf dem Gerät installiert haben neben den ganzen anderen Infos der installierten Software auf den Clients aufgelistet werden oder per Dropdown ausgewählt werden können. (durch das Datum der Einträge (aus dem CSV-Namen auslesbar) soll immer automatisch der zuletzt angemeledete Benutzer angezeigt werden)

Um Überblick über die verschiedenen Einträge behalten zu können, sollte bei jedem Mal, wenn eine CSV-Datei in die Datenbank übertragen wird eine Versionsnummer vergeben werden, die immer weiter ansteigt. Dadurch kann im Webinterface einfacher die aktuellste Version und ältere Versionen sortiert werden...

Computername, Benutzername (unter welchem das Skript ausgeführt wurde) und das Datum inkl. Uhrzeit kann direkt aus dem CSV-Dateinamen ausgelesen werden:{computerName}_-_${userName}_$timeStamp.csv

## Clients
Die Clients sollen außerdem in Gruppen eingeteilt werden können.

## Update / Versionsstand-"Vergleich"
Es soll eine Ansicht geben, in der nach einer bestimmen Software gesucht werden kann (z.B. Chrome) und dann die aktuellste Version (anhand der Versionsnummer) angezeigt wird (z.B. als große Überschrift) und dann darunter alle Geräte, die diese Version noch nicht haben... oder so ähnlich


## in Zukunft
### Datenbank aufräumen --> Performance
Gargabe-Collector Funktion, die alte Einträge (z.B. 2 Monate alt) automatisch oder per Knopfdruck löschen kann, um die Datenbank performant zu halten.
### Updates auf den Clients durchführen
vielleicht kann über chocolatey auch eine Art Update-Center programmiert werden, über welches die aktuellste Version auf einem Client direkt installiert werden kann...
### Deinstallation von unerwünschter Software auf den Clients
das könnte vielleicht über PowerShell geschehen