

list_columns = ["sexo",
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
    "persona con quién desapareció"]




for column in list_columns:
    column = column.replace(" ", "_")
    print(column)