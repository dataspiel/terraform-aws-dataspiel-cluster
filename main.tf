provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Owner   = "dataspiel"
      Cluster = local.cluster_name
    }
  }
}

data "aws_caller_identity" "current" {
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  number  = false
}

locals {
  cluster_name        = "${var.project_name}-${random_string.suffix.result}"
  project_domain_name = "${var.project_name}.${var.domain_name}"
  s3_prefix_full      = local.cluster_name
  issuer_host_path    = trim(module.eks.cluster_oidc_issuer_url, "https://")
  provider_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.issuer_host_path}"
}
