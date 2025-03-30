# Generate a random UUID for the S3 bucket name
resource "random_uuid" "bucket_name" {}

# S3 Bucket
resource "aws_s3_bucket" "app_bucket" {
  bucket        = random_uuid.bucket_name.result
  force_destroy = true

  tags = {
    Name = "Application-Bucket"
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "app_bucket_access" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable default encryption for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Set up lifecycle policy to transition objects to STANDARD_IA after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    id     = "transition-to-IA"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# IAM Role for EC2 with combined S3 and CloudWatch permissions
resource "aws_iam_role" "ec2_role" {
  name = "ec2_combined_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.vpc_name}-EC2-Role"
  }
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3_access_policy_2025"
  description = "Policy to allow EC2 instance to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.app_bucket.arn}",
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach the S3 policy to the role
resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Attach CloudWatch Agent policy to the role
resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create an instance profile for the role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_combined_profile_2025"
  role = aws_iam_role.ec2_role.name
}
