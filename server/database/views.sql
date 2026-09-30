-- =============================================================================
-- SkillSync – Database Views
-- Relational Aggregations, Joins, and Matchmaking
-- Database: skillsync_db
-- =============================================================================

USE skillsync_db;

-- -----------------------------------------------------------------------------
-- View 1: v_student_profiles_with_stats
-- Computes student metrics dynamically without storing redundant avg_rating in users table (3NF compliant).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_student_profiles_with_stats AS
SELECT 
    u.user_id,
    u.name,
    u.email,
    u.department,
    u.year_of_study,
    u.bio,
    u.avatar_url,
    u.created_at,
    -- Dynamically aggregated rating from reviews
    COALESCE(ROUND(AVG(r.rating), 2), 0.00) AS avg_rating,
    COUNT(DISTINCT r.review_id) AS total_reviews,
    -- Dynamically counted skills offered and wanted
    (SELECT COUNT(*) FROM user_skills_offered uo WHERE uo.user_id = u.user_id) AS skills_offered_count,
    (SELECT COUNT(*) FROM user_skills_wanted uw WHERE uw.user_id = u.user_id) AS skills_wanted_count,
    -- Dynamically counted completed sessions as participant
    (
        SELECT COUNT(DISTINCT ls.session_id)
        FROM learning_sessions ls
        JOIN exchange_requests er ON ls.request_id = er.request_id
        WHERE (er.sender_id = u.user_id OR er.receiver_id = u.user_id)
          AND ls.status = 'COMPLETED'
    ) AS completed_sessions_count
FROM users u
LEFT JOIN reviews r ON u.user_id = r.reviewee_id
GROUP BY 
    u.user_id, 
    u.name, 
    u.email, 
    u.department, 
    u.year_of_study, 
    u.bio, 
    u.avatar_url, 
    u.created_at;

-- -----------------------------------------------------------------------------
-- View 2: v_mutual_skill_matches
-- Computes genuine 2-way skill exchange opportunities purely through relational joins.
-- Student A teaches what Student B wants, AND Student B teaches what Student A wants.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_mutual_skill_matches AS
SELECT 
    -- Student A details
    uo_a.user_id AS student_a_id,
    ua.name AS student_a_name,
    ua.department AS student_a_dept,
    ua.year_of_study AS student_a_year,
    -- Skill that Student A teaches and Student B wants
    skill_a_teaches.skill_id AS skill_a_offers_id,
    skill_a_teaches.skill_name AS skill_a_offers_name,
    uo_a.proficiency_level AS student_a_proficiency,
    -- Student B details
    uo_b.user_id AS student_b_id,
    ub.name AS student_b_name,
    ub.department AS student_b_dept,
    ub.year_of_study AS student_b_year,
    -- Skill that Student B teaches and Student A wants
    skill_b_teaches.skill_id AS skill_b_offers_id,
    skill_b_teaches.skill_name AS skill_b_offers_name,
    uo_b.proficiency_level AS student_b_proficiency
FROM user_skills_offered uo_a
-- Join with what Student B wants (matching Student A's offered skill)
JOIN user_skills_wanted uw_b 
    ON uo_a.skill_id = uw_b.skill_id 
   AND uo_a.user_id <> uw_b.user_id
-- Join with what Student B offers
JOIN user_skills_offered uo_b 
    ON uo_b.user_id = uw_b.user_id
-- Join with what Student A wants (matching Student B's offered skill)
JOIN user_skills_wanted uw_a 
    ON uw_a.user_id = uo_a.user_id 
   AND uw_a.skill_id = uo_b.skill_id
-- Join Student profiles
JOIN users ua ON uo_a.user_id = ua.user_id
JOIN users ub ON uo_b.user_id = ub.user_id
-- Join Skill names
JOIN skills skill_a_teaches ON uo_a.skill_id = skill_a_teaches.skill_id
JOIN skills skill_b_teaches ON uo_b.skill_id = skill_b_teaches.skill_id
WHERE uo_a.user_id < uo_b.user_id; -- Avoid symmetric mirror duplicates (A-B and B-A)

-- -----------------------------------------------------------------------------
-- View 3: v_session_details
-- Full relational projection for scheduled learning sessions
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_session_details AS
SELECT 
    ls.session_id,
    ls.request_id,
    ls.scheduled_time,
    ls.duration_minutes,
    ls.meeting_type,
    ls.meeting_location,
    ls.status AS session_status,
    ls.session_notes,
    ls.created_at AS session_created_at,
    -- Request & Participant details
    er.sender_id,
    sender.name AS sender_name,
    sender.email AS sender_email,
    er.receiver_id,
    receiver.name AS receiver_name,
    receiver.email AS receiver_email,
    -- Skill details
    offered_skill.skill_id AS offered_skill_id,
    offered_skill.skill_name AS offered_skill_name,
    wanted_skill.skill_id AS wanted_skill_id,
    wanted_skill.skill_name AS wanted_skill_name
FROM learning_sessions ls
JOIN exchange_requests er ON ls.request_id = er.request_id
JOIN users sender ON er.sender_id = sender.user_id
JOIN users receiver ON er.receiver_id = receiver.user_id
JOIN skills offered_skill ON er.offered_skill_id = offered_skill.skill_id
JOIN skills wanted_skill ON er.wanted_skill_id = wanted_skill.skill_id;
