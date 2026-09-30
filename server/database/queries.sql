-- =============================================================================
-- SkillSync – Academic DBMS Demonstration Queries
-- Comprehensive SQL Demonstrating Core Relational Concepts for Evaluation
-- Database: skillsync_db
-- =============================================================================

USE skillsync_db;

-- =============================================================================
-- SECTION 1: MANDATORY COLLEGE EVALUATION QUERIES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 1.1: Find all students who teach "Java Programming"
-- Demonstrates: INNER JOIN across 3 tables, WHERE filter, ORDER BY
-- -----------------------------------------------------------------------------
SELECT 
    u.user_id,
    u.name AS student_name,
    u.college_email,
    u.department,
    u.year,
    uo.proficiency_level,
    uo.experience_years,
    uo.proof_url
FROM users u
INNER JOIN user_skills_offered uo ON u.user_id = uo.user_id
INNER JOIN skills s ON uo.skill_id = s.skill_id
WHERE s.skill_name LIKE '%Java%'
ORDER BY uo.experience_years DESC, u.name ASC;

-- -----------------------------------------------------------------------------
-- Query 1.2: Find all students who want to learn "Java Programming"
-- Demonstrates: INNER JOIN, filtering on wanted skill, urgency sorting
-- -----------------------------------------------------------------------------
SELECT 
    u.user_id,
    u.name AS student_name,
    u.college_email,
    u.department,
    u.year,
    uw.urgency,
    uw.notes
FROM users u
INNER JOIN user_skills_wanted uw ON u.user_id = uw.user_id
INNER JOIN skills s ON uw.skill_id = s.skill_id
WHERE s.skill_name LIKE '%Java%'
ORDER BY 
    CASE uw.urgency 
        WHEN 'High' THEN 1 
        WHEN 'Medium' THEN 2 
        WHEN 'Low' THEN 3 
    END;

-- -----------------------------------------------------------------------------
-- Query 1.3: Find reciprocal (two-way) skill matches between students
-- Demonstrates: 4-Way Self Join between offered and wanted skills, symmetric elimination
-- -----------------------------------------------------------------------------
SELECT 
    ua.name AS student_a,
    sa.skill_name AS student_a_teaches,
    ub.name AS student_b,
    sb.skill_name AS student_b_teaches,
    ROUND(
        60.00 + 
        (CASE uoa.proficiency_level WHEN 'Expert' THEN 20.00 WHEN 'Advanced' THEN 15.00 WHEN 'Intermediate' THEN 10.00 ELSE 5.00 END) +
        (CASE uob.proficiency_level WHEN 'Expert' THEN 20.00 WHEN 'Advanced' THEN 15.00 WHEN 'Intermediate' THEN 10.00 ELSE 5.00 END),
        2
    ) AS match_compatibility_score
FROM user_skills_offered uoa
JOIN user_skills_wanted uwb ON uoa.skill_id = uwb.skill_id AND uoa.user_id <> uwb.user_id
JOIN user_skills_offered uob ON uob.user_id = uwb.user_id
JOIN user_skills_wanted uwa ON uwa.user_id = uoa.user_id AND uwa.skill_id = uob.skill_id
JOIN users ua ON uoa.user_id = ua.user_id
JOIN users ub ON uob.user_id = ub.user_id
JOIN skills sa ON uoa.skill_id = sa.skill_id
JOIN skills sb ON uob.skill_id = sb.skill_id
WHERE uoa.user_id < uob.user_id
ORDER BY match_compatibility_score DESC;

-- -----------------------------------------------------------------------------
-- Query 1.4: Find the most popular skills (ranked by combined demand and supply)
-- Demonstrates: LEFT JOIN, GROUP BY, Aggregate functions (COUNT), Derived Subqueries
-- -----------------------------------------------------------------------------
SELECT 
    s.skill_id,
    s.skill_name,
    c.category_name,
    COUNT(DISTINCT uo.user_id) AS total_teachers,
    COUNT(DISTINCT uw.user_id) AS total_learners,
    (COUNT(DISTINCT uo.user_id) + COUNT(DISTINCT uw.user_id)) AS total_interest
FROM skills s
INNER JOIN categories c ON s.category_id = c.category_id
LEFT JOIN user_skills_offered uo ON s.skill_id = uo.skill_id
LEFT JOIN user_skills_wanted uw ON s.skill_id = uw.skill_id
GROUP BY s.skill_id, s.skill_name, c.category_name
ORDER BY total_interest DESC, total_learners DESC;

-- -----------------------------------------------------------------------------
-- Query 1.5: Find students with the highest average ratings
-- Demonstrates: LEFT JOIN, Aggregate AVG, HAVING clause, and 3NF dynamic calculation
-- -----------------------------------------------------------------------------
SELECT 
    u.user_id,
    u.name,
    u.college_email,
    u.department,
    COALESCE(ROUND(AVG(r.rating), 2), 0.00) AS average_rating,
    COUNT(r.review_id) AS total_reviews
FROM users u
INNER JOIN reviews r ON u.user_id = r.reviewed_user_id
GROUP BY u.user_id, u.name, u.college_email, u.department
HAVING COUNT(r.review_id) >= 1
ORDER BY average_rating DESC, total_reviews DESC;

-- -----------------------------------------------------------------------------
-- Query 1.6: Find students with the most completed sessions
-- Demonstrates: Conditional counting, Subquery / UNION, GROUP BY, ORDER BY
-- -----------------------------------------------------------------------------
SELECT 
    u.user_id,
    u.name,
    u.department,
    COUNT(s.session_id) AS completed_sessions,
    SUM(s.duration_minutes) AS total_learning_minutes,
    ROUND(SUM(s.duration_minutes) / 60.0, 1) AS total_learning_hours
FROM users u
INNER JOIN sessions s ON (u.user_id = s.teacher_id OR u.user_id = s.learner_id)
WHERE s.status = 'COMPLETED'
GROUP BY u.user_id, u.name, u.department
ORDER BY completed_sessions DESC, total_learning_minutes DESC;

-- -----------------------------------------------------------------------------
-- Query 1.7: Find all upcoming scheduled sessions
-- Demonstrates: Multi-table JOIN (sessions, users as teacher, users as learner, skills)
-- -----------------------------------------------------------------------------
SELECT 
    s.session_id,
    s.scheduled_at,
    s.duration_minutes,
    s.mode,
    COALESCE(s.meeting_link, s.location) AS connection_or_venue,
    t.name AS teacher_name,
    t.college_email AS teacher_email,
    l.name AS learner_name,
    l.college_email AS learner_email,
    sk.skill_name
FROM sessions s
INNER JOIN users t ON s.teacher_id = t.user_id
INNER JOIN users l ON s.learner_id = l.user_id
INNER JOIN skills sk ON s.skill_id = sk.skill_id
WHERE s.status = 'SCHEDULED'
ORDER BY s.scheduled_at ASC;

-- -----------------------------------------------------------------------------
-- Query 1.8: Find all pending exchange requests awaiting approval
-- Demonstrates: Filtering on status, self-documenting sender and receiver details
-- -----------------------------------------------------------------------------
SELECT 
    er.request_id,
    er.created_at AS request_date,
    sender.name AS sender_name,
    sender.college_email AS sender_email,
    receiver.name AS receiver_name,
    receiver.college_email AS receiver_email,
    s.skill_name AS requested_skill,
    er.message
FROM exchange_requests er
INNER JOIN users sender ON er.sender_id = sender.user_id
INNER JOIN users receiver ON er.receiver_id = receiver.user_id
INNER JOIN skills s ON er.skill_id = s.skill_id
WHERE er.status = 'PENDING'
ORDER BY er.created_at DESC;

-- -----------------------------------------------------------------------------
-- Query 1.9: Show a student's complete skill-exchange history (e.g. for user_id = 1)
-- Demonstrates: Correlated history across teaching, learning, and reviews
-- -----------------------------------------------------------------------------
SELECT 
    s.session_id,
    s.scheduled_at,
    s.duration_minutes,
    sk.skill_name,
    CASE 
        WHEN s.teacher_id = 1 THEN 'TAUGHT'
        ELSE 'LEARNED'
    END AS role_in_session,
    CASE 
        WHEN s.teacher_id = 1 THEN learner.name
        ELSE teacher.name
    END AS peer_student_name,
    s.mode,
    s.status AS session_status,
    r.rating AS rating_received,
    r.comment AS feedback_received
FROM sessions s
INNER JOIN users teacher ON s.teacher_id = teacher.user_id
INNER JOIN users learner ON s.learner_id = learner.user_id
INNER JOIN skills sk ON s.skill_id = sk.skill_id
LEFT JOIN reviews r ON s.session_id = r.session_id AND r.reviewed_user_id = 1
WHERE (s.teacher_id = 1 OR s.learner_id = 1)
ORDER BY s.scheduled_at DESC;


-- =============================================================================
-- SECTION 2: CORE SQL CRUD AND ADVANCED RELATIONAL CONCEPTS
-- =============================================================================

-- 2.1 INSERT: Adding a new user and skill offering
INSERT INTO users (name, college_email, password_hash, department, year, bio)
VALUES ('Kavita Mehra', 'kavita.mehra@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Computer Engineering', '2nd Year', 'Full stack enthusiast');

-- 2.2 UPDATE: Modifying proficiency level
UPDATE user_skills_offered
SET proficiency_level = 'Expert', experience_years = 3.5
WHERE user_id = 1 AND skill_id = 1;

-- 2.3 DELETE: Removing a cancelled request
DELETE FROM exchange_requests
WHERE status = 'CANCELLED' AND created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- 2.4 SUBQUERY with NOT IN: Find students who have never booked a session
SELECT u.user_id, u.name, u.college_email
FROM users u
WHERE u.user_id NOT IN (
    SELECT teacher_id FROM sessions
    UNION
    SELECT learner_id FROM sessions
);

-- 2.5 SUM and GROUP BY with HAVING: Departments with more than 100 minutes of tutoring
SELECT 
    u.department,
    COUNT(s.session_id) AS total_sessions,
    SUM(s.duration_minutes) AS total_minutes_exchanged
FROM users u
INNER JOIN sessions s ON (u.user_id = s.teacher_id OR u.user_id = s.learner_id)
WHERE s.status = 'COMPLETED'
GROUP BY u.department
HAVING SUM(s.duration_minutes) >= 60
ORDER BY total_minutes_exchanged DESC;
