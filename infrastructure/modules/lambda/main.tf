locals {
  starter_zip_path     = "${path.root}/../src/lambda/starter/starter.zip"
  validator_zip_path   = "${path.root}/../src/lambda/validator/validator.zip"
  transformer_zip_path = "${path.root}/../src/lambda/transformer/transformer.zip"
}

data "archive_file" "starter" {
  type        = "zip"
  source_dir  = "${path.root}/../src/lambda/starter"
  output_path = local.starter_zip_path
  excludes    = ["*.zip"]
}

data "archive_file" "validator" {
  type        = "zip"
  source_dir  = "${path.root}/../src/lambda/validator"
  output_path = local.validator_zip_path
  excludes    = ["*.zip"]
}

data "archive_file" "transformer" {
  type        = "zip"
  source_dir  = "${path.root}/../src/lambda/transformer"
  output_path = local.transformer_zip_path
  excludes    = ["*.zip"]
}

# ── 1. Starter Lambda — triggered by SQS, starts Step Functions ───────────────
resource "aws_lambda_function" "starter" {
  function_name    = "${var.project_name}-starter-${var.environment}"
  description      = "Reads SQS messages and starts a Step Functions execution per file"
  filename         = data.archive_file.starter.output_path
  source_code_hash = data.archive_file.starter.output_base64sha256
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  timeout          = 30
  memory_size      = 128
  role             = var.starter_lambda_role_arn

  environment {
    variables = {
      STATE_MACHINE_ARN = var.state_machine_arn
      LOG_LEVEL         = "INFO"
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn        = var.sqs_queue_arn
  function_name           = aws_lambda_function.starter.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}

# ── 2. Validator Lambda — invoked by Step Functions ───────────────────────────
resource "aws_lambda_function" "validator" {
  function_name    = "${var.project_name}-validator-${var.environment}"
  description      = "Validates CSV schema and data quality (Step Functions task)"
  filename         = data.archive_file.validator.output_path
  source_code_hash = data.archive_file.validator.output_base64sha256
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  timeout          = 60
  memory_size      = 256
  role             = var.validator_lambda_role_arn

  environment {
    variables = {
      RAW_BUCKET = var.raw_bucket_name
      LOG_LEVEL  = "INFO"
    }
  }
}

# ── 3. Transformer Lambda — invoked by Step Functions ────────────────────────
resource "aws_lambda_function" "transformer" {
  function_name    = "${var.project_name}-transformer-${var.environment}"
  description      = "Converts validated CSV to Parquet with Hive partitions (Step Functions task)"
  filename         = data.archive_file.transformer.output_path
  source_code_hash = data.archive_file.transformer.output_base64sha256
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  timeout          = 300
  memory_size      = 512
  role             = var.transformer_lambda_role_arn
  layers           = [var.layer_arn]

  environment {
    variables = {
      RAW_BUCKET       = var.raw_bucket_name
      PROCESSED_BUCKET = var.processed_bucket_name
      LOG_LEVEL        = "INFO"
    }
  }
}
