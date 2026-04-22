# Architecture Overview

## Pipeline Flow

```
CSV Upload → S3 (raw/) → EventBridge → SNS → SQS → Lambda → S3 (processed/)
                                                                    ↓
                                                        Hive partitions:
                                                        year=/month=/day=/
                                                                    ↓
                                                          Glue Crawler (daily)
                                                                    ↓
                                                        Glue Data Catalog
                                                                    ↓
                                                              Athena
                                                                    ↓
                                                           QuickSight
```

## Services

| Service | Role |
|---|---|
| S3 (raw) | Landing zone for CSV uploads |
| S3 (processed) | Parquet output with Hive partitions |
| EventBridge | Detects new objects in raw/ prefix |
| SNS | Fan-out hub (allows future subscribers) |
| SQS | Message buffer with redrive to DLQ |
| Lambda | Validates + transforms CSV → Parquet |
| SQS DLQ | Captures messages after 3 Lambda failures |
| Lambda Layer | Provides pandas + pyarrow to Lambda |
| Glue Crawler | Discovers schema on processed/ daily |
| Glue Catalog | Queryable table registered for Athena |
| Athena | SQL engine used by QuickSight |
| QuickSight | Dashboards + KPIs |
| CloudWatch | Alarms on DLQ depth and Lambda error rate |

## Partition Scheme

Processed files follow Hive partition format for efficient Athena queries:

```
s3://processed-bucket/processed/year=2026/month=03/day=04/report.parquet
```
