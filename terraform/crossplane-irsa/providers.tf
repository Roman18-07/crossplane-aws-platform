provider "aws" {
  alias  = "target"
  region = var.aws_region

  assume_role {
    role_arn     = var.target_account_deploy_role
    session_name = "${var.environment}-crossplane-infra"
  }

  default_tags {
    tags = {
      Source               = "managed-by-terraform"
      Repo                 = "crossplane-aws-platform"
      Environment          = var.environment
      Application          = "crossplane"
      ApplicationComponent = "application-stack"
      BudgetOwnerTeamId    = "platform"


      kubernetes_cluster   = local.kubernetesClusterName
      kubernetes_namespace = "crossplane-system"
    }
  }
}

