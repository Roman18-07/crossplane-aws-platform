resource "aws_iam_policy" "crossplane_rds" {
  provider    = aws.target
  name        = "${var.environment}-apps-crossplane-rds"
  description = "Allow Crossplane to create/modify/delete RDS (DB + subnet groups) with Environment guard"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [

      {
        "Sid" : "RDSDescribe",
        "Effect" : "Allow",
        "Action" : [
          "rds:Describe*",
          "rds:ListTagsForResource"
        ],
        "Resource" : "*"
      },

      {
        "Sid" : "CreateDBSubnetGroup",
        "Effect" : "Allow",
        "Action" : "rds:CreateDBSubnetGroup",
        "Resource" : "*",
        "Condition" : {
          "ForAllValues:StringEqualsIfExists" : {
            "aws:RequestTag/Environment" : "${var.environment}"
          }
        }
      },

      {
        "Sid" : "ManageSubnetGroup",
        "Effect" : "Allow",
        "Action" : [
          "rds:ModifyDBSubnetGroup",
          "rds:DeleteDBSubnetGroup"
        ],
        "Resource" : "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subgrp:*",
        "Condition" : {
          "StringEquals" : {
            "rds:ResourceTag/Environment" : "${var.environment}"
          }
        }
      },

      {
        "Sid" : "CreateDBInstance",
        "Effect" : "Allow",
        "Action" : "rds:CreateDBInstance",
        "Resource" : "*",
        "Condition" : {
          "ForAllValues:StringEqualsIfExists" : {
            "aws:RequestTag/Environment" : "${var.environment}"
          }
        }
      },

      {
        "Sid" : "AddTagsAnyWithEnv",
        "Effect" : "Allow",
        "Action" : "rds:AddTagsToResource",
        "Resource" : "*",
        "Condition" : {
          "ForAllValues:StringEqualsIfExists" : {
            "aws:RequestTag/Environment" : "${var.environment}"
          }
        }
      },

      {
        "Sid" : "RemoveTagsEnvOnly",
        "Effect" : "Allow",
        "Action" : "rds:RemoveTagsFromResource",
        "Resource" : [
          "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:*",
          "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subgrp:*",
          "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot:*"
        ],
        "Condition" : {
          "StringEquals" : {
            "rds:ResourceTag/Environment" : "${var.environment}"
          }
        }
      },

      {
        "Sid" : "ManageDBInstanceEnvOnly",
        "Effect" : "Allow",
        "Action" : [
          "rds:ModifyDBInstance",
          "rds:DeleteDBInstance",
          "rds:RebootDBInstance",
          "rds:StartDBInstance",
          "rds:StopDBInstance"
        ],
        "Resource" : "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:*",
        "Condition" : {
          "StringEquals" : {
            "rds:ResourceTag/Environment" : "${var.environment}"
          }
        }
      },

      {
        "Sid" : "ManageSnapshotsEnvOnly",
        "Effect" : "Allow",
        "Action" : [
          "rds:CreateDBSnapshot",
          "rds:CopyDBSnapshot",
          "rds:DeleteDBSnapshot"
        ],
        "Resource" : "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot:*",
        "Condition" : {
          "StringEquals" : {
            "rds:ResourceTag/Environment" : "${var.environment}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crossplane_provider_aws_rds" {
  provider   = aws.target
  role       = aws_iam_role.crossplane_provider_aws.name
  policy_arn = aws_iam_policy.crossplane_rds.arn
}
