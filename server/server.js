const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.originalUrl}`);
  next();
});

// Routes
const healthRoute = require('./routes/health');
app.use('/api/health', healthRoute);

// Root route
app.get('/', (req, res) => {
  res.json({
    message: 'SkillSync API is running.',
    healthCheck: '/api/health'
  });
});

// Global 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message
  });
});

app.listen(PORT, () => {
  console.log(`🚀 SkillSync backend server listening on http://localhost:${PORT}`);
  console.log(`📊 Health check available at: http://localhost:${PORT}/api/health`);
});
