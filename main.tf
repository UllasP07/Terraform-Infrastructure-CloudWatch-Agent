# Fetch available AWS Availability Zones dynamically based on region
data "aws_availability_zones" "available" {}

# VPC Resource
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.vpc_name}-VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.vpc_name}-IGW"
  }
}

# Public Subnets (Dynamically selecting AZs)
resource "aws_subnet" "public" {
  count                   = min(length(var.public_subnet_cidrs), length(data.aws_availability_zones.available.names))
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-Public-Subnet-${count.index + 1}"
  }
}

# Private Subnets (Dynamically selecting AZs)
resource "aws_subnet" "private" {
  count             = min(length(var.private_subnet_cidrs), length(data.aws_availability_zones.available.names))
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.vpc_name}-Private-Subnet-${count.index + 1}"
  }
}

# Single Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.vpc_name}-Public-RT"
  }
}

# Public Route for Internet Access
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate All Public Subnets with Public Route Table
resource "aws_route_table_association" "public_association" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Single Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.vpc_name}-Private-RT"
  }
}

# Associate All Private Subnets with Private Route Table
resource "aws_route_table_association" "private_association" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Database Security Group
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main_vpc.id
  name   = "database-security-group"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-DB-SG"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "custom_pg" {
  name   = "custom-db-parameter-group"
  family = var.db_parameter_group_family

  # Add specific parameters as needed
  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.vpc_name}-DB-Subnet-Group"
  }
}

# RDS Instance
resource "aws_db_instance" "db_instance" {
  identifier             = "csye6225"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = "csye6225"
  username               = "csye6225"
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.custom_pg.name
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false
}

# Application Security Group
resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.main_vpc.id

  # Allow SSH, HTTP, HTTPS, and application port from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow StatsD port for CloudWatch metrics
  ingress {
    from_port   = 8125
    to_port     = 8125
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-App-SG"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "/csye6225/webapp"
  retention_in_days = 7

  tags = {
    Name = "${var.vpc_name}-App-Logs"
  }
}

# SNS Topic for CloudWatch Alarms
# resource "aws_sns_topic" "alarm_topic" {
#   name = "ec2-alarms-topic"

#   tags = {
#     Name = "${var.vpc_name}-Alarms-Topic"
#   }
# }

# # SNS Topic Subscription for email notifications
# resource "aws_sns_topic_subscription" "email_subscription" {
#   topic_arn = aws_sns_topic.alarm_topic.arn
#   protocol  = "email"
#   endpoint  = var.alarm_email
# }

# CloudWatch Alarm for CPU Utilization
# resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
#   alarm_name          = "high-cpu-utilization"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = "300"
#   statistic           = "Average"
#   threshold           = "80"
#   alarm_description   = "This metric monitors ec2 cpu utilization"
#   alarm_actions       = [aws_sns_topic.alarm_topic.arn]
#   dimensions = {
#     InstanceId = aws_instance.app_instance.id
#   }

#   tags = {
#     Name = "${var.vpc_name}-CPU-Alarm"
#   }
# }

# CloudWatch Alarm for Health Check
# resource "aws_cloudwatch_metric_alarm" "health_check_alarm" {
#   alarm_name          = "health-check-failed"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "StatusCheckFailed"
#   namespace           = "AWS/EC2"
#   period              = "300"
#   statistic           = "Maximum"
#   threshold           = "0"
#   alarm_description   = "This metric monitors ec2 health status"
#   alarm_actions       = [aws_sns_topic.alarm_topic.arn]
#   dimensions = {
#     InstanceId = aws_instance.app_instance.id
#   }

#   tags = {
#     Name = "${var.vpc_name}-Health-Alarm"
#   }
# }

# Route 53 Zone Data Source
# data "aws_route53_zone" "selected" {
#   name = var.domain_name
# }

# # Route 53 A Record for EC2 Instance
# resource "aws_route53_record" "app_record" {
#   zone_id = data.aws_route53_zone.selected.zone_id
#   name    = var.environment == "dev" ? "dev" : "demo"
#   type    = "A"
#   ttl     = "300"
#   records = [aws_instance.app_instance.public_ip]
# }

# EC2 Instance using Custom AMI
resource "aws_instance" "app_instance" {
  ami                    = var.custom_ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # Pass S3 bucket name directly in user_data
  user_data = templatefile("${path.module}/terraform/user_data.sh", {
    RDS_ENDPOINT   = aws_db_instance.db_instance.address
    S3_BUCKET_NAME = aws_s3_bucket.app_bucket.id
    DB_USER        = aws_db_instance.db_instance.username
    DB_PASS        = var.db_password
    DB_NAME        = aws_db_instance.db_instance.db_name
  })

  root_block_device {
    volume_size           = 25
    volume_type           = "gp3"
    delete_on_termination = true
  }

  disable_api_termination = false

  tags = {
    Name = "${var.vpc_name}-App-Instance"
  }
}
