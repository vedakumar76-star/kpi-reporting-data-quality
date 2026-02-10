"""KPI Trend + Data Quality Analysis (Python)
Run: python notebooks/kpi_trend_analysis.py
This script reads the synthetic CSVs, performs validation checks, builds monthly KPIs,
and produces a few artifacts (csv summaries) you can reference in your README.
"""

import pandas as pd

ORDERS_PATH = "data/orders.csv"
PAYMENTS_PATH = "data/payments.csv"

orders = pd.read_csv(ORDERS_PATH, parse_dates=["order_date","ingestion_date"])
payments = pd.read_csv(PAYMENTS_PATH, parse_dates=["payment_date"])

# Basic quality checks
checks = {}

checks["orders_total_rows"] = len(orders)
checks["orders_unique_order_id"] = orders["order_id"].nunique()
checks["orders_missing_region_pct"] = round(orders["region"].isna().mean() * 100, 2)

# Deduplicate payments similar to SQL logic
payments_dedup = payments.drop_duplicates(subset=["order_id","payment_date","payment_method","payment_amount"])
checks["payments_total_rows"] = len(payments)
checks["payments_dedup_rows"] = len(payments_dedup)
checks["payments_duplicate_rows"] = len(payments) - len(payments_dedup)

# Build order-level collected amount
paid = (
    payments_dedup.groupby("order_id", as_index=False)["payment_amount"]
    .sum()
    .rename(columns={"payment_amount":"paid_amount"})
)

order_pay = orders.merge(paid, on="order_id", how="left")
order_pay["paid_amount"] = order_pay["paid_amount"].fillna(0)

# Monthly KPIs
order_pay["month"] = order_pay["order_date"].dt.to_period("M").dt.to_timestamp()

kpi = (
    order_pay.groupby(["month","channel","product_line"], as_index=False)
    .agg(
        orders_total=("order_id","count"),
        completed_orders=("status", lambda s: (s=="Completed").sum()),
        gross_revenue=("gross_amount","sum"),
        collected_revenue=("paid_amount","sum"),
        late_arriving_orders=("ingestion_date", lambda x: (x > order_pay.loc[x.index, "order_date"]).sum()),
    )
)

kpi["gross_revenue"] = kpi["gross_revenue"].round(2)
kpi["collected_revenue"] = kpi["collected_revenue"].round(2)

# Save artifacts
pd.DataFrame([checks]).to_csv("docs/data_quality_checks.csv", index=False)
kpi.to_csv("docs/monthly_kpis.csv", index=False)

print("Saved docs/data_quality_checks.csv and docs/monthly_kpis.csv")
print(pd.DataFrame([checks]).T.rename(columns={0:"value"}))
