resource "aws_iam_policy" "crossplane_kms_alias" {
  provider    = aws.target
  name        = "${var.environment}-apps-crossplane-kms-alias"
  description = "Allow Crossplane to manage KMS Aliases for ${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowAliasManagement",
        Effect = "Allow",
        Action = [
          "kms:CreateAlias",
          "kms:UpdateAlias",
          "kms:DeleteAlias",
          "kms:ListAliases"
        ],
        Resource = [
          "arn:aws:kms:${var.aws_region}:${local.account_id}:alias/${var.environment}-*"
        ]
      },
      {
        Sid    = "AllowDescribeTargetKey",
        Effect = "Allow",
        Action = [
          "kms:DescribeKey",
          "kms:ListResourceTags"
        ],
        Resource = "arn:aws:kms:${var.aws_region}:${local.account_id}:key/*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_crossplane_kms_alias" {
  provider   = aws.target
  role       = aws_iam_role.crossplane_provider_aws.name
  policy_arn = aws_iam_policy.crossplane_kms_alias.arn
}
