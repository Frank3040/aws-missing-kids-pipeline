"""
CSV → Parquet transformer.
Produces output keys with Hive-style date partitions:
  processed/year=YYYY/month=MM/day=DD/<filename>.parquet
"""
import io
import logging
import re
from datetime import datetime

import pandas as pd

logger = logging.getLogger(__name__)

# ── Expected schema ────────────────────────────────────────────────────────────
# Adjust column names to match the actual dataset.
REQUIRED_COLUMNS: list[str] = [
    "case_number",
    "first_name",
    "last_name",
    "age",
    "missing_date",
    "state",
]


def transform_csv_to_parquet(df: pd.DataFrame, source_key: str) -> tuple[io.BytesIO, str]:
    """
    Transform a validated DataFrame to Parquet bytes and compute
    the Hive-partitioned output S3 key.

    Args:
        df: Validated DataFrame (output of validator.validate_dataframe).
        source_key: Original S3 key of the raw CSV (e.g. 'raw/report.csv').

    Returns:
        (parquet_buffer, output_key) — BytesIO Parquet bytes + target S3 key.
    """
    # Normalise column names: lowercase, strip whitespace
    df.columns = [c.strip().lower().replace(" ", "_") for c in df.columns]

    # Cast missing_date to datetime for correct Parquet typing
    if "missing_date" in df.columns:
        df["missing_date"] = pd.to_datetime(df["missing_date"], errors="coerce")

    # Write to Parquet in memory
    buffer = io.BytesIO()
    df.to_parquet(buffer, index=False, engine="pyarrow")
    buffer.seek(0)

    output_key = _build_output_key(source_key)
    logger.info(f"Transformed {len(df)} rows → {output_key}")
    return buffer, output_key


def _build_output_key(source_key: str) -> str:
    """
    Build a Hive-partitioned output key from the source CSV key.
    
    Example:
      source_key = 'raw/march_report.csv'
      output     = 'processed/year=2026/month=03/day=04/march_report.parquet'
    """
    now = datetime.utcnow()
    filename = re.sub(r"\.csv$", ".parquet", source_key.split("/")[-1], flags=re.IGNORECASE)
    return (
        f"processed/"
        f"year={now.year}/"
        f"month={now.month:02d}/"
        f"day={now.day:02d}/"
        f"{filename}"
    )
