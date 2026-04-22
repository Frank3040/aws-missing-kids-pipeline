{{ config(materialized='table', schema='silver') }}

with base as (
    select distinct
        estado,
        municipio
    from {{ ref('stg_missing_kids') }}
)

select
    md5(
        coalesce(estado, 'Desconocido') || '|' ||
        coalesce(municipio, 'Desconocido')
    ) as geo_id,
    coalesce(estado, 'Desconocido') as estado,
    coalesce(municipio, 'Desconocido') as municipio
from base
