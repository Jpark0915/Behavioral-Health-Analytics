/*
===========================================================
Project: Behavioral Health Analytics
File: create_clean_table.sql

Purpose:
Create an analysis-ready Renpho table by converting raw
text fields into proper date, time, and numeric data types.

Cleaning Decisions:
- Preserve the raw imported table.
- Convert '--' placeholder values to NULL.
- Convert biometric fields from text to NUMERIC.
- Separate timestamp into date and time fields.
- Exclude Remarks because it is unstructured and not used
  for this analysis.
===========================================================
*/


DROP TABLE IF EXISTS renpho_clean;

CREATE TABLE renpho_clean AS
SELECT
    TO_TIMESTAMP("Time of Measurement", 'MM/DD/YYYY, HH24:MI:SS') AS measurement_timestamp,
    TO_TIMESTAMP("Time of Measurement", 'MM/DD/YYYY, HH24:MI:SS')::DATE AS measurement_date,
    TO_TIMESTAMP("Time of Measurement", 'MM/DD/YYYY, HH24:MI:SS')::TIME AS measurement_time,

    "Weight(lb)"::NUMERIC AS weight_lb,
    NULLIF("bmi", '--')::NUMERIC AS bmi,
    NULLIF("Body Fat(%)", '--')::NUMERIC AS body_fat_pct,
    NULLIF("Fat-free Body Weight(lb)", '--')::NUMERIC AS fat_free_body_weight_lb,
    NULLIF("Subcutaneous Fat(%)", '--')::NUMERIC AS subcutaneous_fat_pct,
    NULLIF("Visceral Fat", '--')::NUMERIC AS visceral_fat,
    NULLIF("Body Water(%)", '--')::NUMERIC AS body_water_pct,
    NULLIF("Skeletal Muscle(%)", '--')::NUMERIC AS skeletal_muscle_pct,
    NULLIF("Muscle Mass(lb)", '--')::NUMERIC AS muscle_mass_lb,
    NULLIF("Bone Mass(lb)", '--')::NUMERIC AS bone_mass_lb,
    NULLIF("Protein(%)", '--')::NUMERIC AS protein_pct,
    NULLIF("BMR(kcal)", '--')::NUMERIC AS bmr_kcal,
    NULLIF("Metabolic Age", '--')::NUMERIC AS metabolic_age
FROM renpho_jonathan_park;