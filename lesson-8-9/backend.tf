terraform {}

# use for second run (after bucket + dynamodb created)
# terraform {
#   backend "s3" {
#     bucket         = "nellip-tfstate-lesson7-053414411835"
#     key            = "lesson-7/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
