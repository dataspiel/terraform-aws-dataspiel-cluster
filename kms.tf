
resource "aws_kms_key" "kms_key" {
  description             = "EKS - kms key (${module.eks.cluster_id})"
  policy                  = data.aws_iam_policy_document.kms_access_new.json
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "kms_key" {
  name          = "alias/eks-${module.eks.cluster_id}-kms"
  target_key_id = aws_kms_key.kms_key.key_id
}

data "aws_iam_policy_document" "kms_access_new" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }

    actions = [
      "kms:*",
    ]
    # TODO: restrict to only the key generated above
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "Allow use of the key"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.kms.arn]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    # TODO: restrict to only the key generated above
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "oidc_assume" {
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
      values   = ["system:serviceaccount:flux-system:kustomize-controller"]
    }
  }
}

resource "aws_iam_role" "kms" {
  name               = "eks-${module.eks.cluster_id}-kms"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume.json
  path               = "/"
}
