/*
===========================================================
Project: Behavioral Health Analytics
File: 05_metric_reliability_analysis.sql

Purpose:
Analyze the completeness and stability of smart-scale body
composition metrics to evaluate which metrics should be
emphasized in a health-tech app experience.

Business Context:
Smart scales provide many biometric estimates, but users may
misinterpret noisy or incomplete metrics. This analysis helps
identify which metrics are reliable enough for user-facing
progress insights.
===========================================================
*/

-------------------------------------------------------
-- Metric completeness overview
--
-- Business Question:
-- Which Renpho metrics have the most complete data?
-------------------------------------------------------

SELECT
    COUNT(*) AS total_measurements,
    COUNT(weight_lb) AS weight_records,
    COUNT(bmi) AS bmi_records,
    COUNT(body_fat_pct) AS body_fat_records,
    COUNT(fat_free_body_weight_lb) AS fat_free_body_weight_records,
    COUNT(subcutaneous_fat_pct) AS subcutaneous_fat_records,
    COUNT(visceral_fat) AS visceral_fat_records,
    COUNT(body_water_pct) AS body_water_records,
    COUNT(skeletal_muscle_pct) AS skeletal_muscle_records,
    COUNT(muscle_mass_lb) AS muscle_mass_records,
    COUNT(bone_mass_lb) AS bone_mass_records,
    COUNT(protein_pct) AS protein_records,
    COUNT(bmr_kcal) AS bmr_records,
    COUNT(metabolic_age) AS metabolic_age_records
FROM renpho_clean;

-------------------------------------------------------
-- Metric completeness percentage
--
-- Business Question:
-- What percentage of records are available for each metric?
-------------------------------------------------------

SELECT 'weight_lb' AS metric_name,
       ROUND(COUNT(weight_lb)::NUMERIC / COUNT(*) * 100, 2) AS completeness_pct
FROM renpho_clean

UNION ALL

SELECT 'body_fat_pct',
       ROUND(COUNT(body_fat_pct)::NUMERIC / COUNT(*) * 100, 2)
FROM renpho_clean

UNION ALL

SELECT 'muscle_mass_lb',
       ROUND(COUNT(muscle_mass_lb)::NUMERIC / COUNT(*) * 100, 2)
FROM renpho_clean

UNION ALL

SELECT 'body_water_pct',
       ROUND(COUNT(body_water_pct)::NUMERIC / COUNT(*) * 100, 2)
FROM renpho_clean

UNION ALL

SELECT 'skeletal_muscle_pct',
       ROUND(COUNT(skeletal_muscle_pct)::NUMERIC / COUNT(*) * 100, 2)
FROM renpho_clean

UNION ALL

SELECT 'bmr_kcal',
       ROUND(COUNT(bmr_kcal)::NUMERIC / COUNT(*) * 100, 2)
FROM renpho_clean

ORDER BY completeness_pct DESC;


-------------------------------------------------------
-- Metric volatility overview
--
-- Business Question:
-- Which metrics fluctuate the most across the tracking period?
--
-- Product Context:
-- Metrics with higher volatility may need to be shown with
-- additional context instead of being emphasized as single-day
-- progress indicators.
-------------------------------------------------------

SELECT
    ROUND(AVG(weight_lb)::NUMERIC, 2) AS avg_weight_lb,
    ROUND(STDDEV(weight_lb)::NUMERIC, 2) AS weight_stddev,
    ROUND(AVG(body_fat_pct)::NUMERIC, 2) AS avg_body_fat_pct,
    ROUND(STDDEV(body_fat_pct)::NUMERIC, 2) AS body_fat_stddev,
    ROUND(AVG(muscle_mass_lb)::NUMERIC, 2) AS avg_muscle_mass_lb,
    ROUND(STDDEV(muscle_mass_lb)::NUMERIC, 2) AS muscle_mass_stddev,
    ROUND(AVG(body_water_pct)::NUMERIC, 2) AS avg_body_water_pct,
    ROUND(STDDEV(body_water_pct)::NUMERIC, 2) AS body_water_stddev,
    ROUND(AVG(skeletal_muscle_pct)::NUMERIC, 2) AS avg_skeletal_muscle_pct,
    ROUND(STDDEV(skeletal_muscle_pct)::NUMERIC, 2) AS skeletal_muscle_stddev
FROM renpho_clean;

-------------------------------------------------------
-- Monthly body composition trends
--
-- Business Question:
-- Do body composition metrics show clear long-term patterns?
-------------------------------------------------------

SELECT
    DATE_TRUNC('month', measurement_date)::DATE AS measurement_month,
    ROUND(AVG(weight_lb), 2) AS avg_weight_lb,
    ROUND(AVG(body_fat_pct), 2) AS avg_body_fat_pct,
    ROUND(AVG(muscle_mass_lb), 2) AS avg_muscle_mass_lb,
    ROUND(AVG(body_water_pct), 2) AS avg_body_water_pct,
    ROUND(AVG(skeletal_muscle_pct), 2) AS avg_skeletal_muscle_pct,
    COUNT(*) AS total_measurements,
    COUNT(body_fat_pct) AS valid_body_composition_records
FROM renpho_clean
GROUP BY DATE_TRUNC('month', measurement_date)::DATE
ORDER BY measurement_month;