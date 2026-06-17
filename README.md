# Customer Lifetime Value & Customer Segmentation

Predicting customer lifetime value (CLV) from weekly registration cohorts and segmenting customers with RFM analysis, using BigQuery.

## Overview

This project covers two complementary pieces of customer-value analytics:

1. **CLV / LTV prediction** — Groups users into weekly registration cohorts, tracks average revenue per user over the first 12 weeks, builds cumulative growth curves, and forecasts the remaining weeks to estimate lifetime value.
2. **RFM segmentation** — Scores customers on Recency, Frequency, and Monetary value, then groups them into actionable segments (Best Customers, Loyal Customers, Big Spenders, At-Risk, and more).

Together they answer two questions: *how much is a user worth over time?* and *which customers should we focus on?*

## Goals

- Estimate the lifetime value of a user based on cohort revenue behavior.
- Understand how revenue per cohort evolves and decays week over week.
- Forecast cumulative revenue for incomplete cohorts to project a 12-week LTV.
- Segment the customer base into meaningful groups to guide retention and marketing.

## Datasets

Both datasets are queried from BigQuery.

**CLV / cohort analysis** — `turing_data_analytics.raw_events`

| Field | Description |
|-------|-------------|
| `user_pseudo_id` | Anonymous user identifier |
| `event_date` | Event date (used to derive registration cohort) |
| `purchase_revenue_in_usd` | Revenue per purchase |

Users were bucketed into weekly registration cohorts (week starting Sunday), covering cohorts from **2020-11-01 to 2021-01-24**, tracked across weeks 0–12 since registration.

**RFM segmentation** — `tc-da-1.turing_data_analytics.rfm`

| Field | Description |
|-------|-------------|
| `CustomerID` | Customer identifier |
| `InvoiceNo` | Order identifier (used for frequency) |
| `Quantity`, `UnitPrice` | Used to compute order value (monetary) |
| `InvoiceDate` | Order date (used for recency) |
| `Country` | Customer country |

Filtered to transactions from **2010-12-01 to 2011-12-02**, excluding null customers and non-positive quantities/prices.

## Methodology

### CLV / LTV

1. **Cohort assignment** — Each user's first event week defines their registration cohort.
2. **Weekly revenue** — Summed `purchase_revenue_in_usd` per user per week.
3. **Cohort sizing** — Counted distinct users per cohort.
4. **Revenue per user** — Joined revenue to cohorts and divided by cohort size, by weeks-since-registration (0–12).
5. **Cumulative growth** — Accumulated weekly revenue per cohort and computed period-over-period growth.
6. **Forecasting** — Projected cumulative revenue for incomplete cohorts to reach a full 12-week estimate.
7. **Validation** — Null checks, cohort-size sanity checks, and row-count reconciliation across pipeline stages.

### RFM segmentation

1. **Metric calculation** — Recency (days since last order), Frequency (distinct orders), Monetary (total order value) per customer.
2. **Quartile scoring** — Used `APPROX_QUANTILES` to score each metric on a 1–4 scale.
3. **Segmentation** — Applied rule-based logic on the combined R/F/M scores to assign segments.
4. **Validation** — Checked segment distribution, unclassified customers, and at-risk/lost customer trends.

Segments defined: **Best Customers, Loyal Customers, Big Spenders, Promotion-Driven, At-Risk, One-Time Purchasers, Lost Customers.**

## Key findings

- **Predicted 12-week LTV ≈ 1.47** (cumulative revenue per user).
- The largest cohort was acquired on **2020-12-06** (peak acquisition week).
- Cohorts spend strongly in week 1, then decline steadily through week 12.
- Cumulative growth slows sharply, bottoms out around week 9, then recovers slightly.
- **Cohort 2020-12-13** is the inflection point where positive growth shifts to a slower trajectory.
- Actual cumulative revenue is **beating forecast across all periods**.

### Why this happened

The acquisition spike and later decline line up with seasonality: **Black Friday / Cyber Monday (from 2020-11-27)** inflated sales through promotions and seasonal buying, while the **Christmas / New Year** period is typically slower. These external factors explain both the early surge and the subsequent drop-off rather than any change in product or pricing.

## Limitations

- The 12-week window captures only short-term value; true lifetime value extends further.
- Cohort behavior is heavily influenced by the holiday season, so estimates may not generalize to other periods.
- One cohort (2020-11-08) had a data gap (zero completions in week 8).
- The forecast assumes the observed decay pattern continues; structural changes in behavior would shift the projection.
- The CLV and RFM analyses use different datasets and time ranges, so segment definitions are not directly tied to the cohort LTV figures.

## Tools

- **BigQuery** — cohort construction, revenue aggregation, RFM scoring, and validation (CTEs, `APPROX_QUANTILES`, date functions)
- **Spreadsheet analysis** — cumulative growth tables, forecasting, and LTV estimation

## Repository structure

```
.
├── sql/
│   ├── clv_cohort_revenue.sql     # cohort build + avg revenue per user
│   └── rfm_segmentation.sql       # RFM scoring + segment logic
├── analysis/                      # cumulative growth, forecast, LTV
└── README.md
```
