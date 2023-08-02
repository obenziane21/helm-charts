locals {
  project_type    = "service"
  project_name    = "netbox"
  project_slug    = "netbox"
  environment     = "prod"
  resource_prefix = "${local.project_name}-${local.environment}"
}
