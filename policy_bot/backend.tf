terraform {
  backend "s3" {
    bucket  = "somecompany-terraform-state"
    key     = "atlantis/service/policy-bot/terraform.tfstate"
    region  = "us-east-1"
    encrypt = "true"
  }
}
