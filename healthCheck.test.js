const app = require('../index');
const request = require('supertest');
const { sequelize } = require('../config/database');
const bootstrapDatabase = require('../bootstrap');
const logger = require('../utils/logger');
const metrics = require('../utils/metrics');

// Mock logger and metrics
jest.mock('../utils/logger');
jest.mock('../utils/metrics');

// Set test environment
process.env.NODE_ENV = 'test';

// Import app after setting NODE_ENV
// const { app } = require('../index');

beforeAll(async () => {
    try {
        console.log("Connecting to the database...");
        await sequelize.authenticate();
        console.log("Database authenticated successfully.");

        console.log("Bootstrapping database...");
        await bootstrapDatabase(); 
        console.log("Database bootstrapped successfully.");
    } catch (error) {
        console.error("Setup error:", error);
        throw error;
    }
}, 30000);

afterAll(async () => {
    try {
        console.log("Closing database connection...");
        await sequelize.close();
        console.log("Database connection closed.");
    } catch (error) {
        console.error("Error closing database:", error);
    }
}, 10000);

describe('Health Check API Tests', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('GET /healthz should return 200 with no content and log the request', async () => {
        const response = await request(app).get('/healthz');
        expect(response.status).toBe(200);
        expect(response.headers['cache-control']).toBe('no-cache, no-store, must-revalidate');
        expect(response.headers['pragma']).toBe('no-cache');
        expect(response.headers['x-content-type-options']).toBe('nosniff');
        expect(response.headers['content-length']).toBe('0');

        expect(logger.info).toHaveBeenCalledWith('Incoming request: GET /healthz', expect.any(Object));
        expect(metrics.incrementApiCall).toHaveBeenCalledWith('get.healthz');
        expect(metrics.timeApiCall).toHaveBeenCalledWith('get.healthz', expect.any(Number));
    });

    test('GET /healthz with body should return 400 Bad Request and log the error', async () => {
        const response = await request(app).get('/healthz').send({ invalid: 'data' });
        expect(response.status).toBe(400);
        expect(response.headers['cache-control']).toBe('no-cache, no-store, must-revalidate');

        expect(logger.warn).toHaveBeenCalledWith(expect.stringContaining('GET /healthz request received with query parameters or JSON body'));
        expect(metrics.incrementApiCall).toHaveBeenCalledWith('get.healthz.error');
    });

    test('GET /healthz with query params should return 400 Bad Request and log the error', async () => {
        const response = await request(app).get('/healthz?param=1');
        expect(response.status).toBe(400);
        expect(response.headers['cache-control']).toBe('no-cache, no-store, must-revalidate');

        expect(logger.warn).toHaveBeenCalledWith(expect.stringContaining('GET /healthz request received with query parameters or JSON body'));
        expect(metrics.incrementApiCall).toHaveBeenCalledWith('get.healthz.error');
    });

    test('POST /healthz should return 405 Method Not Allowed and log the error', async () => {
        const response = await request(app).post('/healthz');
        expect(response.status).toBe(405);
        expect(response.headers['cache-control']).toBe('no-cache, no-store, must-revalidate');

        expect(logger.warn).toHaveBeenCalledWith(expect.stringContaining('Unsupported method POST for /healthz'));
        expect(metrics.incrementApiCall).toHaveBeenCalledWith('method_not_allowed.post');
    });

    // Similar updates for PUT, DELETE, HEAD, OPTIONS, and PATCH tests...

    test('When database is disconnected, healthz should return 503 Service Unavailable and log the error', async () => {
        const originalCreate = sequelize.models.HealthCheck.create;
        sequelize.models.HealthCheck.create = jest.fn().mockRejectedValue(new Error('Simulated DB error'));
        
        const response = await request(app).get('/healthz');
        
        sequelize.models.HealthCheck.create = originalCreate;
        
        expect(response.status).toBe(503);
        expect(response.headers['cache-control']).toBe('no-cache, no-store, must-revalidate');

        expect(logger.error).toHaveBeenCalledWith(expect.stringContaining('Health check failed'), expect.objectContaining({error: expect.any(Error)}));
        expect(metrics.incrementApiCall).toHaveBeenCalledWith('get.healthz.error');
    });

    test('Database query time should be measured', async () => {
        await request(app).get('/healthz');
        expect(metrics.timeDbQuery).toHaveBeenCalledWith('healthcheck_insert', expect.any(Number));
    });
});
