"""
Validator Lambda — invoked as a Step Functions task.
Raises on validation failure so Step Functions catches the error.
"""
import csv
import io
import logging
import os

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

s3_client = boto3.client("s3")
RAW_BUCKET = os.environ["RAW_BUCKET"]

# Updated for Chiapas Missing Children Dataset
REQUIRED_COLUMNS = {
    "sexo",
    "edad",
    "grupo etario",
    "municipio",
    "región",
    "migrante",
    "fecha de desaparición",
    "día de la semana",
    "horario",
    "estatus",
    "fecha de localización",
    "días sin localizar",
    "rango desaparición",
    "reincidencia",
    "número de reincidencia",
    "desaparición múltiple",
    "persona con quién desapareció",
}
MIN_VALID_RATIO = 0.70


def lambda_handler(event: dict, context) -> dict:
    """
    Step Functions task handler for CSV validation.
    The entire event is the state machine input — extract s3_key from it.
    """
    s3_key = event["s3_key"]
    logger.info("Validating s3://%s/%s", RAW_BUCKET, s3_key)

    try:
        response = s3_client.get_object(Bucket=RAW_BUCKET, Key=s3_key)
    except ClientError as exc:
        error_code = exc.response["Error"]["Code"]
        raise RuntimeError(
            f"Failed to read s3://{RAW_BUCKET}/{s3_key}: {error_code}"
        ) from exc

    csv_bytes = response["Body"].read()

    row_count, valid_row_count = _validate(csv_bytes)

    logger.info("Validation passed: %d/%d rows valid", valid_row_count, row_count)

    # Pass enriched payload to the next state
    return {
        "s3_key": s3_key,
        "row_count": row_count,
        "valid_row_count": valid_row_count,
        "valid": True,  # BUG FIX: campo mencionado en el docstring pero faltaba
    }


def _normalize_headers(fieldnames: list[str] | None) -> dict[str, str]:
    """
    Returns a mapping of normalized_name -> original_name for all headers.
    Normalization: strip whitespace, lowercase.
    """
    if not fieldnames:
        return {}
    return {h.strip().lower(): h for h in fieldnames}


def _validate(csv_bytes: bytes) -> tuple[int, int]:
    """
    Validates schema and data quality.
    Raises ValueError if validation fails (Step Functions will Catch this).
    """
    # BUG FIX: usar utf-8-sig para eliminar BOM automáticamente si está presente
    text = csv_bytes.decode("utf-8-sig")
    reader = csv.DictReader(io.StringIO(text))

    # BUG FIX: normalizar headers ANTES de consumir las filas, y conservar el
    # mapeo original→normalizado para poder acceder a las filas correctamente.
    header_map = _normalize_headers(reader.fieldnames)
    normalized_headers = set(header_map.keys())

    missing = REQUIRED_COLUMNS - normalized_headers
    if missing:
        raise ValueError(f"CSV missing required columns: {sorted(missing)}")

    # Construir la tabla inversa: normalizado → nombre original en el DictReader
    # para leer cada fila usando las claves que DictReader realmente produce.
    norm_to_original = {norm: orig for norm, orig in header_map.items()}

    rows = list(reader)
    total = len(rows)
    if total == 0:
        raise ValueError("CSV has no data rows")

    valid = 0
    for row in rows:
        # Acceder usando el nombre ORIGINAL del header (como lo entrega DictReader)
        if all(
            (row.get(norm_to_original[col]) or "").strip()
            for col in REQUIRED_COLUMNS
        ):
            valid += 1

    ratio = valid / total
    if ratio < MIN_VALID_RATIO:
        raise ValueError(
            f"Data quality too low: {ratio:.0%} valid rows "
            f"(threshold {MIN_VALID_RATIO:.0%})"
        )

    return total, valid