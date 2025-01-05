# softwareinventarisierung

Dieses Projekt soll helfen die installierte Software auf Windows Clients zu lesen und in eine CSV-Datei auf einem Netzlaufwerk abzulegen. 
Diese CSV-Dateien werden dann über ein Python Skript ausgelesen und in eine Datenbank übertragen. 
Über ein Webinterface sollen dann alle Clients aufgelistet werden können und bei einem Klick auf die Clients die installierte Software angezeigt und über ein einfaches Menü auch "in der Zeit zurückgesprungen" werden können.

Da Software möglicherweise auch nur im Usermode installiert worden sein könnte, muss auch eine Spalte für die Benutzer, die diese Software auf dem Gerät installiert haben neben den ganzen anderen Infos der installierten Software auf den Clients aufgelistet werden oder per Dropdown ausgewählt werden können. (durch das Datum der Einträge (aus dem CSV-Namen auslesbar) soll immer automatisch der zuletzt angemeledete Benutzer angezeigt werden)

Um Überblick über die verschiedenen Einträge behalten zu können, sollte bei jedem Mal, wenn eine CSV-Datei in die Datenbank übertragen wird eine Versionsnummer vergeben werden, die immer weiter ansteigt. Dadurch kann im Webinterface einfacher die aktuellste Version und ältere Versionen sortiert werden...

Computername, Benutzername (unter welchem das Skript ausgeführt wurde) und das Datum inkl. Uhrzeit kann direkt aus dem CSV-Dateinamen ausgelesen werden:{computerName}_-_${userName}_$timeStamp.csv

## Beschreibung des Codes / Funktionsweise
Es soll eine Datenbank (softwareinventarisierung) geben.
Mit einem Python Skript werden dann die CSV-Dateien in die Tabellen der Datenbank übertragen. (computer, user, software)

Namensschema der SCV-Dateien: {computerName}-${userName}_$timeStamp.csv

Hierdurch kann der Computername, Benutzername ausgelesen werden, der dann jeweils in die Tabellen eingetragen wird und über eine ID dann die Einträge in der "software" Tabelle mit dem jeweiligen PC und Benutzer verknüpft werden kann.

Zusätzlich wird in der software Tabelle bei jeder eingetragenen CSV-Datei eine fortlaufende "Versionsnummer" für den PC (nicht für eine Kombination von User&PC oder User, nur PC) vergeben. Über diese kann später im PHP-Skript für das Webinterface eine History angezeigt werden und "schneller" die aktuellste Version und alle "dazugehörigen" Softwares "gefunden" werden.

Das sind eigentlich nicht viele Schreibvorgänge, nur sehr viele Suchvorgänge...

Beim Aufrufen der Seite wird eine Liste der Computer angezeigt. Beim Klicken auf einen der Computernamen, wird der neueste gemeldete Status (durch die vorhin angesprochenen Versionen) gesucht und in einer Tabelle angezeigt. Außerdem werden von dem Benutzer, der den neuesten Status hat, alle vorherigen Versionen und deren Datum herausgesucht und in einer Liste angezeigt, um "zurückspringen" zu können.
Zusätzlich werden alle Benutzer die auf diesem Rechner angemeldet waren herausgesucht und in einem Dropdown angezeigt (um zwischen diesen Benutzern wechseln zu können, da bestimmte Software auch in Usermode installiert worden sein könnte und somit auf dem Rechner unterschiedliche Software bei unterschiedlichen Benutzern installiert sein kann).



Also es kann pro PC mehrere Benutzer geben. 
Das Skript läuft immer automatisch bei der Anmeldung der Benutzer.

Also wenn auf PC_A der Benutzer_1 eine Liste schickt, dann soll dieser die Version 1 bekommen. Danach meldet er sich wieder an und bekommt die Version 2.
Jetzt kommt Benutzer_2 und meldet sich auf PC_A an. Dieser bekommt die Version 3, da es ja egal ist, welcher Benutzer angemeldet wird, es ist nur der PC wichtig.... dieser bekommt bei jedem neuen Eintrag eine neue Version.

--> in der Datenbank wird ein INDEX genutzt, da die Suche nach computer_id + Version die Hauptabfrage ist (INDEX idx_computer_version (computer_id, scan_version))






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