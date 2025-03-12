USE softwareinventar;

-- Ein Scan der Software wird bei einer Anmeldung eines Benutezrs auf einem Client durchgeführt
-- Dabei wird der Computername und der Benutzername neben den Softwaredetails gespeichert
-- Hierdurch werden die Benutzer gesammelt und in der Tabelle gespeichert
CREATE TABLE user (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    UNIQUE KEY (username)
);

-- Hier wird eine Liste der Computer gespeichert, die gescannt wurden
CREATE TABLE computer (
    computer_id INT AUTO_INCREMENT PRIMARY KEY,
    computer_name VARCHAR(255) NOT NULL,
    computer_type VARCHAR(20) NOT NULL DEFAULT 'Client' CHECK (computer_type IN ('Client', 'Server')),
    UNIQUE KEY (computer_name)
);


-- -----------------------------------------------------------------------
-- Die JSON Daten von software_scan und software_scan_archive enthalten:
-- displayName: Name der Software
-- displayVersion: Version der Software
-- publisher: Hersteller der Software
-- installDate: Installationsdatum der Software
-- -----------------------------------------------------------------------

-- Speichert die "Metadaten" der Softwarestände der Rechner
-- Dabei wird immer nur die neueste Version gespeichert und die "vorherige" Version wird in einer anderen Table gespeichert
-- Gespeichert wird die ID des Computers, die ID des Benutzers, das Datum des Scans und die Liste der Software
CREATE TABLE software_scan (
    software_scan_id INT AUTO_INCREMENT PRIMARY KEY,
    computer_id INT NOT NULL,
    user_id INT NOT NULL,
    scan_date TIMESTAMP NOT NULL,
    software_data JSON,
    FOREIGN KEY (computer_id) REFERENCES computer(computer_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id)
)

-- Speichert die alten Softwarestände der Rechner
-- Dabei wird die ID des Computers, die ID des Benutzers, die ID des Scans, das Datum des Scans, das Datum der "Archvierung" und die Liste der Software gespeichert
CREATE TABLE software_scan_archive (
    software_scan_id INT AUTO_INCREMENT PRIMARY KEY,
    computer_id INT NOT NULL,
    user_id INT NOT NULL,
    scan_id INT NOT NULL, -- fortlaufende Nummer für einen Benutzer AND Computer
    scan_date TIMESTAMP NOT NULL,
    archive_date TIMESTAMP NOT NULL, -- Wann wurde der Scan archiviert
    software_data JSON,
    FOREIGN KEY (computer_id) REFERENCES computer(computer_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id)
)