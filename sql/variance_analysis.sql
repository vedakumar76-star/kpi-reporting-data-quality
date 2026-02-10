-- variance_analysis.sql
-- Goal: Explain KPI movements month over month and highlight anomalies

WITH monthly AS (
  SELECT
    DATE_TRUNC('month', order_date) AS month,
    ROUND(SUM(gross_amount),2) AS gross_revenue,
    SUM(CASE WHEN status='Completed' THEN 1 ELSE 0 END) AS completed_orders
  FROM orders
  GROUP BY 1
),
calc AS (
  SELECT
    month,
    gross_revenue,
    completed_orders,
    LAG(gross_revenue) OVER (ORDER BY month) AS prev_gross_revenue,
    LAG(completed_orders) OVER (ORDER BY month) AS prev_completed_orders
  FROM monthly
)
SELECT
  month,
  gross_revenue,
  prev_gross_revenue,
  ROUND(gross_revenue - prev_gross_revenue, 2) AS gross_change,
  CASE
    WHEN prev_gross_revenue IS NULL OR prev_gross_revenue = 0 THEN NULL
    ELSE ROUND((gross_revenue - prev_gross_revenue) / prev_gross_revenue * 100, 2)
  END AS gross_change_pct,
  completed_orders,
  prev_completed_orders,
  (completed_orders - prev_completed_orders) AS completed_orders_change
FROM calc
ORDER BY month;
