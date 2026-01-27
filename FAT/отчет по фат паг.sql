WITH params AS (
    SELECT 
        '2026-01-08 19:00:00'::timestamp as date1_start,
        '2026-01-09 19:00:00'::timestamp as date1_end,
        '2026-01-15 19:00:00'::timestamp as date2_start,
        '2026-01-16 19:00:00'::timestamp as date2_end
),
merchants_list AS (
    SELECT shop_name FROM (VALUES
        ('ZT/Pagsmile Limited (smile.one) RUB'),
        ('ZT/Pagsmile Limited (smile.one) T-Pay (desktop-QR) RUB'),
        ('ZT/Pagsmile Limited (smile.one) T-Pay RUB'),
        ('ZT/Pagsmile Limited RUB'),
        ('ZT/Pagsmile Limited T-Pay RUB'),
        ('ZT/Pagsmile Limited T-Pay (desktop-QR) RUB'),
        ('ZT/Pagsmile Limited SberPay RUB'),
        ('ZT/Pagsmile Limited (BuffBuff) Cards RUB'),
        ('ZT/Pagsmile Limited (BuffBuff) T-Pay RUB'),
        ('ZT/Pagsmile Limited (BuffBuff) SberPay RUB'),
        ('ZT/Pagsmile Limited (BuffBuff) T-Pay (desktop-QR) RUB'),
        ('ZT/Pagsmile Limited Cards KZT'),
        ('ZT/Pagsmile Limited (37games) Cards RUB'),
        ('ZT/Pagsmile Limited (37games) T-Pay (desktop QR) RUB'),
        ('ZT/Pagsmile Limited (37games) T-Pay RUB')
    ) AS t(shop_name)
),
-- БЫСТРЫЙ способ получить shop_id - только из нужных дат
shop_ids AS (
    SELECT DISTINCT shop_id, shop_name
    FROM db_ifat 
    WHERE shop_name IN (SELECT shop_name FROM merchants_list)
      AND (updated_at >= (SELECT date1_start FROM params) 
           AND updated_at < (SELECT date1_end FROM params)
           OR updated_at >= (SELECT date2_start FROM params) 
           AND updated_at < (SELECT date2_end FROM params))
)
SELECT
    COALESCE(si.shop_id, 0) AS "ID",
    ml.shop_name AS "Мерчант",
    COALESCE(d01.cnt, 0) AS "date1",
    COALESCE(d08.cnt, 0) AS "date2",
    (COALESCE(d08.cnt, 0) - COALESCE(d01.cnt, 0)) AS "Δ (абс.)",
    CASE
        WHEN COALESCE(d01.cnt, 0) = 0 AND COALESCE(d08.cnt, 0) = 0 THEN '0 → 0'
        WHEN COALESCE(d01.cnt, 0) = 0 THEN '+∞% (новый поток)'
        WHEN (COALESCE(d08.cnt, 0) - COALESCE(d01.cnt, 0)) > 0 
            THEN '+' || ROUND((COALESCE(d08.cnt, 0) - COALESCE(d01.cnt, 0)) * 100.0 / NULLIF(COALESCE(d01.cnt, 0), 0), 2) || '%'
        WHEN (COALESCE(d08.cnt, 0) - COALESCE(d01.cnt, 0)) < 0 
            THEN ROUND((COALESCE(d08.cnt, 0) - COALESCE(d01.cnt, 0)) * 100.0 / NULLIF(COALESCE(d01.cnt, 0), 0), 2) || '%'
        ELSE '0%'
    END AS "Изменение"
FROM merchants_list ml
LEFT JOIN shop_ids si ON ml.shop_name = si.shop_name
LEFT JOIN (
    -- Считаем ВСЕ create-операции (success + error) для date1
    SELECT 
        shop_name,
        COUNT(*) as cnt
    FROM db_ifat
    WHERE shop_name IN (SELECT shop_name FROM merchants_list)
      AND payment_type = 'create'
      AND operation_status_name IN ('success', 'error')
      AND updated_at >= (SELECT date1_start FROM params)
      AND updated_at < (SELECT date1_end FROM params)
    GROUP BY shop_name
) d01 ON ml.shop_name = d01.shop_name
LEFT JOIN (
    -- Считаем ВСЕ create-операции (success + error) для date2
    SELECT 
        shop_name,
        COUNT(*) as cnt
    FROM db_ifat
    WHERE shop_name IN (SELECT shop_name FROM merchants_list)
      AND payment_type = 'create'
      AND operation_status_name IN ('success', 'error')
      AND updated_at >= (SELECT date2_start FROM params)
      AND updated_at < (SELECT date2_end FROM params)
    GROUP BY shop_name
) d08 ON ml.shop_name = d08.shop_name
ORDER BY "date2" DESC, "Мерчант";