# webapp      

# Health Check API

This repository contains a simple RESTful API built using Node.js, Sequelize ORM, and PostgreSQL. The application includes an endpoint `/healthz` to monitor the application's health by checking the database connection and logging timestamps in UTC.

---

## Prerequisites

Before building and deploying the application locally, ensure the following prerequisites are met:

1. **Environment Requirements:**
   - Node.js (version 14 or higher)
   - npm (comes with Node.js)
   - PostgreSQL (version 12 or higher)
   - pgAdmin for managing your database (optional)

2. **Set Up the Database:**
   - Install PostgreSQL on your system.
   - Create a PostgreSQL database and note the credentials (database name, user, password, host, and port).
   - Ensure the PostgreSQL server is running.

3. **Install Required Tools:**
   - Git (to clone the repository)
   - Bruno or Postman (for API testing)

---

## Build and Deploy Instructions

Follow these steps to build and deploy the application:

### 1. Clone the Repository
Fork this repository into your GitHub namespace and clone the forked repository locally:
```bash
git clone https://github.com/<your-username>/health-check-api.git
cd health-check-api
```
## Build and Deploy Instructions

Follow these steps to build and deploy the application:

### 2. Install Dependencies

Install the required Node.js dependencies:

```bash
npm install
```
### 3. Configure Environment Variables

Create a .env file in the root of the project and configure the required environment variables:

```bash
DB_NAME=<your-database-name>
DB_USER=<your-database-username>
DB_PASS=<your-database-password>
DB_HOST=<your-database-host>
DB_PORT=<your-database-port>
PORT=8080
```
### 4. Bootstrap the Database
The application uses Sequelize to automatically bootstrap and manage the database schema. When the application starts, it will create the necessary tables.

No additional manual setup is required for the database schema.

### 5. Start the application
Run the application in development mode:

```bash
npm run dev
```
Alternatively, start the application in production mode:
```bash
npm run start
```
The server will run at:
http://localhost:8080

### 6. Test the API
Use Bruno, Postman, or cURL to test the /healthz endpoint.

GET /healthz
-Inserts a health check timestamp into the database and returns:
  -200 OK if successful.
  -503 Service Unavailable if the database is unreachable.

Examples:
Using cURL:

```bash
curl -X GET http://localhost:8080/healthz
```
Using Postman or Bruno:

-Create a new request.
-Set the method to GET.
-Use the URL: http://localhost:8080/healthz.
-Send the request and check the response status.


## Assignment 2. Automating Application Setup with Shell Script


This assignment contains a shell script to automate the setup of a nodejs application with PostgreSQL on Ubuntu 24.04 LTS.

## Prerequisites

•⁠  ⁠Ubuntu 24.04 LTS
•⁠  ⁠Nodejs application ZIP file

## Features

•⁠  ⁠Updates package lists and upgrades system packages.

•⁠  ⁠Installs PostgreSQL as the RDBMS.

•⁠  ⁠Creates a database in PostgreSQL.

•⁠  ⁠reates a new Linux group and user for the application.

•⁠  ⁠Extracts the application into /opt/csye6225/.

•⁠  ⁠Updates permissions for the application directory.

•⁠  ⁠Installs dependencies for spring-boot application
  

## Instructions


Clone the repository:

     > git clone <repository_url>

Copy the script and zip file of the web-app repo to the server 

Make the script executable:

    chmod +x setup.sh

Run the script:

    ./setup.sh
