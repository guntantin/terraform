# Store the terraform state file in s3 and lock with dunamodb
terraform {
  backend "s3" {
    bucket         = "terraform-guntant"
    key            = "terraform-guntant/rentzone/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
  }
}