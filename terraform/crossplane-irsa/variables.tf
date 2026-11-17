variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "target_account_deploy_role" {
  type        = string
  description = "Role to assume"
}

variable "environment" {
  type        = string
  description = "staging|prod"
}

variable "namespace" {
  type = string
}

variable "application" {
  type        = string
  description = "staging|prod"
}

variable "kms_key_arn" {
  type        = string
  description = "Optional CMK ARN for RDS encryption; empty = aws/rds"
  default     = ""
}

variable "vpc_id" {
  type        = string
  description = "Target VPC ID for SG creation (e.g., vpc-0123456789abcdef0)"
}

variable "crossplane_provider_role_name" {
  type    = string
  default = null
}

variable "kubernetes_cluster_name" {
  type        = string
  description = "Existing EKS cluster name; null = \"<environment>-apps\""
  default     = null
}

variable "rds_managed_secret_name_prefix" {
  type        = string
  description = "Name prefix of RDS-managed master user secrets in Secrets Manager"
  default     = "rds!"
}
