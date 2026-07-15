/*
===========================================================
Project: Behavioral Health Analytics
File: 04_exploratory_analysis.sql

Purpose:
Analyze the cleaned Renpho dataset to identify long-term
weight, body composition, and measurement trends.

Business Context:
This analysis supports product recommendations for how a
health-tech app should communicate biometric progress to users.
===========================================================
*/

-- Overall date range and dataset size 

SELECT
    COUNT(*) AS total_measurements,
    MIN(measurement_date) AS first_measurement,
    MAX(measurement_date) AS latest_measurement
FROM renpho_clean;

-------------------------------------------------------
-- Earliest recorded weight
--
-- Business Question:
-- What was the user's starting weight at the beginning
-- of the tracking period?
-------------------------------------------------------

SELECT 
    measurement_timestamp,
    measurement_date,
    weight_lb
FROM renpho_clean
ORDER BY measurement_timestamp ASC
LIMIT 1;

-------------------------------------------------------
-- Latest recorded weight
--
-- Business Question:
-- What was the user's most recent recorded weight?
-------------------------------------------------------

SELECT 
    measurement_timestamp,
    measurement_date,
    weight_lb
FROM renpho_clean
ORDER BY measurement_timestamp DESC
LIMIT 1;
	
-------------------------------------------------------
-- Total weight change from earliest to latest measurement
--
-- Business Question:
-- How much did body weight change across the full
-- tracking period?
-------------------------------------------------------

WITH first_record AS (
    SELECT
        measurement_date,
        weight_lb
    FROM renpho_clean
    ORDER BY measurement_timestamp ASC
    LIMIT 1
),
latest_record AS (
    SELECT
        measurement_date,
        weight_lb
    FROM renpho_clean
    ORDER BY measurement_timestamp DESC
    LIMIT 1
)
SELECT
    first_record.measurement_date AS first_date,
    first_record.weight_lb AS first_weight,
    latest_record.measurement_date AS latest_date,
    latest_record.weight_lb AS latest_weight,
    ROUND(latest_record.weight_lb - first_record.weight_lb, 2) AS total_weight_change_lb,
    ROUND(
        ((latest_record.weight_lb - first_record.weight_lb) / first_record.weight_lb) * 100, 
        2
    ) AS percent_weight_change
FROM first_record
CROSS JOIN latest_record;

-------------------------------------------------------
-- Monthly trends for key progress metrics
--
-- Business Question:
-- Do monthly averages provide a clearer view of progress
-- than individual daily measurements?
--
-- DATE_TRUNC('month') groups measurements by each
-- month-year period, allowing long-term trends to be
-- analyzed over time.
-------------------------------------------------------

SELECT
    DATE_TRUNC('month', measurement_date)::DATE AS measurement_month,
    ROUND(AVG(weight_lb), 2) AS avg_weight_lb,
    ROUND(AVG(body_fat_pct), 2) AS avg_body_fat_pct,
    ROUND(AVG(muscle_mass_lb), 2) AS avg_muscle_mass_lb,
    COUNT(*) AS total_measurements,
    COUNT(body_fat_pct) AS valid_body_fat_measurements,
    COUNT(muscle_mass_lb) AS valid_muscle_mass_measurements
FROM renpho_clean
GROUP BY DATE_TRUNC('month', measurement_date)
ORDER BY measurement_month;

-------------------------------------------------------
-- Highest average weight month
--
-- Business Question:
-- Which month had the highest average body weight?
-------------------------------------------------------

WITH monthly_trends AS (
    SELECT 
        DATE_TRUNC('month', measurement_date)::DATE AS measurement_month,
        ROUND(AVG(weight_lb), 2) AS avg_weight_lb
    FROM renpho_clean
    GROUP BY DATE_TRUNC('month', measurement_date)::DATE
)
SELECT 
    *
FROM monthly_trends
ORDER BY avg_weight_lb DESC
LIMIT 1;


-------------------------------------------------------
-- Lowest average weight month
--
-- Business Question:
-- Which month had the lowest average body weight?
-------------------------------------------------------

WITH monthly_trends AS (
    SELECT 
        DATE_TRUNC('month', measurement_date)::DATE AS measurement_month,
        ROUND(AVG(weight_lb), 2) AS avg_weight_lb
    FROM renpho_clean
    GROUP BY DATE_TRUNC('month', measurement_date)::DATE
)
SELECT 
    *
FROM monthly_trends
ORDER BY avg_weight_lb ASC
LIMIT 1;


-------------------------------------------------------
-- Biggest week-over-week weight increases
--
-- Business Question:
-- Which weeks had the largest increases in average weight?
-------------------------------------------------------

WITH weekly_averages AS (
    SELECT 
        DATE_TRUNC('week', measurement_date)::DATE AS measurement_week,
        ROUND(AVG(weight_lb), 2) AS avg_weight_lb,
        COUNT(*) AS measurement_count
    FROM renpho_clean
    GROUP BY DATE_TRUNC('week', measurement_date)::DATE
),
weekly_change AS (
    SELECT
        measurement_week,
        avg_weight_lb,
        LAG(avg_weight_lb) OVER (ORDER BY measurement_week) AS previous_week_avg_weight,
        ROUND(
            avg_weight_lb - LAG(avg_weight_lb) OVER (ORDER BY measurement_week),
            2
        ) AS week_over_week_weight_change,
        measurement_count
    FROM weekly_averages
)
SELECT
    *
FROM weekly_change
where week_over_week_weight_change is not NULL
ORDER BY week_over_week_weight_change DESC 
limit 5;

-------------------------------------------------------
-- Biggest week-over-week weight decreases
--
-- Business Question:
-- Which weeks had the largest decreases in average weight?
-------------------------------------------------------

WITH weekly_averages AS (
    SELECT 
        DATE_TRUNC('week', measurement_date)::DATE AS measurement_week,
        ROUND(AVG(weight_lb), 2) AS avg_weight_lb,
        COUNT(*) AS measurement_count
    FROM renpho_clean
    GROUP BY DATE_TRUNC('week', measurement_date)::DATE
),
weekly_change AS (
    SELECT
        measurement_week,
        avg_weight_lb,
        LAG(avg_weight_lb) OVER (ORDER BY measurement_week) AS previous_week_avg_weight,
        ROUND(
            avg_weight_lb - LAG(avg_weight_lb) OVER (ORDER BY measurement_week),
            2
        ) AS week_over_week_weight_change,
        measurement_count
    FROM weekly_averages
)
SELECT
    *
FROM weekly_change
where week_over_week_weight_change is not NULL
ORDER BY week_over_week_weight_change ASC 
limit 5;

-------------------------------------------------------
-- Biggest daily weight decreases
--
-- Business Question:
-- Which measurement days showed the largest decreases
-- in average body weight compared to the previous
-- measurement day?
-------------------------------------------------------

WITH daily_averages AS (
    SELECT 
        measurement_date AS measurement_day,
        ROUND(AVG(weight_lb), 2) AS avg_daily_weight_lb,
        COUNT(*) AS measurement_count
    FROM renpho_clean
    GROUP BY measurement_date
),
daily_change AS (
    SELECT
        measurement_day,
        avg_daily_weight_lb,
        LAG(avg_daily_weight_lb) OVER (ORDER BY measurement_day) AS previous_day_avg_weight,
        ROUND(
            avg_daily_weight_lb - LAG(avg_daily_weight_lb) OVER (ORDER BY measurement_day),
            2
        ) AS daily_weight_change,
        measurement_count
    FROM daily_averages
)
SELECT
    *
FROM daily_change
WHERE daily_weight_change IS NOT NULL
ORDER BY daily_weight_change ASC
LIMIT 10;

-------------------------------------------------------
-- Biggest daily weight increases
--
-- Business Question:
-- Which measurement days showed the largest increases
-- in average body weight compared to the previous
-- measurement day?
-------------------------------------------------------

WITH daily_averages AS (
    SELECT 
        measurement_date AS measurement_day,
        ROUND(AVG(weight_lb), 2) AS avg_daily_weight_lb,
        COUNT(*) AS measurement_count
    FROM renpho_clean
    GROUP BY measurement_date
),
daily_change AS (
    SELECT
        measurement_day,
        avg_daily_weight_lb,
        LAG(avg_daily_weight_lb) OVER (ORDER BY measurement_day) AS previous_day_avg_weight,
        ROUND(
            avg_daily_weight_lb - LAG(avg_daily_weight_lb) OVER (ORDER BY measurement_day),
            2
        ) AS daily_weight_change,
        measurement_count
    FROM daily_averages
)
SELECT
    *
FROM daily_change
WHERE daily_weight_change IS NOT NULL
ORDER BY daily_weight_change DESC
LIMIT 10;

-------------------------------------------------------
-- 7-day rolling average weight trend
--
-- Business Question:
-- Does a 7-day rolling average provide a clearer view
-- of weight progress than individual daily measurements?
--
-- Product Context:
-- Rolling averages can reduce the impact of short-term
-- weight fluctuations caused by hydration, sodium, food
-- intake, glycogen, and measurement timing.
-------------------------------------------------------

WITH daily_averages AS (
    SELECT 
        measurement_date AS measurement_day,
        ROUND(AVG(weight_lb), 2) AS avg_daily_weight_lb,
        COUNT(*) AS measurement_count
    FROM renpho_clean
    GROUP BY measurement_date
)
SELECT
    measurement_day,
    avg_daily_weight_lb,
    ROUND(
        AVG(avg_daily_weight_lb) OVER (
            ORDER BY measurement_day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_7_day_avg_weight,
    measurement_count
FROM daily_averages
ORDER BY measurement_day;

-------------------------------------------------------
-- Measurement consistency analysis
--
-- Business Question:
-- How consistently did the user record measurements,
-- and how might measurement gaps affect trend reliability?
--
-- Product Context:
-- Smart-scale trend insights are more useful when users
-- measure consistently. Large gaps may reduce confidence
-- in rolling averages, weekly trends, or plateau detection.
-------------------------------------------------------

-------------------------------------------------------
-- Measurement frequency by month
--
-- Business Question:
-- How often were measurements recorded each month?
-------------------------------------------------------

SELECT
    DATE_TRUNC('month', measurement_date)::DATE AS measurement_month,
    COUNT(*) AS total_measurements,
    COUNT(DISTINCT measurement_date) AS measurement_days
FROM renpho_clean
GROUP BY DATE_TRUNC('month', measurement_date)::DATE
ORDER BY measurement_month;


-------------------------------------------------------
-- Monthly measurement coverage
--
-- Business Question:
-- What percentage of days in each month included
-- at least one recorded measurement?
-------------------------------------------------------

WITH monthly_measurements AS (
    SELECT
        DATE_TRUNC('month', measurement_date)::DATE AS measurement_month,
        COUNT(DISTINCT measurement_date) AS measurement_days
    FROM renpho_clean
    GROUP BY DATE_TRUNC('month', measurement_date)::DATE
)
SELECT
    measurement_month,
    measurement_days,
    EXTRACT(
        DAY FROM measurement_month + INTERVAL '1 month - 1 day'
    )::INT AS days_in_month,
    ROUND(
        measurement_days::NUMERIC / 
        EXTRACT(DAY FROM measurement_month + INTERVAL '1 month - 1 day') * 100,
        2
    ) AS measurement_coverage_pct
FROM monthly_measurements
ORDER BY measurement_month;

-------------------------------------------------------
-- Gaps between measurement days
--
-- Business Question:
-- How many days passed between recorded measurements?
-------------------------------------------------------

WITH daily_measurements AS (
    SELECT
        measurement_date AS measurement_day,
        COUNT(*) AS measurements_that_day
    FROM renpho_clean
    GROUP BY measurement_date
),
measurement_gaps AS (
    SELECT
        measurement_day,
        LAG(measurement_day) OVER (ORDER BY measurement_day) AS previous_measurement_day,
        measurement_day - LAG(measurement_day) OVER (ORDER BY measurement_day) AS days_since_previous_measurement,
        measurements_that_day
    FROM daily_measurements
)
SELECT
    *
FROM measurement_gaps
WHERE days_since_previous_measurement IS NOT NULL
ORDER BY measurement_day;

-------------------------------------------------------
-- Longest measurement gaps
--
-- Business Question:
-- What were the longest gaps between recorded measurements?
-------------------------------------------------------

WITH daily_measurements AS (
    SELECT
        measurement_date AS measurement_day,
        COUNT(*) AS measurements_that_day
    FROM renpho_clean
    GROUP BY measurement_date
),
measurement_gaps AS (
    SELECT
        measurement_day,
        LAG(measurement_day) OVER (ORDER BY measurement_day) AS previous_measurement_day,
        measurement_day - LAG(measurement_day) OVER (ORDER BY measurement_day) AS days_since_previous_measurement
    FROM daily_measurements
)
SELECT
    *
FROM measurement_gaps
WHERE days_since_previous_measurement IS NOT NULL
ORDER BY days_since_previous_measurement DESC
LIMIT 10;