// middleware/requestLogger.js
const logger = require('../utils/logger');
const metrics = require('../utils/metrics');

const requestLogger = (req, res, next) => {
  // Record start time
  const startTime = Date.now();
  
  // Log incoming request
  logger.info(`Incoming request: ${req.method} ${req.originalUrl}`, {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
  
  // Capture original end method
  const originalEnd = res.end;
  
  // Override end method to log response
  res.end = function(...args) {
    // Calculate request duration
    const duration = Date.now() - startTime;
    
    // Log response
    logger.info(`Request completed: ${req.method} ${req.originalUrl}`, {
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      duration: `${duration}ms`
    });
    
    // Record metrics
    const routeName = req.route ? req.route.path : 'unknown';
    metrics.incrementApiCall(`${req.method.toLowerCase()}.${routeName}`);
    metrics.timeApiCall(`${req.method.toLowerCase()}.${routeName}`, duration);
    
    // Call original end method
    return originalEnd.apply(this, args);
  };
  
  next();
};

module.exports = requestLogger;
