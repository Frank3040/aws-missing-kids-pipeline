# ── Step Functions State Machine ───────────────────────────────────────────────
resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.project_name}-pipeline-${var.environment}"
  role_arn = var.sfn_role_arn

  definition = jsonencode({
    Comment = "Missing Kids Pipeline — orchestrates CSV validation and Parquet transformation"
    StartAt = "ValidateCSV"
    States = {
      # ── Step 1: Validate ─────────────────────────────────────────────────────
      ValidateCSV = {
        Type       = "Task"
        Resource   = var.validator_lambda_arn
        Comment    = "Validates CSV schema, required columns, and data quality"
        ResultPath = "$.validation"
        Next       = "TransformToParquet"
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts     = 2
          BackoffRate     = 2.0
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "HandleFailure"
          ResultPath  = "$.error"
        }]
      }
      # ── Step 2: Transform ────────────────────────────────────────────────────
      TransformToParquet = {
        Type       = "Task"
        Resource   = var.transformer_lambda_arn
        Comment    = "Converts validated CSV to Parquet with Hive partitions on the processed bucket"
        ResultPath = "$.transformation"
        Next       = "PipelineSuccess"
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts     = 2
          BackoffRate     = 2.0
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "HandleFailure"
          ResultPath  = "$.error"
        }]
      }
      # ── Success terminal ─────────────────────────────────────────────────────
      PipelineSuccess = {
        Type = "Succeed"
      }
      # ── Failure handler ──────────────────────────────────────────────────────
      HandleFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Comment  = "Publishes failure details to the alarm SNS topic"
        Parameters = {
          TopicArn    = var.alarm_topic_arn
          "Message.$" = "States.Format('Pipeline failed. File: {}. Error: {}', $.s3_key, $.error.Cause)"
          Subject     = "Missing Kids Pipeline — processing failure"
        }
        Next = "PipelineFailed"
      }
      PipelineFailed = {
        Type  = "Fail"
        Error = "PipelineExecutionFailed"
        Cause = "CSV processing failed — see HandleFailure step for details"
      }
    }
  })
}
