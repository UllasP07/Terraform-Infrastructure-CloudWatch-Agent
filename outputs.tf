output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main_vpc.id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}

output "application_security_group_id" {
  description = "Security group ID for application"
  value       = aws_security_group.app_sg.id
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.app_instance.id
}

output "ec2_public_ip" {
  description = "EC2 Instance Public IP"
  value       = aws_instance.app_instance.public_ip
}

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.db_instance.address
  sensitive   = true
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.app_bucket.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for the application"
  value       = aws_cloudwatch_log_group.app_log_group.name
}

# output "sns_topic_arn" {
#   description = "ARN of the SNS topic for CloudWatch alarms"
#   value       = aws_sns_topic.alarm_topic.arn
# }

# output "domain_name" {
#   description = "The domain name for the application"
#   value       = "${var.subdomain}.${var.domain_name}"
# }

output "ec2_iam_role" {
  description = "IAM role attached to the EC2 instance"
  value       = aws_iam_role.ec2_role.name
}

# output "cpu_alarm_name" {
#   description = "Name of the CPU utilization alarm"
#   value       = aws_cloudwatch_metric_alarm.cpu_utilization_alarm.alarm_name
# }

# output "health_alarm_name" {
#   description = "Name of the health check alarm"
#   value       = aws_cloudwatch_metric_alarm.health_check_alarm.alarm_name
# }
# output "domain_name" {
#   description = "The domain name for the application"
#   value       = "${var.environment}.${var.domain_name}"
# }
