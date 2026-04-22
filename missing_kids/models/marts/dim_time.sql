{{ config(materialized='table', schema='silver') }}

with date_sources as (
    -- Desapariciones (with associated time/rango_horario)
    select distinct 
        fecha_de_desaparicion as fecha,
        cast(horario as varchar) as rango_horario
    from {{ ref('stg_missing_kids') }}
    where fecha_de_desaparicion is not null

    union 

    -- Localizaciones (usually don't have a specific time recorded, default to 'Desconocido')
    select distinct
        fecha_de_localizacion as fecha,
        'Desconocido' as rango_horario
    from {{ ref('stg_missing_kids') }}
    where fecha_de_localizacion is not null
)

select
    -- Surrogate key for time dimension includes both date and time range
    md5(
        coalesce(cast(fecha as varchar), '1900-01-01') || '|' ||
        coalesce(cast(rango_horario as varchar), 'Desconocido')
    ) as time_id,
    
    fecha,
    extract(year from fecha) as anio,
    extract(month from fecha) as mes,
    extract(day from fecha) as dia,
    extract(quarter from fecha) as trimestre,
    trim(to_char(fecha, 'Day')) as dia_semana,
    trim(to_char(fecha, 'Month')) as nombre_mes,
    coalesce(cast(rango_horario as varchar), 'Desconocido') as rango_horario

from date_sources
