📦 Terraform AWS Infrastructure — lesson-5
🔍 Project Overview

This project demonstrates the use of the Infrastructure as Code (IaC) approach with Terraform to provision basic infrastructure in AWS.

The infrastructure includes:

centralized Terraform state storage in S3 with locking via DynamoDB

network infrastructure (VPC) with public and private subnets

ECR repository for storing Docker images

This project was created as part of a Terraform homework assignment.

📁 Project Structure
lesson-5/
│
├── main.tf            # Root module – connects all modules
├── backend.tf         # Terraform backend configuration
├── outputs.tf         # Global outputs
├── README.md
│
├── modules/
│   ├── s3-backend/    # S3 bucket + DynamoDB for Terraform state
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/           # VPC, subnets, IGW, NAT, routes
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── ecr/           # ECR repository
│       ├── ecr.tf
│       ├── variables.tf
│       └── outputs.tf

⚙️ Prerequisites

Installed Terraform

Installed and configured AWS CLI

AWS account and IAM user with permissions for:

S3

DynamoDB

EC2 / VPC

ECR

Verify access:

aws sts get-caller-identity

🚀 How to Run
1. Initialize Terraform
   terraform init

2. Validate configuration
   terraform validate

3. Review execution plan
   terraform plan

4. Create infrastructure
   terraform apply

5. Destroy infrastructure (after review)
   terraform destroy

🧩 Modules Description
🔹 s3-backend

Responsible for:

creating S3 bucket for Terraform state

enabling versioning

server-side encryption

DynamoDB table for state locking

🔹 vpc

Creates:

VPC with custom CIDR block

3 public and 3 private subnets

Internet Gateway

NAT Gateway

route tables and associations

🔹 ecr

Creates:

ECR repository

automatic image scanning on push

📤 Outputs

After terraform apply, Terraform prints:

S3 bucket name for Terraform state

DynamoDB table name

VPC ID

public and private subnet IDs

ECR repository URL

⚠️ Cost Notice

This project creates a NAT Gateway, which is a paid AWS resource.

👉 After verification, make sure to run:

terraform destroy


and confirm in AWS Console that all resources are deleted.
