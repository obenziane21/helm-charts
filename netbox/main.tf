module "teams" {
  source = "../../data/teams"
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "netbox"
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

data "vault_policy_document" "netbox" {
  rule {
    path         = "secrets/v2/data/${local.project_type}/${local.project_name}/*"
    capabilities = ["read"]
    description  = "Allow Reading Of Netbox Secrets"
  }
}

resource "kubernetes_manifest" "gateway" {
  manifest = yamldecode(templatefile("${path.module}/templates/istio_gateway.tftpl", {
    namespace = kubernetes_namespace.this.metadata[0].name,
    host_name = "netbox.somecompany.tools",
  }))

  depends_on = [
    kubernetes_namespace.this
  ]
}

# Istio VirtualService
resource "kubernetes_manifest" "virtual_service" {
  manifest = yamldecode(templatefile("${path.module}/templates/istio_virtualservice.tftpl", {
    namespace = kubernetes_namespace.this.metadata[0].name,
    host_name = "netbox.somecompany.tools",
  }))

  depends_on = [
    kubernetes_namespace.this
  ]
}

# Certificate
resource "kubernetes_manifest" "certificate" {
  manifest = yamldecode(templatefile("${path.module}/templates/cert_manager_certificate.tftpl", {
    host_name = "netbox.somecompany.tools",
  }))
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "netbox"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.k8s.outputs.private_nlb.dns_name
    zone_id                = data.terraform_remote_state.k8s.outputs.private_nlb.zone_id
    evaluate_target_health = false
  }
}
