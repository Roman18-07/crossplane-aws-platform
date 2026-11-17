output "crossplane_provider_aws_role_arn" {
  value = aws_iam_role.crossplane_provider_aws.arn
}

output "crossplane_kms_policy_arn" {
  description = "IAM policy ARN allowing Crossplane to manage KMS keys/aliases"
  value       = aws_iam_policy.crossplane_kms.arn
}

output "crossplane_rds_kms_policy_arn" {
  description = "IAM policy ARN allowing KMS grants for RDS"
  value       = aws_iam_policy.crossplane_rds_kms.arn
}

