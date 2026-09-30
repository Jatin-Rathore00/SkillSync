-- =============================================================================
-- SkillSync – Database Seed Script
-- Realistic College Student Profiles, Skills, Requests, and Sessions
-- Password for all seed users: password123
-- =============================================================================

USE skillsync_db;

-- 1. Insert Categories
INSERT INTO categories (category_id, category_name, description) VALUES
(1, 'Computer Science & Software', 'Programming, frameworks, databases, and system tools'),
(2, 'Design & Media', 'UI/UX design, graphics, video editing, and animations'),
(3, 'Languages & Communication', 'Foreign languages, public speaking, and technical writing'),
(4, 'Mathematics & Core Engineering', 'Calculus, discrete structures, electronics, and logic design')
ON DUPLICATE KEY UPDATE category_name = VALUES(category_name);

-- 2. Insert Skills
INSERT INTO skills (skill_id, category_id, skill_name, description) VALUES
(1, 1, 'React.js', 'Frontend web library for building modular component-based user interfaces'),
(2, 1, 'Python Programming', 'Core Python, scripting, object-oriented design, and algorithms'),
(3, 1, 'MySQL Database Design', 'Relational modeling, normalization, indexing, and complex queries'),
(4, 1, 'Data Structures & Algorithms', 'Trees, graphs, dynamic programming, and algorithm optimization'),
(5, 1, 'Docker & DevOps Basics', 'Containerization, Dockerfile creation, and multi-container setups'),
(6, 2, 'Figma UI/UX Design', 'Design systems, wireframing, prototyping, and auto-layout'),
(7, 2, 'Video Editing', 'Adobe Premiere Pro and DaVinci Resolve workflows'),
(8, 3, 'German Language (A1/A2)', 'Basic conversational German grammar and vocabulary'),
(9, 3, 'Public Speaking & Debating', 'Presentation delivery, confidence building, and articulation'),
(10, 4, 'Discrete Mathematics', 'Set theory, graph theory, combinatorics, and proof techniques')
ON DUPLICATE KEY UPDATE skill_name = VALUES(skill_name);

-- 3. Insert Students (Password: password123)
INSERT INTO users (user_id, name, email, password_hash, department, year_of_study, bio, avatar_url) VALUES
(1, 'Aarav Sharma', 'aarav.sharma@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Computer Engineering', '3rd Year', 'Passionate full-stack developer who loves React and database indexing. Looking to master Python DSA.', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
(2, 'Ananya Patel', 'ananya.patel@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Information Technology', '3rd Year', 'Competitive programmer specializing in Python and Algorithms. Looking to build web apps with modern React.', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150'),
(3, 'Rohan Gupta', 'rohan.gupta@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Design & Media Tech', '2nd Year', 'UI/UX nerd crafting wireframes and Figma components. Keen to learn SQL to understand how backends store data.', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150'),
(4, 'Priya Verma', 'priya.verma@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Computer Engineering', '4th Year', 'Cloud enthusiast experimenting with containers. Happy to coach peers on public speaking and tech presentations.', 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150'),
(5, 'Devansh Joshi', 'devansh.joshi@college.edu', '$2b$10$/wy7nem9TyCrfbFJMneSVeeDtp4y/fXl72ZgDo3dAdLgZPLa9mZoG', 'Mathematics & Computing', '3rd Year', 'Loves solving discrete math puzzles and logic proofs. Wanting to learn React to visualize graph theory models.', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 4. Skills Offered by Students
INSERT INTO user_skills_offered (offered_id, user_id, skill_id, proficiency_level, years_of_experience, description) VALUES
(1, 1, 1, 'Advanced', 2.0, 'Can teach React functional components, hooks, state management, and Vite tooling'),
(2, 1, 3, 'Expert', 2.5, 'Can guide on relational schema design, 3NF normalization, and query optimization'),
(3, 2, 2, 'Expert', 3.0, 'In-depth Python programming, OOP concepts, list comprehensions, and automation'),
(4, 2, 4, 'Advanced', 2.0, 'Algorithms: sorting, searching, recursion, and dynamic programming fundamentals'),
(5, 3, 6, 'Expert', 2.0, 'Figma master: Auto-layout, components, interactive prototyping, and UI kits'),
(6, 4, 5, 'Intermediate', 1.5, 'Docker containers, volume mounting, and microservice containerization'),
(7, 4, 9, 'Advanced', 3.0, 'Public speaking coaching, slide deck design, and interview delivery skills'),
(8, 5, 10, 'Advanced', 2.5, 'Discrete math, graph algorithms, mathematical induction, and set logic')
ON DUPLICATE KEY UPDATE proficiency_level = VALUES(proficiency_level);

-- 5. Skills Wanted by Students
INSERT INTO user_skills_wanted (wanted_id, user_id, skill_id, priority_level, notes) VALUES
-- Note: Aarav offers React(1) and wants Python(2). Ananya offers Python(2) and wants React(1). Perfect bidirectional match!
(1, 1, 2, 'High', 'Need to practice Python scripting for competitive coding contests'),
(2, 1, 6, 'Medium', 'Want to make cleaner UI designs in Figma for my web projects'),
(3, 2, 1, 'High', 'Want to learn React to build interactive frontend dashboards for ML models'),
(4, 3, 3, 'High', 'Need relational DBMS fundamentals to design database schemas for mobile apps'),
(5, 4, 4, 'High', 'Preparing for placement interviews, need advanced graph algorithms revision'),
(6, 5, 1, 'High', 'Need hands-on frontend knowledge to render interactive graph algorithms')
ON DUPLICATE KEY UPDATE priority_level = VALUES(priority_level);

-- 6. Exchange Requests
INSERT INTO exchange_requests (request_id, sender_id, receiver_id, offered_skill_id, wanted_skill_id, status, message) VALUES
(1, 1, 2, 1, 2, 'COMPLETED', 'Hi Ananya! I see you are great at Python. I can teach you React in exchange for Python sessions.'),
(2, 3, 1, 6, 3, 'ACCEPTED', 'Hey Aarav! Can you teach me MySQL normalization and joins? I can guide you through Figma prototyping.'),
(3, 5, 1, 10, 1, 'PENDING', 'Hello Aarav, I would love to learn React from you in exchange for Discrete Math concepts.')
ON DUPLICATE KEY UPDATE status = VALUES(status);

-- 7. Learning Sessions
INSERT INTO learning_sessions (session_id, request_id, scheduled_time, duration_minutes, meeting_type, meeting_location, status, session_notes) VALUES
(1, 1, '2026-09-28 16:00:00', 90, 'ONLINE', 'https://meet.google.com/abc-defg-hij', 'COMPLETED', 'Covered React useState, useEffect, and Ananya explained Python list comprehensions and generators.'),
(2, 2, '2026-10-05 15:30:00', 60, 'IN_PERSON', 'Central Library, Discussion Room 4', 'SCHEDULED', 'Focus on 1NF to 3NF normalization rules and Figma responsive layouts.')
ON DUPLICATE KEY UPDATE status = VALUES(status);

-- 8. Reviews (Submitted for the completed session)
INSERT INTO reviews (review_id, session_id, reviewer_id, reviewee_id, rating, comment) VALUES
(1, 1, 2, 1, 5, 'Aarav is an exceptional tutor! He explained React component lifecycle and props with very practical examples.'),
(2, 1, 1, 2, 5, 'Ananya gave an awesome session on Python data manipulation. Very patient and articulate!')
ON DUPLICATE KEY UPDATE rating = VALUES(rating);
