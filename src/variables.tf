variable "region" {
  type        = string
  description = "AWS Region"
}

variable "license_key_ssm_parameter_name" {
  type        = string
  description = "Name of the SSM parameter (SecureString) holding the RunsOn license key. Used when `license_key` is null."
  default     = "/runs-on/license-key"
}

variable "ecr_iam_policy_enabled" {
  type        = bool
  description = "Attach a policy to the runner instance role that allows pushing, pulling, retagging and deleting images in any ECR repository in the account. Every job on every runner gets it, so prefer per-workflow OIDC roles."
  default     = false
}

variable "runs_on_environment" {
  description = "Environment name used for resource tagging and RunsOn job filtering. RunsOn will only process jobs with an 'env' label matching this value. See https://runs-on.com/docs/control-plane/environments/ for details."
  type        = string
  default     = "production"
}

variable "cost_allocation_tag" {
  description = "Name of the tag key used for cost allocation and tracking"
  type        = string
  default     = "stack"
}

variable "github_organization" {
  description = "GitHub organization or username for RunsOn integration"
  type        = string
}

variable "github_enterprise_url" {
  description = "GitHub Enterprise web URL (https) for GHE.com data residency or GitHub Enterprise Server (optional, leave empty for github.com)"
  type        = string
  default     = ""
}

variable "license_key" {
  description = "RunsOn license key obtained from runs-on.com. Prefer `license_key_ssm_parameter_name` to keep the key out of stack configuration."
  type        = string
  sensitive   = true
  default     = null
}

variable "vpc_id" {
  description = "VPC ID where RunsOn infrastructure will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for runner instances. Required unless private_mode is \"only\"."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for runner instances (required if private_mode is not 'false')"
  type        = list(string)
  default     = []
}

variable "private_mode" {
  description = "Private networking mode: 'false' (disabled), 'true' (opt-in with label), 'always' (default with opt-out), 'only' (forced, no public option)"
  type        = string
  default     = "false"
}

variable "private_mode_delay" {
  description = "Delay before starting the worker service in private mode, to allow NAT gateways to become ready. Set to \"60s\" or higher for fresh NAT gateway deployments."
  type        = string
  default     = "0s"
}

variable "security_group_ids" {
  description = "Security group IDs for runner instances and the worker service. If empty list provided, security groups will be created automatically."
  type        = list(string)
  default     = []
}

variable "ssh_allowed" {
  description = "Allow SSH access to runner instances"
  type        = bool
  default     = false
}

variable "ssm_allowed" {
  description = "Enable SSM access for runner instances. When true, this attaches AmazonSSMManagedEC2InstanceDefaultPolicy to the runner instance role."
  type        = bool
  default     = true
}

variable "ssh_cidr_range" {
  description = "CIDR range allowed for SSH access to runner instances (only applies if ssh_allowed is true)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "cache_expiration_days" {
  description = "Number of days to retain cache artifacts in S3 before expiration"
  type        = number
  default     = 10
}

variable "cache_bucket_namespace" {
  description = "S3 namespace for the cache bucket. Use account-regional when an organization SCP requires account-regional S3 bucket names."
  type        = string
  default     = "global"
}

variable "cache_bucket_versioning_enabled" {
  description = "Enable S3 object versioning for the cache bucket."
  type        = bool
  default     = false
}

variable "locks_table_point_in_time_recovery_enabled" {
  description = "Enable DynamoDB point-in-time recovery on the locks table. Its rows are transient and expire through TTL, so this only helps satisfy policies that require PITR on every table, at extra storage cost."
  type        = bool
  default     = false
}

variable "force_destroy_buckets" {
  description = "Allow S3 buckets to be destroyed even when not empty. Set to false for production environments to prevent accidental data loss."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs. Runner instance logs use this value as is; control-plane and Lambda logs keep at least 14 days."
  type        = number
  default     = 7
}

variable "permission_boundary_arn" {
  description = "IAM permissions boundary ARN to attach to all IAM roles (optional)"
  type        = string
  default     = ""
}

variable "ipv6_enabled" {
  description = "Enable IPv6 support for runner instances"
  type        = bool
  default     = false
}

variable "ebs_encryption_key_id" {
  description = "KMS key ID for explicit EBS volume encryption. Leave empty to omit explicit EBS encryption fields, use alias/aws/ebs for the AWS-managed EBS key, or provide a customer-managed key ID, alias, or ARN. Prefer a full ARN for customer-managed keys, especially cross-account keys. Customer-managed keys must also trust the generated RunsOn worker task role in their key policy."
  type        = string
  default     = ""
}

variable "messaging_kms_key_arn" {
  description = "Customer-managed KMS key ARN used to encrypt the control plane SQS queues and the SNS alerts topic. Leave empty to keep SQS-managed SSE on queues and no SSE on the topic (SNS default disk encryption only). The key policy must allow events.amazonaws.com (and budgets.amazonaws.com when app_budget_daily_usd > 0) kms:GenerateDataKey and kms:Decrypt; the module grants RunsOn roles access through IAM."
  type        = string
  default     = ""
}

variable "app_image" {
  description = "Container image for the RunsOn worker service. Leave null to use the image pinned by the RunsOn module release."
  type        = string
  default     = null
}

variable "app_tag" {
  description = "Application version tag for the RunsOn service. Leave null to use the tag pinned by the RunsOn module release."
  type        = string
  default     = null
}

variable "maintenance_mode" {
  description = "Enable maintenance mode: scales the worker service to zero, so jobs are not picked up"
  type        = bool
  default     = false
}

variable "app_size" {
  description = "Preset for the worker service, default EC2 launch concurrency, and default registration concurrency. Allowed values: small, medium, high, xhigh."
  type        = string
  default     = "small"
}

variable "container_insights_enabled" {
  description = "Enable ECS Container Insights on the control-plane cluster. Disabled by default: Container Insights publishes custom CloudWatch metrics billed per metric, a fixed cost the RunsOn dashboards do not need."
  type        = bool
  default     = false
}

variable "app_capacity_provider" {
  description = "Fargate capacity provider for the RunsOn worker service. Use fargate_spot to lower idle cost for small installs; interrupted in-flight queue messages retry after the SQS visibility timeout."
  type        = string
  default     = "fargate"
}

variable "app_force_new_deployment" {
  description = "Force a new ECS deployment of the RunsOn control-plane service. Set to true for one apply when migrating existing installs across the v3.0.6 ECS capacity provider change or when changing app_capacity_provider."
  type        = bool
  default     = false
}

variable "app_ecr_repository_url" {
  description = "Private ECR repository URL for RunsOn image (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:tag). When specified, the worker service will pull from this private ECR instead of public ECR."
  type        = string
  default     = ""
}

variable "app_custom_policy_arns" {
  description = "Optional managed IAM policy ARNs to attach to the RunsOn service role."
  type        = list(string)
  default     = []
}

variable "github_app_id" {
  description = "GitHub App ID. If provided along with other github_app_* variables, creates a Secrets Manager secret and skips the web-based GitHub App setup flow."
  type        = number
  default     = null
}

variable "github_app_private_key" {
  description = "GitHub App private key (PEM format)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_app_webhook_secret" {
  description = "GitHub App webhook secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_app_client_id" {
  description = "GitHub App client ID"
  type        = string
  default     = ""
}

variable "github_app_client_secret" {
  description = "GitHub App client secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_api_boost_apps" {
  description = "Additional same-org GitHub Apps used only for API boost capacity. These entries omit webhook secrets and are written under the shared GitHub apps secret."
  type = map(object({
    github_app_id            = number
    github_app_private_key   = string
    github_app_client_id     = string
    github_app_client_secret = string
    github_app_label         = optional(string, "")
  }))
  default   = {}
  sensitive = true
}

variable "github_api_strategy" {
  description = "Strategy for GitHub API calls (normal, conservative)"
  type        = string
  default     = "normal"
}

variable "runner_max_runtime" {
  description = "Maximum runtime in minutes for runners before forced termination"
  type        = number
  default     = 720
}

variable "runner_custom_policy_arns" {
  description = "Optional managed IAM policy ARNs to attach to the EC2 runner instance role. Use this when policy ARNs are computed by other resources."
  type        = list(string)
  default     = []
}

variable "runner_config_auto_extends_from" {
  description = "Repository whose .github/runs-on.yml every repository config extends, replacing any _extends it declares. Set to \".\" to use each repository's own _extends"
  type        = string
  default     = ".github-private"
}

variable "runner_custom_tags" {
  description = "Custom tags to apply to runner instances (comma-separated list)"
  type        = list(string)
  default     = []
}

variable "enable_cost_reports" {
  description = "Cost report email cadence: no, daily, weekly, or monthly. Legacy true/false values must be replaced with daily/no when upgrading."
  type        = string
  default     = "daily"
}

variable "spot_circuit_breaker" {
  description = "Spot instance circuit breaker, counted per instance family (e.g., '2/15/30' = 2 interruptions of one family in 15min stop spot launches of that family for 30min; jobs whose families are all paused launch on-demand). 'false' disables it"
  type        = string
  default     = "2/15/30"
}

variable "enable_warm_pools" {
  description = "Whether this stack keeps warm pool instances. When false, jobs with a pool= label still run on this stack, on a newly launched instance."
  type        = bool
  default     = true
}

variable "app_budget_daily_usd" {
  description = "Daily AWS cost budget in USD for this stack, filtered by the configured cost allocation tag. Set to 0 to disable the budget. For AWS Organizations member accounts, activate the cost allocation tag in the management account's Billing settings."
  type        = number
  default     = 10
}

variable "enable_default_dashboard" {
  description = "Create the default RunsOn CloudWatch dashboard. Set to false when managing a custom dashboard separately."
  type        = bool
  default     = true
}

variable "integration_step_security_api_key" {
  description = "API key for StepSecurity integration (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "otel_exporter_endpoint" {
  description = "OpenTelemetry exporter endpoint for observability (optional)"
  type        = string
  default     = ""
}

variable "otel_exporter_headers" {
  description = "OpenTelemetry exporter headers as comma-separated key=value pairs, as in OTEL_EXPORTER_OTLP_HEADERS. Values may be percent-encoded: authorization=Bearer%20KEY and authorization=Bearer KEY are equivalent (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "otel_exporter_temporality" {
  description = "OTLP metrics temporality: cumulative (default, for Prometheus-compatible backends) or delta (recommended for SigNoz, required by Datadog). Delta applies to counters and histograms; up-down counters stay cumulative."
  type        = string
  default     = "cumulative"
}

variable "otel_resource_attributes" {
  description = "Extra OTLP resource attributes as comma-separated key=value pairs, set as OTEL_RESOURCE_ATTRIBUTES. They override RunsOn defaults such as deployment.environment, except service.name. (optional)"
  type        = string
  default     = ""
}

variable "otel_logs_enabled" {
  description = "Enable OpenTelemetry log export"
  type        = bool
  default     = true
}

variable "otel_traces_enabled" {
  description = "Enable OpenTelemetry trace export"
  type        = bool
  default     = true
}

variable "logger_level" {
  description = "Logging level for the RunsOn service and the runner agent (debug, info, warn, error)"
  type        = string
  default     = "info"
}

variable "extra_env_vars" {
  description = "Additional environment variables to set on the worker service"
  type        = map(string)
  default     = {}
}

variable "email" {
  description = "Email address for alerts and notifications (requires confirmation)"
  type        = string
}

variable "alert_slack_webhook_url" {
  description = "Slack webhook URL for alert notifications (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mandatory_extras" {
  description = "Runner extras (e.g. s3-cache, otel) that are always enabled for every runner, regardless of label or repo config overrides."
  type        = list(string)
  default     = []
}

variable "enable_efs" {
  description = "Enable EFS file system for shared storage across runners"
  type        = bool
  default     = false
}

variable "enable_ecr" {
  description = "Enable ECR repository for ephemeral Docker image storage"
  type        = bool
  default     = false
}

variable "ecr_pull_through_cache_rules" {
  description = "Existing ECR pull-through cache rules to reference for runner image pulls. Create or import the regional rules outside the RunsOn module."
  type = map(object({
    ecr_repository_prefix      = string
    upstream_registry_url      = string
    upstream_repository_prefix = optional(string)
  }))
  default = {}
}

variable "enable_bedrock" {
  description = "Enable Amazon Bedrock access for EC2 runner instances."
  type        = bool
  default     = false
}

variable "prevent_destroy_optional_resources" {
  description = "Prevent destruction of durable optional resources such as EFS. ECR contains ephemeral runner images and is force-deleted by default."
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Enable AWS WAF for the public ingress"
  type        = bool
  default     = false
}

variable "enable_admin_routes" {
  description = "Enable the admin Lambda routes (`/`, `/setup`, `/setup/{proxy+}`, `/readyz`) on the public ingress"
  type        = bool
  default     = true
}

variable "public_ingress_web_acl_arn" {
  description = "Optional user-managed AWS WAFv2 Web ACL ARN to associate with the public ingress. When set, RunsOn will not manage webhook IP synchronization."
  type        = string
  default     = ""
}

variable "enable_cache_isolation" {
  description = "Enable brokered, per-repository/per-branch credentials for Magic Cache data under scoped-cache/*. Direct S3 cache integrations keep instance-profile access to the stack-shared cache/* namespace and are not repository-isolated. Opt-in"
  type        = bool
  default     = false
}

variable "enable_stickydisk_isolation" {
  description = "Remove the legacy EBS volume/snapshot permissions from the runner instance role, so all sticky-disk EBS operations happen exclusively on the control plane. Breaks the legacy v1 runs-on/snapshot action. Opt-in"
  type        = bool
  default     = false
}
