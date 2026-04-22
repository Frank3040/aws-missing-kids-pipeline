variable "project_name" { type = string }
variable "environment" { type = string }
variable "sfn_role_arn" { type = string }
variable "validator_lambda_arn" { type = string }
variable "transformer_lambda_arn" { type = string }
variable "alarm_topic_arn" { type = string }
