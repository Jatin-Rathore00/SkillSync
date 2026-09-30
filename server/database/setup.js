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
  console.log('🔄 Connecting to MySQL server at', `${config.host}:${config.port}`, 'as user:', config.user);
  
  let connection;
  try {
    connection = await mysql.createConnection(config);
    console.log('✅ Successfully connected to MySQL server.');

    // 1. Run schema.sql
    console.log('\n📦 [1/5] Applying schema.sql (DDL Tables, Constraints, Indexes)...');
    const schemaSql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
    await connection.query(schemaSql);
    console.log('✅ schema.sql executed successfully.');

    // Switch to skillsync_db
    await connection.changeUser({ database: 'skillsync_db' });

    // 2. Run views.sql
    console.log('\n👁️  [2/5] Applying views.sql (Dynamic Aggregations & Matches)...');
    const viewsSql = fs.readFileSync(path.join(__dirname, 'views.sql'), 'utf8');
    await connection.query(viewsSql);
    console.log('✅ views.sql executed successfully.');

    // 3. Run triggers.sql (split by DELIMITER or individual trigger statements)
    console.log('\n⚡ [3/5] Applying triggers.sql...');
    // We run the trigger statements individually without DELIMITER keyword
    const triggers = [
      `DROP TRIGGER IF EXISTS trg_validate_review_eligibility;`,
      `CREATE TRIGGER trg_validate_review_eligibility
       BEFORE INSERT ON reviews
       FOR EACH ROW
       BEGIN
           DECLARE v_session_status VARCHAR(20);
           DECLARE v_sender_id INT;
           DECLARE v_receiver_id INT;

           SELECT ls.status, er.sender_id, er.receiver_id
           INTO v_session_status, v_sender_id, v_receiver_id
           FROM learning_sessions ls
           JOIN exchange_requests er ON ls.request_id = er.request_id
           WHERE ls.session_id = NEW.session_id;

           IF v_session_status IS NULL OR v_session_status <> 'COMPLETED' THEN
               SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'Integrity Violation: Reviews can only be submitted after a session is marked COMPLETED.';
           END IF;

           IF NOT (
               (NEW.reviewer_id = v_sender_id AND NEW.reviewee_id = v_receiver_id) OR
               (NEW.reviewer_id = v_receiver_id AND NEW.reviewee_id = v_sender_id)
           ) THEN
               SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'Integrity Violation: Reviewer and reviewee must be verified participants of the scheduled session.';
           END IF;
       END;`,
      `DROP TRIGGER IF EXISTS trg_prevent_session_for_unaccepted_request;`,
      `CREATE TRIGGER trg_prevent_session_for_unaccepted_request
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
       END;`,
      `DROP TRIGGER IF EXISTS trg_sync_request_status_on_session_complete;`,
      `CREATE TRIGGER trg_sync_request_status_on_session_complete
       AFTER UPDATE ON learning_sessions
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

    // 4. Run procedures.sql
    console.log('\n⚙️  [4/5] Applying procedures.sql (Transactions & Stored Procedures)...');
    const procedures = [
      `DROP PROCEDURE IF EXISTS sp_schedule_session_transaction;`,
      `CREATE PROCEDURE sp_schedule_session_transaction(
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

          DECLARE EXIT HANDLER FOR SQLEXCEPTION
          BEGIN
              ROLLBACK;
              SET p_session_id = NULL;
              SET p_status_code = 'ERR_SQL_EXCEPTION';
              SET p_status_message = 'Transaction aborted due to a database exception.';
          END;

          START TRANSACTION;

          SELECT status INTO v_current_status
          FROM exchange_requests
          WHERE request_id = p_request_id
          FOR UPDATE;

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

          COMMIT;

          SET p_status_code = 'SUCCESS';
          SET p_status_message = 'Session scheduled successfully.';
      END;`,
      `DROP PROCEDURE IF EXISTS sp_get_student_mutual_matches;`,
      `CREATE PROCEDURE sp_get_student_mutual_matches(
          IN p_user_id INT
      )
      BEGIN
          SELECT 
              partner.user_id AS partner_id,
              partner.name AS partner_name,
              partner.email AS partner_email,
              partner.department AS partner_dept,
              partner.year_of_study AS partner_year,
              partner.avatar_url AS partner_avatar,
              COALESCE(ROUND(AVG(r.rating), 2), 0.00) AS partner_avg_rating,
              COUNT(DISTINCT r.review_id) AS partner_review_count,
              teach_skill.skill_id AS you_teach_skill_id,
              teach_skill.skill_name AS you_teach_skill_name,
              my_offer.proficiency_level AS your_proficiency,
              learn_skill.skill_id AS partner_teaches_skill_id,
              learn_skill.skill_name AS partner_teaches_skill_name,
              partner_offer.proficiency_level AS partner_proficiency
          FROM user_skills_offered my_offer
          JOIN user_skills_wanted partner_want 
              ON my_offer.skill_id = partner_want.skill_id 
             AND my_offer.user_id <> partner_want.user_id
          JOIN user_skills_offered partner_offer 
              ON partner_offer.user_id = partner_want.user_id
          JOIN user_skills_wanted my_want 
              ON my_want.user_id = my_offer.user_id 
             AND my_want.skill_id = partner_offer.skill_id
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
      END;`
    ];

    for (const proc of procedures) {
      await connection.query(proc);
    }
    console.log('✅ procedures.sql executed successfully.');

    // 5. Run seed.sql
    console.log('\n🌱 [5/5] Applying seed.sql (Sample Students, Skills, Requests, Reviews)...');
    const seedSql = fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8');
    await connection.query(seedSql);
    console.log('✅ seed.sql executed successfully.');

    // Run verification query
    console.log('\n🔍 Verifying Database Content:');
    const [tables] = await connection.query('SHOW TABLES;');
    console.log(`• Total Tables/Views in skillsync_db: ${tables.length}`);

    const [userRows] = await connection.query('SELECT COUNT(*) AS count FROM users;');
    const [skillRows] = await connection.query('SELECT COUNT(*) AS count FROM skills;');
    const [matches] = await connection.query('SELECT * FROM v_mutual_skill_matches;');

    console.log(`• Total Users: ${userRows[0].count}`);
    console.log(`• Total Skills: ${skillRows[0].count}`);
    console.log(`• Mutual Matches Detected via SQL View: ${matches.length}`);
    if (matches.length > 0) {
      console.log(`  -> Match found: "${matches[0].student_a_name}" (${matches[0].skill_a_offers_name}) <--> "${matches[0].student_b_name}" (${matches[0].skill_b_offers_name})`);
    }

    console.log('\n🎉 Database setup and verification completed with 100% success!');
  } catch (err) {
    console.error('\n❌ Database setup error:', err.message);
    if (err.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('👉 Hint: Please check your MySQL password in server/.env');
    }
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

runSetup();
