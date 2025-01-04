https://www.notion.so/phd-technik-auer-guss/Installierte-Software-der-Rechner-auslesen-und-sammeln-158323ffb92b80609516ec33f2b78145?pvs=4


---

Das Skript sammelt den Computernamen, Benutzername, Uhrzeit und die installierten Programme eines Rechner und speichert diese Infos in einer .csv-Datei unter dem im Skript eingestellten Pfad.
![image](https://github.com/user-attachments/assets/5cc6fb32-64be-4a44-ac09-4430b2e9710d)

---

**Format:** .csv kommagetrennt UTF-8 (Softwarename, Version, Hersteller, Installationsdatum)

**Ablageort:** \\amb-filer\Alle\EDV-Dateien

**Dateiname:** COMPUTERNAME_-_BENUTZER_DATUM_UHRZEIT 
*(z.B. WK1-LAP-EDV01_-_andreas.koller_20240903_144314)*

## PowerShell Skript per GPO

1. neue GPO erstellen
2. Unter **Benutzerkonfiguration > Richtlinien > Windows-Einstellungen > Skripts (Anmelden/Abmelden)**
![image2](https://github.com/user-attachments/assets/53ea6716-eb00-46a5-bb19-d4fcae85d6f6)
3. verlinke dort die .PS1-Datei, die ausgeführt werden soll
