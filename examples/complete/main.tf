module "dataspiel" {
  source = "../../"

  project_name = var.project_name
  domain_name  = var.domain_name
  region       = var.region

  context = module.this.context
}
