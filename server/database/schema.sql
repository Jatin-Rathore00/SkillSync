-- =============================================================================
-- SkillSync – Campus Skill Exchange Platform
-- Relational Database DDL Schema (Strict 3NF)
-- Database: skillsync_db
-- =============================================================================

CREATE DATABASE IF NOT EXISTS skillsync_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE skillsync_db;

-- Drop dependent tables in reverse FK order to allow clean re-execution
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS skill_matches;
DROP TABLE IF EXISTS exchange_requests;
DROP TABLE IF EXISTS user_skills_wanted;
DROP TABLE IF EXISTS user_skills_offered;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

-- -----------------------------------------------------------------------------
-- 1. Table: users
-- Represents college student & administrator profiles.
-- Strictly 3NF: No derived average ratings stored here.
-- -----------------------------------------------------------------------------
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    college_email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    department VARCHAR(100) NOT NULL,
    year ENUM('1st Year', '2nd Year', '3rd Year', '4th Year', 'Postgraduate') NOT NULL,
    bio TEXT NULL,
    avatar VARCHAR(255) NULL,
    role ENUM('student', 'admin') NOT NULL DEFAULT 'student',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 2. Table: categories
-- Domain classifications for skills (e.g. Programming, Design, Languages).
-- -----------------------------------------------------------------------------
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 3. Table: skills
-- Master catalog of skills categorized into academic and professional domains.
-- -----------------------------------------------------------------------------
CREATE TABLE skills (
    skill_id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    skill_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL,
    difficulty ENUM('Beginner', 'Intermediate', 'Advanced') NOT NULL DEFAULT 'Intermediate',
    CONSTRAINT fk_skills_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 4. Table: user_skills_offered (Junction table: M:N Users <-> Skills to teach)
-- Composite PK (user_id, skill_id) guarantees no duplicate offerings.
-- -----------------------------------------------------------------------------
CREATE TABLE user_skills_offered (
    user_id INT NOT NULL,
    skill_id INT NOT NULL,
    proficiency_level ENUM('Beginner', 'Intermediate', 'Advanced', 'Expert') NOT NULL DEFAULT 'Intermediate',
    experience_years DECIMAL(3,1) NOT NULL DEFAULT 0.0 CHECK (experience_years >= 0.0),
    proof_url VARCHAR(255) NULL COMMENT 'Link to GitHub repo, portfolio, certificate',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, skill_id),
    CONSTRAINT fk_offered_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_offered_skill FOREIGN KEY (skill_id)
        REFERENCES skills(skill_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 5. Table: user_skills_wanted (Junction table: M:N Users <-> Skills to learn)
-- Composite PK (user_id, skill_id) guarantees no duplicate learning goals.
-- -----------------------------------------------------------------------------
CREATE TABLE user_skills_wanted (
    user_id INT NOT NULL,
    skill_id INT NOT NULL,
    urgency ENUM('Low', 'Medium', 'High') NOT NULL DEFAULT 'Medium',
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, skill_id),
    CONSTRAINT fk_wanted_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_wanted_skill FOREIGN KEY (skill_id)
        REFERENCES skills(skill_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 6. Table: exchange_requests
-- Learning requests submitted by a sender to a potential tutor/peer.
-- -----------------------------------------------------------------------------
CREATE TABLE exchange_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    skill_id INT NOT NULL,
    status ENUM('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED', 'COMPLETED') NOT NULL DEFAULT 'PENDING',
    message TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_requests_sender FOREIGN KEY (sender_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_requests_receiver FOREIGN KEY (receiver_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_requests_skill FOREIGN KEY (skill_id)
        REFERENCES skills(skill_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 7. Table: skill_matches
-- Materialized/persisted bilateral match compatibility between student pairs.
-- -----------------------------------------------------------------------------
CREATE TABLE skill_matches (
    match_id INT AUTO_INCREMENT PRIMARY KEY,
    user_a_id INT NOT NULL,
    user_b_id INT NOT NULL,
    match_score DECIMAL(5,2) NOT NULL CHECK (match_score >= 0.0 AND match_score <= 100.0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_match_pair UNIQUE (user_a_id, user_b_id),
    CONSTRAINT fk_match_user_a FOREIGN KEY (user_a_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_match_user_b FOREIGN KEY (user_b_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 8. Table: sessions
-- Scheduled learning sessions resulting from accepted exchange requests.
-- -----------------------------------------------------------------------------
CREATE TABLE sessions (
    session_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    teacher_id INT NOT NULL,
    learner_id INT NOT NULL,
    skill_id INT NOT NULL,
    scheduled_at DATETIME NOT NULL,
    duration_minutes INT NOT NULL DEFAULT 60 CHECK (duration_minutes > 0),
    mode ENUM('ONLINE', 'IN_PERSON') NOT NULL DEFAULT 'ONLINE',
    meeting_link VARCHAR(255) NULL,
    location VARCHAR(255) NULL,
    status ENUM('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'SCHEDULED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_session_request FOREIGN KEY (request_id)
        REFERENCES exchange_requests(request_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_session_teacher FOREIGN KEY (teacher_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_session_learner FOREIGN KEY (learner_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_session_skill FOREIGN KEY (skill_id)
        REFERENCES skills(skill_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 9. Table: reviews
-- Post-session evaluation and ratings (1-5 stars).
-- Unique constraint uk_session_reviewer prevents duplicate reviews per session.
-- -----------------------------------------------------------------------------
CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL,
    reviewer_id INT NOT NULL,
    reviewed_user_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_session_reviewer UNIQUE (session_id, reviewer_id),
    CONSTRAINT fk_reviews_session FOREIGN KEY (session_id)
        REFERENCES sessions(session_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_reviewer FOREIGN KEY (reviewer_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_reviewed_user FOREIGN KEY (reviewed_user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Performance & Optimization Indexes
-- -----------------------------------------------------------------------------
CREATE INDEX idx_users_email ON users(college_email);
CREATE INDEX idx_users_department ON users(department);
CREATE INDEX idx_skills_name ON skills(skill_name);
CREATE INDEX idx_skills_category ON skills(category_id);
CREATE INDEX idx_offered_skill ON user_skills_offered(skill_id);
CREATE INDEX idx_wanted_skill ON user_skills_wanted(skill_id);
CREATE INDEX idx_requests_status ON exchange_requests(status);
CREATE INDEX idx_requests_pair ON exchange_requests(sender_id, receiver_id);
CREATE INDEX idx_sessions_scheduled_status ON sessions(scheduled_at, status);
CREATE INDEX idx_sessions_participants ON sessions(teacher_id, learner_id);
CREATE INDEX idx_reviews_reviewed_user ON reviews(reviewed_user_id);
