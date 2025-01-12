<?php
// Konfiguration einbinden
$config = require 'config.php';

// Datenbankverbindung herstellen
try {
    $pdo = new PDO(
        "mysql:host={$config['server']};dbname={$config['database']};charset=utf8",
        $config['user'],
        $config['password']
    );
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Verbindungsfehler: " . $e->getMessage());
}

// Ausgewählter Computer und Benutzer
$selectedComputer = $_GET['computer'] ?? null;
$selectedUser = $_GET['user'] ?? null;

// Computer-Typen und zugehörige Computer abrufen
$stmt = $pdo->query("
    SELECT DISTINCT computer_type 
    FROM computer 
    ORDER BY computer_type
");
$computerTypes = $stmt->fetchAll(PDO::FETCH_COLUMN);

// Computer für jeden Typ abrufen
$computersByType = [];
foreach ($computerTypes as $type) {
    $stmt = $pdo->prepare("
        SELECT computer_id, computer_name 
        FROM computer 
        WHERE computer_type = ? 
        ORDER BY computer_name
    ");
    $stmt->execute([$type]);
    $computersByType[$type] = $stmt->fetchAll(PDO::FETCH_ASSOC);
}

// Wenn ein Computer ausgewählt ist, hole die zugehörigen Informationen
$computerInfo = null;
$users = [];
$latestScan = null;
if ($selectedComputer) {
    // Letzte Aktualisierung (höchste scan_version)
    $stmt = $pdo->prepare("
        SELECT ss.scan_date, ss.scan_version, u.username, u.user_id
        FROM software_scan ss
        JOIN user u ON ss.user_id = u.user_id
        WHERE ss.computer_id = ?
        ORDER BY ss.scan_version DESC
        LIMIT 1
    ");
    $stmt->execute([$selectedComputer]);
    $latestScan = $stmt->fetch(PDO::FETCH_ASSOC);

    // Alle Benutzer für diesen Computer
    $stmt = $pdo->prepare("
        SELECT DISTINCT u.user_id, u.username
        FROM software_scan ss
        JOIN user u ON ss.user_id = u.user_id
        WHERE ss.computer_id = ?
        ORDER BY u.username
    ");
    $stmt->execute([$selectedComputer]);
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Wenn kein Benutzer ausgewählt ist, nehme den letzten aktiven
    if (!$selectedUser && $latestScan) {
        $selectedUser = $latestScan['user_id'];
    }
}

// Verlauf für ausgewählten Computer und Benutzer
$history = [];
if ($selectedComputer && $selectedUser) {
    $stmt = $pdo->prepare("
        SELECT scan_date, scan_version
        FROM software_scan
        WHERE computer_id = ? AND user_id = ?
        ORDER BY scan_version DESC
    ");
    $stmt->execute([$selectedComputer, $selectedUser]);
    $history = $stmt->fetchAll(PDO::FETCH_ASSOC);
}

// Installierte Software für den ausgewählten Computer und Benutzer
$software = [];
if ($selectedComputer && $selectedUser) {
    $stmt = $pdo->prepare("
        SELECT s.*
        FROM software s
        JOIN software_scan ss ON s.scan_id = ss.scan_id
        WHERE ss.computer_id = ? AND ss.user_id = ?
        ORDER BY s.display_name
    ");
    $stmt->execute([$selectedComputer, $selectedUser]);
    $software = $stmt->fetchAll(PDO::FETCH_ASSOC);
}

// Computer-Name für den Header
$computerName = '';
if ($selectedComputer) {
    $stmt = $pdo->prepare("SELECT computer_name FROM computer WHERE computer_id = ?");
    $stmt->execute([$selectedComputer]);
    $computerName = $stmt->fetchColumn();
}
?>
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Softwareinventarisierung</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50">
    <div class="min-h-screen">
        <header class="bg-white shadow">
            <div class="flex justify-between items-center px-4 py-3">
                <h1 class="text-xl font-semibold">Softwareinventarisierung</h1>
                <div class="space-x-2">
                    <a href="https://google.de" class="bg-blue-500 text-white px-4 py-2 rounded">Updatemanager</a>
                    <a href="https://google.de" class="bg-blue-500 text-white px-4 py-2 rounded">Einstellungen</a>
                </div>
            </div>
        </header>

        <div class="flex w-full">
            <!-- Linke Spalte - Geräteliste -->
            <div class="w-52 bg-white shadow-lg h-screen p-4 flex-shrink-0">
                <div class="mb-4">
                    <input type="text" placeholder="Suche..." class="w-full px-3 py-2 border rounded">
                </div>
                
                <?php foreach ($computerTypes as $type): ?>
                <div class="mb-4">
                    <h2 class="font-semibold mb-2"><?= htmlspecialchars($type) ?></h2>
                    <ul>
                        <?php foreach ($computersByType[$type] as $computer): ?>
                        <li>
                            <a href="?computer=<?= $computer['computer_id'] ?>" 
                               class="block py-1 px-2 hover:bg-gray-100 rounded truncate <?= $selectedComputer == $computer['computer_id'] ? 'bg-blue-100' : '' ?>">
                                <?= htmlspecialchars($computer['computer_name']) ?>
                            </a>
                        </li>
                        <?php endforeach; ?>
                    </ul>
                </div>
                <?php endforeach; ?>
            </div>

            <!-- Mittlerer Bereich -->
            <div class="flex-1 p-6">
                <?php if ($selectedComputer): ?>
                <div class="mb-6">
                    <h2 class="text-2xl font-semibold">
                        <?= htmlspecialchars($computerName) ?>
                        <?php if ($latestScan): ?>
                        <span class="text-sm font-normal text-gray-500">
                            Letzte Aktualisierung: <?= date('d.m.Y H:i', strtotime($latestScan['scan_date'])) ?> Uhr
                        </span>
                        <?php endif; ?>
                    </h2>
                    
                    <div class="mt-4">
                        <label class="block text-sm font-medium text-gray-700">Benutzer:</label>
                        <select onchange="window.location.href='?computer=<?= $selectedComputer ?>&user=' + this.value"
                                class="mt-1 block w-64 rounded-md border-gray-300 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200">
                            <?php foreach ($users as $user): ?>
                            <option value="<?= $user['user_id'] ?>" <?= $selectedUser == $user['user_id'] ? 'selected' : '' ?>>
                                <?= htmlspecialchars($user['username']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>

                <!-- Software-Liste -->
                <div class="bg-white shadow rounded-lg p-4">
                    <table class="min-w-full">
                        <thead>
                            <tr class="bg-gray-50">
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Version</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Publisher</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Install-Datum</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <?php foreach ($software as $app): ?>
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap"><?= htmlspecialchars($app['display_name']) ?></td>
                                <td class="px-6 py-4 whitespace-nowrap"><?= htmlspecialchars($app['display_version']) ?></td>
                                <td class="px-6 py-4 whitespace-nowrap"><?= htmlspecialchars($app['publisher']) ?></td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <?= $app['install_date'] ? date('d.m.Y', strtotime($app['install_date'])) : '-' ?>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
                <?php endif; ?>
            </div>

            <!-- Rechte Spalte - Verlauf -->
            <?php if ($selectedComputer): ?>
            <div class="w-72 bg-white shadow-lg p-4 flex-shrink-0">
                <h2 class="font-semibold mb-4">Verlauf</h2>
                <ul>
                    <?php foreach ($history as $entry): ?>
                    <li class="py-1">
                        <?= date('d.m.Y H:i', strtotime($entry['scan_date'])) ?> Uhr
                    </li>
                    <?php endforeach; ?>
                </ul>
            </div>
            <?php endif; ?>
        </div>
    </div>
</body>
</html>