resource "aws_s3_bucket" "airflow" {
  acl           = "private"
  bucket        = join("-", [local.s3_prefix_full, "airflow"])
  force_destroy = true
}

data "aws_iam_policy_document" "oidc_assume_airflow" {
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
      values   = ["system:serviceaccount:airflow:airflow-worker", "system:serviceaccount:airflow:airflow-webserver"]
    }
  }
}

data "aws_iam_policy_document" "access_airflow" {
  statement {
    sid    = "S3Airflow"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    # TODO: limit to the specific bucket (might have to then create multiple statements)
    resources = ["*"]
  }
}

resource "aws_iam_policy" "access_airflow" {
  name        = "eks-${module.eks.cluster_id}-access-airflow"
  description = "EKS - access for airflow service ($var.cluster_name)"
  path        = "/"
  policy      = data.aws_iam_policy_document.access_airflow.json
}

resource "aws_iam_role" "airflow" {
  name               = "eks-${module.eks.cluster_id}-airflow"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_airflow.json
  path               = "/"
}

resource "aws_iam_role_policy_attachment" "access_airflow" {
  role       = aws_iam_role.airflow.name
  policy_arn = aws_iam_policy.access_airflow.arn
}
