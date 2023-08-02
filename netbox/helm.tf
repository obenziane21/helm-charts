# TODO: when the helm chart is forked we can actually use this
module "netbox_irsa" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git@github.com:somecompany/terraform-modules//vault-eks-irsa?ref=v0.0.8"

  cluster_name         = data.aws_eks_cluster.this.id
  namespace            = kubernetes_namespace.this.metadata[0].name
  service_account_name = local.resource_prefix
  policy_document      = data.vault_policy_document.netbox.hcl
  depends_on = [
    kubernetes_namespace.this,
  ]
}

# TODO: for now, we use the existing secret method
resource "kubernetes_secret" "this" {
  metadata {
    name      = local.resource_prefix
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  data = {
    db_password          = data.vault_generic_secret.rds.data["password"]
    napalm_password      = data.vault_generic_secret.napalm.data["password"]
    redis_tasks_password = data.vault_generic_secret.elasticache.data["token"]
    redis_cache_password = data.vault_generic_secret.elasticache.data["token"]
    secret_key           = data.vault_generic_secret.admin.data["secret_key"]
    superuser_password   = data.vault_generic_secret.admin.data["password"]
    superuser_api_token  = data.vault_generic_secret.admin.data["api_key"]
    email_password       = ""
  }
}


resource "helm_release" "this" {
  atomic     = true
  name       = "netbox"
  repository = "https://charts.boo.tc"
  chart      = "netbox"
  version    = "4.1.1"
  namespace  = kubernetes_namespace.this.metadata[0].name
  timeout    = 600
  values = [
    templatefile(
      "./templates/netbox.tftpl", {
        role_arn             = module.netbox_irsa.irsa.iam_role_arn
        service_account_name = local.resource_prefix
        secret_name          = kubernetes_secret.this.metadata[0].name

        rds_host     = aws_db_instance.this.address
        rds_port     = aws_db_instance.this.port
        rds_database = aws_db_instance.this.db_name
        rds_username = aws_db_instance.this.username

        redis_host = aws_elasticache_replication_group.this.primary_endpoint_address
        redis_port = aws_elasticache_replication_group.this.port

        storage_bucket = aws_s3_bucket.media.id

      }
  )]
  depends_on = [
    kubernetes_namespace.this,
    kubernetes_secret.this,
    # module.netbox_irsa,
    kubernetes_secret.dockerhub,
  ]
}
