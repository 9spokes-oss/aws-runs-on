---
tags:
  - component/runs-on
  - layer/github
  - provider/aws
---

# Component: `runs-on`

Component: `runs-on`

This component provisions [RunsOn](https://runs-on.com/) Flex, ephemeral self-hosted GitHub Actions runners on EC2,
with the official [RunsOn Terraform module](https://github.com/runs-on/terraform-aws-runs-on).
After deploying it, open the `getting_started` output URL to register the RunsOn GitHub App in your organization.

RunsOn runs in a VPC you manage (for example the `vpc` component). Runners in private subnets need NAT for
outbound access to GitHub.

Compatibility: Version 3 of this component deploys RunsOn v3. Earlier versions wrapped the RunsOn CloudFormation
template; see "Migrating from the CloudFormation-based component" below.

## Usage

**Stack Level**: Regional

Store the RunsOn license key as an SSM SecureString in the target account, so it never appears in stack
configuration:

```shell
aws ssm put-parameter --name /runs-on/license-key --type SecureString --value "<LICENSE_KEY>"
```

(`stacks/catalog/runs-on/defaults.yaml`)

```yaml
components:
  terraform:
    runs-on/defaults:
      metadata:
        component: runs-on
        type: abstract
      vars:
        enabled: true
        name: runs-on
        github_organization: acme
        email: developer@acme.com
        license_key_ssm_parameter_name: /runs-on/license-key
        # false: public subnets only; true: private subnets for jobs labelled private=true;
        # always: private unless a job opts out; only: private subnets only.
        private_mode: "only"
        public_subnet_ids: []
        ebs_encryption_key_id: alias/aws/ebs
        app_size: small
```

(`runs-on.yaml`)

```yaml
import:
  - orgs/acme/core/auto/_defaults
  - mixins/region/us-east-1
  - catalog/runs-on/defaults

components:
  terraform:
    runs-on:
      metadata:
        component: runs-on
        inherits:
          - runs-on/defaults
      vars:
        vpc_id: !terraform.state vpc vpc_id
        private_subnet_ids: !terraform.state vpc private_subnet_ids
```

After the first apply, print the setup instructions and follow the link to register the GitHub App:

```shell
atmos terraform output runs-on -s <stack> --skip-init -- -raw getting_started
```

The admin routes (`/`, `/setup`, `/setup/{proxy+}`, `/readyz`) have no sign-in. Once the GitHub App is registered,
turn them off in the stack and apply:

```yaml
      vars:
        enable_waf: true           # webhooks accept only GitHub's IPs, synced hourly
        enable_admin_routes: false
```

The deployed API Gateway stage keeps the removed routes until the deployment is replaced
([runs-on/terraform-aws-runs-on#76](https://github.com/runs-on/terraform-aws-runs-on/issues/76)), so replace it
once and check that `/setup` returns 403:

```shell
atmos terraform apply runs-on -s <stack> -- \
  -replace='module.runs_on[0].module.control_plane.aws_api_gateway_deployment.public_ingress'
```

Inputs mirror the RunsOn Flex module's, with two exceptions: `stack_name` and `tags` come from the Cloud Posse
label context (`module.this.id` and `module.this.tags`), and the module's `environment` input is
`runs_on_environment`, because `environment` is a context label.

### Migrating from the CloudFormation-based component (v2.x)

Version 3 is a breaking change. Terraform cannot adopt resources owned by a CloudFormation stack, so migrating
replaces the RunsOn installation. Atmos keys Terraform state by the component key, so the new install needs its own
key; reusing the old key would put both installations in one state, and the first apply would destroy the old one:

1. Add this version under a new component key (for example `runs-on-v3`) with a different `name`, so resource
   names don't collide, and apply it next to the existing one. Keep the old key on its v2.x `component.yaml` pin
   (vendor v3 into a separate component directory) until step 3.
2. Register its GitHub App, then move workflows to it.
3. Destroy the old CloudFormation-based component (`atmos terraform destroy <old key> -s <stack>`), then remove it
   from the stack.

| v2.x | v3 |
|------|----|
| `template_url` | removed; the RunsOn version comes from the module version |
| `networking_stack: embedded` | removed; pass `vpc_id` and subnets from a VPC you manage |
| `parameters.LicenseKey` | `license_key_ssm_parameter_name` (or `license_key`) |
| `parameters.GithubOrganization` | `github_organization` |
| `parameters.EmailAddress` | `email` |
| `parameters.Private` | `private_mode` |
| `parameters.SSHAllowed` | `ssh_allowed` |
| `parameters.EncryptEbs: true` | `ebs_encryption_key_id: alias/aws/ebs` |
| `parameters.Ec2LogRetentionInDays` | `log_retention_days` |
| `subnet_ids` | `public_subnet_ids` |
| `security_group_id` | `security_group_ids` |
| `security_group_rules` | removed; pass your own `security_group_ids` |
| `capabilities`, `on_failure`, `timeout_in_minutes`, `policy_body` | removed |
| outputs `vpc_id`, `vpc_cidr`, `*_subnet_ids`, `nat_*`, `private_route_table_ids` | removed; read them from the VPC component |

v2.x attached an account-wide ECR policy (push, delete, lifecycle) to every runner instance by default. It is now
opt-in: set `ecr_iam_policy_enabled: true` to keep it, or give workflows their own (for example OIDC) role.



<!-- markdownlint-disable -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.45.0, < 7.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.45.0, < 7.0.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_iam_policy"></a> [iam\_policy](#module\_iam\_policy) | cloudposse/iam-policy/aws | 2.0.2 |
| <a name="module_iam_roles"></a> [iam\_roles](#module\_iam\_roles) | cloudposse/label/null | 0.25.0 |
| <a name="module_runs_on"></a> [runs\_on](#module\_runs\_on) | git::https://github.com/9spokes-oss/terraform-aws-runs-on.git//modules/flex | d47976dfadfe7f837100f8802d08d398cb36d451 |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.account_verification](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.account_verification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ssm_parameter.license_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_map"></a> [account\_map](#input\_account\_map) | Map of account names (tenant-stage format) to account IDs. Used to verify we're targeting the correct AWS account. Optional attributes support component-specific functionality (e.g., audit\_account\_account\_name for cloudtrail, root\_account\_account\_name for aws-sso). | <pre>object({<br/>    full_account_map              = map(string)<br/>    audit_account_account_name    = optional(string, "")<br/>    root_account_account_name     = optional(string, "")<br/>    identity_account_account_name = optional(string, "")<br/>    aws_partition                 = optional(string, "aws")<br/>    iam_role_arn_templates        = optional(map(string), {})<br/>  })</pre> | <pre>{<br/>  "audit_account_account_name": "",<br/>  "aws_partition": "aws",<br/>  "full_account_map": {},<br/>  "iam_role_arn_templates": {},<br/>  "identity_account_account_name": "",<br/>  "root_account_account_name": ""<br/>}</pre> | no |
| <a name="input_account_map_enabled"></a> [account\_map\_enabled](#input\_account\_map\_enabled) | Enable the account map component | `bool` | `false` | no |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_alert_slack_webhook_url"></a> [alert\_slack\_webhook\_url](#input\_alert\_slack\_webhook\_url) | Slack webhook URL for alert notifications (optional) | `string` | `""` | no |
| <a name="input_app_budget_daily_usd"></a> [app\_budget\_daily\_usd](#input\_app\_budget\_daily\_usd) | Daily AWS cost budget in USD for this stack, filtered by the configured cost allocation tag. Set to 0 to disable the budget. For AWS Organizations member accounts, activate the cost allocation tag in the management account's Billing settings. | `number` | `10` | no |
| <a name="input_app_capacity_provider"></a> [app\_capacity\_provider](#input\_app\_capacity\_provider) | Fargate capacity provider for the RunsOn worker service. Use fargate\_spot to lower idle cost for small installs; interrupted in-flight queue messages retry after the SQS visibility timeout. | `string` | `"fargate"` | no |
| <a name="input_app_custom_policy_arns"></a> [app\_custom\_policy\_arns](#input\_app\_custom\_policy\_arns) | Optional managed IAM policy ARNs to attach to the RunsOn service role. | `list(string)` | `[]` | no |
| <a name="input_app_ecr_repository_url"></a> [app\_ecr\_repository\_url](#input\_app\_ecr\_repository\_url) | Private ECR repository URL for RunsOn image (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:tag). When specified, the worker service will pull from this private ECR instead of public ECR. | `string` | `""` | no |
| <a name="input_app_force_new_deployment"></a> [app\_force\_new\_deployment](#input\_app\_force\_new\_deployment) | Force a new ECS deployment of the RunsOn control-plane service. Set to true for one apply when migrating existing installs across the v3.0.6 ECS capacity provider change or when changing app\_capacity\_provider. | `bool` | `false` | no |
| <a name="input_app_image"></a> [app\_image](#input\_app\_image) | Container image for the RunsOn worker service. Leave null to use the image pinned by the RunsOn module release. | `string` | `null` | no |
| <a name="input_app_size"></a> [app\_size](#input\_app\_size) | Preset for the worker service, default EC2 launch concurrency, and default registration concurrency. Allowed values: small, medium, high, xhigh. | `string` | `"small"` | no |
| <a name="input_app_tag"></a> [app\_tag](#input\_app\_tag) | Application version tag for the RunsOn service. Leave null to use the tag pinned by the RunsOn module release. | `string` | `null` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_cache_bucket_namespace"></a> [cache\_bucket\_namespace](#input\_cache\_bucket\_namespace) | S3 namespace for the cache bucket. Use account-regional when an organization SCP requires account-regional S3 bucket names. | `string` | `"global"` | no |
| <a name="input_cache_bucket_versioning_enabled"></a> [cache\_bucket\_versioning\_enabled](#input\_cache\_bucket\_versioning\_enabled) | Enable S3 object versioning for the cache bucket. | `bool` | `false` | no |
| <a name="input_cache_expiration_days"></a> [cache\_expiration\_days](#input\_cache\_expiration\_days) | Number of days to retain cache artifacts in S3 before expiration | `number` | `10` | no |
| <a name="input_container_insights_enabled"></a> [container\_insights\_enabled](#input\_container\_insights\_enabled) | Enable ECS Container Insights on the control-plane cluster. Disabled by default: Container Insights publishes custom CloudWatch metrics billed per metric, a fixed cost the RunsOn dashboards do not need. | `bool` | `false` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "namespace": null,<br/>  "regex_replace_chars": null,<br/>  "stage": null,<br/>  "tags": {},<br/>  "tenant": null<br/>}</pre> | no |
| <a name="input_cost_allocation_tag"></a> [cost\_allocation\_tag](#input\_cost\_allocation\_tag) | Name of the tag key used for cost allocation and tracking | `string` | `"stack"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>  format = string<br/>  labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_ebs_encryption_key_id"></a> [ebs\_encryption\_key\_id](#input\_ebs\_encryption\_key\_id) | KMS key ID for explicit EBS volume encryption. Leave empty to omit explicit EBS encryption fields, use alias/aws/ebs for the AWS-managed EBS key, or provide a customer-managed key ID, alias, or ARN. Prefer a full ARN for customer-managed keys, especially cross-account keys. Customer-managed keys must also trust the generated RunsOn worker task role in their key policy. | `string` | `""` | no |
| <a name="input_ecr_iam_policy_enabled"></a> [ecr\_iam\_policy\_enabled](#input\_ecr\_iam\_policy\_enabled) | Attach a policy to the runner instance role that allows pushing, pulling, retagging and deleting images in any ECR repository in the account. Every job on every runner gets it, so prefer per-workflow OIDC roles. | `bool` | `false` | no |
| <a name="input_ecr_pull_through_cache_rules"></a> [ecr\_pull\_through\_cache\_rules](#input\_ecr\_pull\_through\_cache\_rules) | Existing ECR pull-through cache rules to reference for runner image pulls. Create or import the regional rules outside the RunsOn module. | <pre>map(object({<br/>    ecr_repository_prefix      = string<br/>    upstream_registry_url      = string<br/>    upstream_repository_prefix = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_email"></a> [email](#input\_email) | Email address for alerts and notifications (requires confirmation) | `string` | n/a | yes |
| <a name="input_enable_admin_routes"></a> [enable\_admin\_routes](#input\_enable\_admin\_routes) | Enable the admin Lambda routes (`/`, `/setup`, `/setup/{proxy+}`, `/readyz`) on the public ingress | `bool` | `true` | no |
| <a name="input_enable_bedrock"></a> [enable\_bedrock](#input\_enable\_bedrock) | Enable Amazon Bedrock access for EC2 runner instances. | `bool` | `false` | no |
| <a name="input_enable_cache_isolation"></a> [enable\_cache\_isolation](#input\_enable\_cache\_isolation) | Enable brokered, per-repository/per-branch credentials for Magic Cache data under scoped-cache/*. Direct S3 cache integrations keep instance-profile access to the stack-shared cache/* namespace and are not repository-isolated. Opt-in | `bool` | `false` | no |
| <a name="input_enable_cost_reports"></a> [enable\_cost\_reports](#input\_enable\_cost\_reports) | Cost report email cadence: no, daily, weekly, or monthly. Legacy true/false values must be replaced with daily/no when upgrading. | `string` | `"daily"` | no |
| <a name="input_enable_default_dashboard"></a> [enable\_default\_dashboard](#input\_enable\_default\_dashboard) | Create the default RunsOn CloudWatch dashboard. Set to false when managing a custom dashboard separately. | `bool` | `true` | no |
| <a name="input_enable_ecr"></a> [enable\_ecr](#input\_enable\_ecr) | Enable ECR repository for ephemeral Docker image storage | `bool` | `false` | no |
| <a name="input_enable_efs"></a> [enable\_efs](#input\_enable\_efs) | Enable EFS file system for shared storage across runners | `bool` | `false` | no |
| <a name="input_enable_stickydisk_isolation"></a> [enable\_stickydisk\_isolation](#input\_enable\_stickydisk\_isolation) | Remove the legacy EBS volume/snapshot permissions from the runner instance role, so all sticky-disk EBS operations happen exclusively on the control plane. Breaks the legacy v1 runs-on/snapshot action. Opt-in | `bool` | `false` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Enable AWS WAF for the public ingress | `bool` | `false` | no |
| <a name="input_enable_warm_pools"></a> [enable\_warm\_pools](#input\_enable\_warm\_pools) | Whether this stack keeps warm pool instances. When false, jobs with a pool= label still run on this stack, on a newly launched instance. | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_extra_env_vars"></a> [extra\_env\_vars](#input\_extra\_env\_vars) | Additional environment variables to set on the worker service | `map(string)` | `{}` | no |
| <a name="input_force_destroy_buckets"></a> [force\_destroy\_buckets](#input\_force\_destroy\_buckets) | Allow S3 buckets to be destroyed even when not empty. Set to false for production environments to prevent accidental data loss. | `bool` | `false` | no |
| <a name="input_github_api_boost_apps"></a> [github\_api\_boost\_apps](#input\_github\_api\_boost\_apps) | Additional same-org GitHub Apps used only for API boost capacity. These entries omit webhook secrets and are written under the shared GitHub apps secret. | <pre>map(object({<br/>    github_app_id            = number<br/>    github_app_private_key   = string<br/>    github_app_client_id     = string<br/>    github_app_client_secret = string<br/>    github_app_label         = optional(string, "")<br/>  }))</pre> | `{}` | no |
| <a name="input_github_api_strategy"></a> [github\_api\_strategy](#input\_github\_api\_strategy) | Strategy for GitHub API calls (normal, conservative) | `string` | `"normal"` | no |
| <a name="input_github_app_client_id"></a> [github\_app\_client\_id](#input\_github\_app\_client\_id) | GitHub App client ID | `string` | `""` | no |
| <a name="input_github_app_client_secret"></a> [github\_app\_client\_secret](#input\_github\_app\_client\_secret) | GitHub App client secret | `string` | `""` | no |
| <a name="input_github_app_id"></a> [github\_app\_id](#input\_github\_app\_id) | GitHub App ID. If provided along with other github\_app\_* variables, creates a Secrets Manager secret and skips the web-based GitHub App setup flow. | `number` | `null` | no |
| <a name="input_github_app_private_key"></a> [github\_app\_private\_key](#input\_github\_app\_private\_key) | GitHub App private key (PEM format) | `string` | `""` | no |
| <a name="input_github_app_webhook_secret"></a> [github\_app\_webhook\_secret](#input\_github\_app\_webhook\_secret) | GitHub App webhook secret | `string` | `""` | no |
| <a name="input_github_enterprise_url"></a> [github\_enterprise\_url](#input\_github\_enterprise\_url) | GitHub Enterprise web URL (https) for GHE.com data residency or GitHub Enterprise Server (optional, leave empty for github.com) | `string` | `""` | no |
| <a name="input_github_organization"></a> [github\_organization](#input\_github\_organization) | GitHub organization or username for RunsOn integration | `string` | n/a | yes |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_integration_step_security_api_key"></a> [integration\_step\_security\_api\_key](#input\_integration\_step\_security\_api\_key) | API key for StepSecurity integration (optional) | `string` | `""` | no |
| <a name="input_ipv6_enabled"></a> [ipv6\_enabled](#input\_ipv6\_enabled) | Enable IPv6 support for runner instances | `bool` | `false` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_license_key"></a> [license\_key](#input\_license\_key) | RunsOn license key obtained from runs-on.com. Prefer `license_key_ssm_parameter_name` to keep the key out of stack configuration. | `string` | `null` | no |
| <a name="input_license_key_ssm_parameter_name"></a> [license\_key\_ssm\_parameter\_name](#input\_license\_key\_ssm\_parameter\_name) | Name of the SSM parameter (SecureString) holding the RunsOn license key. Used when `license_key` is null. | `string` | `"/runs-on/license-key"` | no |
| <a name="input_locks_table_point_in_time_recovery_enabled"></a> [locks\_table\_point\_in\_time\_recovery\_enabled](#input\_locks\_table\_point\_in\_time\_recovery\_enabled) | Enable DynamoDB point-in-time recovery on the locks table. Its rows are transient and expire through TTL, so this only helps satisfy policies that require PITR on every table, at extra storage cost. | `bool` | `false` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain CloudWatch logs. Runner instance logs use this value as is; control-plane and Lambda logs keep at least 14 days. | `number` | `7` | no |
| <a name="input_logger_level"></a> [logger\_level](#input\_logger\_level) | Logging level for the RunsOn service and the runner agent (debug, info, warn, error) | `string` | `"info"` | no |
| <a name="input_maintenance_mode"></a> [maintenance\_mode](#input\_maintenance\_mode) | Enable maintenance mode: scales the worker service to zero, so jobs are not picked up | `bool` | `false` | no |
| <a name="input_mandatory_extras"></a> [mandatory\_extras](#input\_mandatory\_extras) | Runner extras (e.g. s3-cache, otel) that are always enabled for every runner, regardless of label or repo config overrides. | `list(string)` | `[]` | no |
| <a name="input_messaging_kms_key_arn"></a> [messaging\_kms\_key\_arn](#input\_messaging\_kms\_key\_arn) | Customer-managed KMS key ARN used to encrypt the control plane SQS queues and the SNS alerts topic. Leave empty to keep SQS-managed SSE on queues and no SSE on the topic (SNS default disk encryption only). The key policy must allow events.amazonaws.com (and budgets.amazonaws.com when app\_budget\_daily\_usd > 0) kms:GenerateDataKey and kms:Decrypt; the module grants RunsOn roles access through IAM. | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_otel_exporter_endpoint"></a> [otel\_exporter\_endpoint](#input\_otel\_exporter\_endpoint) | OpenTelemetry exporter endpoint for observability (optional) | `string` | `""` | no |
| <a name="input_otel_exporter_headers"></a> [otel\_exporter\_headers](#input\_otel\_exporter\_headers) | OpenTelemetry exporter headers as comma-separated key=value pairs, as in OTEL\_EXPORTER\_OTLP\_HEADERS. Values may be percent-encoded: authorization=Bearer%20KEY and authorization=Bearer KEY are equivalent (optional) | `string` | `""` | no |
| <a name="input_otel_exporter_temporality"></a> [otel\_exporter\_temporality](#input\_otel\_exporter\_temporality) | OTLP metrics temporality: cumulative (default, for Prometheus-compatible backends) or delta (recommended for SigNoz, required by Datadog). Delta applies to counters and histograms; up-down counters stay cumulative. | `string` | `"cumulative"` | no |
| <a name="input_otel_logs_enabled"></a> [otel\_logs\_enabled](#input\_otel\_logs\_enabled) | Enable OpenTelemetry log export | `bool` | `true` | no |
| <a name="input_otel_resource_attributes"></a> [otel\_resource\_attributes](#input\_otel\_resource\_attributes) | Extra OTLP resource attributes as comma-separated key=value pairs, set as OTEL\_RESOURCE\_ATTRIBUTES. They override RunsOn defaults such as deployment.environment, except service.name. (optional) | `string` | `""` | no |
| <a name="input_otel_traces_enabled"></a> [otel\_traces\_enabled](#input\_otel\_traces\_enabled) | Enable OpenTelemetry trace export | `bool` | `true` | no |
| <a name="input_permission_boundary_arn"></a> [permission\_boundary\_arn](#input\_permission\_boundary\_arn) | IAM permissions boundary ARN to attach to all IAM roles (optional) | `string` | `""` | no |
| <a name="input_prevent_destroy_optional_resources"></a> [prevent\_destroy\_optional\_resources](#input\_prevent\_destroy\_optional\_resources) | Prevent destruction of durable optional resources such as EFS. ECR contains ephemeral runner images and is force-deleted by default. | `bool` | `true` | no |
| <a name="input_private_mode"></a> [private\_mode](#input\_private\_mode) | Private networking mode: 'false' (disabled), 'true' (opt-in with label), 'always' (default with opt-out), 'only' (forced, no public option) | `string` | `"false"` | no |
| <a name="input_private_mode_delay"></a> [private\_mode\_delay](#input\_private\_mode\_delay) | Delay before starting the worker service in private mode, to allow NAT gateways to become ready. Set to "60s" or higher for fresh NAT gateway deployments. | `string` | `"0s"` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs for runner instances (required if private\_mode is not 'false') | `list(string)` | `[]` | no |
| <a name="input_public_ingress_web_acl_arn"></a> [public\_ingress\_web\_acl\_arn](#input\_public\_ingress\_web\_acl\_arn) | Optional user-managed AWS WAFv2 Web ACL ARN to associate with the public ingress. When set, RunsOn will not manage webhook IP synchronization. | `string` | `""` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | List of public subnet IDs for runner instances. Required unless private\_mode is "only". | `list(string)` | n/a | yes |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | n/a | yes |
| <a name="input_runner_config_auto_extends_from"></a> [runner\_config\_auto\_extends\_from](#input\_runner\_config\_auto\_extends\_from) | Repository whose .github/runs-on.yml every repository config extends, replacing any \_extends it declares. Set to "." to use each repository's own \_extends | `string` | `".github-private"` | no |
| <a name="input_runner_custom_policy_arns"></a> [runner\_custom\_policy\_arns](#input\_runner\_custom\_policy\_arns) | Optional managed IAM policy ARNs to attach to the EC2 runner instance role. Use this when policy ARNs are computed by other resources. | `list(string)` | `[]` | no |
| <a name="input_runner_custom_tags"></a> [runner\_custom\_tags](#input\_runner\_custom\_tags) | Custom tags to apply to runner instances (comma-separated list) | `list(string)` | `[]` | no |
| <a name="input_runner_max_runtime"></a> [runner\_max\_runtime](#input\_runner\_max\_runtime) | Maximum runtime in minutes for runners before forced termination | `number` | `720` | no |
| <a name="input_runs_on_environment"></a> [runs\_on\_environment](#input\_runs\_on\_environment) | Environment name used for resource tagging and RunsOn job filtering. RunsOn will only process jobs with an 'env' label matching this value. See https://runs-on.com/docs/control-plane/environments/ for details. | `string` | `"production"` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Security group IDs for runner instances and the worker service. If empty list provided, security groups will be created automatically. | `list(string)` | `[]` | no |
| <a name="input_spot_circuit_breaker"></a> [spot\_circuit\_breaker](#input\_spot\_circuit\_breaker) | Spot instance circuit breaker, counted per instance family (e.g., '2/15/30' = 2 interruptions of one family in 15min stop spot launches of that family for 30min; jobs whose families are all paused launch on-demand). 'false' disables it | `string` | `"2/15/30"` | no |
| <a name="input_ssh_allowed"></a> [ssh\_allowed](#input\_ssh\_allowed) | Allow SSH access to runner instances | `bool` | `false` | no |
| <a name="input_ssh_cidr_range"></a> [ssh\_cidr\_range](#input\_ssh\_cidr\_range) | CIDR range allowed for SSH access to runner instances (only applies if ssh\_allowed is true) | `string` | `"0.0.0.0/0"` | no |
| <a name="input_ssm_allowed"></a> [ssm\_allowed](#input\_ssm\_allowed) | Enable SSM access for runner instances. When true, this attaches AmazonSSMManagedEC2InstanceDefaultPolicy to the runner instance role. | `bool` | `true` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element \_(Rarely used, not included by default)\_. A customer identifier, indicating who this instance of a resource is for | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where RunsOn infrastructure will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_alerts"></a> [alerts](#output\_alerts) | RunsOn alerting resources |
| <a name="output_getting_started"></a> [getting\_started](#output\_getting\_started) | Post-apply instructions, including the URL that starts the GitHub App setup |
| <a name="output_ingress"></a> [ingress](#output\_ingress) | RunsOn public ingress endpoints (setup, health and webhook URLs) |
| <a name="output_name"></a> [name](#output\_name) | Name of the RunsOn stack |
| <a name="output_optional_features"></a> [optional\_features](#output\_optional\_features) | Optional runner platform features (EFS, ECR, cache isolation) |
| <a name="output_platform"></a> [platform](#output\_platform) | Shared runner platform resources: cache, networking, runner IAM, logs and launch templates |
| <a name="output_queues"></a> [queues](#output\_queues) | RunsOn SQS queues |
| <a name="output_runner_iam_policy_arn"></a> [runner\_iam\_policy\_arn](#output\_runner\_iam\_policy\_arn) | ARN of the ECR policy attached to the runner instance role |
| <a name="output_runtime"></a> [runtime](#output\_runtime) | RunsOn control-plane ECS resources |
| <a name="output_stack"></a> [stack](#output\_stack) | RunsOn stack metadata and operator-facing entrypoints |
| <a name="output_tables"></a> [tables](#output\_tables) | RunsOn DynamoDB tables |
<!-- markdownlint-restore -->



## References


- [RunsOn](https://runs-on.com/) - 

- [RunsOn Flex Terraform module](https://github.com/runs-on/terraform-aws-runs-on/tree/main/modules/flex) - 

- [RunsOn Changelog](https://runs-on.com/changelog/) - 

- [RunsOn job labels](https://runs-on.com/configuration/job-labels/) - 




[<img src="https://cloudposse.com/logo-300x69.svg" height="32" align="right"/>](https://cpco.io/homepage?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-runs-on&utm_content=)

