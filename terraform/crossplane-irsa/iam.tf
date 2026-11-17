resource "aws_iam_role" "crossplane_provider_aws" {
  provider    = aws.target
  name        = "${var.environment}-apps-crossplane-aws"
  description = "IRSA role for Crossplane provider-aws"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.apps_eks_openid.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(data.aws_iam_openid_connect_provider.apps_eks_openid.url, "https://", "")}:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          "${replace(data.aws_iam_openid_connect_provider.apps_eks_openid.url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:crossplane-provider-aws-*"
        }
      }
    }]
  })
}

# S3 (FullAccess)
resource "aws_iam_role_policy_attachment" "crossplane_provider_aws_s3" {
  provider   = aws.target
  role       = aws_iam_role.crossplane_provider_aws.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


