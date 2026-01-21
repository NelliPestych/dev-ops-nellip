variable "bucket_name" {
  type        = string
  description = "S3 bucket name for Terraform state"
}

variable "table_name" {
  type        = string
  description = "DynamoDB table name for state locking"
}
