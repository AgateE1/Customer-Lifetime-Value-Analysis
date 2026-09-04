-- Customer Lifetime Value — weekly registration cohorts, average revenue per user
--
-- Assigns every user to the week they first appear, sums their purchase revenue by week,
-- and divides by cohort size to get average revenue per user for weeks 0–12 since
-- registration. Output feeds the cumulative-growth and forecast tables in the workbook.
--
-- Source: `turing_data_analytics.raw_events` (BigQuery)
-- Cohorts: 2020-11-01 to 2021-01-24, weeks starting Sunday

WITH
  registration_cohorts AS (
    SELECT
      user_pseudo_id,
      DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(SUNDAY)) AS cohort_week
    FROM `turing_data_analytics.raw_events`
    GROUP BY user_pseudo_id
  ),

  weekly_revenue AS (
    SELECT
      user_pseudo_id,
      DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(SUNDAY)) AS revenue_week,
      SUM(purchase_revenue_in_usd) AS weekly_spend
    FROM `turing_data_analytics.raw_events`
    WHERE purchase_revenue_in_usd IS NOT NULL
    GROUP BY user_pseudo_id, revenue_week
  ),

  cohort_sizes AS (
    SELECT
      cohort_week,
      COUNT(DISTINCT user_pseudo_id) AS cohort_size
    FROM registration_cohorts
    GROUP BY cohort_week
  ),

  cohort_revenue AS (
    SELECT
      r.cohort_week,
      DATE_DIFF(w.revenue_week, r.cohort_week, WEEK) AS week_number,
      MAX(cs.cohort_size) AS cohort_size,
      SUM(w.weekly_spend) AS total_revenue
    FROM registration_cohorts r
    INNER JOIN weekly_revenue w
      ON r.user_pseudo_id = w.user_pseudo_id
      AND DATE_DIFF(w.revenue_week, r.cohort_week, WEEK) BETWEEN 0 AND 12
    INNER JOIN cohort_sizes cs
      ON r.cohort_week = cs.cohort_week
    WHERE r.cohort_week BETWEEN '2020-11-01' AND '2021-01-24'
    GROUP BY r.cohort_week, week_number
  )

SELECT
  cohort_week,
  week_number,
  total_revenue / cohort_size AS avg_revenue_per_user,
  cohort_size
FROM cohort_revenue
ORDER BY cohort_week, week_number;


-- ---------------------------------------------------------------------------
-- Validation
-- ---------------------------------------------------------------------------

-- Null check
/*
SELECT 'NULL Check' AS test, COUNT(*)
FROM `turing_data_analytics.raw_events`
WHERE event_date IS NULL OR user_pseudo_id IS NULL;
*/

-- Cohort sanity: are cohort sizes in a plausible range?
-- NOTE: the version of this check in the workbook filtered on MIN(event_date) inside a
-- WHERE clause, which BigQuery rejects (aggregates are not allowed in WHERE). Rewritten
-- below to derive cohorts first and filter afterwards. Run it before committing.
/*
WITH
  reg_cohorts AS (
    SELECT
      user_pseudo_id,
      DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(SUNDAY)) AS cohort_week
    FROM `turing_data_analytics.raw_events`
    GROUP BY user_pseudo_id
  ),
  sizes AS (
    SELECT cohort_week, COUNT(DISTINCT user_pseudo_id) AS size
    FROM reg_cohorts
    WHERE cohort_week BETWEEN '2020-11-01' AND '2021-01-24'
    GROUP BY cohort_week
  )
SELECT
  'Cohort Distribution' AS test,
  MIN(size) AS min_cohort,
  MAX(size) AS max_cohort,
  ROUND(AVG(size), 0) AS avg_cohort
FROM sizes;
*/

-- Row-count reconciliation across pipeline stages
/*
SELECT 'Raw Events' AS stage, COUNT(*) AS row_count, COUNT(DISTINCT user_pseudo_id) AS users
FROM `turing_data_analytics.raw_events`
UNION ALL
SELECT 'With Purchase Revenue', COUNT(*), COUNT(DISTINCT user_pseudo_id)
FROM `turing_data_analytics.raw_events`
WHERE purchase_revenue_in_usd IS NOT NULL
UNION ALL
SELECT 'In Cohort Date Range', COUNT(*), COUNT(DISTINCT user_pseudo_id)
FROM `turing_data_analytics.raw_events`
WHERE DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(SUNDAY))
      BETWEEN '2020-11-01' AND '2021-01-24';
*/
