const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const HealthCheck = sequelize.define('HealthCheck', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
    },
    datetime: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: sequelize.fn('NOW'),
    },
}, {
    timestamps: false,
    tableName: 'health_checks',
    freezeTableName: true // Prevent Sequelize from pluralizing the table name
});

module.exports = HealthCheck;