resource "aws_glue_catalog_database" "pipeline" {
  name        = "${replace(var.project_name, "-", "_")}_${var.environment}"
  description = "Glue catalog for processed missing-kids Parquet data"
}

resource "aws_glue_crawler" "processed" {
  name          = "${var.project_name}-crawler-${var.environment}"
  role          = var.glue_role_arn
  database_name = aws_glue_catalog_database.pipeline.name
  description   = "Crawls processed/ Parquet partitions and updates the Glue catalog"

  s3_target {
    path = "s3://${var.processed_bucket_name}/processed/"
  }

  # Hive-compatible partition detection (year=/month=/day=/)
  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })

  schedule = "cron(0 6 * * ? *)" # 06:00 UTC daily
}
