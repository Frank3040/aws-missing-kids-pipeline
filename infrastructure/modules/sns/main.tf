resource "aws_sns_topic" "pipeline" {
  name = "${var.project_name}-pipeline-${var.environment}"
}

# Subscribe the SQS queue to the SNS topic
resource "aws_sns_topic_subscription" "to_sqs" {
  topic_arn = aws_sns_topic.pipeline.arn
  protocol  = "sqs"
  endpoint  = var.sqs_queue_arn

  # Pass raw S3 event payload to SQS (no SNS envelope wrapping)
  raw_message_delivery = true
}
