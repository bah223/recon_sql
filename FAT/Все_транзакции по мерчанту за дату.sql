--title: FAT — ZT/Pagsmile Limited (smile.one) RUB — все транзакции за 01.01.2026 (как в Grafana)
--status:ok
SELECT
    order_id,
    updated_at AT TIME ZONE 'UTC' + INTERVAL '3 hours' AS "updated_at_MSC",
    created_at AT TIME ZONE 'UTC' + INTERVAL '3 hours' AS "created_at_MSC",
    payment_type,
    operation_status_name,
    order_status,
    system_amount,
    system_currency,
    user_email
FROM db_ifat
WHERE
    shop_name = 'ZT/Pagsmile Limited (smile.one) RUB'
    AND operation_status_name IN ('success', 'error')
    AND updated_at >= '2025-12-31 21:00:00'  -- начало 01.01.2026 МСК
    AND updated_at <  '2026-01-01 21:00:00'   -- конец 01.01.2026 МСК
ORDER BY updated_at;