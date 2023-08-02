module "policy_bot_irsa" {
  source = "git@github.com:somecompany/terraform-modules//vault-eks-irsa?ref=v0.0.8"

  cluster_name         = data.aws_eks_cluster.this.id
  namespace            = kubernetes_namespace.this.metadata[0].name
  service_account_name = local.resource_prefix
  policy_document      = data.vault_policy_document.policy_bot.hcl
  depends_on = [
    kubernetes_namespace.this,
  ]
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = local.resource_prefix
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  data = {
    app_id        = data.vault_generic_secret.policy_bot.data["APP_ID"]
    client_id     = data.vault_generic_secret.policy_bot.data["CLIENT_ID"]
    client_secret = data.vault_generic_secret.policy_bot.data["CLIENT_SECRET"]
    private_key   = data.vault_generic_secret.policy_bot.data["PRIVATE_KEY"]
  }
}

resource "helm_release" "this" {
  name                = "policy-bot"
  repository          = "https://somecompany.jfrog.io/artifactory/api/helm/incubator"
  chart               = "policy-bot"
  version             = "0.1.1"
  namespace           = kubernetes_namespace.this.metadata[0].name
  repository_username = "terraform"
  repository_password = data.vault_generic_secret.artifactory_terraform.data["token"]

  values = [
    templatefile(
      "./templates/policy_bot.tftpl", {
        secretName         = kubernetes_secret.this.metadata[0].name
        roleArn            = module.policy_bot_irsa.irsa.iam_role_arn
        serviceAccountName = local.resource_prefix
      }
    ),
  ]
  depends_on = [
    kubernetes_namespace.this,
    kubernetes_secret.this,
    kubernetes_secret.dockerhub,
    aws_route53_record.this,
  ]
}
