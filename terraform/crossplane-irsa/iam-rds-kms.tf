resource "aws_iam_policy" "crossplane_rds_kms" {
  provider    = aws.target
  name        = "${var.environment}-apps-crossplane-rds-kms"
  description = "Allow Crossplane/RDS to create KMS grants on env-scoped keys"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "KMSGrantForRDS",
        Effect   = "Allow",
        Action   = ["kms:CreateGrant", "kms:DescribeKey"],
        Resource = "*",
        Condition = {
          Bool = { "kms:GrantIsForAWSResource" : true },
          StringEquals = {
            "kms:ViaService" : "rds.${var.aws_region}.amazonaws.com",
            "aws:ResourceTag/Environment" : var.environment
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crossplane_provider_aws_rds_kms" {
  provider   = aws.target
  role       = aws_iam_role.crossplane_provider_aws.name
  policy_arn = aws_iam_policy.crossplane_rds_kms.arn
}
