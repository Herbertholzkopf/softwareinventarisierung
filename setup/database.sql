USE softwareinventar;

CREATE TABLE computer (
    computer_id INT AUTO_INCREMENT PRIMARY KEY,
    computer_name VARCHAR(255) NOT NULL,
    computer_type VARCHAR(20) NOT NULL DEFAULT 'Client' CHECK (computer_type IN ('Client', 'Server')),
    UNIQUE KEY (computer_name)
);

CREATE TABLE user (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    UNIQUE KEY (username)
);

CREATE TABLE software_scan (
    scan_id INT AUTO_INCREMENT PRIMARY KEY,
    computer_id INT NOT NULL,
    user_id INT NOT NULL,
    scan_version INT NOT NULL,
    scan_date TIMESTAMP NOT NULL,
    FOREIGN KEY (computer_id) REFERENCES computer(computer_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    INDEX idx_computer_version (computer_id, scan_version)
);

CREATE TABLE software (
    software_id INT AUTO_INCREMENT PRIMARY KEY,
    scan_id INT NOT NULL,
    display_name VARCHAR(255),
    display_version VARCHAR(100),
    publisher VARCHAR(255),
    install_date DATE,
    FOREIGN KEY (scan_id) REFERENCES software_scan(scan_id)
);