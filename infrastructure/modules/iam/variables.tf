variable "project_name" { type = string }
variable "environment" { type = string }
variable "raw_bucket_arn" { type = string }
variable "processed_bucket_arn" { type = string }
variable "sqs_queue_arn" { type = string }
variable "sqs_dlq_arn" { type = string }
# Step Functions — needed by Starter Lambda and SF execution role
variable "state_machine_arn" { type = string }
variable "validator_lambda_arn" { type = string }
variable "transformer_lambda_arn" { type = string }
variable "alarm_topic_arn" { type = string }
