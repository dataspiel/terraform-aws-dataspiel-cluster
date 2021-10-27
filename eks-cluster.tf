module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = var.k8s_version
  subnets         = module.vpc.private_subnets
  enable_irsa     = true

  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = var.k8s_worker_group_instance_type
      asg_desired_capacity = 2
      asg_min_size         = 1
      asg_max_size         = var.k8s_worker_group_asg_max_size
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
          "propagate_at_launch" = "false"
          "value"               = "true"
        }
      ]
  }]

  # TODO: check whether we want to use node_group instead??
  # TODO: for spot instances => https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/spot-instances.md
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      var.vpc_cidr
    ]
  }
}

# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes

# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

# below is for creating a role with the necessary permissions for autoscaling

data "aws_iam_policy_document" "oidc_assume_autoscaler" {
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
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
  }
}

data "aws_iam_policy_document" "autoscaling_access_autoscaler" {
  statement {
    sid    = "AutoscalingChange"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]
    # TODO: limit scope?
    resources = ["*"]
  }
}

resource "aws_iam_policy" "autoscaling_access_autoscaler" {
  name        = "eks-${module.eks.cluster_id}-autoscaler-autoscaling-access"
  description = "EKS - Autoscaling access for autoscaler service ($var.cluster_name)"
  path        = "/"
  policy      = data.aws_iam_policy_document.autoscaling_access_autoscaler.json
}

resource "aws_iam_role" "autoscaler" {
  name               = "eks-${module.eks.cluster_id}-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_autoscaler.json
  path               = "/"
}

resource "aws_iam_role_policy_attachment" "autoscaling_access_autoscaler" {
  role       = aws_iam_role.autoscaler.name
  policy_arn = aws_iam_policy.autoscaling_access_autoscaler.arn
}
