-- =========================================================
-- Virtuāls uzdevumu plānotājs komandai
-- MariaDB datubāzes sākotnējās struktūras izveide
-- =========================================================


-- =========================================================
-- 1. Datubāzes izveide
-- =========================================================

CREATE DATABASE IF NOT EXISTS team_task_planner
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE team_task_planner;


-- =========================================================
-- 2. Teams
-- =========================================================
-- owner_id ārējā atslēga tiek pievienota vēlāk,
-- jo Users tabula šajā brīdī vēl nav izveidota.

CREATE TABLE IF NOT EXISTS Teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    owner_id INT NULL
);


-- =========================================================
-- 3. Users
-- =========================================================

CREATE TABLE IF NOT EXISTS Users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    team_id INT NULL,

    CONSTRAINT fk_users_team
        FOREIGN KEY (team_id)
        REFERENCES Teams(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);


-- =========================================================
-- 4. Teams vadītāja ārējā atslēga
-- =========================================================

ALTER TABLE Teams
ADD CONSTRAINT fk_teams_owner
FOREIGN KEY (owner_id)
REFERENCES Users(id)
ON DELETE SET NULL
ON UPDATE CASCADE;


-- =========================================================
-- 5. Status
-- =========================================================

CREATE TABLE IF NOT EXISTS Status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);


-- =========================================================
-- 6. Tasks
-- =========================================================

CREATE TABLE IF NOT EXISTS Tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status_id INT NOT NULL,
    assigned_to INT NULL,
    team_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_tasks_status
        FOREIGN KEY (status_id)
        REFERENCES Status(id)
        ON UPDATE CASCADE,

    CONSTRAINT fk_tasks_assigned_user
        FOREIGN KEY (assigned_to)
        REFERENCES Users(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_tasks_team
        FOREIGN KEY (team_id)
        REFERENCES Teams(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =========================================================
-- 7. Comments
-- =========================================================

CREATE TABLE IF NOT EXISTS Comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    user_id INT NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_comments_task
        FOREIGN KEY (task_id)
        REFERENCES Tasks(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_comments_user
        FOREIGN KEY (user_id)
        REFERENCES Users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =========================================================
-- 8. Sākotnējie uzdevumu statusi
-- =========================================================

INSERT IGNORE INTO Status (id, name)
VALUES
    (1, 'New'),
    (2, 'In Progress'),
    (3, 'Done');