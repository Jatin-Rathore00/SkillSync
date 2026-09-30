-- =============================================================================
-- SkillSync – Stored Procedures & Transactions
-- Matchmaking Engine & ACID Session Booking
-- Database: skillsync_db
-- =============================================================================

USE skillsync_db;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- Procedure 1: sp_find_skill_matches
-- Finds bilateral matches for a given student with calculated compatibility scores.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_find_skill_matches$$
CREATE PROCEDURE sp_find_skill_matches(
    IN p_user_id INT
)
BEGIN
    SELECT 
        -- Target student details
        p_user_id AS student_id,
        -- Peer matched student
        peer.user_id AS matched_user_id,
        peer.name AS matched_user_name,
        peer.college_email AS matched_user_email,
        peer.department AS matched_user_department,
        peer.year AS matched_user_year,
        peer.avatar AS matched_user_avatar,
        -- Dynamically calculated rating for peer from reviews table
        COALESCE(ROUND(AVG(r.rating), 2), 0.00) AS matched_user_avg_rating,
        COUNT(DISTINCT r.review_id) AS matched_user_review_count,
        -- Skill target student can teach peer
        teach_s.skill_id AS you_teach_skill_id,
        teach_s.skill_name AS you_teach_skill_name,
        my_offer.proficiency_level AS your_proficiency,
        my_offer.experience_years AS your_experience,
        -- Skill peer can teach target student
        learn_s.skill_id AS peer_teaches_skill_id,
        learn_s.skill_name AS peer_teaches_skill_name,
        peer_offer.proficiency_level AS peer_proficiency,
        peer_offer.experience_years AS peer_experience,
        -- Compatibility Score Calculation (Base 60 + Proficiency Weights)
        ROUND(
            60.00 + 
            (CASE my_offer.proficiency_level WHEN 'Expert' THEN 20.00 WHEN 'Advanced' THEN 15.00 WHEN 'Intermediate' THEN 10.00 ELSE 5.00 END) +
            (CASE peer_offer.proficiency_level WHEN 'Expert' THEN 20.00 WHEN 'Advanced' THEN 15.00 WHEN 'Intermediate' THEN 10.00 ELSE 5.00 END),
            2
        ) AS compatibility_score
    FROM user_skills_offered my_offer
    -- Peer wants what I offer
    JOIN user_skills_wanted peer_want 
        ON my_offer.skill_id = peer_want.skill_id 
       AND my_offer.user_id <> peer_want.user_id
    -- Peer offers what I want
    JOIN user_skills_offered peer_offer 
        ON peer_offer.user_id = peer_want.user_id
    JOIN user_skills_wanted my_want 
        ON my_want.user_id = my_offer.user_id 
       AND my_want.skill_id = peer_offer.skill_id
    -- Join User & Skill tables
    JOIN users peer ON peer_offer.user_id = peer.user_id
    JOIN skills teach_s ON my_offer.skill_id = teach_s.skill_id
    JOIN skills learn_s ON peer_offer.skill_id = learn_s.skill_id
    LEFT JOIN reviews r ON peer.user_id = r.reviewed_user_id
    WHERE my_offer.user_id = p_user_id
    GROUP BY 
        peer.user_id, peer.name, peer.college_email, peer.department, 
        peer.year, peer.avatar,
        teach_s.skill_id, teach_s.skill_name, my_offer.proficiency_level, my_offer.experience_years,
        learn_s.skill_id, learn_s.skill_name, peer_offer.proficiency_level, peer_offer.experience_years
    ORDER BY compatibility_score DESC, peer.name ASC;
END$$

-- -----------------------------------------------------------------------------
-- Procedure 2: sp_book_session_transaction
-- ACID-compliant transaction with pessimistic row-locking (FOR UPDATE)
-- Atomically transitions request to ACCEPTED and books the learning session.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_book_session_transaction$$
CREATE PROCEDURE sp_book_session_transaction(
    IN p_request_id INT,
    IN p_scheduled_at DATETIME,
    IN p_duration_minutes INT,
    IN p_mode ENUM('ONLINE', 'IN_PERSON'),
    IN p_meeting_link VARCHAR(255),
    IN p_location VARCHAR(255),
    OUT p_session_id INT,
    OUT p_status_code VARCHAR(30),
    OUT p_status_message VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_current_status VARCHAR(20);
    DECLARE v_sender_id INT;
    DECLARE v_receiver_id INT;
    DECLARE v_skill_id INT;

    -- Exception handler to ensure atomicity with explicit ROLLBACK
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_session_id = NULL;
        SET p_status_code = 'ERR_SQL_EXCEPTION';
        SET p_status_message = 'Transaction aborted: an unexpected SQL error occurred.';
    END;

    -- 1. Start atomic transaction
    START TRANSACTION;

    -- 2. Lock request row pessimistically to prevent concurrent modification race conditions
    SELECT status, sender_id, receiver_id, skill_id
    INTO v_current_status, v_sender_id, v_receiver_id, v_skill_id
    FROM exchange_requests
    WHERE request_id = p_request_id
    FOR UPDATE;

    -- 3. Validate existence
    IF v_current_status IS NULL THEN
        ROLLBACK;
        SET p_session_id = NULL;
        SET p_status_code = 'REQUEST_NOT_FOUND';
        SET p_status_message = 'Exchange request does not exist.';
        LEAVE proc_label;
    END IF;

    -- 4. Validate current status (can be ACCEPTED or PENDING being approved)
    IF v_current_status NOT IN ('PENDING', 'ACCEPTED') THEN
        ROLLBACK;
        SET p_session_id = NULL;
        SET p_status_code = 'INVALID_REQUEST_STATUS';
        SET p_status_message = CONCAT('Cannot schedule session: request is currently ', v_current_status);
        LEAVE proc_label;
    END IF;

    -- 5. If PENDING, promote request to ACCEPTED
    IF v_current_status = 'PENDING' THEN
        UPDATE exchange_requests
        SET status = 'ACCEPTED'
        WHERE request_id = p_request_id;
    END IF;

    -- 6. Insert new learning session (sender is learner, receiver is teacher)
    INSERT INTO sessions (
        request_id,
        teacher_id,
        learner_id,
        skill_id,
        scheduled_at,
        duration_minutes,
        mode,
        meeting_link,
        location,
        status
    ) VALUES (
        p_request_id,
        v_receiver_id,
        v_sender_id,
        v_skill_id,
        p_scheduled_at,
        p_duration_minutes,
        p_mode,
        p_meeting_link,
        p_location,
        'SCHEDULED'
    );

    SET p_session_id = LAST_INSERT_ID();

    -- 7. Commit atomic transaction
    COMMIT;

    SET p_status_code = 'SUCCESS';
    SET p_status_message = 'Exchange accepted and session successfully scheduled.';
END$$

DELIMITER ;
