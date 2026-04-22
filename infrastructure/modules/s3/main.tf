# ── Raw bucket (CSV uploads) ───────────────────────────────────────────────────
resource "aws_s3_bucket" "raw" {
  bucket = "${var.project_name}-raw-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration { status = "Enabled" }
}

# Enable EventBridge notifications on the raw bucket
resource "aws_s3_bucket_notification" "raw" {
  bucket      = aws_s3_bucket.raw.id
  eventbridge = true
}

# ── Processed bucket (Parquet output) ─────────────────────────────────────────
resource "aws_s3_bucket" "processed" {
  bucket = "${var.project_name}-processed-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "processed" {
  bucket = aws_s3_bucket.processed.id
  versioning_configuration { status = "Enabled" }
}

# Lifecycle: move processed Parquet to cheaper storage after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    id     = "archive-old-parquet"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}

data "aws_caller_identity" "current" {}
