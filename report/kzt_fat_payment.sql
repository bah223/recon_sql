-- Запрос по платежам KZT в процессинге FAT за период времени в UTC -4, сравниваем количество транзакций дата1 и дата2 - рост и падение отображаем в процентах в выдаче.
-- ок

WITH params AS (
    SELECT 
        '2026-01-13 20:00:00'::timestamp as date1_start,
        '2026-01-14 08:00:00'::timestamp as date1_end,
        '2026-01-20 20:00:00'::timestamp as date2_start,
        '2026-01-21 08:00:00'::timestamp as date2_end
),
merchants_list AS (
    SELECT * FROM (VALUES
        ('ZT/PLAYMAG-FZCO Cards KZT'),
        ('ZT/VIBESTREAM PAYMENT SERVICES PROVIDER L.L.C Cards KZT'),
        ('ZT/Pagsmile Limited Cards KZT')
    ) AS t(shop_name)
),
period1_data AS (
    SELECT 
        shop_name,
        COUNT(*) as cnt,
        MAX(shop_id) as shop_id
    FROM db_ifat
    WHERE shop_name IN (SELECT shop_name FROM merchants_list)
      AND payment_type = 'create'
      AND operation_status_name IN ('success', 'error')
      AND system_currency = 'KZT'
      AND created_at >= (SELECT date1_start FROM params)
      AND created_at < (SELECT date1_end FROM params)
    GROUP BY shop_name
),
period2_data AS (
    SELECT 
        shop_name,
        COUNT(*) as cnt,
        MAX(shop_id) as shop_id
    FROM db_ifat
    WHERE shop_name IN (SELECT shop_name FROM merchants_list)
      AND payment_type = 'create'
      AND operation_status_name IN ('success', 'error')
      AND system_currency = 'KZT'
      AND created_at >= (SELECT date2_start FROM params)
      AND created_at < (SELECT date2_end FROM params)
    GROUP BY shop_name
),
found_shop_ids AS (
    SELECT DISTINCT shop_id, shop_name 
    FROM period1_data 
    WHERE shop_id IS NOT NULL
    UNION 
    SELECT DISTINCT shop_id, shop_name 
    FROM period2_data 
    WHERE shop_id IS NOT NULL
)
SELECT
    COALESCE(fsi.shop_id, 0) AS "ID",
    ml.shop_name AS "Мерчант",
    COALESCE(p1.cnt, 0) AS "date1",
    COALESCE(p2.cnt, 0) AS "date2",
    (COALESCE(p2.cnt, 0) - COALESCE(p1.cnt, 0)) AS "Δ (абс.)",
    CASE
        WHEN COALESCE(p1.cnt, 0) = 0 AND COALESCE(p2.cnt, 0) = 0 THEN '⚪️ 0 → 0'
        WHEN COALESCE(p1.cnt, 0) = 0 THEN '🟢 +∞% (новый поток)'
        WHEN COALESCE(p2.cnt, 0) = 0 THEN '🔴 -100% (поток прекратился)'
        WHEN (COALESCE(p2.cnt, 0) - COALESCE(p1.cnt, 0)) > 0 
            THEN '🟢 +' || ROUND((COALESCE(p2.cnt, 0) - COALESCE(p1.cnt, 0)) * 100.0 / NULLIF(COALESCE(p1.cnt, 0), 0), 2) || '%'
        WHEN (COALESCE(p2.cnt, 0) - COALESCE(p1.cnt, 0)) < 0 
            THEN '🔴 ' || ROUND((COALESCE(p2.cnt, 0) - COALESCE(p1.cnt, 0)) * 100.0 / NULLIF(COALESCE(p1.cnt, 0), 0), 2) || '%'
        ELSE '⚪️ 0%'
    END AS "Изменение"
FROM merchants_list ml
LEFT JOIN found_shop_ids fsi ON ml.shop_name = fsi.shop_name
LEFT JOIN period1_data p1 ON ml.shop_name = p1.shop_name
LEFT JOIN period2_data p2 ON ml.shop_name = p2.shop_name
ORDER BY COALESCE(p2.cnt, 0) DESC;