resource "aws_iam_policy" "crossplane_rds_subnet_group" {
  provider    = aws.target
  name        = "${var.environment}-apps-crossplane-rds-subnet-group"
  description = "Allow Crossplane to manage RDS DB Subnet Groups (scoped by Environment tag)"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [

      {
        "Sid" : "DescribeSubnetGroups",
        "Effect" : "Allow",
        "Action" : ["rds:DescribeDBSubnetGroups"],
        "Resource" : "*"
      },

      {
        "Sid" : "CreateSubnetGroup",
        "Effect" : "Allow",
        "Action" : ["rds:CreateDBSubnetGroup"],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/Environment" : "${var.environment}"
          }
        }
      },

      {
        "Sid" : "TaggingSubnetGroup",
        "Effect" : "Allow",
        "Action" : [
          "rds:AddTagsToResource",
          "rds:ListTagsForResource",
          "rds:RemoveTagsFromResource"
        ],
        "Resource" : "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subgrp:*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/Environment" : "${var.environment}"
          }
        }
      },

      {
        "Sid" : "UpdateDeleteSubnetGroup",
        "Effect" : "Allow",
        "Action" : [
          "rds:ModifyDBSubnetGroup",
          "rds:DeleteDBSubnetGroup"
        ],
        "Resource" : "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subgrp:*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/Environment" : "${var.environment}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crossplane_provider_rds_subnet_group" {
  provider   = aws.target
  role       = aws_iam_role.crossplane_provider_aws.name
  policy_arn = aws_iam_policy.crossplane_rds_subnet_group.arn
}
