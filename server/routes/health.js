const express = require('express');
const router = express.Router();
const pool = require('../config/db');

// @route   GET /api/health
// @desc    System health check & database connection probe
router.get('/', async (req, res) => {
  let dbStatus = 'DISCONNECTED';
  let dbError = null;
  let dbStats = null;

  try {
    const [rows] = await pool.query('SELECT 1 + 1 AS result');
    if (rows && rows[0].result === 2) {
      dbStatus = 'CONNECTED';
      const [tableCount] = await pool.query('SELECT COUNT(*) AS total FROM information_schema.tables WHERE table_schema = ?', [process.env.DB_NAME || 'skillsync_db']);
      dbStats = {
        database: process.env.DB_NAME || 'skillsync_db',
        total_tables_views: tableCount[0].total
      };
    }
  } catch (err) {
    dbStatus = 'ERROR';
    dbError = err.message;
  }

  res.json({
    status: 'ONLINE',
    project: 'SkillSync – Campus Skill Exchange Platform (DBMS PBL)',
    timestamp: new Date().toISOString(),
    backend: 'Express.js v4 on Node.js',
    database: {
      status: dbStatus,
      error: dbError,
      stats: dbStats
    }
  });
});

module.exports = router;
