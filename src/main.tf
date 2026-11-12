locals {
  enabled = module.this.enabled

  license_key = var.license_key != null ? var.license_key : one(data.aws_ssm_parameter.license_key[*].value)

  runner_custom_policy_arns = concat(
    var.runner_custom_policy_arns,
    compact([module.iam_policy.policy_arn]),
  )
}

data "aws_ssm_parameter" "license_key" {
  count = local.enabled && var.license_key == null ? 1 : 0

  name            = var.license_key_ssm_parameter_name
  with_decryption = true
}

module "iam_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.2"

  context = module.this.context
  enabled = local.enabled && var.ecr_iam_policy_enabled

  iam_policy_enabled = true
  iam_policy = [
    {
      version   = "2012-10-17"
      policy_id = "example"
      statements = [
        {
          sid    = "AllowECRActions"
          effect = "Allow"
          actions = [
            "ecr:UploadLayerPart",
            "ecr:UntagResource",
            "ecr:TagResource",
            "ecr:StartLifecyclePolicyPreview",
            "ecr:StartImageScan",
            "ecr:PutLifecyclePolicy",
            "ecr:PutImageTagMutability",
            "ecr:PutImageScanningConfiguration",
            "ecr:PutImage",
            "ecr:ListImages",
            "ecr:InitiateLayerUpload",
            "ecr:GetRepositoryPolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:GetLifecyclePolicy",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetAuthorizationToken",
            "ecr:DescribeRepositories",
            "ecr:DescribeImages",
            "ecr:DescribeImageScanFindings",
            "ecr:DeleteLifecyclePolicy",
            "ecr:CompleteLayerUpload",
            "ecr:BatchGetImage",
            "ecr:BatchDeleteImage",
            "ecr:BatchCheckLayerAvailability",
          ]
          resources = ["*"]
        }
      ]
    }
  ]
}

module "runs_on" {
  count = local.enabled ? 1 : 0

  # RunsOn v3.6.0 plus two unreleased patches (no public IP on the default launch templates with private_mode "only";
  # runs-on/terraform-aws-runs-on#74). Back to runs-on/runs-on/aws//modules/flex once a RunsOn release ships both.
  source = "git::https://github.com/9spokes-oss/terraform-aws-runs-on.git//modules/flex?ref=d47976dfadfe7f837100f8802d08d398cb36d451"

  stack_name = module.this.id
  tags       = module.this.tags

  license_key               = local.license_key
  runner_custom_policy_arns = local.runner_custom_policy_arns

  environment                                = var.runs_on_environment
  cost_allocation_tag                        = var.cost_allocation_tag
  github_organization                        = var.github_organization
  github_enterprise_url                      = var.github_enterprise_url
  vpc_id                                     = var.vpc_id
  public_subnet_ids                          = var.public_subnet_ids
  private_subnet_ids                         = var.private_subnet_ids
  private_mode                               = var.private_mode
  private_mode_delay                         = var.private_mode_delay
  security_group_ids                         = var.security_group_ids
  ssh_allowed                                = var.ssh_allowed
  ssm_allowed                                = var.ssm_allowed
  ssh_cidr_range                             = var.ssh_cidr_range
  cache_expiration_days                      = var.cache_expiration_days
  cache_bucket_namespace                     = var.cache_bucket_namespace
  cache_bucket_versioning_enabled            = var.cache_bucket_versioning_enabled
  locks_table_point_in_time_recovery_enabled = var.locks_table_point_in_time_recovery_enabled
  force_destroy_buckets                      = var.force_destroy_buckets
  log_retention_days                         = var.log_retention_days
  permission_boundary_arn                    = var.permission_boundary_arn
  ipv6_enabled                               = var.ipv6_enabled
  ebs_encryption_key_id                      = var.ebs_encryption_key_id
  messaging_kms_key_arn                      = var.messaging_kms_key_arn
  app_image                                  = var.app_image
  app_tag                                    = var.app_tag
  maintenance_mode                           = var.maintenance_mode
  app_size                                   = var.app_size
  container_insights_enabled                 = var.container_insights_enabled
  app_capacity_provider                      = var.app_capacity_provider
  app_force_new_deployment                   = var.app_force_new_deployment
  app_ecr_repository_url                     = var.app_ecr_repository_url
  app_custom_policy_arns                     = var.app_custom_policy_arns
  github_app_id                              = var.github_app_id
  github_app_private_key                     = var.github_app_private_key
  github_app_webhook_secret                  = var.github_app_webhook_secret
  github_app_client_id                       = var.github_app_client_id
  github_app_client_secret                   = var.github_app_client_secret
  github_api_boost_apps                      = var.github_api_boost_apps
  github_api_strategy                        = var.github_api_strategy
  runner_max_runtime                         = var.runner_max_runtime
  runner_config_auto_extends_from            = var.runner_config_auto_extends_from
  runner_custom_tags                         = var.runner_custom_tags
  enable_cost_reports                        = var.enable_cost_reports
  spot_circuit_breaker                       = var.spot_circuit_breaker
  enable_warm_pools                          = var.enable_warm_pools
  app_budget_daily_usd                       = var.app_budget_daily_usd
  enable_default_dashboard                   = var.enable_default_dashboard
  integration_step_security_api_key          = var.integration_step_security_api_key
  otel_exporter_endpoint                     = var.otel_exporter_endpoint
  otel_exporter_headers                      = var.otel_exporter_headers
  otel_exporter_temporality                  = var.otel_exporter_temporality
  otel_resource_attributes                   = var.otel_resource_attributes
  otel_logs_enabled                          = var.otel_logs_enabled
  otel_traces_enabled                        = var.otel_traces_enabled
  logger_level                               = var.logger_level
  extra_env_vars                             = var.extra_env_vars
  email                                      = var.email
  alert_slack_webhook_url                    = var.alert_slack_webhook_url
  mandatory_extras                           = var.mandatory_extras
  enable_efs                                 = var.enable_efs
  enable_ecr                                 = var.enable_ecr
  ecr_pull_through_cache_rules               = var.ecr_pull_through_cache_rules
  enable_bedrock                             = var.enable_bedrock
  prevent_destroy_optional_resources         = var.prevent_destroy_optional_resources
  enable_waf                                 = var.enable_waf
  enable_admin_routes                        = var.enable_admin_routes
  public_ingress_web_acl_arn                 = var.public_ingress_web_acl_arn
  enable_cache_isolation                     = var.enable_cache_isolation
  enable_stickydisk_isolation                = var.enable_stickydisk_isolation
}
