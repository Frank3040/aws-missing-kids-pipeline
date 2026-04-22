"""
Data validation layer — runs before transformation.
Bad rows are logged and dropped; if too many rows are invalid the
whole file is rejected to avoid polluting the processed bucket.
"""
import io
import logging

import pandas as pd

logger = logging.getLogger(__name__)

# Minimum fraction of rows that must be valid (70%)
MIN_VALID_RATIO = 0.70

REQUIRED_COLUMNS: list[str] = [
    "case_number",
    "first_name",
    "last_name",
    "missing_date",
]


def validate_dataframe(csv_bytes: bytes) -> pd.DataFrame:
    """
    Parse CSV bytes, validate schema and data quality.

    Args:
        csv_bytes: Raw CSV content as bytes.

    Returns:
        A clean DataFrame with bad rows removed.

    Raises:
        ValueError: If the CSV is missing required columns or too many rows fail.
    """
    df = pd.read_csv(io.BytesIO(csv_bytes))
    _check_required_columns(df)

    original_count = len(df)
    df = _drop_bad_rows(df)
    valid_count = len(df)

    if original_count > 0:
        ratio = valid_count / original_count
        logger.info(f"Validation: {valid_count}/{original_count} rows valid ({ratio:.0%})")
        if ratio < MIN_VALID_RATIO:
            raise ValueError(
                f"Too many invalid rows: only {ratio:.0%} passed validation "
                f"(threshold {MIN_VALID_RATIO:.0%}). Rejecting file."
            )

    return df


def _check_required_columns(df: pd.DataFrame) -> None:
    """Raise if any required column is missing entirely."""
    normalised = {c.strip().lower().replace(" ", "_") for c in df.columns}
    missing = [c for c in REQUIRED_COLUMNS if c not in normalised]
    if missing:
        raise ValueError(f"CSV is missing required columns: {missing}")


def _drop_bad_rows(df: pd.DataFrame) -> pd.DataFrame:
    """Drop rows where any required column is null."""
    normalised_cols = {c.strip().lower().replace(" ", "_"): c for c in df.columns}
    present_required = [
        normalised_cols[rc] for rc in REQUIRED_COLUMNS if rc in normalised_cols
    ]
    before = len(df)
    df = df.dropna(subset=present_required)
    dropped = before - len(df)
    if dropped:
        logger.warning(f"Dropped {dropped} rows with null values in required columns")
    return df
