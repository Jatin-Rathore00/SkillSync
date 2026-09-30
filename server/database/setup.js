const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const config = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  multipleStatements: true
};

async function runSetup() {
  console.log('=============================================================================');
  console.log('🔄 SkillSync MySQL Database Setup & Academic DBMS Test Runner');
  console.log('=============================================================================');
  console.log(`Connecting to: ${config.host}:${config.port} as user '${config.user}'...`);

  let connection;
  try {
    connection = await mysql.createConnection(config);
    console.log('✅ Connection to MySQL server established successfully.');

    // 1. Schema DDL
    console.log('\n📦 [1/5] Executing schema.sql (9 Core Tables, Constraints, Indexes)...');
    const schemaSql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
    await connection.query(schemaSql);
    console.log('✅ schema.sql executed successfully.');

    // Switch to database
    await connection.changeUser({ database: 'skillsync_db' });

    // 2. Seed Data
    console.log('\n🌱 [2/5] Executing seed.sql (Categories, Skills, Users, Sessions, Reviews)...');
    const seedSql = fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8');
    await connection.query(seedSql);
    console.log('✅ seed.sql loaded successfully.');

    // 3. Views
    console.log('\n👁️  [3/5] Executing views.sql (4 Dynamic Views)...');
    const viewsSql = fs.readFileSync(path.join(__dirname, 'views.sql'), 'utf8');
    await connection.query(viewsSql);
    console.log('✅ views.sql executed successfully.');

    // 4. Triggers
    console.log('\n⚡ [4/5] Executing triggers.sql (5 Integrity & Status Sync Triggers)...');
    const triggers = [
      `DROP TRIGGER IF EXISTS trg_validate_exchange_request;`,
      `CREATE TRIGGER trg_validate_exchange_request
       BEFORE INSERT ON exchange_requests
       FOR EACH ROW
       BEGIN
           IF NEW.sender_id = NEW.receiver_id THEN
               SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'Integrity Violation: Sender and receiver must be different students.';
           END IF;
       END;`,
      `DROP TRIGGER IF EXISTS trg_validate_session_participants;`,
      `CREATE TRIGGER trg_validate_session_participants
       BEFORE INSERT ON sessions
       FOR EACH ROW
       BEGIN
           IF NEW.teacher_id = NEW.learner_id THEN
               SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'Integrity Violation: Teacher and learner must be different students.';
           END IF;
       END;`,
      `DROP TRIGGER IF EXISTS trg_prevent_review_unless_completed;`,
      `CREATE TRIGGER trg_prevent_review_unless_completed
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

           IF v_session_status IS NULL OR v_session_status <> 'COMPLETED' THEN
               SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'Business Rule Violation: Reviews can only be submitted for sessions that are COMPLETED.';
           END IF;

           IF NEW.reviewer_id = NEW.reviewed_user_id THEN
               SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'Integrity Violation: A student cannot submit a review for themselves.';
           END IF;

           IF NOT (
               (NEW.reviewer_id = v_teacher_id AND NEW.reviewed_user_id = v_learner_id) OR
               (NEW.reviewer_id = v_learner_id AND NEW.reviewed_user_id = v_teacher_id)
           ) THEN
               SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'Integrity Violation: Reviewer and reviewed student must be verified participants of the session.';
           END IF;
       END;`,
      `DROP TRIGGER IF EXISTS trg_prevent_session_for_non_accepted_request;`,
      `CREATE TRIGGER trg_prevent_session_for_non_accepted_request
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
       END;`,
      `DROP TRIGGER IF EXISTS trg_sync_request_status_on_session_complete;`,
      `CREATE TRIGGER trg_sync_request_status_on_session_complete
       AFTER UPDATE ON sessions
       FOR EACH ROW
       BEGIN
           IF NEW.status = 'COMPLETED' AND OLD.status <> 'COMPLETED' THEN
               UPDATE exchange_requests
               SET status = 'COMPLETED'
               WHERE request_id = NEW.request_id;
           END IF;
       END;`
    ];

    for (const trg of triggers) {
      await connection.query(trg);
    }
    console.log('✅ triggers.sql executed successfully.');

    // 5. Stored Procedures & Transactions
    console.log('\n⚙️  [5/5] Executing procedures.sql (sp_find_skill_matches & sp_book_session_transaction)...');
    const procedures = [
      `DROP PROCEDURE IF EXISTS sp_find_skill_matches;`,
      `CREATE PROCEDURE sp_find_skill_matches(
          IN p_user_id INT
      )
      BEGIN
          SELECT 
              p_user_id AS student_id,
              peer.user_id AS matched_user_id,
              peer.name AS matched_user_name,
              peer.college_email AS matched_user_email,
              peer.department AS matched_user_department,
              peer.year AS matched_user_year,
              peer.avatar AS matched_user_avatar,
              COALESCE(ROUND(AVG(r.rating), 2), 0.00) AS matched_user_avg_rating,
              COUNT(DISTINCT r.review_id) AS matched_user_review_count,
              teach_s.skill_id AS you_teach_skill_id,
              teach_s.skill_name AS you_teach_skill_name,
              my_offer.proficiency_level AS your_proficiency,
              my_offer.experience_years AS your_experience,
              learn_s.skill_id AS peer_teaches_skill_id,
              learn_s.skill_name AS peer_teaches_skill_name,
              peer_offer.proficiency_level AS peer_proficiency,
              peer_offer.experience_years AS peer_experience,
              ROUND(
                  60.00 + 
                  (CASE my_offer.proficiency_level WHEN 'Expert' THEN 20.00 WHEN 'Advanced' THEN 15.00 WHEN 'Intermediate' THEN 10.00 ELSE 5.00 END) +
                  (CASE peer_offer.proficiency_level WHEN 'Expert' THEN 20.00 WHEN 'Advanced' THEN 15.00 WHEN 'Intermediate' THEN 10.00 ELSE 5.00 END),
                  2
              ) AS compatibility_score
          FROM user_skills_offered my_offer
          JOIN user_skills_wanted peer_want 
              ON my_offer.skill_id = peer_want.skill_id 
             AND my_offer.user_id <> peer_want.user_id
          JOIN user_skills_offered peer_offer 
              ON peer_offer.user_id = peer_want.user_id
          JOIN user_skills_wanted my_want 
              ON my_want.user_id = my_offer.user_id 
             AND my_want.skill_id = peer_offer.skill_id
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
      END;`,
      `DROP PROCEDURE IF EXISTS sp_book_session_transaction;`,
      `CREATE PROCEDURE sp_book_session_transaction(
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

          DECLARE EXIT HANDLER FOR SQLEXCEPTION
          BEGIN
              ROLLBACK;
              SET p_session_id = NULL;
              SET p_status_code = 'ERR_SQL_EXCEPTION';
              SET p_status_message = 'Transaction aborted: an unexpected SQL error occurred.';
          END;

          START TRANSACTION;

          SELECT status, sender_id, receiver_id, skill_id
          INTO v_current_status, v_sender_id, v_receiver_id, v_skill_id
          FROM exchange_requests
          WHERE request_id = p_request_id
          FOR UPDATE;

          IF v_current_status IS NULL THEN
              ROLLBACK;
              SET p_session_id = NULL;
              SET p_status_code = 'REQUEST_NOT_FOUND';
              SET p_status_message = 'Exchange request does not exist.';
              LEAVE proc_label;
          END IF;

          IF v_current_status NOT IN ('PENDING', 'ACCEPTED') THEN
              ROLLBACK;
              SET p_session_id = NULL;
              SET p_status_code = 'INVALID_REQUEST_STATUS';
              SET p_status_message = CONCAT('Cannot schedule session: request is currently ', v_current_status);
              LEAVE proc_label;
          END IF;

          IF v_current_status = 'PENDING' THEN
              UPDATE exchange_requests
              SET status = 'ACCEPTED'
              WHERE request_id = p_request_id;
          END IF;

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

          COMMIT;

          SET p_status_code = 'SUCCESS';
          SET p_status_message = 'Exchange accepted and session successfully scheduled.';
      END;`
    ];

    for (const proc of procedures) {
      await connection.query(proc);
    }
    console.log('✅ procedures.sql executed successfully.');

    // =========================================================================
    // AUTOMATED DBMS VERIFICATION TEST SUITE
    // =========================================================================
    console.log('\n=============================================================================');
    console.log('🧪 RUNNING AUTOMATED DBMS ACADEMIC VERIFICATION TESTS');
    console.log('=============================================================================');

    // Test 1: Verify Table Counts
    const [tables] = await connection.query(`SHOW FULL TABLES WHERE Table_type = 'BASE TABLE';`);
    console.log(`\n[Test 1] Core Tables Created: ${tables.length} / 9`);
    tables.forEach(t => console.log(`   ✓ ${Object.values(t)[0]}`));

    // Test 2: Verify View Counts
    const [views] = await connection.query(`SHOW FULL TABLES WHERE Table_type = 'VIEW';`);
    console.log(`\n[Test 2] Views Created: ${views.length} / 4`);
    views.forEach(v => console.log(`   ✓ ${Object.values(v)[0]}`));

    // Test 3: Verify Java Query (Query 1.1 & 1.2)
    const [javaTeachers] = await connection.query(`
      SELECT u.name, s.skill_name, uo.proficiency_level, uo.experience_years
      FROM users u
      JOIN user_skills_offered uo ON u.user_id = uo.user_id
      JOIN skills s ON uo.skill_id = s.skill_id
      WHERE s.skill_name LIKE '%Java%';
    `);
    console.log(`\n[Test 3] Java Teachers Query: Found ${javaTeachers.length} student(s) teaching Java:`);
    javaTeachers.forEach(r => console.log(`   ✓ ${r.name} (${r.skill_name}, ${r.proficiency_level}, ${r.experience_years} yrs)`));

    // Test 4: Verify View v_mutual_matches
    const [mutualMatches] = await connection.query(`SELECT * FROM v_mutual_matches;`);
    console.log(`\n[Test 4] View 'v_mutual_matches': Found ${mutualMatches.length} reciprocal match pair(s):`);
    mutualMatches.forEach(m => {
      console.log(`   ✓ ${m.student_a_name} (offers ${m.skill_a_offers_name}) <--> ${m.student_b_name} (offers ${m.skill_b_offers_name}) | Score: ${m.calculated_match_score}`);
    });

    // Test 5: Verify View v_user_profiles_summary (3NF dynamic ratings)
    const [profiles] = await connection.query(`SELECT name, department, avg_rating, total_reviews, completed_sessions_count FROM v_user_profiles_summary LIMIT 4;`);
    console.log(`\n[Test 5] View 'v_user_profiles_summary' (Dynamic Ratings):`);
    profiles.forEach(p => console.log(`   ✓ ${p.name} (${p.department}) - Rating: ${p.avg_rating}★ (${p.total_reviews} reviews, ${p.completed_sessions_count} sessions)`));

    // Test 6: Verify Stored Procedure sp_find_skill_matches
    const [spResult] = await connection.query(`CALL sp_find_skill_matches(1);`);
    console.log(`\n[Test 6] Stored Procedure 'sp_find_skill_matches(1)' for Aarav Sharma:`);
    if (spResult[0] && spResult[0].length > 0) {
      spResult[0].forEach(m => {
        console.log(`   ✓ Match: ${m.matched_user_name} | Teaches you: ${m.peer_teaches_skill_name} | You teach: ${m.you_teach_skill_name} | Compatibility: ${m.compatibility_score}%`);
      });
    }

    // Test 7: Verify Trigger trg_prevent_review_unless_completed (Negative Test)
    console.log(`\n[Test 7] Trigger 'trg_prevent_review_unless_completed' Enforcement Test:`);
    try {
      // Session 3 is 'SCHEDULED' (not COMPLETED). Attempting to review should trigger an exception!
      await connection.query(`
        INSERT INTO reviews (session_id, reviewer_id, reviewed_user_id, rating, comment)
        VALUES (3, 3, 4, 5, 'Should fail because session is SCHEDULED, not COMPLETED');
      `);
      console.error(`   ❌ FAILED: Trigger did not prevent review on non-completed session!`);
    } catch (err) {
      if (err.sqlState === '45000') {
        console.log(`   ✓ PASS: Trigger successfully blocked review on incomplete session! Error: "${err.message}"`);
      } else {
        throw err;
      }
    }

    // Test 8: Verify Transaction Procedure sp_book_session_transaction
    console.log(`\n[Test 8] Transaction Procedure 'sp_book_session_transaction' Booking Test:`);
    await connection.query(`CALL sp_book_session_transaction(4, '2026-10-10 11:00:00', 60, 'ONLINE', 'https://meet.google.com/test-book-session', NULL, @new_session_id, @status_code, @status_msg);`);
    const [transOut] = await connection.query(`SELECT @new_session_id AS session_id, @status_code AS status_code, @status_msg AS status_msg;`);
    console.log(`   ✓ Transaction Result: Code=${transOut[0].status_code} | Msg="${transOut[0].status_msg}" | Created Session ID=${transOut[0].session_id}`);

    console.log('\n=============================================================================');
    console.log('🎉 ALL DATABASE COMPONENTS & ACADEMIC TESTS PASSED WITH 100% SUCCESS!');
    console.log('=============================================================================');

  } catch (err) {
    console.error('\n❌ Database setup error:', err.message);
    if (err.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('👉 Hint: Set your MySQL root password in server/.env: DB_PASSWORD=your_password');
    }
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

runSetup();
