-- Конверсия = (успешные платежи / созданные платежи) * 100%
-- Успешный платеж: payment_type='pay' AND operation_status_name='success'
-- Созданный платеж: payment_type='create' AND operation_status_name IN ('success', 'error')
-- Если операций нет — конверсия = NULL
WITH created_payments AS (
    SELECT COUNT(*) AS created_count
    FROM db_ifat
    WHERE shop_name = 'ZT/Pelican Pay Cards KZT'
      AND payment_type = 'create'
      AND operation_status_name IN ('success', 'error')
      AND created_at >= '2025-12-27 21:00:00'
      AND created_at < '2025-12-28 21:00:00'
),
successful_payments AS (
    SELECT COUNT(*) AS success_count
    FROM db_ifat
    WHERE shop_name = 'ZT/Pelican Pay Cards KZT'
      AND payment_type = 'pay'
      AND operation_status_name = 'success'
      AND created_at >= '2025-12-27 21:00:00'
      AND created_at < '2025-12-28 21:00:00'
)
SELECT
    COALESCE(c.created_count, 0) AS created_transactions,
    COALESCE(s.success_count, 0) AS success_transactions,
    ROUND(
        COALESCE(s.success_count, 0) * 100.0 
        / NULLIF(COALESCE(c.created_count, 0), 0),
        2
    ) AS conversion_percent
FROM created_payments c
CROSS JOIN successful_payments s;