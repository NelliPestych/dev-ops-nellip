# Lesson 7 — Helm + EKS + ECR (Terraform)

## Overview
This project provisions AWS infrastructure using Terraform and deploys a Django application to an EKS cluster using a Helm chart.
It includes:
- Remote Terraform state backend (S3 + DynamoDB locking)
- VPC with public and private subnets, IGW and NAT
- ECR repository for Docker images
- EKS cluster with a managed node group
- Helm chart: Deployment, Service (LoadBalancer), ConfigMap (env), HPA (2–6 replicas, CPU > 70%)

## Project structure
lesson-7/
main.tf
backend.tf
outputs.tf
modules/
s3-backend/
vpc/
ecr/
eks/
charts/
django-app/
Chart.yaml
values.yaml
templates/
deployment.yaml
service.yaml
configmap.yaml
hpa.yaml

## Prerequisites
- Terraform
- AWS CLI configured (example: `--profile study`)
- kubectl
- helm
- Docker

## Terraform workflow

### First run (backend disabled)
Backend is disabled on the first run to create S3 bucket and DynamoDB table first.

bash
cd lesson-7
terraform init
terraform validate
terraform plan
terraform apply

### Enable remote backend (second run)

Uncomment the backend "s3" block in backend.tf and reinitialize:

terraform init -reconfigure
terraform plan
terraform apply

### Connect kubectl to EKS
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks --profile study
kubectl get nodes

### Build & Push Docker image to ECR

Get ECR URL from Terraform output:

terraform output ecr_repository_url


Login to ECR, build and push:

aws ecr get-login-password --region us-west-2 --profile study | docker login --username AWS --password-stdin <ECR_REPO_URL>

docker build -t django-app:latest .
docker tag django-app:latest <ECR_REPO_URL>:latest
docker push <ECR_REPO_URL>:latest

### Deploy with Helm

Update charts/django-app/values.yaml:

image.repository: "<ECR_REPO_URL>"

keep tag: "latest"

Install / upgrade:

helm install django-app ./charts/django-app -n default
# or
helm upgrade --install django-app ./charts/django-app -n default


Check resources:

kubectl get pods
kubectl get svc
kubectl get hpa

### Cleanup
cd lesson-7
terraform destroy

Note: Deleting everything also removes the S3 bucket and DynamoDB table used for the remote state.
