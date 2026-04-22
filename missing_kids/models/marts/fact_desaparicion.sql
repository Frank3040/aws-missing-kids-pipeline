{{ config(materialized='table', schema='gold') }}

with base as (
    select
        id,
        fecha_de_desaparicion,
        fecha_de_localizacion,
        horario,
        dias_sin_localizar,
        estado,
        municipio,
        estatus,
        rango_desaparicion
    from {{ ref('stg_missing_kids') }}
    where id is not null
)

select
    md5(cast(id as varchar)) as fact_id,
    
    -- Foreign keys to dimensions
    md5(
        coalesce(cast(fecha_de_desaparicion as varchar), '1900-01-01') || '|' ||
        coalesce(cast(horario as varchar), 'Desconocido')
    ) as time_id_desaparicion,

    md5(
        coalesce(cast(fecha_de_localizacion as varchar), '1900-01-01') || '|' ||
        'Desconocido'
    ) as time_id_localizacion,

    md5(cast(id as varchar)) as persona_id,
    
    md5(
        coalesce(estado, 'Desconocido') || '|' ||
        coalesce(municipio, 'Desconocido')
    ) as geo_id,
    
    md5(
        coalesce(estatus, 'Desconocido') || '|' ||
        coalesce(rango_desaparicion, 'Desconocido')
    ) as estatus_id,
    
    -- Measures
    dias_sin_localizar,
    1 as case_count,

    -- Event Dates (optional, kept for raw analysis if desired)
    fecha_de_desaparicion,
    fecha_de_localizacion
from base
