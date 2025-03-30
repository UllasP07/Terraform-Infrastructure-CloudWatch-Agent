// index.js
const express = require('express');
const { connectDB } = require('./config/database');
const bootstrapDatabase = require('./bootstrap');
const logger = require('./utils/logger');
const requestLogger = require('./middleware/requestLogger');
require('dotenv').config();

// Initialize Express app
const app = express();

// Request logging middleware
app.use(requestLogger);

// Body parsing middleware
app.use(express.json({ strict: false }));
app.use(express.urlencoded({ extended: true }));

// Import routes
const healthCheckRoute = require('./routes/healthCheck');
const filesRoute = require('./routes/files');

// Apply routes
app.use(healthCheckRoute);
app.use(filesRoute);

// 404 handler
app.use((req, res) => {
  logger.warn(`404 Not Found: ${req.method} ${req.originalUrl}`);
  res.status(404).send();
});

// Global error handler
app.use((err, req, res, next) => {
  logger.error('Unhandled server error', { error: err });
  res.status(500).send();
});

// Port config
const PORT = process.env.PORT || 8080;

// Handle different environments
const isTest = process.env.NODE_ENV === 'test';

// Start server function
const startApp = async () => {
  if (!isTest) {
    try {
      await connectDB();
      await bootstrapDatabase();
      const server = app.listen(PORT, () => {
        logger.info(`Server started successfully and running on port ${PORT}`);
      });
      
      // Export the server
      module.exports.server = server;
    } catch (error) {
      logger.error('Failed to start application', { error });
      process.exit(1);
    }
  }
};

// Start the app if not in test mode
startApp();

// Export the app for testing
module.exports = app;
