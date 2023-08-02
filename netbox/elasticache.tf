data "aws_iam_policy_document" "elasticache" {
  policy_id = "${local.resource_prefix}-elasticache"

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        format(
          "arn:%s:iam::%s:root",
          data.aws_partition.current.id,
          data.aws_caller_identity.current.account_id
        )
      ]
    }
    actions = [
      "kms:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowElasticacheService"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.current.account_id
      ]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "elasticache.${data.aws_region.current.name}.amazonaws.com",
        "dax.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
  }
}

resource "aws_kms_key" "elasticache" {
  description             = "${local.resource_prefix}-elasticache"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.elasticache.json
  enable_key_rotation     = true
}

resource "aws_kms_alias" "elasticache" {
  name          = "alias/${local.resource_prefix}-elasticache"
  target_key_id = aws_kms_key.elasticache.key_id
}

resource "aws_elasticache_subnet_group" "this" {
  name       = local.resource_prefix
  subnet_ids = data.aws_subnets.this.ids
}

resource "aws_security_group" "elasticache" {
  name        = "${local.resource_prefix}-elasticache"
  description = "Allow access to Elasticache"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_elasticache_parameter_group" "this" {
  name   = local.resource_prefix
  family = "redis6.x"

  parameter {
    name  = "cluster-enabled"
    value = "no"
  }
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = local.resource_prefix
  description                = local.resource_prefix
  at_rest_encryption_enabled = true
  auth_token                 = data.vault_generic_secret.elasticache.data["token"]
  automatic_failover_enabled = true
  engine                     = "redis"
  engine_version             = "6.x"
  kms_key_id                 = aws_kms_key.elasticache.arn
  multi_az_enabled           = true
  node_type                  = "cache.t4g.medium"
  port                       = 6379
  parameter_group_name       = aws_elasticache_parameter_group.this.name
  security_group_ids         = [aws_security_group.elasticache.id]
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  snapshot_retention_limit   = 7
  transit_encryption_enabled = true

  num_cache_clusters = 2

}

resource "aws_security_group_rule" "eks_nodes_egress_elasticache" {
  description              = "Allow EKS nodes To Egress To Elasticache"
  type                     = "egress"
  from_port                = aws_elasticache_replication_group.this.port
  to_port                  = aws_elasticache_replication_group.this.port
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.k8s.outputs.workloads_secgroup_id
  source_security_group_id = aws_security_group.elasticache.id
}

resource "aws_security_group_rule" "elasticache_ingress_eks_nodes" {
  description              = "Allow EKS Nodes To Ingress To Elasticache"
  type                     = "ingress"
  from_port                = aws_elasticache_replication_group.this.port
  to_port                  = aws_elasticache_replication_group.this.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elasticache.id
  source_security_group_id = data.terraform_remote_state.k8s.outputs.workloads_secgroup_id
}


resource "aws_security_group_rule" "elasticache_ingress_vpn" {
  description              = "Allow VPN To Ingress To EC"
  type                     = "ingress"
  from_port                = aws_elasticache_replication_group.this.port
  to_port                  = aws_elasticache_replication_group.this.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elasticache.id
  source_security_group_id = data.aws_security_group.vpn.id
}
