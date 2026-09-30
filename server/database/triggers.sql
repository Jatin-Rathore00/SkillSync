-- =============================================================================
-- SkillSync – Database Triggers
-- Business Rule Enforcement & Workflow Consistency
-- Database: skillsync_db
-- =============================================================================

USE skillsync_db;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- Trigger 1: trg_validate_review_eligibility
-- Ensures reviews can ONLY be submitted by genuine participants of a COMPLETED session.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_validate_review_eligibility$$
CREATE TRIGGER trg_validate_review_eligibility
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    DECLARE v_session_status VARCHAR(20);
    DECLARE v_sender_id INT;
    DECLARE v_receiver_id INT;

    -- Retrieve session status and participant IDs from the underlying request
    SELECT ls.status, er.sender_id, er.receiver_id
    INTO v_session_status, v_sender_id, v_receiver_id
    FROM learning_sessions ls
    JOIN exchange_requests er ON ls.request_id = er.request_id
    WHERE ls.session_id = NEW.session_id;

    -- 1. Check if session was completed
    IF v_session_status IS NULL OR v_session_status <> 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Integrity Violation: Reviews can only be submitted after a session is marked COMPLETED.';
    END IF;

    -- 2. Check if reviewer and reviewee are the two participants of the exchange
    IF NOT (
        (NEW.reviewer_id = v_sender_id AND NEW.reviewee_id = v_receiver_id) OR
        (NEW.reviewer_id = v_receiver_id AND NEW.reviewee_id = v_sender_id)
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Integrity Violation: Reviewer and reviewee must be verified participants of the scheduled session.';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- Trigger 2: trg_prevent_session_for_unaccepted_request
-- Ensures a learning session cannot be scheduled unless the exchange request was ACCEPTED.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_prevent_session_for_unaccepted_request$$
CREATE TRIGGER trg_prevent_session_for_unaccepted_request
BEFORE INSERT ON learning_sessions
FOR EACH ROW
BEGIN
    DECLARE v_request_status VARCHAR(20);

    SELECT status INTO v_request_status
    FROM exchange_requests
    WHERE request_id = NEW.request_id;

    IF v_request_status IS NULL OR v_request_status <> 'ACCEPTED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Integrity Violation: Sessions can only be scheduled for requests with ACCEPTED status.';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- Trigger 3: trg_sync_request_status_on_session_complete
-- Keeps request lifecycle in sync: once session is marked COMPLETED, update request status.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_sync_request_status_on_session_complete$$
CREATE TRIGGER trg_sync_request_status_on_session_complete
AFTER UPDATE ON learning_sessions
FOR EACH ROW
BEGIN
    IF NEW.status = 'COMPLETED' AND OLD.status <> 'COMPLETED' THEN
        UPDATE exchange_requests
        SET status = 'COMPLETED'
        WHERE request_id = NEW.request_id;
    END IF;
END$$

DELIMITER ;
