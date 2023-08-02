locals {
  project_type    = "service"
  project_name    = "policy-bot"
  project_slug    = "policy-bot"
  environment     = "prod"
  resource_prefix = "${local.project_name}-${local.environment}"
}
