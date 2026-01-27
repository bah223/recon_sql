WITH merchants AS (
    SELECT * FROM (VALUES
        ('ZT/Pelican Pay Cards KZT', 'Pelican Pay KZT'),
        ('ZT/Pagsmile Limited (smile.one) RUB', 'Pagsmile RUB'),
        ('ZT/SWOOSHTRANSFER Ltd T-Pay Funplus RUB', 'SWOOSH Funplus RUB')
        -- ↑ ДОБАВЛЯЙ СЮДА
    ) AS t(shop_name, merchant_name)
),
merchant_stats AS (
    SELECT
        m.shop_name,
        m.merchant_name,
        COUNT(*) AS total_operations,
        COUNT(*) FILTER (WHERE x.payment_type = 'create' AND x.operation_status_name IN ('success', 'error')) AS created_payments,
        COUNT(*) FILTER (WHERE x.payment_type = 'pay' AND x.operation_status_name = 'success') AS successful_payments,
        COUNT(*) FILTER (WHERE x.payment_type = 'create' AND x.operation_status_name = 'error') AS failed_creations,
        MAX(x.created_at) AS last_operation_time
    FROM merchants m
    LEFT JOIN db_ifat x ON x.shop_name = m.shop_name
      AND x.created_at >= '2025-12-27 21:00:00'
      AND x.created_at < '2025-12-28 21:00:00'
    GROUP BY m.shop_name, m.merchant_name
)
SELECT
    merchant_name AS "Мерчант",
    total_operations AS "Всего операций",
    created_payments AS "Создано платежей",
    successful_payments AS "Успешных платежей",
    failed_creations AS "Ошибок создания",
    ROUND(
        successful_payments * 100.0 
        / NULLIF(created_payments, 0),
        2
    ) AS "Конверсия, %",
    last_operation_time AS "Последняя операция"
FROM merchant_stats
ORDER BY successful_payments DESC;