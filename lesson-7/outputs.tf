output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "state_bucket_name" {
  value = module.s3_backend.bucket_name
}

output "dynamodb_table_name" {
  value = module.s3_backend.table_name
}
