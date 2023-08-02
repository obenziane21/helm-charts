terraform {
  required_version = "= 1.1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.39.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.3.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      project_type = local.project_type
      project_name = local.project_name
      project_slug = local.project_slug
      environment  = local.environment
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    # args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.this.id, "--profile", "avengers"]
    args = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.this.id]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.this.id]
      command     = "aws"
    }
  }
}

provider "vault" {
  address = "https://vault.somecompany.tools"

  auth_login {
    path   = "auth/aws/login"
    method = "aws"
    parameters = {
      role   = "atlantis" # this is the vault role
      type   = "iam"
      region = "us-east-1"
    }
  }
}
