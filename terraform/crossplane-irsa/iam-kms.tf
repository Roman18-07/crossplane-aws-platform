resource "aws_iam_policy" "crossplane_kms" {
  provider    = aws.target
  name        = "${var.environment}-apps-crossplane-kms"
  description = "Allow Crossplane to manage KMS keys/aliases with env tag guardrails"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      {
        "Sid" : "DescribeList",
        "Effect" : "Allow",
        "Action" : [
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:ListResourceTags"
        ],
        "Resource" : "*"
      },

      {
        "Sid" : "CreateKey",
        "Effect" : "Allow",
        "Action" : ["kms:CreateKey"],
        "Resource" : "*"
      },

      {
        "Sid" : "TagByRequestEnvRequired",
        "Effect" : "Allow",
        "Action" : ["kms:TagResource"],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : { "aws:RequestTag/Environment" : var.environment },
          "ForAllValues:StringEquals" : { "aws:TagKeys" : ["Environment", "Application"] }
        }
      },

      {
        "Sid" : "TagUntagEnvKeys",
        "Effect" : "Allow",
        "Action" : ["kms:TagResource", "kms:UntagResource"],
        "Resource" : "*",
        "Condition" : { "StringEquals" : { "aws:ResourceTag/Environment" : var.environment } }
      },

      {
        "Sid" : "ManageEnvKeys",
        "Effect" : "Allow",
        "Action" : [
          "kms:PutKeyPolicy",
          "kms:EnableKeyRotation",
          "kms:DisableKeyRotation",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:UpdateKeyDescription"
        ],
        "Resource" : "*",
        "Condition" : { "StringEquals" : { "aws:ResourceTag/Environment" : var.environment } }
      },

      {
        "Sid" : "AliasOpsByName",
        "Effect" : "Allow",
        "Action" : ["kms:CreateAlias", "kms:UpdateAlias", "kms:DeleteAlias"],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : { "kms:RequestAliasName" : "alias/${var.environment}-*" }
        }
      },

      {
        "Sid" : "CreateUpdateAliasOnEnvKeys",
        "Effect" : "Allow",
        "Action" : ["kms:CreateAlias", "kms:UpdateAlias"],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : { "aws:ResourceTag/Environment" : var.environment }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crossplane_provider_aws_kms" {
  provider   = aws.target
  role       = aws_iam_role.crossplane_provider_aws.name
  policy_arn = aws_iam_policy.crossplane_kms.arn
}
