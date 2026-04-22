terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "missing-kids"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ── S3 (first — other modules depend on bucket ARNs) ───────────────────────────
module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  environment  = var.environment
}

# ── SQS (needed by SNS, IAM, Lambda) ──────────────────────────────────────────
module "sqs" {
  source       = "./modules/sqs"
  project_name = var.project_name
  environment  = var.environment
}

# ── SNS (needed by EventBridge + Step Functions failure handler) ───────────────
module "sns" {
  source        = "./modules/sns"
  project_name  = var.project_name
  environment   = var.environment
  sqs_queue_arn = module.sqs.queue_arn
}

# ── EventBridge (depends on S3 raw bucket name + SNS topic) ───────────────────
module "eventbridge" {
  source          = "./modules/eventbridge"
  project_name    = var.project_name
  environment     = var.environment
  raw_bucket_arn  = module.s3.raw_bucket_arn
  raw_bucket_name = module.s3.raw_bucket_name
  sns_topic_arn   = module.sns.topic_arn
}

# ── Lambda (3 functions — Starter, Validator, Transformer) ────────────────────
# Validator and Transformer ARNs are required by Step Functions module, so
# Lambda must be created BEFORE the Step Functions state machine.
module "lambda" {
  source                      = "./modules/lambda"
  project_name                = var.project_name
  environment                 = var.environment
  starter_lambda_role_arn     = module.iam.starter_lambda_role_arn
  validator_lambda_role_arn   = module.iam.validator_lambda_role_arn
  transformer_lambda_role_arn = module.iam.transformer_lambda_role_arn
  layer_arn                   = "arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python312:22"
  sqs_queue_arn               = module.sqs.queue_arn
  state_machine_arn           = module.step_functions.state_machine_arn
  raw_bucket_name             = module.s3.raw_bucket_name
  processed_bucket_name       = module.s3.processed_bucket_name
}

# ── Step Functions State Machine ───────────────────────────────────────────────
module "step_functions" {
  source                 = "./modules/step_functions"
  project_name           = var.project_name
  environment            = var.environment
  sfn_role_arn           = module.iam.sfn_role_arn
  validator_lambda_arn   = module.lambda.validator_function_arn
  transformer_lambda_arn = module.lambda.transformer_function_arn
  alarm_topic_arn        = module.cloudwatch.alarm_topic_arn
}

# ── IAM (roles depend on Step Functions ARN + Lambda ARNs) ────────────────────
# NOTE: circular dependency is broken by Terraform's lazy evaluation —
# state_machine_arn comes from module.step_functions which is created first.
module "iam" {
  source                 = "./modules/iam"
  project_name           = var.project_name
  environment            = var.environment
  raw_bucket_arn         = module.s3.raw_bucket_arn
  processed_bucket_arn   = module.s3.processed_bucket_arn
  sqs_queue_arn          = module.sqs.queue_arn
  sqs_dlq_arn            = module.sqs.dlq_arn
  state_machine_arn      = module.step_functions.state_machine_arn
  validator_lambda_arn   = module.lambda.validator_function_arn
  transformer_lambda_arn = module.lambda.transformer_function_arn
  alarm_topic_arn        = module.cloudwatch.alarm_topic_arn
}

# ── Glue Crawler ───────────────────────────────────────────────────────────────
module "glue" {
  source                = "./modules/glue"
  project_name          = var.project_name
  environment           = var.environment
  glue_role_arn         = module.iam.glue_role_arn
  processed_bucket_name = module.s3.processed_bucket_name
}

# ── Athena Workgroup ───────────────────────────────────────────────────────────
module "athena" {
  source       = "./modules/athena"
  project_name = var.project_name
  environment  = var.environment
}

# ── CloudWatch Alarms ──────────────────────────────────────────────────────────
module "cloudwatch" {
  source               = "./modules/cloudwatch"
  project_name         = var.project_name
  environment          = var.environment
  dlq_name             = module.sqs.dlq_name
  lambda_function_name = module.lambda.function_name
  alarm_email          = var.alarm_email
}
