/*
===========================================================
Project: Behavioral Health Analytics
File: data_quality_audit.sql

Purpose:
Audit the raw Renpho smart-scale export before creating
an analysis-ready table.

Business Context:
The project evaluates how a health-tech product communicates
biometric progress to users. Before analyzing trends, the raw
data must be reviewed for missing values, placeholder values,
date formatting issues, and measurement completeness.
===========================================================
*/


-------------------------------------------------------
-- 1. Preview raw dataset
-------------------------------------------------------

SELECT *
FROM renpho_jonathan_park
;


-------------------------------------------------------
-- 2. Confirm dataset size
-------------------------------------------------------

SELECT 
    COUNT(*) AS total_rows
FROM renpho_jonathan_park;


-------------------------------------------------------
-- 3. Validate measurement date range
--
-- The raw timestamp is stored as text, so it must be
-- converted before calculating the true earliest and
-- latest measurements.
-------------------------------------------------------

SELECT 
    MIN(TO_TIMESTAMP("Time of Measurement", 'MM/DD/YYYY, HH24:MI:SS')) AS earliest_measurement,
    MAX(TO_TIMESTAMP("Time of Measurement", 'MM/DD/YYYY, HH24:MI:SS')) AS latest_measurement
FROM renpho_jonathan_park;


-------------------------------------------------------
-- 4. Check hidden blank values in key columns
-------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN "Time of Measurement" IS NULL OR TRIM("Time of Measurement") = '' THEN 1 ELSE 0 END) AS missing_time,
    SUM(CASE WHEN "Weight(lb)" IS NULL OR TRIM("Weight(lb)") = '' THEN 1 ELSE 0 END) AS missing_weight,
    SUM(CASE WHEN "Body Fat(%)" IS NULL OR TRIM("Body Fat(%)") = '' OR "Body Fat(%)" = '--' THEN 1 ELSE 0 END) AS missing_body_fat
FROM renpho_jonathan_park;


-------------------------------------------------------
-- 5. Count placeholder values across body composition fields
--
-- Several Renpho fields use '--' to represent unavailable
-- estimates. These should be treated as NULL, not zero.
-------------------------------------------------------

SELECT
    SUM(CASE WHEN "Body Fat(%)" = '--' THEN 1 ELSE 0 END) AS missing_body_fat,
    SUM(CASE WHEN "Fat-free Body Weight(lb)" = '--' THEN 1 ELSE 0 END) AS missing_fat_free_body_weight,
    SUM(CASE WHEN "Subcutaneous Fat(%)" = '--' THEN 1 ELSE 0 END) AS missing_subcutaneous_fat,
    SUM(CASE WHEN "Visceral Fat" = '--' THEN 1 ELSE 0 END) AS missing_visceral_fat,
    SUM(CASE WHEN "Body Water(%)" = '--' THEN 1 ELSE 0 END) AS missing_body_water,
    SUM(CASE WHEN "Skeletal Muscle(%)" = '--' THEN 1 ELSE 0 END) AS missing_skeletal_muscle,
    SUM(CASE WHEN "Muscle Mass(lb)" = '--' THEN 1 ELSE 0 END) AS missing_muscle_mass,
    SUM(CASE WHEN "Bone Mass(lb)" = '--' THEN 1 ELSE 0 END) AS missing_bone_mass,
    SUM(CASE WHEN "Protein(%)" = '--' THEN 1 ELSE 0 END) AS missing_protein,
    SUM(CASE WHEN "BMR(kcal)" = '--' THEN 1 ELSE 0 END) AS missing_bmr,
    SUM(CASE WHEN "Metabolic Age" = '--' THEN 1 ELSE 0 END) AS missing_metabolic_age
FROM renpho_jonathan_park;


-------------------------------------------------------
-- 6. Verify whether missing body composition values occur
--    in the same rows
-------------------------------------------------------

SELECT
    COUNT(*) AS rows_missing_body_composition
FROM renpho_jonathan_park
WHERE "Body Fat(%)" = '--'
  AND "Fat-free Body Weight(lb)" = '--'
  AND "Subcutaneous Fat(%)" = '--'
  AND "Visceral Fat" = '--'
  AND "Body Water(%)" = '--'
  AND "Skeletal Muscle(%)" = '--'
  AND "Muscle Mass(lb)" = '--'
  AND "Bone Mass(lb)" = '--'
  AND "Protein(%)" = '--'
  AND "BMR(kcal)" = '--'
  AND "Metabolic Age" = '--';


-------------------------------------------------------
-- 7. Identify date range of missing body composition values
-------------------------------------------------------

SELECT
    MIN(TO_TIMESTAMP("Time of Measurement", 'MM/DD/YYYY, HH24:MI:SS')) AS earliest_missing_measurement,
    MAX(TO_TIMESTAMP("Time of Measurement", 'MM/DD/YYYY, HH24:MI:SS')) AS latest_missing_measurement,
    COUNT(*) AS missing_rows
FROM renpho_jonathan_park
WHERE "Body Fat(%)" = '--';