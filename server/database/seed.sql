-- =============================================================================
-- SkillSync – Database Seed Script
-- Realistic College Student Profiles, Skills, Exchanges, Sessions, and Reviews
-- Default password for all sample users: password123
-- Password hash: $2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG
-- =============================================================================

USE skillsync_db;

-- 1. Categories
INSERT INTO categories (category_id, category_name, description) VALUES
(1, 'Software Engineering', 'Core programming languages, backend systems, and application architecture'),
(2, 'Web & Mobile Development', 'Frontend frameworks, responsive web apps, and cross-platform mobile tools'),
(3, 'Database Systems', 'Relational modeling, SQL query tuning, normalization, and NoSQL storage'),
(4, 'UI/UX & Design', 'Visual communication, design systems, wireframing, and usability testing'),
(5, 'Communication & Soft Skills', 'Technical presentations, debate, interview readiness, and teamwork');

-- 2. Skills (Includes Java, Python, React, MySQL, etc.)
INSERT INTO skills (skill_id, category_id, skill_name, description, difficulty) VALUES
(1, 1, 'Java Programming', 'Core Java, OOP principles, Collections Framework, multithreading, and JDBC', 'Intermediate'),
(2, 1, 'Python Programming', 'Pythonic syntax, scripting, data manipulation, and automation', 'Beginner'),
(3, 2, 'React.js', 'Modular component-based frontend web development, hooks, and state management', 'Intermediate'),
(4, 3, 'MySQL Database Design', 'Schema normalization (1NF-3NF), indexing, joins, transactions, and triggers', 'Intermediate'),
(5, 1, 'Data Structures & Algorithms', 'Binary trees, graph algorithms, dynamic programming, and complexity analysis', 'Advanced'),
(6, 4, 'Figma UI/UX Design', 'Auto-layout, reusable design systems, prototyping, and accessibility guidelines', 'Beginner'),
(7, 1, 'Machine Learning Basics', 'Supervised regression, classification models, Scikit-learn, and data preprocessing', 'Advanced'),
(8, 5, 'Public Speaking & Presentations', 'Confident technical delivery, elevator pitches, and audience engagement', 'Beginner'),
(9, 1, 'Docker & DevOps Basics', 'Containerization, Docker Compose, environment isolation, and deployment', 'Intermediate'),
(10, 1, 'Spring Boot', 'Enterprise Java backend services, REST APIs, and Hibernate JPA integration', 'Advanced');

-- 3. Users (College Students & Admins)
INSERT INTO users (user_id, name, college_email, password_hash, department, year, bio, avatar, role) VALUES
(1, 'Aarav Sharma', 'aarav.sharma@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Computer Engineering', '3rd Year', 'Passionate Java and React builder. Looking to improve Python scripting and UI design.', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150', 'student'),
(2, 'Ananya Patel', 'ananya.patel@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Information Technology', '3rd Year', 'Competitive programmer fluent in Python & DSA. Eager to master Java for enterprise placements.', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', 'student'),
(3, 'Rohan Gupta', 'rohan.gupta@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Electronics & Comm', '2nd Year', 'UI/UX enthusiast focused on Figma prototypes. Wanting to learn MySQL relational modeling.', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150', 'student'),
(4, 'Priya Verma', 'priya.verma@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Computer Engineering', '4th Year', 'Database enthusiast and Docker tinkerer. Looking to practice public speaking and Spring Boot.', 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150', 'student'),
(5, 'Devansh Joshi', 'devansh.joshi@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Data Science', '3rd Year', 'Machine learning and Python enthusiast. Need hands-on Java fundamentals for systems coursework.', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', 'student'),
(6, 'Sneha Kulkarni', 'sneha.kulkarni@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Information Technology', '4th Year', 'Spring Boot backend engineer. Wanting to explore Machine Learning and Python.', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150', 'student'),
(7, 'Prof. Vikram Rao', 'vikram.rao@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Computer Engineering', 'Postgraduate', 'Faculty coordinator overseeing peer mentorship and DBMS PBL projects.', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', 'admin');

-- 4. User Skills Offered (Teaching Skills)
INSERT INTO user_skills_offered (user_id, skill_id, proficiency_level, experience_years, proof_url) VALUES
(1, 1, 'Expert', 2.5, 'https://github.com/aarav/java-collections-lab'),      -- Aarav teaches Java
(1, 3, 'Advanced', 2.0, 'https://github.com/aarav/campus-portal-react'),      -- Aarav teaches React
(2, 2, 'Expert', 3.0, 'https://github.com/ananya/python-dsa-toolkit'),        -- Ananya teaches Python
(2, 5, 'Advanced', 2.5, 'https://leetcode.com/ananya_coder'),                  -- Ananya teaches DSA
(3, 6, 'Expert', 2.0, 'https://www.figma.com/@rohandesign'),                  -- Rohan teaches Figma
(4, 4, 'Expert', 3.0, 'https://github.com/priya/sql-database-portfolio'),     -- Priya teaches MySQL
(4, 9, 'Intermediate', 1.5, 'https://github.com/priya/dockerized-microservices'), -- Priya teaches Docker
(5, 7, 'Advanced', 2.0, 'https://github.com/devansh/ml-housing-prediction'),  -- Devansh teaches ML
(5, 2, 'Advanced', 2.5, 'https://github.com/devansh/python-automation'),       -- Devansh teaches Python
(6, 10, 'Expert', 3.0, 'https://github.com/sneha/spring-boot-ecommerce'),     -- Sneha teaches Spring Boot
(6, 1, 'Advanced', 2.5, 'https://github.com/sneha/java-core-repo');            -- Sneha teaches Java

-- 5. User Skills Wanted (Learning Goals)
INSERT INTO user_skills_wanted (user_id, skill_id, urgency, notes) VALUES
(1, 2, 'High', 'Need Python proficiency for machine learning and technical interviews'),    -- Aarav wants Python
(1, 6, 'Medium', 'Want to make cleaner UI wireframes for web applications'),                 -- Aarav wants Figma
(2, 1, 'High', 'Urgent preparation for campus placement drive requiring Core Java OOP'),     -- Ananya wants Java (Mutual with Aarav!)
(2, 3, 'Medium', 'Want to build interactive web dashboards for Python data models'),         -- Ananya wants React
(3, 4, 'High', 'Need MySQL normalization to design mobile application backend'),             -- Rohan wants MySQL
(3, 1, 'Low', 'Interested in learning foundational Java syntax'),                            -- Rohan wants Java
(4, 10, 'High', 'Want to master Spring Boot backend architecture alongside MySQL'),          -- Priya wants Spring Boot (Mutual with Sneha!)
(4, 8, 'Medium', 'Improve presentation confidence for seminar defense'),                     -- Priya wants Public Speaking
(5, 1, 'High', 'Need Java for Systems Programming university course'),                       -- Devansh wants Java
(5, 3, 'Medium', 'Frontend React fundamentals'),                                             -- Devansh wants React
(6, 7, 'High', 'Need Machine Learning fundamentals to integrate AI into Spring services');  -- Sneha wants ML (Mutual with Devansh!)

-- 6. Exchange Requests
INSERT INTO exchange_requests (request_id, sender_id, receiver_id, skill_id, status, message) VALUES
(1, 2, 1, 1, 'COMPLETED', 'Hi Aarav, saw you are an expert in Java. Could you teach me Java OOP and Collections in exchange for Python?'),
(2, 1, 2, 2, 'COMPLETED', 'Hey Ananya, I would love to learn Python scripting from you. Happy to coach you on Java!'),
(3, 3, 4, 4, 'ACCEPTED', 'Hello Priya! I need help understanding 1NF-3NF normalization in MySQL. I can teach you Figma prototyping in return.'),
(4, 5, 1, 1, 'PENDING', 'Hey Aarav, would you be interested in teaching Java? I can mentor you in Python or Machine Learning basics.'),
(5, 4, 6, 10, 'ACCEPTED', 'Hi Sneha! Can we schedule a session on Spring Boot REST controllers? I can share in-depth MySQL indexing tips.');

-- 7. Persisted Skill Matches
INSERT INTO skill_matches (match_id, user_a_id, user_b_id, match_score) VALUES
(1, 1, 2, 95.00), -- Aarav & Ananya (Mutual Java <-> Python match)
(2, 1, 5, 85.00), -- Aarav & Devansh (Mutual Java <-> Python/ML match)
(3, 4, 6, 90.00), -- Priya & Sneha (Mutual MySQL <-> Spring Boot match)
(4, 5, 6, 88.00); -- Devansh & Sneha (Mutual ML <-> Spring Boot match)

-- 8. Learning Sessions
INSERT INTO sessions (session_id, request_id, teacher_id, learner_id, skill_id, scheduled_at, duration_minutes, mode, meeting_link, location, status) VALUES
(1, 1, 1, 2, 1, '2026-09-25 15:00:00', 90, 'ONLINE', 'https://meet.google.com/abc-defg-hij', NULL, 'COMPLETED'),
(2, 2, 2, 1, 2, '2026-09-27 16:30:00', 60, 'IN_PERSON', NULL, 'Central Library, Discussion Room 2', 'COMPLETED'),
(3, 3, 4, 3, 4, '2026-10-05 14:00:00', 60, 'IN_PERSON', NULL, 'CS Department Lab 302', 'SCHEDULED'),
(4, 5, 6, 4, 10, '2026-10-08 17:00:00', 90, 'ONLINE', 'https://meet.google.com/xyz-uvwx-rst', NULL, 'SCHEDULED');

-- 9. Reviews (Evaluations for completed sessions)
INSERT INTO reviews (review_id, session_id, reviewer_id, reviewed_user_id, rating, comment) VALUES
(1, 1, 2, 1, 5, 'Aarav is an outstanding teacher! He explained Java Collections and polymorphism with campus project examples that clicked immediately.'),
(2, 2, 1, 2, 5, 'Ananya gave a fantastic walkthrough on Python list comprehensions and generator functions. Very patient and structured.');
