// routes/healthCheck.js (updated)
const express = require('express');
const HealthCheck = require('../models/HealthCheck');
const logger = require('../utils/logger');
const metrics = require('../utils/metrics');
const router = express.Router();

// Custom middleware to check for raw body content
router.use('/healthz', express.raw({ type: '*/*' }), (req, res, next) => {
  // Check if there's any content in the raw body for GET requests
  if (req.method === 'GET' && (Buffer.isBuffer(req.body) && req.body.length > 0)) {
    logger.warn('GET /healthz request received with query parameters or JSON body', { 
      bodySize: req.body.length 
    });
    metrics.incrementApiCall('get.healthz.error');
    return res.status(400)
      .set({
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'X-Content-Type-Options': 'nosniff',
        'Date': new Date().toUTCString(),
        'Content-Length': '0'
      })
      .send();
  }
  next();
});

// Handle unsupported HTTP methods for healthz
router.all('/healthz', (req, res, next) => {
  if (req.method !== 'GET') {
    logger.warn(`Unsupported method ${req.method} for /healthz`);
    metrics.incrementApiCall(`method_not_allowed.${req.method.toLowerCase()}`);
    return res.status(405)
      .set({
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'X-Content-Type-Options': 'nosniff',
        'Date': new Date().toUTCString(),
        'Content-Length': '0'
      })
      .send();
  }
  next();
});

// Handle GET healthz
router.get('/healthz', async (req, res) => {
  const startTime = Date.now();
  logger.info('Incoming request: GET /healthz', {
    method: 'GET',
    url: '/healthz'
  });
  metrics.incrementApiCall('get.healthz');
  
  try {
    // Check for query parameters or JSON body
    if (Object.keys(req.query).length > 0 || 
        (req.is('application/json') && Object.keys(req.body).length > 0)) {
      logger.warn('GET /healthz request received with query parameters or JSON body');
      metrics.incrementApiCall('get.healthz.error');
      return res.status(400)
        .set({
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'X-Content-Type-Options': 'nosniff',
          'Date': new Date().toUTCString(),
          'Content-Length': '0'
        })
        .send();
    }
    
    // Insert a health check record
    const dbStartTime = Date.now();
    await HealthCheck.create();
    const dbDuration = Date.now() - dbStartTime;
    
    // Record DB query time
    metrics.timeDbQuery('healthcheck_insert', dbDuration);
    
    logger.info('Health check successful', { 
      dbDuration: `${dbDuration}ms` 
    });
    
    const totalDuration = Date.now() - startTime;
    metrics.timeApiCall('get.healthz', totalDuration);
    
    return res.status(200)
      .set({
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'X-Content-Type-Options': 'nosniff',
        'Date': new Date().toUTCString(),
        'Content-Length': '0'
      })
      .send();
  } catch (error) {
    logger.error('Health check failed', { error });
    
    const totalDuration = Date.now() - startTime;
    metrics.incrementApiCall('get.healthz.error');
    metrics.timeApiCall('get.healthz.error', totalDuration);
    
    return res.status(503)
      .set({
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'X-Content-Type-Options': 'nosniff',
        'Date': new Date().toUTCString(),
        'Content-Length': '0'
      })
      .send();
  }
});

module.exports = router;
