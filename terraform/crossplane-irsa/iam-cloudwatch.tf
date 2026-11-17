resource "aws_iam_policy" "crossplane_cloudwatch" {
  provider    = aws.target
  name        = "${var.environment}-apps-crossplane-cloudwatch"
  description = "Allow Crossplane to manage CloudWatch MetricAlarms with env tag guardrails"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "CWDescribe",
        Effect = "Allow",
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListTagsForResource"
        ],
        Resource = "*"
      },
      {
        Sid    = "CWPutDeleteAlarm",
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms"
        ],
        Resource = "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:*"
      },
      {
        Sid    = "CWTagUntagAlarm",
        Effect = "Allow",
        Action = [
          "cloudwatch:TagResource",
          "cloudwatch:UntagResource"
        ],
        Resource = "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:*",
        Condition = {
          "StringEquals" : { "aws:RequestTag/Environment" : var.environment },
          "ForAllValues:StringEquals" : { "aws:TagKeys" : ["Environment", "Application"] }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crossplane_provider_aws_cloudwatch" {
  provider   = aws.target
  role       = aws_iam_role.crossplane_provider_aws.name
  policy_arn = aws_iam_policy.crossplane_cloudwatch.arn
}
