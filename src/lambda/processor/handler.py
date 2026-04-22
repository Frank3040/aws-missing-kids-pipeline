"""
Lambda handler — triggered by SQS.
Each SQS message contains an S3 event (CSV uploaded to raw/ prefix).
"""
import json
import logging
import os

import boto3

from transformer import transform_csv_to_parquet
from validator import validate_dataframe

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

s3_client = boto3.client("s3")

RAW_BUCKET = os.environ["RAW_BUCKET"]
PROCESSED_BUCKET = os.environ["PROCESSED_BUCKET"]


def lambda_handler(event: dict, context) -> dict:
    """
    Process a batch of SQS messages.
    Returns batchItemFailures so Lambda retries only failed records.
    """
    batch_item_failures = []

    for record in event.get("Records", []):
        message_id = record["messageId"]
        try:
            body = json.loads(record["body"])
            # Body is a raw S3 event from EventBridge via SNS
            s3_key = _extract_s3_key(body)
            logger.info(f"Processing s3://{RAW_BUCKET}/{s3_key}")

            _process_file(s3_key)

        except Exception as exc:
            logger.error(f"Failed to process message {message_id}: {exc}", exc_info=True)
            batch_item_failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": batch_item_failures}


def _extract_s3_key(body: dict) -> str:
    """Extract the S3 object key from an EventBridge S3 event payload."""
    try:
        return body["detail"]["object"]["key"]
    except KeyError as e:
        raise ValueError(f"Unexpected event structure, missing key: {e}") from e


def _process_file(s3_key: str) -> None:
    """Download CSV, validate, transform to Parquet, upload."""
    # Download raw CSV
    response = s3_client.get_object(Bucket=RAW_BUCKET, Key=s3_key)
    csv_bytes = response["Body"].read()

    # Validate + transform
    df = validate_dataframe(csv_bytes)
    parquet_buffer, output_key = transform_csv_to_parquet(df, s3_key)

    # Upload Parquet with Hive partition path
    s3_client.put_object(
        Bucket=PROCESSED_BUCKET,
        Key=output_key,
        Body=parquet_buffer.getvalue(),
        ContentType="application/octet-stream",
    )
    logger.info(f"Written to s3://{PROCESSED_BUCKET}/{output_key}")
