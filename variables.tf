variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Name        = "main-vpc"
    Environment = "Development"
    Owner       = "Team Dev"
  }
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "app_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 8080
}

variable "custom_ami_id" {
  description = "Custom AMI ID for EC2 instance"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Port for database connections"
  type        = number
  default     = 5432
}

variable "db_engine" {
  description = "Database engine type"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "14.17"
}

variable "db_parameter_group_family" {
  description = "Parameter group family for the database"
  type        = string
  default     = "postgres14"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for file storage"
  type        = string
  default     = "my-unique-bucket-name"
}

# variable "alarm_email" {
#   description = "Email address for CloudWatch alarm notifications"
#   type        = string
#   default     = "cw"
# }

# variable "domain_name" {
#   description = "Domain name for Route 53"
#   type        = string
#   default     = "dom"
# }

# variable "subdomain" {
#   description = "Subdomain for the application"
#   type        = string
#   default     = "dev"
# }
# variable "domain_name" {
#   description = "Domain name for Route 53"
#   type        = string
# }

# variable "environment" {
#   description = "Environment (dev or demo)"
#   type        = string
# }
