terraform {}
# use for second run
# terraform {
#   backend "s3" {
#     bucket         = "nellip-tfstate-lesson5-053414411835"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
