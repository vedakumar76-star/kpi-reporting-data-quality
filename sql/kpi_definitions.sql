-- kpi_definitions.sql
-- Goal: Create analytics-ready KPI dataset from orders and payments
-- Notes:
-- 1) Use ingestion_date to model "late arriving data" cutoffs
-- 2) Deduplicate payments by (order_id, payment_date, payment_amount, payment_method)

WITH dedup_payments AS (
    SELECT
        order_id,
        payment_date,
        payment_method,
        payment_amount,
        ROW_NUMBER() OVER (
            PARTITION BY order_id, payment_date, payment_method, payment_amount
            ORDER BY payment_id
        ) AS rn
    FROM payments
),
payments_clean AS (
    SELECT
        order_id,
        payment_date,
        payment_method,
        payment_amount
    FROM dedup_payments
    WHERE rn = 1
),
order_payments AS (
    SELECT
        o.order_id,
        o.order_date,
        o.ingestion_date,
        o.channel,
        o.region,
        o.product_line,
        o.status,
        o.gross_amount,
        COALESCE(SUM(p.payment_amount), 0) AS paid_amount,
        MAX(p.payment_date) AS last_payment_date
    FROM orders o
    LEFT JOIN payments_clean p
        ON o.order_id = p.order_id
    GROUP BY
        o.order_id, o.order_date, o.ingestion_date, o.channel, o.region, o.product_line, o.status, o.gross_amount
)
SELECT
    DATE_TRUNC('month', order_date) AS month,
    channel,
    region,
    product_line,
    COUNT(*) AS orders_total,
    SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS orders_completed,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS orders_cancelled,
    SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS orders_returned,
    ROUND(SUM(gross_amount), 2) AS gross_revenue,
    ROUND(SUM(paid_amount), 2) AS collected_revenue,
    ROUND(SUM(CASE WHEN status='Completed' THEN gross_amount ELSE 0 END), 2) AS completed_gross_revenue
FROM order_payments
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4;
