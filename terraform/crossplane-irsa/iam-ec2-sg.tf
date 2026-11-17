resource "aws_iam_policy" "crossplane_ec2_sg" {
  provider    = aws.target
  name        = "${var.environment}-apps-crossplane-ec2-sg"
  description = "TEMP/DEBUG: allow SG create; tag+manage; delete guarded by Environment tag"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [

      {
        "Sid" : "EC2Describe",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeTags",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones"
        ],
        "Resource" : "*"
      },

      {
        "Sid" : "CreateSG",
        "Effect" : "Allow",
        "Action" : ["ec2:CreateSecurityGroup"],
        "Resource" : "*"
      },

      {
        "Sid" : "TagNewSG",
        "Effect" : "Allow",
        "Action" : ["ec2:CreateTags"],
        "Resource" : "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
        "Condition" : {
          "ForAllValues:StringLikeIfExists" : {
            "aws:TagKeys" : [
              "Environment",
              "Application",
              "ApplicationComponent",
              "BudgetOwnerTeamId",
              "kubernetes_cluster",
              "kubernetes_namespace",
              "Name",
              "Repo",
              "Source",
              "crossplane-*"
            ]
          },
          "StringEquals" : {
            "aws:RequestTag/Environment" : "${var.environment}"
          }
        }
      },

      {
        "Sid" : "ManageRules",
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:ModifySecurityGroupRules",
          "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
          "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
          "ec2:DeleteTags"
        ],
        "Resource" : "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*"
      },

      {
        "Sid" : "DeleteEnvSGOnly",
        "Effect" : "Allow",
        "Action" : ["ec2:DeleteSecurityGroup"],
        "Resource" : "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
        "Condition" : {
          "StringEquals" : {
            "ec2:ResourceTag/Environment" : "${var.environment}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crossplane_provider_aws_ec2_sg" {
  provider   = aws.target
  role       = aws_iam_role.crossplane_provider_aws.name
  policy_arn = aws_iam_policy.crossplane_ec2_sg.arn
}
