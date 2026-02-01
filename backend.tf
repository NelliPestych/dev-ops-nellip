# Backend configuration
# Для первого запуска backend настроен как локальный (terraform {})
# После первого apply можно раскомментировать backend "s3" и выполнить миграцию state

terraform {
  # Для первого запуска - локальный backend
  # После создания S3 bucket и DynamoDB таблицы раскомментируйте:
  #
  # backend "s3" {
  #   bucket         = "nellip-tfstate-lesson-db-module-053414411835"
  #   key            = "terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  #   profile        = "study"
  # }
}

