/*
===========================================================
Project: Behavioral Health Analytics
File: 06_phase_progress_analysis.sql

Purpose:
Analyze progress across fitness phases to determine whether
trend-based metrics reflect the user's intended goal.

Business Context:
Health-tech apps should help users understand whether their
progress aligns with their current goal, such as gaining,
losing, or maintaining weight.
===========================================================
*/

-------------------------------------------------------
-- Label measurements by estimated fitness phase
--
-- Business Question:
-- Which records belong to each major goal phase?
--
-- Note:
-- Earlier phase dates are estimated based on personal
-- training history and should be interpreted as approximate.
-------------------------------------------------------

WITH phase_labels AS (
    SELECT
        measurement_date,
        weight_lb,
        body_fat_pct,
        muscle_mass_lb,
        CASE
            WHEN measurement_date BETWEEN DATE '2023-11-20' AND DATE '2024-08-04'
                THEN 'Bulk 1 - Estimated'

            WHEN measurement_date BETWEEN DATE '2024-08-26' AND DATE '2024-12-15'
                THEN 'Cut 1 - Estimated'

            WHEN measurement_date BETWEEN DATE '2025-02-01' AND DATE '2026-04-14'
                THEN 'Bulk 2'

            WHEN measurement_date BETWEEN DATE '2026-04-15' AND DATE '2026-07-15'
                THEN 'Cut 2'

            ELSE 'Transition / Unlabeled'
        END AS fitness_phase
    FROM renpho_clean
)
SELECT
    *
FROM phase_labels
ORDER BY measurement_date;

-------------------------------------------------------
-- Phase-level progress summary
--
-- Business Question:
-- How did average weight and body composition differ
-- across estimated fitness phases?
--
-- Note:
-- Earlier phase dates are estimated based on personal
-- training history and should be interpreted as approximate.
-------------------------------------------------------

WITH phase_labels AS (
    SELECT
        measurement_date,
        weight_lb,
        body_fat_pct,
        muscle_mass_lb,
        CASE
            WHEN measurement_date BETWEEN DATE '2023-11-20' AND DATE '2024-08-04'
                THEN 'Bulk 1 - Estimated'

            WHEN measurement_date BETWEEN DATE '2024-08-26' AND DATE '2024-12-15'
                THEN 'Cut 1 - Estimated'

            WHEN measurement_date BETWEEN DATE '2025-02-01' AND DATE '2026-04-14'
                THEN 'Bulk 2'

            WHEN measurement_date BETWEEN DATE '2026-04-15' AND DATE '2026-07-15'
                THEN 'Cut 2'

            ELSE 'Transition / Unlabeled'
        END AS fitness_phase
    FROM renpho_clean
)
SELECT
    fitness_phase,
    COUNT(*) AS total_measurements,
    MIN(measurement_date) AS phase_start_date,
    MAX(measurement_date) AS phase_end_date,
    ROUND(AVG(weight_lb), 2) AS avg_weight_lb,
    ROUND(MIN(weight_lb), 2) AS min_weight_lb,
    ROUND(MAX(weight_lb), 2) AS max_weight_lb,
    ROUND(MAX(weight_lb) - MIN(weight_lb), 2) AS weight_range_lb,
    ROUND(AVG(body_fat_pct), 2) AS avg_body_fat_pct,
    ROUND(AVG(muscle_mass_lb), 2) AS avg_muscle_mass_lb
FROM phase_labels
GROUP BY fitness_phase
ORDER BY phase_start_date;

-------------------------------------------------------
-- Start-to-end weight change by fitness phase
--
-- Business Question:
-- Did weight move in the intended direction during
-- each fitness phase?
--
-- Product Context:
-- Goal context matters. A weight increase may be positive
-- during a bulking phase, while a weight decrease may be
-- positive during a cutting phase.
-------------------------------------------------------

WITH phase_labels AS (
    SELECT
        measurement_timestamp,
        measurement_date,
        weight_lb,
        body_fat_pct,
        muscle_mass_lb,
        CASE
            WHEN measurement_date BETWEEN DATE '2023-11-20' AND DATE '2024-08-04'
                THEN 'Bulk 1 - Estimated'

            WHEN measurement_date BETWEEN DATE '2024-08-26' AND DATE '2024-12-15'
                THEN 'Cut 1 - Estimated'

            WHEN measurement_date BETWEEN DATE '2025-02-01' AND DATE '2026-04-14'
                THEN 'Bulk 2'

            WHEN measurement_date BETWEEN DATE '2026-04-15' AND DATE '2026-07-15'
                THEN 'Cut 2'

            ELSE 'Transition / Unlabeled'
        END AS fitness_phase
    FROM renpho_clean
),
phase_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY fitness_phase
            ORDER BY measurement_timestamp ASC
        ) AS first_record_rank,
        ROW_NUMBER() OVER (
            PARTITION BY fitness_phase
            ORDER BY measurement_timestamp DESC
        ) AS latest_record_rank
    FROM phase_labels
)
SELECT
    fitness_phase,
    MIN(CASE WHEN first_record_rank = 1 THEN measurement_date END) AS phase_start_date,
    MIN(CASE WHEN latest_record_rank = 1 THEN measurement_date END) AS phase_end_date,
    MAX(CASE WHEN first_record_rank = 1 THEN weight_lb END) AS starting_weight_lb,
    MAX(CASE WHEN latest_record_rank = 1 THEN weight_lb END) AS ending_weight_lb,
    ROUND(
        MAX(CASE WHEN latest_record_rank = 1 THEN weight_lb END)
        - MAX(CASE WHEN first_record_rank = 1 THEN weight_lb END),
        2
    ) AS phase_weight_change_lb,
    CASE
        WHEN fitness_phase ILIKE 'Bulk%' 
             AND MAX(CASE WHEN latest_record_rank = 1 THEN weight_lb END)
                 > MAX(CASE WHEN first_record_rank = 1 THEN weight_lb END)
            THEN 'Aligned with bulking goal'
        WHEN fitness_phase ILIKE 'Cut%' 
             AND MAX(CASE WHEN latest_record_rank = 1 THEN weight_lb END)
                 < MAX(CASE WHEN first_record_rank = 1 THEN weight_lb END)
            THEN 'Aligned with cutting goal'
        WHEN fitness_phase = 'Transition / Unlabeled'
            THEN 'No clear goal phase'
        ELSE 'Not aligned or needs review'
    END AS goal_alignment
FROM phase_ranked
GROUP BY fitness_phase
ORDER BY phase_start_date;