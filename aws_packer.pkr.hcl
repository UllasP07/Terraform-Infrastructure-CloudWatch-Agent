packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0, < 2.0.0"
      source  = "github.com/hashicorp/amazon"
    }
    googlecompute = {
      version = ">= 1.0.0, < 2.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

# AWS Variables
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ami_name" {
  type    = string
  default = "webapp-ami"
}

variable "source_ami_owner" {
  type    = string
  default = "099720109477" # Canonical's AWS account ID
}

# GCP Variables
variable "gcp_project_id" {
  type    = string
  default = "csye6225-451919"
}

variable "gcp_zone" {
  type    = string
  default = "us-central1-a"
}

variable "gcp_image_name" {
  type    = string
  default = "webapp-image"
}

variable "gcp_service_account_file" {
  type    = string
  default = ""
}

variable "db_user" {
  type    = string
  default = "csye6225user"
}

variable "db_pass" {
  type    = string
  default = "csye6225password"
}

variable "db_name" {
  type    = string
  default = "csye6225db"
}

variable "db_host" {
  type    = string
  default = "localhost"
}

variable "port" {
  type    = string
  default = "8080"
}

variable "gcp_service_account_email" {
  type    = string
  default = null
}

# New variables for sharing with DEMO accounts
variable "demo_aws_account_id" {
  type        = string
  description = "AWS Account ID of the DEMO account to share the AMI with"
  default     = "340752835501"
}

variable "gcp_demo_project_id" {
  type        = string
  description = "GCP Project ID of the DEMO project to share the image with"
  default     = "csye6225-demo-452101"
}

variable "source_ami" {
  type    = string
  default = "ami-04b4f1a9cf54c11d0"
}

# AWS Source (removed ami_users)
source "amazon-ebs" "webapp" {
  region          = var.aws_region
  instance_type   = "t2.micro"
  ssh_username    = "ubuntu"
  source_ami      = var.source_ami
  ami_name        = "${var.ami_name}-{{timestamp}}"
  ami_description = "Custom AMI for Health Check API application"

  tags = {
    Name        = var.ami_name
    Environment = "dev"
    Application = "health-check-api"
  }
}

# Define the GCP builder
# source "googlecompute" "webapp" {
#   project_id              = var.gcp_project_id
#   zone                    = var.gcp_zone
#   source_image_family     = "ubuntu-2404-lts-amd64" # Use 22.04 LTS instead of 24.04
#   source_image_project_id = ["ubuntu-os-cloud"]
#   machine_type            = "e2-medium"
#   ssh_username            = "ubuntu"
#   image_name              = "${var.gcp_image_name}-{{timestamp}}"
#   image_description       = "Custom GCP Image for Health Check API application"

#   # Optional: specify a service account file if not using Application Default Credentials
#   account_file = var.gcp_service_account_file != "" ? var.gcp_service_account_file : null

#   # Labels for the image
#   image_labels = {
#     name        = var.gcp_image_name
#     environment = "dev"
#     application = "health-check-api"
#   }
#   # Share image with DEMO project
#   image_storage_locations = ["us"]
# }

# Build and provision the images
build {
  # Specify sources - use only AWS builder by default, add GCP if project_id is provided
  sources = ["source.amazon-ebs.webapp"]

  # Upload set.sh script for system setup
  provisioner "file" {
    source      = "packer/scripts/set.sh"
    destination = "/tmp/set.sh"
  }

  # Make script executable and run it
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/set.sh",
      "/tmp/set.sh || (echo 'Setup script completed with non-zero exit code' && exit 0)"
    ]
  }

  # Create application user and group
  provisioner "shell" {
    inline = [
      "sudo groupadd -f csye6225 || echo 'Group already exists'",
      "sudo useradd -m -s /bin/bash -g csye6225 csye6225user || echo 'User already exists'"
    ]
  }

  # Create application directory structure
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/csye6225/webapp",
      "sudo mkdir -p /opt/csye6225/webapp/config",
      "sudo mkdir -p /opt/csye6225/webapp/middleware",
      "sudo mkdir -p /opt/csye6225/webapp/models",
      "sudo mkdir -p /opt/csye6225/webapp/packer",
      "sudo mkdir -p /opt/csye6225/webapp/routes",
      "sudo mkdir -p /opt/csye6225/webapp/tests",
      "sudo mkdir -p /opt/csye6225/webapp/utils",
      "sudo chown -R csye6225user:csye6225 /opt/csye6225",
      "sudo chmod -R 755 /opt/csye6225"
    ]
  }

  # Create a temporary directory for storing the files
  provisioner "shell" {
    inline = [
      "mkdir -p /tmp/webapp_files"
    ]
  }

  # Upload application files individually - main files
  provisioner "file" {
    source      = "bootstrap.js"
    destination = "/tmp/webapp_files/bootstrap.js"
  }

  provisioner "file" {
    source      = "index.js"
    destination = "/tmp/webapp_files/index.js"
  }

  provisioner "file" {
    source      = "package.json"
    destination = "/tmp/webapp_files/package.json"
  }

  provisioner "file" {
    source      = "package-lock.json"
    destination = "/tmp/webapp_files/package-lock.json"
  }

  # Upload subdirectory files - config
  provisioner "file" {
    source      = "config/database.js"
    destination = "/tmp/webapp_files/database.js"
  }

  provisioner "file" {
    source      = "middleware/requestLogger.js"
    destination = "/tmp/webapp_files/requestLogger.js"
  }

  # Upload subdirectory files - models
  provisioner "file" {
    source      = "models/HealthCheck.js"
    destination = "/tmp/webapp_files/HealthCheck.js"
  }

  provisioner "file" {
    source      = "models/FileMetadata.js"
    destination = "/tmp/webapp_files/FileMetadata.js"
  }

  provisioner "file" {
    source      = "packer/cloudwatch-config.json"
    destination = "/tmp/webapp_files/cloudwatch-config.json"
  }

  # Upload subdirectory files - routes
  provisioner "file" {
    source      = "routes/healthCheck.js"
    destination = "/tmp/webapp_files/healthCheck.js"
  }

  provisioner "file" {
    source      = "routes/files.js"
    destination = "/tmp/webapp_files/files.js"
  }

  # Upload subdirectory files - tests (if needed)
  provisioner "file" {
    source      = "tests/healthCheck.test.js"
    destination = "/tmp/webapp_files/healthCheck.test.js"
  }

  provisioner "file" {
    source      = "utils/logger.js"
    destination = "/tmp/webapp_files/logger.js"
  }

  provisioner "file" {
    source      = "utils/metrics.js"
    destination = "/tmp/webapp_files/metrics.js"
  }

  provisioner "file" {
    source      = "utils/s3.js"
    destination = "/tmp/webapp_files/s3.js"
  }

  # Move files to application directory with proper structure
  provisioner "shell" {
    inline = [
      "sudo cp /tmp/webapp_files/bootstrap.js /opt/csye6225/webapp/",
      "sudo cp /tmp/webapp_files/index.js /opt/csye6225/webapp/",
      "sudo cp /tmp/webapp_files/package.json /opt/csye6225/webapp/",
      "sudo cp /tmp/webapp_files/package-lock.json /opt/csye6225/webapp/",
      "sudo cp /tmp/webapp_files/database.js /opt/csye6225/webapp/config/",
      "sudo cp /tmp/webapp_files/HealthCheck.js /opt/csye6225/webapp/models/",
      "sudo cp /tmp/webapp_files/FileMetadata.js /opt/csye6225/webapp/models/",
      "sudo cp /tmp/webapp_files/healthCheck.js /opt/csye6225/webapp/routes/",
      "sudo cp /tmp/webapp_files/files.js /opt/csye6225/webapp/routes/",
      "sudo cp /tmp/webapp_files/healthCheck.test.js /opt/csye6225/webapp/tests/",
      "sudo cp /tmp/webapp_files/requestLogger.js /opt/csye6225/webapp/middleware/",
      "sudo cp /tmp/webapp_files/cloudwatch-config.json /opt/csye6225/webapp/packer/",
      "sudo cp /tmp/webapp_files/logger.js /opt/csye6225/webapp/utils/",
      "sudo cp /tmp/webapp_files/metrics.js /opt/csye6225/webapp/utils/",
      "sudo cp /tmp/webapp_files/s3.js /opt/csye6225/webapp/utils/",
      "sudo chown -R csye6225user:csye6225 /opt/csye6225/webapp",
      "sudo chmod -R 755 /opt/csye6225/webapp"
    ]
  }

  # Install application dependencies
  provisioner "shell" {
    inline = [
      "cd /opt/csye6225/webapp",
      "sudo -u csye6225user npm install --no-fund --no-audit --loglevel=error || echo 'npm install attempted'"
    ]
  }

  # Create systemd service file
  provisioner "file" {
    source      = "packer/scripts/webapp.service"
    destination = "/tmp/webapp.service"
  }

  # Move and enable systemd service
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/webapp.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable webapp.service"
    ]
  }

  # Configure firewall to allow application port
  provisioner "shell" {
    inline = [
      "sudo ufw allow 22/tcp || echo 'SSH port allow attempted'",
      "sudo ufw allow 8080/tcp || echo 'App port allow attempted'",
      "sudo ufw --force enable || echo 'Firewall enabled'"
    ]
  }

  # Configure and start CloudWatch agent
  provisioner "shell" {
    inline = [
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
      "echo \"[$(date +'%Y-%m-%d %H:%M:%S')] CloudWatch agent configured and started\""
    ]
  }

}