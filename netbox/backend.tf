terraform {
  backend "s3" {
    bucket  = "somecompany-terraform-state"
    key     = "atlantis/service/netbox/terraform.tfstate"
    region  = "us-east-1"
    encrypt = "true"
  }
}
