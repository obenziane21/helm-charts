data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_eks_cluster" "this" {
  name = "obelix-prod"
}

data "aws_vpc" "this" {
  tags = {
    Name = "Prod NAT VPC"
  }
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Name"
    values = ["PROD_PRIVATE_*"]
  }
}

data "aws_security_group" "vpn" {
  filter {
    name   = "tag:Name"
    values = ["VPN-Pritunl"]
  }
}


data "vault_generic_secret" "rds" {
  path = "secrets/v2/${local.project_type}/${local.project_name}/${local.environment}/rds"
}

data "vault_generic_secret" "elasticache" {
  path = "secrets/v2/${local.project_type}/${local.project_name}/${local.environment}/elasticache"
}

data "vault_generic_secret" "napalm" {
  path = "secrets/v2/${local.project_type}/${local.project_name}/${local.environment}/napalm"
}

data "vault_generic_secret" "admin" {
  path = "secrets/v2/${local.project_type}/${local.project_name}/${local.environment}/admin"
}

data "vault_generic_secret" "dockerhub" {
  path = "secrets/v1/k8s-cluster-configs/global/dockerhub"
}

data "aws_route53_zone" "this" {
  name         = "somecompany.tools"
  private_zone = true
}

# Get Obelix Platform Remote State
data "terraform_remote_state" "k8s" {
  backend = "s3"

  config = {
    bucket  = "somecompany-terraform-state"
    key     = "atlantis/platform/eks/obelix/terraform.tfstate"
    region  = "us-east-1"
    encrypt = "true"
  }

}
