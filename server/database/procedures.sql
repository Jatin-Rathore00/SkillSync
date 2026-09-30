-- =============================================================================
-- SkillSync – Stored Procedures & Transactions
-- ACID Transaction Management and Targeted Matchmaking
-- Database: skillsync_db
-- =============================================================================

USE skillsync_db;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- Procedure 1: sp_schedule_session_transaction
-- Demonstrates ACID transaction with pessimistic row-locking (FOR UPDATE)
-- to safely schedule a session for an accepted exchange request.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_schedule_session_transaction$$
CREATE PROCEDURE sp_schedule_session_transaction(
    IN p_request_id INT,
    IN p_scheduled_time DATETIME,
    IN p_duration_minutes INT,
    IN p_meeting_type ENUM('ONLINE', 'IN_PERSON'),
    IN p_meeting_location VARCHAR(255),
    IN p_session_notes TEXT,
    OUT p_session_id INT,
    OUT p_status_code VARCHAR(20),
    OUT p_status_message VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_current_status VARCHAR(20);

    -- Declare exception handler to ensure atomicity via ROLLBACK
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_session_id = NULL;
        SET p_status_code = 'ERR_SQL_EXCEPTION';
        SET p_status_message = 'Transaction aborted due to a database exception.';
    END;

    -- 1. Begin atomic transaction
    START TRANSACTION;

    -- 2. Lock request row for update to prevent concurrent race conditions
    SELECT status INTO v_current_status
    FROM exchange_requests
    WHERE request_id = p_request_id
    FOR UPDATE;

    -- 3. Validate existence and status
    IF v_current_status IS NULL THEN
        ROLLBACK;
        SET p_session_id = NULL;
        SET p_status_code = 'NOT_FOUND';
        SET p_status_message = 'Exchange request does not exist.';
        LEAVE proc_label;
    END IF;

    IF v_current_status <> 'ACCEPTED' THEN
        ROLLBACK;
        SET p_session_id = NULL;
        SET p_status_code = 'INVALID_STATUS';
        SET p_status_message = CONCAT('Cannot schedule session: request is currently ', v_current_status);
        LEAVE proc_label;
    END IF;

    -- 4. Insert learning session
    INSERT INTO learning_sessions (
        request_id,
        scheduled_time,
        duration_minutes,
        meeting_type,
        meeting_location,
        status,
        session_notes
    ) VALUES (
        p_request_id,
        p_scheduled_time,
        p_duration_minutes,
        p_meeting_type,
        p_meeting_location,
        'SCHEDULED',
        p_session_notes
    );

    SET p_session_id = LAST_INSERT_ID();

    -- 5. Commit atomic transaction
    COMMIT;

    SET p_status_code = 'SUCCESS';
    SET p_status_message = 'Session scheduled successfully.';
END$$

-- -----------------------------------------------------------------------------
-- Procedure 2: sp_get_student_mutual_matches
-- Finds 2-way skill exchange partners for a specific student using relational joins.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_get_student_mutual_matches$$
CREATE PROCEDURE sp_get_student_mutual_matches(
    IN p_user_id INT
)
BEGIN
    SELECT 
        -- Matched partner details
        partner.user_id AS partner_id,
        partner.name AS partner_name,
        partner.email AS partner_email,
        partner.department AS partner_dept,
        partner.year_of_study AS partner_year,
        partner.avatar_url AS partner_avatar,
        -- Dynamically calculated partner rating
        COALESCE(ROUND(AVG(r.rating), 2), 0.00) AS partner_avg_rating,
        COUNT(DISTINCT r.review_id) AS partner_review_count,
        -- What the target student can teach the partner
        teach_skill.skill_id AS you_teach_skill_id,
        teach_skill.skill_name AS you_teach_skill_name,
        my_offer.proficiency_level AS your_proficiency,
        -- What the partner can teach the target student
        learn_skill.skill_id AS partner_teaches_skill_id,
        learn_skill.skill_name AS partner_teaches_skill_name,
        partner_offer.proficiency_level AS partner_proficiency
    FROM user_skills_offered my_offer
    -- Partner wants what I offer
    JOIN user_skills_wanted partner_want 
        ON my_offer.skill_id = partner_want.skill_id 
       AND my_offer.user_id <> partner_want.user_id
    -- Partner offers what I want
    JOIN user_skills_offered partner_offer 
        ON partner_offer.user_id = partner_want.user_id
    JOIN user_skills_wanted my_want 
        ON my_want.user_id = my_offer.user_id 
       AND my_want.skill_id = partner_offer.skill_id
    -- Details
    JOIN users partner ON partner_offer.user_id = partner.user_id
    JOIN skills teach_skill ON my_offer.skill_id = teach_skill.skill_id
    JOIN skills learn_skill ON partner_offer.skill_id = learn_skill.skill_id
    LEFT JOIN reviews r ON partner.user_id = r.reviewee_id
    WHERE my_offer.user_id = p_user_id
    GROUP BY 
        partner.user_id, partner.name, partner.email, partner.department, 
        partner.year_of_study, partner.avatar_url,
        teach_skill.skill_id, teach_skill.skill_name, my_offer.proficiency_level,
        learn_skill.skill_id, learn_skill.skill_name, partner_offer.proficiency_level;
END$$

DELIMITER ;
