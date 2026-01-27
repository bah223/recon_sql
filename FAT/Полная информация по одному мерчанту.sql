WITH stats AS (
    SELECT
        -- Все операции
        COUNT(*) AS total_operations,
        -- Созданные платежи (инициированные)
        COUNT(*) FILTER (WHERE payment_type = 'create' AND operation_status_name IN ('success', 'error')) AS created_payments,
        -- Успешные платежи (оплаченные)
        COUNT(*) FILTER (WHERE payment_type = 'pay' AND operation_status_name = 'success') AS successful_payments,
        -- Ошибочные создания
        COUNT(*) FILTER (WHERE payment_type = 'create' AND operation_status_name = 'error') AS failed_creations,
        -- Последняя операция
        MAX(created_at) AS last_operation_time
    FROM db_ifat
    WHERE shop_name = 'ZT/Pelican Pay Cards KZT'
      AND created_at >= '2025-12-27 21:00:00'
      AND created_at < '2025-12-28 21:00:00'
)
SELECT
    'ZT/Pelican Pay Cards KZT' AS merchant_name,
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
FROM stats;