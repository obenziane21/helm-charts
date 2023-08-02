data "aws_eks_cluster" "this" {
  name = "obelix-prod"
}

data "vault_generic_secret" "policy_bot" {
  path = "secrets/v2/${local.project_type}/${local.project_name}/${local.environment}/github"
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

data "vault_generic_secret" "artifactory_terraform" {
  path = "secrets/v2/service/atlantis/artifactory/terraform"
}
