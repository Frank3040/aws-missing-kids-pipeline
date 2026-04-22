"""
Starter Lambda — triggered by SQS.
Reads each SQS message (S3 event from EventBridge), extracts the S3 key,
and starts one Step Functions execution per file.
"""
import json
import logging
import os
import uuid

import boto3

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

sfn_client = boto3.client("stepfunctions")
STATE_MACHINE_ARN = os.environ["STATE_MACHINE_ARN"]


def lambda_handler(event: dict, context) -> dict:
    """
    SQS → Step Functions starter.
    Returns batchItemFailures so only failed SQS records are retried.
    """
    batch_item_failures = []

    for record in event.get("Records", []):
        message_id = record["messageId"]
        try:
            body = json.loads(record["body"])
            s3_key = _extract_s3_key(body)
            logger.info(f"Starting pipeline execution for key: {s3_key}")

            # Unique execution name per file (max 80 chars)
            exec_name = f"pipeline-{uuid.uuid4().hex[:16]}"

            sfn_client.start_execution(
                stateMachineArn=STATE_MACHINE_ARN,
                name=exec_name,
                input=json.dumps({"s3_key": s3_key}),
            )
            logger.info(f"Started execution: {exec_name}")

        except Exception as exc:
            logger.error(f"Failed to start execution for message {message_id}: {exc}", exc_info=True)
            batch_item_failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": batch_item_failures}


def _extract_s3_key(body: dict) -> str:
    """Extract the S3 object key from the EventBridge S3 event payload."""
    try:
        return body["detail"]["object"]["key"]
    except KeyError as e:
        raise ValueError(f"Unexpected event structure, missing key: {e}") from e
