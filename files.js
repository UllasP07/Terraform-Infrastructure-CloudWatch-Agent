const express = require('express');
const { S3Client, PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const multer = require('multer');
const { sequelize } = require('../config/database');
const FileMetadata = require('../models/FileMetadata');
const logger = require('../utils/logger');
const metrics = require('../utils/metrics');

const router = express.Router();

// Configure multer with robust error handling
const storage = multer.memoryStorage();
const multerUpload = multer({ 
    storage,
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// Custom middleware to handle multer errors
const handleMulterUpload = (req, res, next) => {
    const upload = multerUpload.single('file');
    
    upload(req, res, (err) => {
        if (err instanceof multer.MulterError) {
            // Multer error (wrong field name, file too large, etc.)
            logger.error("Multer error", { error: err });
            metrics.incrementApiCall('file_upload_error');
            return res.status(400).send();
        } else if (err) {
            // Other unexpected errors
            logger.error("Unexpected upload error", { error: err });
            metrics.incrementApiCall('file_upload_error');
            return res.status(400).send();
        }
        
        // No errors, continue
        next();
    });
};

// Initialize S3 client with environment variables
const s3Region = process.env.AWS_REGION || 'us-east-1';
const s3 = new S3Client({ region: s3Region });

// Handle Method Not Allowed for root path (/v1/file)
router.all('/v1/file', (req, res, next) => {
    if (req.method === 'POST') {
        next();
    } else if (req.method === 'GET' || req.method === 'DELETE') {
        logger.warn(`Method ${req.method} not allowed on /v1/file path`, { method: req.method, path: '/v1/file' });
        metrics.incrementApiCall(`method_not_allowed.${req.method.toLowerCase()}`);
        return res.status(400).send();
    } else {
        // HEAD, OPTIONS, PATCH, PUT methods
        logger.warn(`Method ${req.method} not allowed on /v1/file path`, { method: req.method, path: '/v1/file' });
        metrics.incrementApiCall(`method_not_allowed.${req.method.toLowerCase()}`);
        return res.status(405).send();
    }
});

// Handle Method Not Allowed for path with ID (/v1/file/:id)
router.all('/v1/file/:id', (req, res, next) => {
    if (req.method === 'GET' || req.method === 'DELETE') {
        next();
    } else {
        // HEAD, OPTIONS, PATCH, PUT, POST methods for path with ID
        logger.warn(`Method ${req.method} not allowed on /v1/file/:id path`, { method: req.method, path: `/v1/file/${req.params.id}` });
        metrics.incrementApiCall(`method_not_allowed.${req.method.toLowerCase()}`);
        return res.status(405).send();
    }
});

/**
 * POST /v1/file - Add a file.
 * Using handleMulterUpload middleware to catch multer errors
 */
router.post('/v1/file', handleMulterUpload, async (req, res) => {
    const startTime = Date.now();
    logger.info("File upload request received", { method: 'POST', path: '/v1/file' });
    metrics.incrementApiCall('post.file');
    
    try {
        // This check is now redundant but kept for safety
        if (!req.file) {
            logger.warn("No file provided in upload request");
            return res.status(400).send();
        }

        const { originalname, buffer } = req.file;
        const fileKey = `${Date.now()}-${originalname}`;
        
        // Check if S3_BUCKET is defined
        const s3Bucket = process.env.S3_BUCKET || process.env.S3_BUCKET_NAME;
        if (!s3Bucket) {
            logger.error("S3_BUCKET environment variable is not defined");
            return res.status(500).send();
        }

        try {
            // Upload file to S3
            const s3StartTime = Date.now();
            logger.info("Uploading file to S3", { filename: originalname, key: fileKey });
            
            const uploadResponse = await s3.send(new PutObjectCommand({
                Bucket: s3Bucket,
                Key: fileKey,
                Body: buffer,
            }));
            
            const s3Duration = Date.now() - s3StartTime;
            metrics.timeS3Operation('upload', s3Duration);
            logger.info("S3 upload completed", { duration: `${s3Duration}ms` });

            if (!uploadResponse.$metadata || uploadResponse.$metadata.httpStatusCode !== 200) {
                logger.error("S3 upload failed", { response: uploadResponse });
                return res.status(500).send();
            }

            // Format the date as YYYY-MM-DD
            const today = new Date();
            const formattedDate = today.toISOString().split('T')[0]; // Format as YYYY-MM-DD

            // Save file metadata in RDS with the proper date format
            const dbStartTime = Date.now();
            logger.info("Saving file metadata to database");
            
            const file = await FileMetadata.create({
                filename: originalname,
                s3_key: fileKey,
                s3_url: `https://${s3Bucket}.s3.amazonaws.com/${fileKey}`,
                upload_date: formattedDate
            });
            
            const dbDuration = Date.now() - dbStartTime;
            metrics.timeDbQuery('file_metadata_create', dbDuration);
            logger.info("Database operation completed", { duration: `${dbDuration}ms` });

            // Calculate total request time
            const totalDuration = Date.now() - startTime;
            metrics.timeApiCall('post.file', totalDuration);
            logger.info("File upload request completed successfully", { 
                duration: `${totalDuration}ms`,
                fileId: file.id 
            });

            // Return success response with the expected format
            return res.status(201).json({
                file_name: file.filename,
                id: file.id,
                url: file.s3_url,
                upload_date: formattedDate
            });
        } catch (error) {
            logger.error("Error uploading file to S3", { error: error, filename: req.file.originalname });
            return res.status(500).send();
        }
    } catch (error) {
        logger.error("Error in POST /v1/file route", { error: error });
        return res.status(500).send();
    }
});

/**
 * GET /v1/file/{id} - Get file metadata.
 * With improved error handling for invalid IDs
 */
router.get('/v1/file/:id', async (req, res) => {
    const startTime = Date.now();
    logger.info("File metadata request received", { method: 'GET', path: `/v1/file/${req.params.id}`, fileId: req.params.id });
    metrics.incrementApiCall('get.file');
    
    try {
        // Validate UUID format
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        if (!uuidRegex.test(req.params.id)) {
            logger.warn("Invalid UUID format in request", { fileId: req.params.id });
            return res.status(404).send();
        }

        // Try to find the file
        const dbStartTime = Date.now();
        const file = await FileMetadata.findByPk(req.params.id);
        const dbDuration = Date.now() - dbStartTime;
        metrics.timeDbQuery('file_metadata_find', dbDuration);
        logger.info("Database query completed", { duration: `${dbDuration}ms` });
        
        if (!file) {
            logger.warn("File not found", { fileId: req.params.id });
            return res.status(404).send();
        }

        // Format date if it exists, or use a placeholder
        let uploadDate = file.upload_date;
        if (!uploadDate) {
            // If upload_date doesn't exist, use createdAt as fallback or today's date
            uploadDate = file.createdAt ? new Date(file.createdAt) : new Date();
        }
        
        // Ensure date is in YYYY-MM-DD format
        if (uploadDate instanceof Date) {
            uploadDate = uploadDate.toISOString().split('T')[0];
        }

        // Calculate total request time
        const totalDuration = Date.now() - startTime;
        metrics.timeApiCall('get.file', totalDuration);
        logger.info("File metadata request completed successfully", { 
            duration: `${totalDuration}ms`,
            fileId: file.id 
        });

        // Return file metadata in the expected format
        return res.status(200).json({
            file_name: file.filename,
            id: file.id,
            url: file.s3_url,
            upload_date: uploadDate
        });
    } catch (error) {
        const totalDuration = Date.now() - startTime;
        metrics.timeApiCall('get.file.error', totalDuration);
        logger.error("Error fetching file metadata", { error: error, fileId: req.params.id });
        return res.status(404).send();
    }
});

/**
 * DELETE /v1/file/{id} - Delete a file.
 * With improved error handling for invalid IDs
 */
router.delete('/v1/file/:id', async (req, res) => {
    const startTime = Date.now();
    logger.info("File deletion request received", { method: 'DELETE', path: `/v1/file/${req.params.id}`, fileId: req.params.id });
    metrics.incrementApiCall('delete.file');
    
    try {
        // Validate UUID format
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        if (!uuidRegex.test(req.params.id)) {
            logger.warn("Invalid UUID format in delete request", { fileId: req.params.id });
            return res.status(404).send();
        }

        // Try to find the file
        const dbFindStartTime = Date.now();
        const file = await FileMetadata.findByPk(req.params.id);
        const dbFindDuration = Date.now() - dbFindStartTime;
        metrics.timeDbQuery('file_metadata_find_for_delete', dbFindDuration);
        logger.info("Database find query completed", { duration: `${dbFindDuration}ms` });
        
        if (!file) {
            logger.warn("File not found for deletion", { fileId: req.params.id });
            return res.status(404).send();
        }

        // Check if S3_BUCKET is defined
        const s3Bucket = process.env.S3_BUCKET || process.env.S3_BUCKET_NAME;
        if (!s3Bucket) {
            logger.error("S3_BUCKET environment variable is not defined");
            return res.status(500).send();
        }

        try {
            // Delete file from S3
            const s3StartTime = Date.now();
            logger.info("Deleting file from S3", { key: file.s3_key });
            
            await s3.send(new DeleteObjectCommand({
                Bucket: s3Bucket,
                Key: file.s3_key,
            }));
            
            const s3Duration = Date.now() - s3StartTime;
            metrics.timeS3Operation('delete', s3Duration);
            logger.info("S3 delete completed", { duration: `${s3Duration}ms` });
        } catch (s3Error) {
            logger.error("Error deleting from S3", { error: s3Error, key: file.s3_key });
            metrics.incrementApiCall('s3_delete_error');
            // Continue with database deletion even if S3 deletion fails
        }

        // Delete file metadata from RDS
        const dbDeleteStartTime = Date.now();
        logger.info("Deleting file metadata from database", { fileId: file.id });
        
        await file.destroy();
        
        const dbDeleteDuration = Date.now() - dbDeleteStartTime;
        metrics.timeDbQuery('file_metadata_delete', dbDeleteDuration);
        logger.info("Database delete completed", { duration: `${dbDeleteDuration}ms` });

        // Calculate total request time
        const totalDuration = Date.now() - startTime;
        metrics.timeApiCall('delete.file', totalDuration);
        logger.info("File deletion request completed successfully", { 
            duration: `${totalDuration}ms`,
            fileId: req.params.id 
        });

        // Return success response with no content
        return res.status(204).send();
    } catch (error) {
        const totalDuration = Date.now() - startTime;
        metrics.timeApiCall('delete.file.error', totalDuration);
        logger.error("Error deleting file", { error: error, fileId: req.params.id });
        return res.status(404).send();
    }
});

module.exports = router;
