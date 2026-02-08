terraform {
  backend "s3" {
    bucket         = "devops-nellip-tfstate-dev"
    key            = "main/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-nellip-tflock-dev"
    encrypt        = true
  }
}
