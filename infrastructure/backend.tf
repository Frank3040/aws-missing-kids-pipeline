# Remote state backend — uncomment and fill in after creating the state bucket manually.
# This prevents state loss and enables team collaboration.
#
# terraform {
#   backend "s3" {
#     bucket         = "missing-kids-terraform-state"
#     key            = "pipeline/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "missing-kids-tf-locks"
#   }
# }
