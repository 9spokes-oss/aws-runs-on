output "name" {
  value       = one(module.runs_on[*].stack.name)
  description = "Name of the RunsOn stack"

  # RunsOn appends suffixes of up to 33 characters (e.g. "-github-runner-cache-refresh-role") to the stack
  # name in IAM role names, which AWS caps at 64 characters. A precondition fails the plan; a check would only warn.
  precondition {
    condition     = !local.enabled || length(module.this.id) <= 31
    error_message = "The label ID (${module.this.id}) must be 31 characters or fewer, or RunsOn IAM role names exceed 64 characters. Shorten it with `name` or `id_length_limit`."
  }
}

output "getting_started" {
  value       = one(module.runs_on[*].stack.getting_started)
  description = "Post-apply instructions, including the URL that starts the GitHub App setup"
}

output "stack" {
  value       = one(module.runs_on[*].stack)
  description = "RunsOn stack metadata and operator-facing entrypoints"
}

output "ingress" {
  value       = one(module.runs_on[*].ingress)
  description = "RunsOn public ingress endpoints (setup, health and webhook URLs)"
}

output "platform" {
  value       = one(module.runs_on[*].platform)
  description = "Shared runner platform resources: cache, networking, runner IAM, logs and launch templates"
}

output "runtime" {
  value       = one(module.runs_on[*].runtime)
  description = "RunsOn control-plane ECS resources"
}

output "queues" {
  value       = one(module.runs_on[*].queues)
  description = "RunsOn SQS queues"
}

output "tables" {
  value       = one(module.runs_on[*].tables)
  description = "RunsOn DynamoDB tables"
}

output "alerts" {
  value       = one(module.runs_on[*].alerts)
  description = "RunsOn alerting resources"
}

output "optional_features" {
  value       = one(module.runs_on[*].optional_features)
  description = "Optional runner platform features (EFS, ECR, cache isolation)"
}

output "runner_iam_policy_arn" {
  value       = module.iam_policy.policy_arn
  description = "ARN of the ECR policy attached to the runner instance role"
}
