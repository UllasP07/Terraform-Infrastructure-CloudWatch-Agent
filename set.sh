#!/bin/bash

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting system setup..."

# Disable command-not-found handler temporarily to avoid errors
if [ -f /etc/apt/apt.conf.d/50command-not-found ]; then
    sudo mv /etc/apt/apt.conf.d/50command-not-found /etc/apt/apt.conf.d/50command-not-found.bak
    log "Temporarily disabled command-not-found handler"
fi

# Clean and update package lists
log "Cleaning APT lists and cache..."
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get clean

log "Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install Node.js
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - 
sudo apt-get install -y nodejs

# Install additional utilities
log "Installing required packages..."
sudo apt-get install -y curl unzip 

# Install CloudWatch agent
log "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Create CloudWatch agent configuration directory
log "Creating CloudWatch configuration directory..."
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/

# Create CloudWatch agent configuration file
log "Creating CloudWatch agent configuration file..."
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/webapp.log",
            "log_group_name": "/csye6225/webapp",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "statsd": {
        "service_address": ":8125",
        "metrics_collection_interval": 10,
        "metrics_aggregation_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          "used_percent"
        ]
      },
      "cpu": {
        "resources": [
          "*"
        ],
        "measurement": [
          "usage_active",
          "usage_idle"
        ],
        "totalcpu": true
      }
    },
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    }
  }
}
EOF

# Create log file with proper permissions
log "Creating webapp log file..."
sudo touch /var/log/webapp.log
sudo chmod 664 /var/log/webapp.log

# Enable CloudWatch agent to start on boot
log "Enabling CloudWatch agent service..."
sudo systemctl enable amazon-cloudwatch-agent.service

# Ensure firewall allows necessary ports
log "Setting up firewall rules..."
sudo ufw allow 22/tcp
sudo ufw allow 8080/tcp
sudo ufw --force enable

# Restore command-not-found handler if it was disabled
if [ -f /etc/apt/apt.conf.d/50command-not-found.bak ]; then
    sudo mv /etc/apt/apt.conf.d/50command-not-found.bak /etc/apt/apt.conf.d/50command-not-found
    log "Restored command-not-found handler"
fi

log "System setup completed successfully."
exit 0  # Exit with success code
