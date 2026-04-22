# EventBridge rule: fires when a .csv file is created under s3://raw-bucket/raw/
resource "aws_cloudwatch_event_rule" "csv_uploaded" {
  name        = "${var.project_name}-csv-upload-${var.environment}"
  description = "Fires when a CSV is dropped on the raw/ S3 prefix"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = { name = [var.raw_bucket_name] }
      object = { key = [{ prefix = "raw/" }] }
    }
  })
}

# Target: forward matched events to SNS
resource "aws_cloudwatch_event_target" "to_sns" {
  rule      = aws_cloudwatch_event_rule.csv_uploaded.name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}

# Allow EventBridge to publish to SNS
resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn = var.sns_topic_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridge"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = var.sns_topic_arn
    }]
  })
}
