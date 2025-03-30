const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const FileMetadata = sequelize.define('FileMetadata', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    filename: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    s3_key: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    s3_url: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    upload_date: {
        type: DataTypes.DATEONLY,  // DATEONLY for YYYY-MM-DD format
        allowNull: true,  // Allow null initially to handle existing records
    }
}, {
    timestamps: true,
    tableName: 'file_metadata',
});

module.exports = FileMetadata;