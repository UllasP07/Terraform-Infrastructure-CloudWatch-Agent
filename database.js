const Sequelize = require('sequelize');
const logger = require('../utils/logger');
const metrics = require('../utils/metrics');
require('dotenv').config();

// Determine if we're in test mode
const isTest = process.env.NODE_ENV === 'test';

// Create custom logging function to track query times
const customLogger = (query, time) => {
  logger.debug(`Database query executed in ${time}ms`, { query });
  metrics.timeDbQuery('query', time);
  if (!isTest) {
    console.log(query);
  }
};

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASS,
  {
    host: process.env.DB_HOST,
    dialect: 'postgres',
    logging: isTest ? false : customLogger,
    timezone: '+0000', // Ensure UTC timezone
    dialectOptions: {
      useUTC: true,
    },
    define: {
      underscored: true, // Use snake_case instead of camelCase for columns
    },
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    benchmark: true // Enable query timing
  }
);

// Rest of the code remains the same


const connectDB = async (retries = 5) => {
    while (retries) {
        try {
            await sequelize.authenticate();
            console.log('Connected to RDS database successfully.');
            return;
        } catch (error) {
            console.error(`Database connection failed. Retries left: ${retries - 1}`);
            retries -= 1;
            if (retries === 0) {
                if (isTest) {
                    // In test mode, throw instead of exiting
                    throw new Error("Failed to connect to the database after retries");
                } else {
                    console.error("Failed to connect to the database after retries:", error);
                    process.exit(1);
                }
            }
            await new Promise(res => setTimeout(res, 2000)); // Wait 2 seconds before retrying
        }
    }
};

module.exports = { sequelize, connectDB };