https://www.notion.so/phd-technik-auer-guss/Installierte-Software-der-Rechner-auslesen-und-sammeln-158323ffb92b80609516ec33f2b78145?pvs=4


---

Das Skript sammelt den Computernamen, Benutzername, Uhrzeit und die installierten Programme eines Rechner und speichert diese Infos in einer .csv-Datei unter dem im Skript eingestellten Pfad.

---

**Format:** .csv kommagetrennt UTF-8 (Softwarename, Version, Hersteller, Installationsdatum)

**Ablageort:** \\amb-filer\Alle\EDV-Dateien

**Dateiname:** COMPUTERNAME_-_BENUTZER_DATUM_UHRZEIT 
*(z.B. WK1-LAP-EDV01_-_andreas.koller_20240903_144314)*

## PowerShell Skript per GPO

1. neue GPO erstellen
2. Unter **Benutzerkonfiguration > Richtlinien > Windows-Einstellungen > Skripts (Anmelden/Abmelden)**

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/599e61c6-64fd-4308-9655-dde035f846d6/f52eb6a5-fa5b-46c8-90b6-67454fa49b0b/image.png)

3. verlinke dort die .PS1-Datei, die ausgeführt werden soll