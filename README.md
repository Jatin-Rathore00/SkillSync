# SkillSync – Campus Skill Exchange Platform 🎓

> **Course:** Database Management Systems (DBMS) – Project-Based Learning (PBL)  
> **Team Scope:** 3-Person 3rd-Year B.Tech / B.E. Project  
> **Tech Stack:** React 19 + Vite + Tailwind CSS | Node.js + Express.js | MySQL 8.0 (InnoDB)

---

## 📌 Project Overview

**SkillSync** is a peer-to-peer campus platform connecting college students who want to trade practical skills. Instead of paying money for tutoring, students teach what they know (e.g., React, Figma, Discrete Math) in exchange for skills they want to learn (e.g., Python, SQL, Public Speaking).

Unlike basic web apps, SkillSync is engineered primarily around **relational database principles**:
1. **Fully Normalized to 3NF**: No multivalued attributes, no partial dependencies, and strictly no transitive dependencies.
2. **Dynamic Aggregations without Redundancy**: Student ratings are **not** stored as a redundant column in the `users` table; they are calculated dynamically from verified reviews using SQL views.
3. **Pure SQL Bidirectional Matchmaking**: Smart 2-way skill matches are resolved using relational joins between `user_skills_offered` and `user_skills_wanted`.
4. **ACID Transactions**: Session scheduling uses `START TRANSACTION`, row-level locking (`SELECT ... FOR UPDATE`), and `COMMIT / ROLLBACK`.
5. **Database Triggers**: Business integrity enforcement (preventing self-reviews, disallowing unaccepted session bookings, and auto-syncing request statuses).

---

## 📁 Repository Structure

```text
SkillSync/
├── server/                           # Backend (Node.js & Express)
│   ├── config/
│   │   └── db.js                     # MySQL connection pool (mysql2/promise)
│   ├── database/                     # Academic DBMS SQL Scripts
│   │   ├── schema.sql                # 3NF DDL: Tables, constraints, indexes
│   │   ├── views.sql                 # SQL views (ratings, mutual matching)
│   │   ├── triggers.sql              # SQL triggers (validation, lifecycle)
│   │   ├── procedures.sql            # Stored procedures & ACID transactions
│   │   ├── seed.sql                  # Realistic student sample dataset
│   │   └── setup.js                  # Automated database execution runner
│   ├── routes/
│   │   └── health.js                 # API & database diagnostic probe
│   ├── .env.example                  # Environment configuration template
│   ├── server.js                     # Express application entry point
│   └── package.json
│
├── client/                           # Frontend (React 19 + Vite + Tailwind CSS)
│   ├── src/
│   │   ├── services/
│   │   │   └── api.js                # Axios HTTP client with JWT interceptor
│   │   ├── App.jsx                   # Setup diagnostic and architectural dashboard
│   │   ├── index.css                 # Tailwind CSS styling tokens
│   │   └── main.jsx
│   ├── vite.config.js                # Vite configuration with Tailwind plugin & proxy
│   └── package.json
│
└── README.md                         # Project documentation & execution guide
```

---

## ⚡ Quick Start Guide

### 1. Database Configuration
1. Open [`server/.env`](file:///c:/Users/jatin/OneDrive/Desktop/SkillSync/server/.env).
2. Set your MySQL `root` password:
   ```env
   PORT=5000
   DB_HOST=localhost
   DB_PORT=3306
   DB_USER=root
   DB_PASSWORD=your_mysql_password
   DB_NAME=skillsync_db
   ```
3. Run the automated database setup script:
   ```bash
   cd server
   npm run db:setup
   ```
   *This automatically creates `skillsync_db`, executes the 3NF schema, registers views, triggers, stored procedures, and loads realistic sample data.*

### 2. Start the Backend API
```bash
cd server
npm run dev
```
*Backend runs on `http://localhost:5000`. Health check available at `http://localhost:5000/api/health`.*

### 3. Start the Frontend Client
```bash
cd client
npm run dev
```
*Frontend runs on `http://localhost:5173`.*

---

## 📑 DBMS Academic Documentation
For the full **ER Diagram**, **Relational Schema notation**, **3NF Normalization Proof**, and **advanced SQL feature walkthrough**, refer to the detailed project design artifact generated during development.
