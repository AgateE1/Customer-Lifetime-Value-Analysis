[README.md](https://github.com/user-attachments/files/31844741/README.md)
# Customer Lifetime Value & RFM Segmentation

**What is a user worth over their first three months, and which customers deserve the
marketing budget?**

Two complementary pieces of customer-value analytics in BigQuery: an LTV forecast built from
weekly registration cohorts, and an RFM segmentation that sorts the customer base into seven
actionable groups.

**Headline:** projected **12-week LTV ≈ $1.47 in cumulative revenue per user**. Actual
cumulative revenue is running ahead of forecast in every period, and the acquisition spike
and subsequent decay track the Black Friday → Christmas cycle rather than any change in
product or pricing.

<!-- Add the cumulative-revenue-per-user curve here, exported from the workbook:
![Cumulative revenue per user by cohort week](images/clv-cumulative-curve.png) -->

**Full workbook:** [Google Sheets](https://docs.google.com/spreadsheets/d/1V8RU_zTwhAfx7iabQ1ZvmPWoIhl1pcmEAs5I6KIfyfk/edit?usp=sharing) · **Write-up:** [clv-analysis.pdf](clv-analysis.pdf)

---

## What the two analyses answer

1. **CLV / LTV prediction** — groups users into weekly registration cohorts, tracks average
   revenue per user across the first 12 weeks, builds cumulative growth curves, and forecasts
   the remaining weeks for cohorts that are not yet complete.
2. **RFM segmentation** — scores customers on Recency, Frequency and Monetary value, then
   groups them into Best Customers, Loyal Customers, Big Spenders, Promotion-Driven, At-Risk,
   One-Time Purchasers and Lost Customers.

## Data

**CLV / cohort analysis** — `turing_data_analytics.raw_events`

| Field | Description |
|---|---|
| `user_pseudo_id` | Anonymous user identifier |
| `event_date` | Event date (used to derive the registration cohort) |
| `purchase_revenue_in_usd` | Revenue per purchase |

Users bucketed into weekly registration cohorts (week starting Sunday), covering cohorts from
**2020-11-01 to 2021-01-24**, tracked across weeks 0–12 since registration.

**RFM segmentation** — `tc-da-1.turing_data_analytics.rfm`

| Field | Description |
|---|---|
| `CustomerID` | Customer identifier |
| `InvoiceNo` | Order identifier (frequency) |
| `Quantity`, `UnitPrice` | Order value (monetary) |
| `InvoiceDate` | Order date (recency) |
| `Country` | Customer country |

Filtered to transactions from **2010-12-01 to 2011-12-02**, excluding null customers and
non-positive quantities or prices.

## Method

### CLV / LTV

1. **Cohort assignment** — each user's first event week defines their registration cohort.
2. **Weekly revenue** — `purchase_revenue_in_usd` summed per user per week.
3. **Cohort sizing** — distinct users counted per cohort.
4. **Revenue per user** — revenue joined to cohorts and divided by cohort size, by weeks
   since registration (0–12).
5. **Cumulative growth** — weekly revenue accumulated per cohort, with period-over-period
   growth rates.
6. **Forecasting** — cumulative revenue projected for incomplete cohorts to reach a full
   12-week estimate.
7. **Validation** — null checks, cohort-size sanity checks and row-count reconciliation
   across every pipeline stage.

### RFM segmentation

1. **Metrics** — recency (days since last order), frequency (distinct orders) and monetary
   value (total order value) per customer.
2. **Quartile scoring** — `APPROX_QUANTILES` to score each metric 1–4.
3. **Segmentation** — rule-based logic over the combined R/F/M scores.
4. **Validation** — segment distribution, unclassified customers, and at-risk / lost trends.

## Findings

- **Predicted 12-week LTV ≈ $1.47** cumulative revenue per user.
- The largest cohort was acquired the week of **2020-12-06** — the peak acquisition week.
- Cohorts spend strongly in week 1, then decline steadily through week 12.
- Cumulative growth slows sharply, bottoms out around week 9, then recovers slightly.
- **Cohort 2020-12-13** is the inflection point where positive growth shifts to a slower
  trajectory.
- Actual cumulative revenue is beating forecast across all periods.

**Why:** the acquisition spike and later decline line up with seasonality. Black Friday /
Cyber Monday (from 2020-11-27) inflated sales through promotions and seasonal buying, while
the Christmas / New Year period is typically slower. These external factors explain both the
early surge and the drop-off — not a change in product or pricing.

## Limitations

- A 12-week window captures short-term value only; true lifetime value extends further, so
  $1.47 is a floor rather than a lifetime figure.
- Cohort behaviour is heavily shaped by the holiday season, so these estimates do not
  generalise to other periods.
- One cohort (2020-11-08) has a data gap — zero completions in week 8.
- The forecast assumes the observed decay pattern continues; a structural change in behaviour
  would shift the projection.
- The CLV and RFM analyses use different datasets and time ranges, so the segments are not
  directly tied to the cohort LTV figure. Treat them as two answers to two questions, not one
  joined model.

## Tools

**BigQuery** — cohort construction, revenue aggregation, RFM scoring and validation (CTEs,
`APPROX_QUANTILES`, date functions) · **Spreadsheet analysis** — cumulative growth tables,
forecasting and LTV estimation

## Repository

```
.
├── sql/
│   ├── clv_cohort_revenue.sql     # cohort build + average revenue per user + validation
│   └── rfm_segmentation.sql       # RFM scoring + segment logic
├── clv-analysis.pdf               # full write-up with charts
└── README.md
```
