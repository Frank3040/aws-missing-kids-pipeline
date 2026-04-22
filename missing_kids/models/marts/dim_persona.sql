{{ config(materialized='table', schema='silver') }}

with base as (
    select distinct
        id,
        sexo,
        edad,
        grupo_etario,
        migrante,
        reincidencia,
        numero_de_reincidencia,
        desaparicion_multiple,
        persona_con_quien_desaparecio
    from {{ ref('stg_missing_kids') }}
    where id is not null
)

select
    md5(cast(id as varchar)) as persona_id,
    sexo,
    edad,
    grupo_etario,
    migrante,
    reincidencia,
    numero_de_reincidencia,
    desaparicion_multiple,
    persona_con_quien_desaparecio
from base
