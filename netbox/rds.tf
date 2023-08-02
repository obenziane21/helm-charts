resource "aws_db_subnet_group" "this" {
  name       = local.resource_prefix
  subnet_ids = data.aws_subnets.this.ids
}

resource "aws_security_group" "rds" {
  name        = "${local.resource_prefix}-rds"
  description = "Allow access to PostgreSQL"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_db_parameter_group" "this" {
  name   = local.resource_prefix
  family = "postgres13"
}

#tfsec:ignore:aws-rds-enable-performance-insights- It's not enabled?
resource "aws_db_instance" "this" {
  allocated_storage       = 20
  max_allocated_storage   = 100
  engine                  = "postgres"
  engine_version          = "13.7"
  instance_class          = "db.t4g.medium"
  identifier              = local.resource_prefix
  port                    = 5432
  username                = "postgres"
  password                = data.vault_generic_secret.rds.data["password"]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  multi_az                = false
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = true
  storage_encrypted       = true
  backup_retention_period = 7
  parameter_group_name    = aws_db_parameter_group.this.name
  tags = {
    Name = local.resource_prefix
  }
}

resource "aws_security_group_rule" "eks_nodes_egress_rds" {
  description              = "Allow EKS Nodes To Egress To RDS"
  type                     = "egress"
  from_port                = aws_db_instance.this.port
  to_port                  = aws_db_instance.this.port
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.k8s.outputs.workloads_secgroup_id
  source_security_group_id = aws_security_group.rds.id
}

resource "aws_security_group_rule" "rds_ingress_eks_nodes" {
  description              = "Allow EKS Nodes To Ingress To RDS"
  type                     = "ingress"
  from_port                = aws_db_instance.this.port
  to_port                  = aws_db_instance.this.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = data.terraform_remote_state.k8s.outputs.workloads_secgroup_id
}

resource "aws_security_group_rule" "rds_ingress_vpn" {
  description              = "Allow VPN To Ingress To RDS"
  type                     = "ingress"
  from_port                = aws_db_instance.this.port
  to_port                  = aws_db_instance.this.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = data.aws_security_group.vpn.id
}
