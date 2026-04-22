output "raw_bucket_name" {
  description = "S3 bucket for raw CSV uploads"
  value       = module.s3.raw_bucket_name
}

output "processed_bucket_name" {
  description = "S3 bucket for processed Parquet files"
  value       = module.s3.processed_bucket_name
}

output "sqs_queue_url" {
  description = "URL of the processing SQS queue"
  value       = module.sqs.queue_url
}

output "dlq_url" {
  description = "URL of the Dead Letter Queue"
  value       = module.sqs.dlq_url
}

output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.step_functions.state_machine_arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = module.step_functions.state_machine_name
}

output "starter_function_name" {
  description = "Name of the SQS-triggered Starter Lambda"
  value       = module.lambda.starter_function_name
}

output "glue_crawler_name" {
  description = "Name of the Glue Crawler"
  value       = module.glue.crawler_name
}
