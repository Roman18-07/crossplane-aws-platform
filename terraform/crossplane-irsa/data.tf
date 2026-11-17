data "aws_eks_cluster" "apps" {
  provider = aws.target
  name     = local.kubernetesClusterName
}

data "aws_iam_openid_connect_provider" "apps_eks_openid" {
  provider = aws.target
  url      = data.aws_eks_cluster.apps.identity[0].oidc[0].issuer
}

data "aws_caller_identity" "current" {
  provider = aws.target
}



