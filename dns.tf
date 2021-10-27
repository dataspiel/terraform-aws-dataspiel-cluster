resource "aws_route53_zone" "main" {
  name          = local.project_domain_name
  force_destroy = true
}


# external-dns access to route53

data "aws_iam_policy_document" "oidc_assume_external_dns" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.issuer_host_path}:sub"
      values   = ["system:serviceaccount:external-dns:external-dns"]
    }
  }
}

data "aws_iam_policy_document" "route53_access_external_dns" {
  statement {
    sid    = "Route53UpdateZones"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    # TODO: only our hosted zone!
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    sid    = "Route53ListZones"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "route53_access_external_dns" {
  name        = "eks-${module.eks.cluster_id}-external-dns-route53-access"
  description = "EKS - Route53 access for external-dns service ($var.cluster_name)"
  path        = "/"
  policy      = data.aws_iam_policy_document.route53_access_external_dns.json
}

resource "aws_iam_role" "external_dns" {
  name               = "eks-${module.eks.cluster_id}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_external_dns.json
  path               = "/"
}

resource "aws_iam_role_policy_attachment" "route53_access_external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.route53_access_external_dns.arn
}


# cert-manager access to route53

data "aws_iam_policy_document" "oidc_assume_cert_manager" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.issuer_host_path}:sub"
      values   = ["system:serviceaccount:cert-manager:cert-manager"]
    }
  }
}

data "aws_iam_policy_document" "route53_access_cert_manager" {
  statement {
    sid    = "Route53Change"
    effect = "Allow"
    actions = [
      "route53:GetChange",
    ]
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    sid    = "Route53UpdateZones"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    # TODO: only use the hosted zone we used
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    sid    = "Route53ListZones"
    effect = "Allow"
    actions = [
      "route53:ListHostedZonesByName",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "route53_access_cert_manager" {
  name        = "eks-${module.eks.cluster_id}-cert-manager-route53-access"
  description = "EKS - Route53 access for cert-manager service ($var.cluster_name)"
  path        = "/"
  policy      = data.aws_iam_policy_document.route53_access_cert_manager.json
}

resource "aws_iam_role" "cert_manager" {
  name               = "eks-${module.eks.cluster_id}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_cert_manager.json
  path               = "/"
}

resource "aws_iam_role_policy_attachment" "route53_access_cert_manager" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.route53_access_cert_manager.arn
}
