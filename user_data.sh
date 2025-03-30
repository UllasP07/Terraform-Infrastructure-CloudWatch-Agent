#!/bin/bash
set -e

# Fetch Terraform-generated values (from template)
RDS_ENDPOINT="${RDS_ENDPOINT}"
S3_BUCKET_NAME="${S3_BUCKET_NAME}"
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"
DB_NAME="${DB_NAME}"

# Write environment variables
cat <<EOF > /opt/csye6225/webapp/.env
AWS_REGION=us-east-1
S3_BUCKET=$S3_BUCKET_NAME
DB_HOST=$RDS_ENDPOINT
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=$DB_NAME
PORT=8080
EOF

# Fix permissions
chown csye6225user:csye6225 /opt/csye6225/webapp/.env
chmod 600 /opt/csye6225/webapp/.env

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
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
      "InstanceId": "$${aws:InstanceId}"
    }
  }
}
EOF

# Start CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Restart web application to apply new environment variables
systemctl restart webapp

# Log completion for debugging
echo "User data script completed successfully at $(date)" >> /var/log/user-data.log
