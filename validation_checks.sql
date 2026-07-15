/*
===========================================================
Project: Behavioral Health Analytics
File: validation_checks.sql

Purpose:
Validate the cleaned Renpho table before exploratory and
business analysis.
===========================================================
*/


-------------------------------------------------------
-- 1. Confirm no rows were lost during cleaning
-------------------------------------------------------

SELECT 
    (SELECT COUNT(*) FROM renpho_jonathan_park) AS raw_row_count,
    (SELECT COUNT(*) FROM renpho_clean) AS clean_row_count;


-------------------------------------------------------
-- 2. Validate measurement date range
-------------------------------------------------------

SELECT
    MIN(measurement_date) AS earliest_measurement,
    MAX(measurement_date) AS latest_measurement
FROM renpho_clean;


-------------------------------------------------------
-- 3. Check valid row counts after cleaning
-------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(weight_lb) AS valid_weight_rows,
    COUNT(bmi) AS valid_bmi_rows,
    COUNT(body_fat_pct) AS valid_body_fat_rows,
    COUNT(muscle_mass_lb) AS valid_muscle_mass_rows,
    COUNT(body_water_pct) AS valid_body_water_rows,
    COUNT(bmr_kcal) AS valid_bmr_rows
FROM renpho_clean;


-------------------------------------------------------
-- 4. Identify date range of missing body composition values
-------------------------------------------------------

SELECT
    MIN(measurement_date) AS earliest_missing_date,
    MAX(measurement_date) AS latest_missing_date,
    COUNT(*) AS missing_rows
FROM renpho_clean
WHERE body_fat_pct IS NULL;