// utils/logger.js
const fs = require('fs');
const path = require('path');

// Use a directory in your project instead of /var/log
const logDir = process.env.NODE_ENV === 'production' ? '/var/log' : './logs';
// Ensure the directory exists
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}
const logFile = path.join(logDir, 'webapp.log');

// Log levels
const LOG_LEVELS = {
  ERROR: 'ERROR',
  WARN: 'WARN',
  INFO: 'INFO',
  DEBUG: 'DEBUG'
};

// Create a formatted log message
const formatLogMessage = (level, message, metadata = {}) => {
  const timestamp = new Date().toISOString();
  let logMessage = `${timestamp} [${level}] ${message}`;
  
  if (metadata.error && metadata.error.stack) {
    logMessage += `\n${metadata.error.stack}`;
  }
  
  if (Object.keys(metadata).length > 0 && !metadata.error) {
    logMessage += ` ${JSON.stringify(metadata)}`;
  }
  
  return logMessage;
};

// Write log to file
const writeLog = (message) => {
  fs.appendFileSync(logFile, message + '\n');
  console.log(message);
};

// Logger methods
const logger = {
  error: (message, metadata = {}) => {
    writeLog(formatLogMessage(LOG_LEVELS.ERROR, message, metadata));
  },
  warn: (message, metadata = {}) => {
    writeLog(formatLogMessage(LOG_LEVELS.WARN, message, metadata));
  },
  info: (message, metadata = {}) => {
    writeLog(formatLogMessage(LOG_LEVELS.INFO, message, metadata));
  },
  debug: (message, metadata = {}) => {
    writeLog(formatLogMessage(LOG_LEVELS.DEBUG, message, metadata));
  }
};

module.exports = logger;
