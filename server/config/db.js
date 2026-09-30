const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'skillsync_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Test connection helper
pool.getConnection()
  .then((conn) => {
    console.log('✅ Connected to MySQL database:', process.env.DB_NAME || 'skillsync_db');
    conn.release();
  })
  .catch((err) => {
    console.error('⚠️  MySQL Connection Pool Error:', err.message);
    console.error('👉 Make sure MySQL is running and credentials in server/.env are valid.');
  });

module.exports = pool;
