const { sequelize } = require('./config/database');
// No need to import models, Sequelize will find them

const bootstrapDatabase = async () => {
   try {
       // Simple sync with force: true for tests
       await sequelize.sync({ force: true });
       console.log('Database bootstrapped successfully.');
   } catch (error) {
       console.error('Error bootstrapping database:', error.message);
       throw error; // Pass the original error for better debugging
   }
};

module.exports = bootstrapDatabase;