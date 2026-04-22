resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-athena-results-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_athena_workgroup" "pipeline" {
  name        = "${var.project_name}-wg-${var.environment}"
  description = "Workgroup for querying processed missing-kids Parquet"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }
  }
}

data "aws_caller_identity" "current" {}
