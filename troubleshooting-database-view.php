<?php
// Konfiguration einlesen
$config = require 'config.php';

// Datenbankverbindung herstellen
try {
    $pdo = new PDO(
        "mysql:host={$config['server']};dbname={$config['database']};charset=utf8",
        $config['user'],
        $config['password']
    );
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Verbindungsfehler: " . $e->getMessage());
}

// CSS für bessere Darstellung
echo '<style>
    table { border-collapse: collapse; margin: 20px 0; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
    h2 { margin-top: 30px; }
</style>';

// Alle Tabellen auslesen
try {
    $tables = $pdo->query("SHOW TABLES FROM {$config['database']}")->fetchAll(PDO::FETCH_COLUMN);
    
    foreach ($tables as $table) {
        echo "<h2>Tabelle: $table</h2>";
        
        // Tabellenstruktur anzeigen
        echo "<h3>Struktur:</h3>";
        $columns = $pdo->query("DESCRIBE $table")->fetchAll(PDO::FETCH_ASSOC);
        echo "<table>";
        echo "<tr><th>Feld</th><th>Typ</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
        foreach ($columns as $column) {
            echo "<tr>";
            foreach ($column as $value) {
                echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
            }
            echo "</tr>";
        }
        echo "</table>";
        
        // Tabelleninhalt anzeigen
        echo "<h3>Inhalt:</h3>";
        $data = $pdo->query("SELECT * FROM $table")->fetchAll(PDO::FETCH_ASSOC);
        
        if (empty($data)) {
            echo "<p>Keine Daten vorhanden.</p>";
        } else {
            echo "<table>";
            // Spaltenüberschriften
            echo "<tr>";
            foreach (array_keys($data[0]) as $header) {
                echo "<th>" . htmlspecialchars($header) . "</th>";
            }
            echo "</tr>";
            
            // Daten
            foreach ($data as $row) {
                echo "<tr>";
                foreach ($row as $value) {
                    echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
                }
                echo "</tr>";
            }
            echo "</table>";
        }
    }
} catch (PDOException $e) {
    die("Fehler beim Auslesen der Daten: " . $e->getMessage());
}
?>