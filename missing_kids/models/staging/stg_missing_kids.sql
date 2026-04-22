{{ config(materialized='view') }}

with source as (
    select * from {{ source('bronze_missing_kids', 'missing_kids_complete') }}
),

renamed as (
    select
        ID as id,
        "sexo" as sexo,
        "edad" as edad,
        "grupo_etario" as grupo_etario,
        "migrante" as migrante,
        "fecha_de_desaparicion" as fecha_de_desaparicion,
        "fecha_de_localizacion" as fecha_de_localizacion,
        "dia_de_la_semana" as dia_de_la_semana,
        "horario" as horario,
        "dias_sin_localizar" as dias_sin_localizar,
        "rango_desaparicion" as rango_desaparicion,
        "reincidencia" as reincidencia,
        "numero_de_reincidencia" as numero_de_reincidencia,
        "estado" as estado,
        "region" as region,
        "municipio" as municipio,
        "estatus" as estatus,
        "desaparicion_multiple" as desaparicion_multiple,
        "persona_con_quien_desaparecio" as persona_con_quien_desaparecio
    from source
)

select * from renamed
