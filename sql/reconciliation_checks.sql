-- reconciliation_checks.sql
-- Goal: Reconcile KPI totals across two source systems (System A vs System B)
-- Typical issues: join logic, date cutoffs, timezone shifts, late arriving records

WITH a AS (
  SELECT
    DATE_TRUNC('month', order_date) AS month,
    COUNT(*) AS orders_a,
    ROUND(SUM(gross_amount),2) AS gross_a
  FROM system_a_orders
  GROUP BY 1
),
b AS (
  SELECT
    DATE_TRUNC('month', order_date) AS month,
    COUNT(*) AS orders_b,
    ROUND(SUM(gross_amount),2) AS gross_b
  FROM system_b_orders
  GROUP BY 1
)
SELECT
  COALESCE(a.month, b.month) AS month,
  orders_a, orders_b,
  (orders_a - orders_b) AS orders_diff,
  gross_a, gross_b,
  ROUND((gross_a - gross_b),2) AS gross_diff
FROM a
FULL OUTER JOIN b
  ON a.month = b.month
ORDER BY 1;
