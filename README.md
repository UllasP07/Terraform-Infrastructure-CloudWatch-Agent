# tf-aws-infra

# Terraform AWS Infrastructure

## Overview
This repository contains Terraform scripts to set up AWS networking infrastructure, including:
- A **Virtual Private Cloud (VPC)**
- **Public and Private Subnets** across available availability zones
- A **single Internet Gateway (IGW)** for public internet access
- **One Public and One Private Route Table** to manage traffic
- Dynamic allocation of resources based on the selected AWS region

## Prerequisites
Before you begin, ensure you have the following:
- **Terraform** installed (`>=1.0.0`)
- **AWS CLI** installed and configured with a profile
- **Git** installed

## Project Structure
tf-aws-infra/
│── .github/workflows/ # GitHub Actions CI/CD pipeline
│── main.tf # Terraform configuration for AWS infrastructure
│── variables.tf # Variable definitions
│── terraform.tfvars # Terraform variable values
│── provider.tf # AWS provider configuration
│── outputs.tf # Output values
│── versions.tf # Terraform version configuration
│── README.md # Project documentation


## Setup Instructions

### 1. Clone the Repository

git clone https://github.com/<your-username>/tf-aws-infra.git
cd tf-aws-infra


### 2. Configure AWS CLI
Ensure your AWS CLI is set up with a valid profile:

aws configure --profile dev


### 3. Initialize Terraform
terraform init


### 4. Validate Configuration
terraform validate


### 5. Plan Infrastructure Deployment
terraform plan


### 6. Deploy Infrastructure
terraform apply

- Type **"yes"** to confirm.

### 7. Destroy Infrastructure
terraform destroy

- Type **"yes"** to confirm.