#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    echo "Sourcing .env file..."
    source .env
else
    echo "Error: .env file not found."
    exit 1
fi

# Ensure DB details are lowercase
DB_NAME=$(echo "$DB_NAME" | tr '[:upper:]' '[:lower:]')
DB_USER=$(echo "$DB_USER" | tr '[:upper:]' '[:lower:]')

# Update system packages
echo "Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install necessary packages
echo "Installing required packages..."
sudo apt-get install -y curl unzip nodejs npm

# Create group and user
echo "Creating non-root user 'csye6225user'..."
sudo groupadd -f csye6225
id -u csye6225user &>/dev/null || sudo useradd -m -s /bin/bash -g csye6225 csye6225user

# Prepare application directory
echo "Setting up application directory..."
sudo mkdir -p /opt/csye6225/webapp
sudo chown -R csye6225user:csye6225 /opt/csye6225
sudo chmod -R 755 /opt/csye6225

# Move to webapp directory
cd /opt/csye6225/webapp || { echo "Error: Webapp directory not found."; exit 1; }

# Installing dependencies
echo "Installing Node.js dependencies..."
sudo -u csye6225user npm install

# Create .env file
echo "Creating .env file..."
sudo bash -c "cat > /opt/csye6225/webapp/.env <<EOL
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASS=$DB_PASSWORD
DB_HOST=${DB_HOST:-localhost}  # Allow overriding in CI/CD
PORT=8080
EOL"

# Ensure firewall allows port 8080
echo "Allowing incoming connections on port 8080..."
sudo ufw allow 8080/tcp
sudo ufw reload

# Ensure Express listens on 0.0.0.0
echo "Ensuring Express app listens on 0.0.0.0..."
sudo sed -i "s|app.listen(PORT, () => {|app.listen(PORT, '0.0.0.0', () => {|g" /opt/csye6225/webapp/index.js

echo "Setup completed successfully."
