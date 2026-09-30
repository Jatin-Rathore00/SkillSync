-- =============================================================================
-- SkillSync – Database Triggers
-- Business Rule Enforcement & Workflow Consistency
-- Database: skillsync_db
-- =============================================================================

USE skillsync_db;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- Trigger 1: trg_validate_exchange_request
-- Ensures a student cannot send an exchange request to themselves.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_validate_exchange_request$$
CREATE TRIGGER trg_validate_exchange_request
BEFORE INSERT ON exchange_requests
FOR EACH ROW
BEGIN
    IF NEW.sender_id = NEW.receiver_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Integrity Violation: Sender and receiver must be different students.';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- Trigger 2: trg_validate_session_participants
-- Ensures teacher and learner in a session are different students.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_validate_session_participants$$
CREATE TRIGGER trg_validate_session_participants
BEFORE INSERT ON sessions
FOR EACH ROW
BEGIN
    IF NEW.teacher_id = NEW.learner_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Integrity Violation: Teacher and learner must be different students.';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- Trigger 3: trg_prevent_review_unless_completed
-- Prevents reviews from being recorded unless the session is in 'COMPLETED' status.
-- Also verifies that reviewer and reviewed user are genuine participants of the session.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_prevent_review_unless_completed$$
CREATE TRIGGER trg_prevent_review_unless_completed
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_session_status VARCHAR(20);
    DECLARE v_teacher_id INT;
    DECLARE v_learner_id INT;

    SELECT status, teacher_id, learner_id 
    INTO v_session_status, v_teacher_id, v_learner_id
    FROM sessions
    WHERE session_id = NEW.session_id;

    -- 1. Verify session completion
    IF v_session_status IS NULL OR v_session_status <> 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Business Rule Violation: Reviews can only be submitted for sessions that are COMPLETED.';
    END IF;

    -- 2. Prevent self-review
    IF NEW.reviewer_id = NEW.reviewed_user_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Integrity Violation: A student cannot submit a review for themselves.';
    END IF;

    -- 3. Verify participant validity (only teacher or learner can review each other)
    IF NOT (
        (NEW.reviewer_id = v_teacher_id AND NEW.reviewed_user_id = v_learner_id) OR
        (NEW.reviewer_id = v_learner_id AND NEW.reviewed_user_id = v_teacher_id)
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Integrity Violation: Reviewer and reviewed student must be verified participants of the session.';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- Trigger 4: trg_prevent_session_for_non_accepted_request
-- Ensures a learning session cannot be created unless the exchange request is ACCEPTED.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_prevent_session_for_non_accepted_request$$
CREATE TRIGGER trg_prevent_session_for_non_accepted_request
BEFORE INSERT ON sessions
FOR EACH ROW
BEGIN
    DECLARE v_request_status VARCHAR(20);

    SELECT status INTO v_request_status
    FROM exchange_requests
    WHERE request_id = NEW.request_id;

    IF v_request_status IS NULL OR v_request_status <> 'ACCEPTED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Workflow Violation: Sessions can only be scheduled for exchange requests with ACCEPTED status.';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- Trigger 5: trg_sync_request_status_on_session_complete
-- Keeps request lifecycle synchronized when a learning session completes.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_sync_request_status_on_session_complete$$
CREATE TRIGGER trg_sync_request_status_on_session_complete
AFTER UPDATE ON sessions
FOR EACH ROW
BEGIN
    IF NEW.status = 'COMPLETED' AND OLD.status <> 'COMPLETED' THEN
        UPDATE exchange_requests
        SET status = 'COMPLETED'
        WHERE request_id = NEW.request_id;
    END IF;
END$$

DELIMITER ;
