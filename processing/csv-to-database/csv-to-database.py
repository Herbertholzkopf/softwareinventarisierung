import os
import re
import mysql.connector
from mysql.connector import Error
import configparser
from datetime import datetime
import pandas as pd
import shutil

def load_database_config(config_file='database-config.ini'):
    """Lädt die Datenbank-Konfiguration aus der INI-Datei."""
    config = configparser.ConfigParser()
    config.read(config_file)
    
    return {
        'host': config['database']['host'],
        'user': config['database']['user'],
        'password': config['database']['password'],
        'database': config['database']['database'],
        'ssl_disabled': config['database'].getboolean('ssl_disabled')
    }

def parse_filename(filename):
    """Extrahiert Informationen aus dem Dateinamen."""
    # Beispiel: WKS1LAP02__a.koller_20250105_012747.csv
    pattern = r'(.+?)_-_(.+?)_(\d{8}_\d{6})\.csv$'
    match = re.match(pattern, filename)
    
    if not match:
        raise ValueError(f"Ungültiges Dateiformat: {filename}")
    
    computer_name, username, timestamp = match.groups()
    scan_datetime = datetime.strptime(timestamp, '%Y%m%d_%H%M%S')
    
    return computer_name, username, scan_datetime

def get_or_create_record(cursor, table, search_column, search_value):
    """Sucht einen Datensatz oder erstellt ihn, wenn er nicht existiert."""
    # Suche nach existierendem Eintrag
    cursor.execute(f"SELECT {table}_id FROM {table} WHERE {search_column} = %s", (search_value,))
    result = cursor.fetchone()
    
    if result:
        return result[0]
    
    # Erstelle neuen Eintrag
    cursor.execute(f"INSERT INTO {table} ({search_column}) VALUES (%s)", (search_value,))
    return cursor.lastrowid

def get_next_scan_version(cursor, computer_id):
    """Ermittelt die nächste scan_version für einen Computer."""
    cursor.execute("""
        SELECT MAX(scan_version) 
        FROM software_scan 
        WHERE computer_id = %s
    """, (computer_id,))
    
    result = cursor.fetchone()[0]
    return 0 if result is None else result + 1

def process_csv_file(connection, file_path):
    """Verarbeitet eine einzelne CSV-Datei."""
    try:
        # Dateinamen parsen
        filename = os.path.basename(file_path)
        computer_name, username, scan_datetime = parse_filename(filename)
        
        cursor = connection.cursor()
        
        # Computer und User IDs ermitteln/erstellen
        computer_id = get_or_create_record(cursor, 'computer', 'computer_name', computer_name)
        user_id = get_or_create_record(cursor, 'user', 'username', username)
        
        # Nächste scan_version ermitteln
        scan_version = get_next_scan_version(cursor, computer_id)
        
        # Neuen Scan-Eintrag erstellen
        cursor.execute("""
            INSERT INTO software_scan (computer_id, user_id, scan_version, scan_date)
            VALUES (%s, %s, %s, %s)
        """, (computer_id, user_id, scan_version, scan_datetime))
        
        scan_id = cursor.lastrowid
        
        # CSV-Daten einlesen und verarbeiten
        df = pd.read_csv(file_path, encoding='utf-8')
        df = df.dropna(how='all')  # Leere Zeilen überspringen
        
        # Software-Einträge erstellen
        for _, row in df.iterrows():
            # Konvertiere nan-Werte zu None und kürze zu lange Werte
            def truncate_value(value, max_length=255):
                if pd.isna(value):
                    return None
                str_value = str(value)
                return str_value[:max_length] if len(str_value) > max_length else str_value

            # Alle Felder auf 255 Zeichen begrenzen
            display_name = truncate_value(row['DisplayName'])
            display_version = truncate_value(row['DisplayVersion'])
            publisher = truncate_value(row['Publisher'])
            install_date = None if pd.isna(row['InstallDate']) else row['InstallDate']
            
            cursor.execute("""
                INSERT INTO software (scan_id, display_name, display_version, publisher, install_date)
                VALUES (%s, %s, %s, %s, %s)
            """, (
                scan_id,
                display_name,
                display_version,
                publisher,
                install_date
            ))
        
        connection.commit()
        print(f"Erfolgreich verarbeitet: {filename}")
        
        # Datei nach erfolgreicher Verarbeitung löschen
        os.remove(file_path)
        
    except Exception as e:
        connection.rollback()
        print(f"Fehler bei der Verarbeitung von {filename}: {str(e)}")
        # Fehlerhafte Dateien in einen 'error' Ordner verschieben
        error_dir = os.path.join(os.path.dirname(file_path), 'error')
        os.makedirs(error_dir, exist_ok=True)
        shutil.move(file_path, os.path.join(error_dir, filename))

def main():
    """Hauptfunktion des Skripts."""
    try:
        # Datenbankverbindung herstellen
        db_config = load_database_config()
        connection = mysql.connector.connect(**db_config)
        
        # Verarbeite alle CSV-Dateien im /files Ordner
        files_dir = 'test-files'
        files = sorted(os.listdir(files_dir))
        for filename in files:
            if filename.endswith('.csv'):
                file_path = os.path.join(files_dir, filename)
                process_csv_file(connection, file_path)
        
    except Error as e:
        print(f"Datenbankfehler: {str(e)}")
    except Exception as e:
        print(f"Allgemeiner Fehler: {str(e)}")
    finally:
        if 'connection' in locals() and connection.is_connected():
            connection.close()

if __name__ == "__main__":
    main()