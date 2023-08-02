#tfsec:ignore:aws-vpc-no-public-egress-sgr - It's fine
resource "aws_security_group_rule" "egress_https_all" {
  description       = "HTTPS egress to the world"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.terraform_remote_state.k8s.outputs.workloads_secgroup_id
}
