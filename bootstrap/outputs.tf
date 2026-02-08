output "bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = module.s3_backend.bucket_id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

