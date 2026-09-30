-- =============================================================================
-- SkillSync – Campus Skill Exchange Platform
-- DBMS PBL Schema (Normalized to 3NF)
-- Database: skillsync_db
-- =============================================================================

CREATE DATABASE IF NOT EXISTS skillsync_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE skillsync_db;

-- -----------------------------------------------------------------------------
-- 1. Table: users
-- Note: In accordance with 3NF, avg_rating is NOT stored here to avoid transitive
-- functional dependencies. It is dynamically computed from reviews via SQL views.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    department VARCHAR(100) NOT NULL,
    year_of_study ENUM('1st Year', '2nd Year', '3rd Year', '4th Year', 'Postgraduate') NOT NULL,
    bio TEXT NULL,
    avatar_url VARCHAR(255) DEFAULT 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 2. Table: categories
-- Skill classification domains (Academic, Technical, Creative, etc.)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 3. Table: skills
-- Standardized skills categorized within domains
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS skills (
    skill_id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    skill_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL,
    CONSTRAINT fk_skills_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 4. Table: user_skills_offered (Junction table resolving M:N User <-> Skills to teach)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_skills_offered (
    offered_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    skill_id INT NOT NULL,
    proficiency_level ENUM('Beginner', 'Intermediate', 'Advanced', 'Expert') NOT NULL DEFAULT 'Intermediate',
    years_of_experience DECIMAL(3,1) DEFAULT 1.0,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_user_offered_skill UNIQUE (user_id, skill_id),
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
-- 5. Table: user_skills_wanted (Junction table resolving M:N User <-> Skills to learn)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_skills_wanted (
    wanted_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    skill_id INT NOT NULL,
    priority_level ENUM('Low', 'Medium', 'High') NOT NULL DEFAULT 'Medium',
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_user_wanted_skill UNIQUE (user_id, skill_id),
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
-- Represents a mutual proposal between two students
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS exchange_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    offered_skill_id INT NOT NULL,
    wanted_skill_id INT NOT NULL,
    status ENUM('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED', 'COMPLETED') NOT NULL DEFAULT 'PENDING',
    message TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_different_students CHECK (sender_id <> receiver_id),
    CONSTRAINT fk_req_sender FOREIGN KEY (sender_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_req_receiver FOREIGN KEY (receiver_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_req_offered_skill FOREIGN KEY (offered_skill_id)
        REFERENCES skills(skill_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_req_wanted_skill FOREIGN KEY (wanted_skill_id)
        REFERENCES skills(skill_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 7. Table: learning_sessions
-- Scheduled teaching/learning sessions resulting from an accepted request
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS learning_sessions (
    session_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    scheduled_time DATETIME NOT NULL,
    duration_minutes INT NOT NULL DEFAULT 60,
    meeting_type ENUM('ONLINE', 'IN_PERSON') NOT NULL DEFAULT 'ONLINE',
    meeting_location VARCHAR(255) NOT NULL COMMENT 'Google Meet/Zoom link or campus room/library table',
    status ENUM('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'SCHEDULED',
    session_notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_positive_duration CHECK (duration_minutes > 0),
    CONSTRAINT fk_session_request FOREIGN KEY (request_id)
        REFERENCES exchange_requests(request_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 8. Table: reviews
-- Post-session rating and feedback given by one participant to another
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL,
    reviewer_id INT NOT NULL,
    reviewee_id INT NOT NULL,
    rating INT NOT NULL,
    comment TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_rating_range CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT chk_reviewer_reviewee CHECK (reviewer_id <> reviewee_id),
    CONSTRAINT uk_session_reviewer UNIQUE (session_id, reviewer_id),
    CONSTRAINT fk_rev_session FOREIGN KEY (session_id)
        REFERENCES learning_sessions(session_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_rev_reviewer FOREIGN KEY (reviewer_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_rev_reviewee FOREIGN KEY (reviewee_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Indexes for performance & query optimization
-- -----------------------------------------------------------------------------
CREATE INDEX idx_skills_name ON skills(skill_name);
CREATE INDEX idx_offered_user_skill ON user_skills_offered(user_id, skill_id);
CREATE INDEX idx_wanted_user_skill ON user_skills_wanted(user_id, skill_id);
CREATE INDEX idx_requests_status ON exchange_requests(status);
CREATE INDEX idx_requests_pair ON exchange_requests(sender_id, receiver_id);
CREATE INDEX idx_sessions_time_status ON learning_sessions(scheduled_time, status);
CREATE INDEX idx_reviews_reviewee ON reviews(reviewee_id);
