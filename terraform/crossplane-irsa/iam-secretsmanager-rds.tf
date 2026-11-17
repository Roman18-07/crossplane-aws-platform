resource "aws_iam_policy" "crossplane_secretsmanager_rds" {
  provider    = aws.target
  name        = "${var.environment}-apps-crossplane-aws-secretsmanager-rds"
  description = "Allow Crossplane to create and manage RDS master user secret"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      {
        Sid    = "CreateSecretAndGetRandomPassword",
        Effect = "Allow",
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:GetRandomPassword"
        ],
        Resource = "*"
      },
      {
        Sid    = "ManageCreatedSecrets",
        Effect = "Allow",
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:TagResource",
          "secretsmanager:PutSecretValue"
        ],

        Resource = "arn:aws:secretsmanager:${var.aws_region}:${local.account_id}:secret:${var.rds_managed_secret_name_prefix}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_crossplane_secretsmanager_rds" {
  provider   = aws.target
  role       = aws_iam_role.crossplane_provider_aws.name
  policy_arn = aws_iam_policy.crossplane_secretsmanager_rds.arn
}
