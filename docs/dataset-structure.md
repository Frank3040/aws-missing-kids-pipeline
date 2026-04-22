# Dataset Description and Processing Plan for LLM

Consider the dataset name is 'base-desapariciones-dataton-2025.csv'

## 1. Dataset Overview
- **Topic:** Records of missing children in the state of Chiapas, Mexico.
- **Time Period Covered:** from 2019 to 2025.

## 2. Data Schema and Column Descriptions
Below is a detailed breakdown of each column in the dataset.

- **`Sexo`**
    - **Type:** `string`
    - **Description:** The gender of the missing person.
    - **Example Values:** "Mujer", "Hombre".

- **`Edad`**
    - **Type:** `int`
    - **Description:** The age of the person at the time of disappearance.

- **`Grupo etario`**
    - **Type:** `string`
    - **Description:** The age group category the person belongs to.
    - **Example Values:** "12 a 17".

- **`Municipio`**
    - **Type:** `string`
    - **Description:** The municipality in Chiapas where the person was last seen.

- **`Región`**
    - **Type:** `string`
    - **Description:** The broader geographical region within Chiapas.
    - **Example Values:** "Metropolitana".

- **`Colonia/Localidad`**
    - **Type:** `string`
    - **Description:** The specific neighborhood or locality. Contains "No especificado" for unknown values.

- **`Migrante`**
    - **Type:** `string`
    - **Description:** A flag indicating if the person is a migrant or the place it comes from.

- **`Fecha de desaparición`**
    - **Type:** `string` (datetime)
    - **Description:** The date the person went missing.

- **`Día de la semana`**
    - **Type:** `string`
    - **Description:** The day of the week the disappearance occurred.

- **`Horario`**
    - **Type:** `string`
    - **Description:** The time of day the disappearance occurred.

- **`Estatus`**
    - **Type:** `string`
    - **Description:** The current status of the case.

- **`Fecha de localización`**
    - **Type:** `string`
    - **Description:** The date the person was found.

- **`Días sin localizar`**
    - **Type:** `string`
    - **Description:** The number of days the person was missing.

- **`Rango desaparición`**
    - **Type:** `string`
    - **Description:** A categorical range for the duration of the disappearance. Contains "No aplica" / "No especificada".

- **`Reincidencia`**
    - **Type:** `string`
    - **Description:** A flag indicating if this is a recurring disappearance for the same person.
    - **Example Values:** "No", "Sí".

- **`Número de reincidencia`**
    - **Type:** `string`
    - **Description:** The count of previous disappearances. Contains "No aplica".

- **`Desaparición múltiple`**
    - **Type:** `string`
    - **Description:** A flag indicating if the person disappeared with others.

- **`Persona con quién desapareció`**
    - **Type:** `string`
    - **Description:** Name or description of the person they disappeared with.

- **`Hipótesis`**
    - **Type:** `string`
    - **Description:** The initial hypothesis about the cause of disappearance.

- **`Fuente`**
    - **Type:** `string`
    - **Description:** The source of the information for the record.

- **`Sistematizó`**
    - **Type:** `string`
    - **Description:** The person or entity that recorded the data entry.
