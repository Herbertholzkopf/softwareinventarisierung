#!/usr/bin/env python3
import os
import re
import json
import csv
import sys
import mysql.connector
from datetime import datetime
import importlib.util

# Datenbank-Konfiguration aus ../config/database.py laden
def load_db_config():
    try:
        # Pfad zur Konfigurationsdatei
        config_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'config', 'database.py')
        spec = importlib.util.spec_from_file_location("database", config_path)
        database = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(database)
        
        return {
            'host': database.DB_HOST,
            'user': database.DB_USER,
            'password': database.DB_PASSWORD,
            'database': database.DB_NAME
        }
    except Exception as e:
        print(f"Fehler beim Laden der Datenbank-Konfiguration: {e}")
        sys.exit(1)

# Verbindung zur Datenbank herstellen
def connect_to_database(config):
    try:
        conn = mysql.connector.connect(
            host=config['host'],
            user=config['user'],
            password=config['password'],
            database=config['database'],
            use_pure=True  # Stellt sicher, dass keine SSL/TLS-Verbindung verwendet wird
        )
        return conn
    except mysql.connector.Error as e:
        print(f"Fehler bei der Verbindung zur MySQL-Datenbank: {e}")
        sys.exit(1)

# Informationen aus dem Dateinamen extrahieren (Rechnername, Benutzername, Datum)
def parse_filename(filename):
    pattern = r'(.+?)_-_(.+?)_(\d{8}_\d{6})\.csv$'
    match = re.match(pattern, filename)
    
    if match:
        computer_name, username, date_time = match.groups()
        # Konvertierung des Datumsformats in MySQL-Timestamp-Format
        date_obj = datetime.strptime(date_time, '%Y%m%d_%H%M%S')
        scan_date = date_obj.strftime('%Y-%m-%d %H:%M:%S')
        
        return {
            'computer_name': computer_name,
            'username': username,
            'scan_date': scan_date,
            'date_time_str': date_time,
            'raw_filename': filename
        }
    return None

# CSV-Dateien nach Datum sortiert abrufen (älteste zuerst)
def get_sorted_csv_files(directory):
    csv_files = []
    
    for filename in os.listdir(directory):
        if filename.endswith('.csv'):
            file_info = parse_filename(filename)
            if file_info:
                csv_files.append(file_info)
    
    # Nach date_time_str sortieren (im Format YYYYMMDD_HHMMSS)
    return sorted(csv_files, key=lambda x: x['date_time_str'])

# Benutzer in der Datenbank abrufen oder erstellen
def get_or_create_user(conn, username):
    cursor = conn.cursor(dictionary=True)
    
    # Vorhandenen Benutzer suchen
    cursor.execute("SELECT user_id FROM user WHERE username = %s", (username,))
    user = cursor.fetchone()
    
    if user:
        cursor.close()
        return user['user_id']
    
    # Neuen Benutzer erstellen
    cursor.execute("INSERT INTO user (username) VALUES (%s)", (username,))
    conn.commit()
    
    user_id = cursor.lastrowid
    cursor.close()
    return user_id

# Computer in der Datenbank abrufen oder erstellen
def get_or_create_computer(conn, computer_name):
    cursor = conn.cursor(dictionary=True)
    
    # Vorhandenen Computer suchen
    cursor.execute("SELECT computer_id FROM computer WHERE computer_name = %s", (computer_name,))
    computer = cursor.fetchone()
    
    if computer:
        cursor.close()
        return computer['computer_id']
    
    # Neuen Computer erstellen (Standardtyp ist 'Client')
    cursor.execute("INSERT INTO computer (computer_name) VALUES (%s)", (computer_name,))
    conn.commit()
    
    computer_id = cursor.lastrowid
    cursor.close()
    return computer_id

# Bestehende Scan-Daten für eine Computer-Benutzer-Kombination abrufen
def get_existing_scan(conn, computer_id, user_id):
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute(
        "SELECT software_scan_id, scan_date, software_data FROM software_scan WHERE computer_id = %s AND user_id = %s",
        (computer_id, user_id)
    )
    
    scan = cursor.fetchone()
    cursor.close()
    return scan

# Vergleich von Software-Daten (JSON-Strings)
def is_software_data_different(existing_json_str, new_json_str):
    # JSON-Strings in Python-Objekte umwandeln für einen korrekten Vergleich
    existing_data = json.loads(existing_json_str)
    new_data = json.loads(new_json_str)
    
    # Beide Listen sortieren, um einen konsistenten Vergleich zu gewährleisten
    existing_data.sort(key=lambda x: x.get('displayName', ''))
    new_data.sort(key=lambda x: x.get('displayName', ''))
    
    return existing_data != new_data

# Bestehenden Scan in die Archiv-Tabelle verschieben
def archive_scan(conn, scan, archive_date):
    cursor = conn.cursor()
    
    cursor.execute(
        "INSERT INTO software_scan_archive (computer_id, user_id, scan_date, archive_date, software_data) "
        "SELECT computer_id, user_id, scan_date, %s, software_data FROM software_scan WHERE software_scan_id = %s",
        (archive_date, scan['software_scan_id'])
    )
    
    conn.commit()
    cursor.close()

# Bestehenden Scan mit neuen Daten aktualisieren
def update_scan(conn, scan_id, scan_date, software_data):
    cursor = conn.cursor()
    
    cursor.execute(
        "UPDATE software_scan SET scan_date = %s, software_data = %s WHERE software_scan_id = %s",
        (scan_date, software_data, scan_id)
    )
    
    conn.commit()
    cursor.close()

# Neuen Scan-Datensatz erstellen
def create_scan(conn, computer_id, user_id, scan_date, software_data):
    cursor = conn.cursor()
    
    cursor.execute(
        "INSERT INTO software_scan (computer_id, user_id, scan_date, software_data) VALUES (%s, %s, %s, %s)",
        (computer_id, user_id, scan_date, software_data)
    )
    
    conn.commit()
    cursor.close()

# CSV-Datei parsen und Software-Daten als JSON-String zurückgeben
def parse_csv_content(csv_file_path):
    software_list = []
    
    with open(csv_file_path, 'r', encoding='utf-8') as csv_file:
        csv_reader = csv.reader(csv_file)
        for row in csv_reader:
            # Prüfen, ob mindestens die ersten drei Elemente vorhanden sind
            if len(row) >= 3:
                software_info = {
                    "displayName": row[0],
                    "displayVersion": row[1],
                    "publisher": row[2],
                    # Optionales Installationsdatum behandeln (kann leer sein)
                    "installDate": row[3] if len(row) > 3 and row[3] else None
                }
                software_list.append(software_info)
    
    return json.dumps(software_list)

# Eine einzelne CSV-Datei verarbeiten
def process_csv_file(conn, file_info):
    computer_name = file_info['computer_name']
    username = file_info['username']
    scan_date = file_info['scan_date']
    filename = file_info['raw_filename']
    
    file_path = os.path.join(os.getcwd(), filename)
    
    if not os.path.exists(file_path):
        print(f"Datei {filename} nicht gefunden.")
        return
    
    print(f"Verarbeite Datei: {filename}")
    
    # Benutzer- und Computer-Datensätze abrufen oder erstellen
    user_id = get_or_create_user(conn, username)
    computer_id = get_or_create_computer(conn, computer_name)
    
    # CSV-Inhalt zu JSON parsen
    software_data_json = parse_csv_content(file_path)
    
    # Prüfen, ob diese Computer-Benutzer-Kombination bereits existiert
    existing_scan = get_existing_scan(conn, computer_id, user_id)
    
    if existing_scan:
        # Software-Daten vergleichen
        if is_software_data_different(existing_scan['software_data'], software_data_json):
            # Archivierungsdatum erstellen (eine Sekunde vor dem neuen Scan-Datum)
            archive_date_obj = datetime.strptime(scan_date, '%Y-%m-%d %H:%M:%S')
            archive_date_obj = archive_date_obj.replace(second=max(0, archive_date_obj.second - 1))
            archive_date = archive_date_obj.strftime('%Y-%m-%d %H:%M:%S')
            
            # Aktuelle Daten archivieren
            archive_scan(conn, existing_scan, archive_date)
            
            # Scan mit neuen Daten aktualisieren
            update_scan(conn, existing_scan['software_scan_id'], scan_date, software_data_json)
            print(f"Scan für {computer_name} - {username} aktualisiert")
        else:
            print(f"Keine Änderungen für {computer_name} - {username}")
    else:
        # Neuen Scan-Datensatz erstellen
        create_scan(conn, computer_id, user_id, scan_date, software_data_json)
        print(f"Neuer Scan für {computer_name} - {username} erstellt")

# Hauptfunktion
def main():
    # Datenbank-Konfiguration laden
    db_config = load_db_config()
    
    # Mit Datenbank verbinden
    conn = connect_to_database(db_config)
    
    # Sortierte CSV-Dateien abrufen
    directory = os.getcwd()  # Aktuelles Verzeichnis
    csv_files = get_sorted_csv_files(directory)
    
    print(f"{len(csv_files)} CSV-Dateien zur Verarbeitung gefunden.")
    
    # Jede Datei verarbeiten
    for file_info in csv_files:
        try:
            process_csv_file(conn, file_info)
        except Exception as e:
            print(f"Fehler bei der Verarbeitung der Datei {file_info['raw_filename']}: {e}")
    
    # Datenbankverbindung schließen
    conn.close()
    print("Verarbeitung abgeschlossen.")

if __name__ == "__main__":
    main()