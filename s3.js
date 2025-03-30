// utils/s3.js
const { S3Client } = require('@aws-sdk/client-s3');
const { Upload } = require('@aws-sdk/lib-storage');
const { GetObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const logger = require('./logger');
const metrics = require('./metrics');

// Initialize S3 client
const s3Client = new S3Client({ region: process.env.AWS_REGION || 'us-east-1' });

// S3 utility functions
const s3 = {
  // Upload file to S3
  uploadFile: async (fileBuffer, key, contentType) => {
    const startTime = Date.now();
    try {
      logger.info(`Uploading file to S3: ${key}`);
      
      const upload = new Upload({
        client: s3Client,
        params: {
          Bucket: process.env.S3_BUCKET,
          Key: key,
          Body: fileBuffer,
          ContentType: contentType
        }
      });
      
      const result = await upload.done();
      
      const duration = Date.now() - startTime;
      metrics.timeS3Operation('upload', duration);
      
      logger.info(`File uploaded successfully to S3: ${key}`, { 
        duration: `${duration}ms`,
        location: result.Location
      });
      
      return result;
    } catch (error) {
      const duration = Date.now() - startTime;
      metrics.timeS3Operation('upload_error', duration);
      
      logger.error(`Error uploading file to S3: ${key}`, { error });
      throw error;
    }
  },
  
  // Get file from S3
  getFile: async (key) => {
    const startTime = Date.now();
    try {
      logger.info(`Getting file from S3: ${key}`);
      
      const command = new GetObjectCommand({
        Bucket: process.env.S3_BUCKET,
        Key: key
      });
      
      const result = await s3Client.send(command);
      
      const duration = Date.now() - startTime;
      metrics.timeS3Operation('get', duration);
      
      logger.info(`File retrieved successfully from S3: ${key}`, { 
        duration: `${duration}ms` 
      });
      
      return result;
    } catch (error) {
      const duration = Date.now() - startTime;
      metrics.timeS3Operation('get_error', duration);
      
      logger.error(`Error getting file from S3: ${key}`, { error });
      throw error;
    }
  },
  
  // Delete file from S3
  deleteFile: async (key) => {
    const startTime = Date.now();
    try {
      logger.info(`Deleting file from S3: ${key}`);
      
      const command = new DeleteObjectCommand({
        Bucket: process.env.S3_BUCKET,
        Key: key
      });
      
      const result = await s3Client.send(command);
      
      const duration = Date.now() - startTime;
      metrics.timeS3Operation('delete', duration);
      
      logger.info(`File deleted successfully from S3: ${key}`, { 
        duration: `${duration}ms` 
      });
      
      return result;
    } catch (error) {
      const duration = Date.now() - startTime;
      metrics.timeS3Operation('delete_error', duration);
      
      logger.error(`Error deleting file from S3: ${key}`, { error });
      throw error;
    }
  }
};

module.exports = s3;
