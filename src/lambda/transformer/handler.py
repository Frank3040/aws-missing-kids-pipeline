"""
Transformer Lambda — invoked as a Step Functions task.
"""
import io
import logging
import os
from datetime import datetime, timezone

import boto3
import pandas as pd
import awswrangler as wr

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

s3_client = boto3.client("s3")

RAW_BUCKET       = os.environ["RAW_BUCKET"]
PROCESSED_BUCKET = os.environ["PROCESSED_BUCKET"]


def lambda_handler(event: dict, context) -> dict:
    """
    Step Functions task handler for CSV → Parquet transformation.
    """
    s3_key = event["s3_key"]
    logger.info(f"Transforming s3://{RAW_BUCKET}/{s3_key}")

    # Download raw CSV
    response = s3_client.get_object(Bucket=RAW_BUCKET, Key=s3_key)
    csv_bytes = response["Body"].read()

    # Transform
    df = _load_and_clean(csv_bytes)

    # s3 path for awswrangler
    s3_path = f"s3://{PROCESSED_BUCKET}/processed"

    logger.info(f"Writing {len(df)} rows to partitioned Parquet at {s3_path}")
    
    wr.s3.to_parquet(
        df=df,
        path=s3_path,
        dataset=True,
        partition_cols=['year']
    )

    logger.info("Successfully wrote partitioned data.")
    return {
        "s3_key": s3_key,
        "output_key_prefix": "processed/",
        "rows_written": len(df),
    }


def parse_edad(x):
    x = str(x).lower().strip()
    if pd.isna(x) or x == "nan" or x == "":
        return pd.NA
    if "mes" in x:
        return 0
    elif x.isdigit():
        return int(x)
    else:
        return pd.NA


def parse_fecha(x):
    if pd.isna(x):
        return pd.NaT
    x = str(x).strip()
    try:
        parts = x.split("/")
        if len(parts) != 3:
            return pd.NaT
        part1 = int(parts[0])
        part2 = int(parts[1])
        # Si el segundo número es > 12 → seguro es día
        if part2 > 12:
            return pd.to_datetime(x, format="%m/%d/%Y")
        else:
            return pd.to_datetime(x, format="%d/%m/%Y")
    except:
        return pd.NaT


def parse_dias(x):
    if pd.isna(x):
        return pd.NA
    x = str(x).strip()
    if '-' in x:
        num = x.replace('-', '')
        return int(num) if num.isdigit() else pd.NA
    elif x.isdigit():
        return int(x)
    else:
        return pd.NA


def parse_horario(x):
    if pd.isna(x):
        return pd.NA
    x = str(x).strip().lower()
    if "no especificada" in x:
        return pd.NA
    try:
        # e.g., "02:30 PM"
        # Convert to string "HH:MM:SS" for Athena compatibility
        t = pd.to_datetime(x, format="%I:%M %p", errors="coerce").time()
        return t.strftime("%H:%M:%S")
    except:
        return pd.NA


def _load_and_clean(csv_bytes: bytes) -> "pd.DataFrame":
    df = pd.read_csv(io.BytesIO(csv_bytes))

    # 1. Lowercase column names
    df.columns = df.columns.str.lower()
    
    # 2. Filter specific range of columns as per transform-specific.py
    # "df_filtered = df.loc[:, 'sexo':'persona con quién desapareció']"
    if 'sexo' in df.columns and 'persona con quién desapareció' in df.columns:
        df = df.loc[:, 'sexo':'persona con quién desapareció']
    
    # Clean municipality
    if 'municipio' in df.columns:
        # Split municipio
        split_result = df['municipio'].str.split(',', n=1, expand=True)
        
        if split_result.shape[1] == 1:
            df['municipio'] = split_result[0].str.strip()
            df['estado'] = pd.NA
        else:
            df['municipio'] = split_result[0].str.strip()
            df['estado'] = split_result[1].str.strip()
    
    if 'colonia/localidad' in df.columns:
        df = df.drop(columns=['colonia/localidad'])

    if 'edad' in df.columns:
        df['edad'] = df['edad'].apply(parse_edad).astype("Int64")

    if 'fecha de desaparición' in df.columns:
        df['fecha de desaparición'] = df['fecha de desaparición'].apply(parse_fecha)
        # Add year column for partitioning
        df['year'] = df['fecha de desaparición'].dt.year.fillna(9999).astype(int).astype(str)
    else:
        df['year'] = 'unknown'

    if 'fecha de localización' in df.columns:
        df['fecha de localización'] = df['fecha de localización'].apply(parse_fecha)

    if 'día de la semana' in df.columns:
        df['día de la semana'] = df['día de la semana'].apply(lambda x: str(x).lower() if not pd.isna(x) else x)

    if 'estatus' in df.columns:
        df['estatus'] = df['estatus'].apply(lambda x: str(x).lower() if not pd.isna(x) else x)

    if 'días sin localizar' in df.columns:
        df['días sin localizar'] = df['días sin localizar'].apply(parse_dias).astype('Int64')

    if 'horario' in df.columns:
        df['horario'] = df['horario'].apply(parse_horario)

    if 'migrante' in df.columns:
        df['migrante'] = df['migrante'].apply(lambda x: str(x).lower().strip() if not pd.isna(x) else x)

    if 'región' in df.columns:
        df['región'] = df['región'].apply(lambda x: str(x).lower() if not pd.isna(x) else x)

    if 'persona con quién desapareció' in df.columns:
        df['persona con quién desapareció'] = df['persona con quién desapareció'].apply(
            lambda x: "Compañero/a" if str(x).strip() == "Compañero" else x
        )

    # 4. Drop duplicates
    df = df.drop_duplicates()

    return df
