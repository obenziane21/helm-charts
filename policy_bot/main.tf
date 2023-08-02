module "teams" {
  source = "../../data/teams"
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "policy-bot"
  }
}

resource "kubernetes_secret" "dockerhub" {
  metadata {
    name      = "dockerhub"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (data.vault_generic_secret.dockerhub.data["docker_server"]) = {
          "username" = data.vault_generic_secret.dockerhub.data["docker_username"]
          "password" = data.vault_generic_secret.dockerhub.data["docker_password"]
          "email"    = data.vault_generic_secret.dockerhub.data["docker_email"]
          "auth"     = base64encode("${data.vault_generic_secret.dockerhub.data["docker_username"]}:${data.vault_generic_secret.dockerhub.data["docker_password"]}")
        }
      }
    })
  }
}

data "vault_policy_document" "policy_bot" {
  rule {
    path         = "secrets/v2/data/${local.project_type}/${local.project_name}/*"
    capabilities = ["read"]
    description  = "Allow Reading Of Github Policy bot Secrets"
  }
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "pr-policy-bot"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.k8s.outputs.private_nlb.dns_name
    zone_id                = data.terraform_remote_state.k8s.outputs.private_nlb.zone_id
    evaluate_target_health = false
  }
}
