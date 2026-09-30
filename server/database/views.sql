-- =============================================================================
-- SkillSync – Database Views
-- Relational Aggregations, Matchmaking & Projections
-- Database: skillsync_db
-- =============================================================================

USE skillsync_db;

-- -----------------------------------------------------------------------------
-- View 1: v_mutual_matches
-- Computes genuine 2-way skill exchange pairs purely via relational joins.
-- Student A teaches what Student B wants, AND Student B teaches what Student A wants.
-- Also calculates a meaningful match compatibility score (0 to 100) based on proficiency.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_mutual_matches AS
SELECT 
    -- Student A
    uo_a.user_id AS student_a_id,
    ua.name AS student_a_name,
    ua.college_email AS student_a_email,
    ua.department AS student_a_dept,
    ua.year AS student_a_year,
    -- Skill A offers & B wants
    skill_a_offers.skill_id AS skill_a_offers_id,
    skill_a_offers.skill_name AS skill_a_offers_name,
    uo_a.proficiency_level AS student_a_proficiency,
    -- Student B
    uo_b.user_id AS student_b_id,
    ub.name AS student_b_name,
    ub.college_email AS student_b_email,
    ub.department AS student_b_dept,
    ub.year AS student_b_year,
    -- Skill B offers & A wants
    skill_b_offers.skill_id AS skill_b_offers_id,
    skill_b_offers.skill_name AS skill_b_offers_name,
    uo_b.proficiency_level AS student_b_proficiency,
    -- Calculated Match Score (Base 60 + Proficiency weight A + Proficiency weight B)
    ROUND(
        60.00 + 
        (CASE uo_a.proficiency_level WHEN 'Expert' THEN 20.00 WHEN 'Advanced' THEN 15.00 WHEN 'Intermediate' THEN 10.00 ELSE 5.00 END) +
        (CASE uo_b.proficiency_level WHEN 'Expert' THEN 20.00 WHEN 'Advanced' THEN 15.00 WHEN 'Intermediate' THEN 10.00 ELSE 5.00 END),
        2
    ) AS calculated_match_score
FROM user_skills_offered uo_a
-- Match with what Student B wants (matching Student A's offered skill)
JOIN user_skills_wanted uw_b 
    ON uo_a.skill_id = uw_b.skill_id 
   AND uo_a.user_id <> uw_b.user_id
-- Join with what Student B offers
JOIN user_skills_offered uo_b 
    ON uo_b.user_id = uw_b.user_id
-- Match with what Student A wants (matching Student B's offered skill)
JOIN user_skills_wanted uw_a 
    ON uw_a.user_id = uo_a.user_id 
   AND uw_a.skill_id = uo_b.skill_id
-- Join Student profiles
JOIN users ua ON uo_a.user_id = ua.user_id
JOIN users ub ON uo_b.user_id = ub.user_id
-- Join Skill names
JOIN skills skill_a_offers ON uo_a.skill_id = skill_a_offers.skill_id
JOIN skills skill_b_offers ON uo_b.skill_id = skill_b_offers.skill_id
WHERE uo_a.user_id < uo_b.user_id; -- Avoid symmetric duplicate permutations (A-B and B-A)

-- -----------------------------------------------------------------------------
-- View 2: v_user_profiles_summary
-- Dynamic profile summary with live calculated rating, eliminating data anomalies (3NF).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_user_profiles_summary AS
SELECT 
    u.user_id,
    u.name,
    u.college_email,
    u.department,
    u.year,
    u.bio,
    u.avatar,
    u.role,
    u.created_at,
    -- Dynamic ratings calculated from reviews
    COALESCE(ROUND(AVG(r.rating), 2), 0.00) AS avg_rating,
    COUNT(DISTINCT r.review_id) AS total_reviews,
    -- Offered and wanted skill counts
    (SELECT COUNT(*) FROM user_skills_offered uo WHERE uo.user_id = u.user_id) AS skills_offered_count,
    (SELECT COUNT(*) FROM user_skills_wanted uw WHERE uw.user_id = u.user_id) AS skills_wanted_count,
    -- Completed sessions count (as either teacher or learner)
    (
        SELECT COUNT(*) 
        FROM sessions s 
        WHERE (s.teacher_id = u.user_id OR s.learner_id = u.user_id) 
          AND s.status = 'COMPLETED'
    ) AS completed_sessions_count
FROM users u
LEFT JOIN reviews r ON u.user_id = r.reviewed_user_id
GROUP BY 
    u.user_id, 
    u.name, 
    u.college_email, 
    u.department, 
    u.year, 
    u.bio, 
    u.avatar, 
    u.role, 
    u.created_at;

-- -----------------------------------------------------------------------------
-- View 3: v_upcoming_sessions
-- Displays upcoming or scheduled learning sessions with full participant & skill details.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_upcoming_sessions AS
SELECT 
    s.session_id,
    s.request_id,
    s.scheduled_at,
    s.duration_minutes,
    s.mode,
    s.meeting_link,
    s.location,
    s.status AS session_status,
    -- Teacher details
    s.teacher_id,
    t.name AS teacher_name,
    t.college_email AS teacher_email,
    t.department AS teacher_dept,
    -- Learner details
    s.learner_id,
    l.name AS learner_name,
    l.college_email AS learner_email,
    l.department AS learner_dept,
    -- Skill details
    sk.skill_id,
    sk.skill_name,
    sk.difficulty AS skill_difficulty,
    c.category_name
FROM sessions s
JOIN users t ON s.teacher_id = t.user_id
JOIN users l ON s.learner_id = l.user_id
JOIN skills sk ON s.skill_id = sk.skill_id
JOIN categories c ON sk.category_id = c.category_id
WHERE s.status = 'SCHEDULED'
ORDER BY s.scheduled_at ASC;

-- -----------------------------------------------------------------------------
-- View 4: v_student_skill_summary
-- Unified summary of all teaching and learning skills across students.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_student_skill_summary AS
SELECT 
    u.user_id,
    u.name AS student_name,
    u.department,
    u.year,
    'TEACHING' AS skill_type,
    s.skill_id,
    s.skill_name,
    c.category_name,
    uo.proficiency_level AS level_or_urgency,
    uo.experience_years AS experience_or_notes,
    uo.proof_url
FROM user_skills_offered uo
JOIN users u ON uo.user_id = u.user_id
JOIN skills s ON uo.skill_id = s.skill_id
JOIN categories c ON s.category_id = c.category_id

UNION ALL

SELECT 
    u.user_id,
    u.name AS student_name,
    u.department,
    u.year,
    'LEARNING' AS skill_type,
    s.skill_id,
    s.skill_name,
    c.category_name,
    uw.urgency AS level_or_urgency,
    uw.notes AS experience_or_notes,
    NULL AS proof_url
FROM user_skills_wanted uw
JOIN users u ON uw.user_id = u.user_id
JOIN skills s ON uw.skill_id = s.skill_id
JOIN categories c ON s.category_id = c.category_id;
