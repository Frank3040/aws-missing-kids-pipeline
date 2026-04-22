{{ config(materialized='table', schema='silver') }}

with base as (
    select distinct
        estatus,
        rango_desaparicion
    from {{ ref('stg_missing_kids') }}
)

select
    md5(
        coalesce(estatus, 'Desconocido') || '|' ||
        coalesce(rango_desaparicion, 'Desconocido')
    ) as estatus_id,
    coalesce(estatus, 'Desconocido') as estatus,
    coalesce(rango_desaparicion, 'Desconocido') as rango_desaparicion
from base
