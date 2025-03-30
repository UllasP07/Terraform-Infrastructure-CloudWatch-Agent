// utils/metrics.js
const StatsD = require('hot-shots');

// Initialize StatsD client
const client = new StatsD({
  host: 'localhost',
  port: 8125,
  prefix: 'webapp.',
  errorHandler: (error) => {
    console.error('StatsD error:', error);
  }
});

// Metrics utility functions
const metrics = {
  // Increment counter for API calls
  incrementApiCall: (apiName) => {
    client.increment(`api.${apiName}.calls`);
  },
  
  // Time API calls
  timeApiCall: (apiName, timeInMs) => {
    client.timing(`api.${apiName}.time`, timeInMs);
  },
  
  // Time database queries
  timeDbQuery: (queryName, timeInMs) => {
    client.timing(`db.${queryName}.time`, timeInMs);
  },
  
  // Time S3 operations
  timeS3Operation: (operation, timeInMs) => {
    client.timing(`s3.${operation}.time`, timeInMs);
  }
};

module.exports = metrics;
