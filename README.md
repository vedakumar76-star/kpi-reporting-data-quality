# KPI Reporting & Data Quality (SQL + Python)

This repository demonstrates an **enterprise-style KPI reporting workflow**:
- building analytics-ready KPI datasets in SQL,
- validating and reconciling metrics across sources,
- and explaining month-over-month KPI movements.

The data is **synthetic** (safe to publish) but intentionally includes real-world issues:
late-arriving records, duplicate payments, missing values, and source-to-source date drift.

## What’s inside

### 1) KPI dataset build (SQL)
- `sql/kpi_definitions.sql` — produces a monthly KPI table (orders, revenue, collected revenue) with deduped payments.
- `sql/variance_analysis.sql` — month-over-month variance breakdown.
- `sql/reconciliation_checks.sql` — reconciles totals between “System A” and “System B”.

### 2) Data quality checks (Python)
- `notebooks/kpi_trend_analysis.py` — runs validation checks and exports:
  - `docs/data_quality_checks.csv`
  - `docs/monthly_kpis.csv`

## Key KPIs
- Orders (total / completed / cancelled / returned)
- Gross revenue vs collected revenue
- Late-arriving orders (ingestion_date > order_date)

## How to run locally

```bash
# from repo root
pip install -r requirements.txt
python notebooks/kpi_trend_analysis.py
```

## Talking points (for interviews)
- How you deduped payments and prevented double-counting
- How you handled late-arriving data for month-end cutoffs
- How you reconciled KPI mismatches across systems and documented metric definitions
