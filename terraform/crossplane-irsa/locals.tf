locals {
  kubernetesClusterName = coalesce(var.kubernetes_cluster_name, "${var.environment}-apps")
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}


