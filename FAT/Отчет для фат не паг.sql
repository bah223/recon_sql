WITH params AS (
    SELECT 
        '2026-01-08 20:59:00'::timestamp as date1_start,  -- Начало первой даты (можно менять)
        '2026-01-09 21:00:00'::timestamp as date1_end,    -- Конец первой даты (можно менять)
        '2026-01-15 20:59:00'::timestamp as date2_start,  -- Начало второй даты (можно менять)
        '2026-01-16 21:00:00'::timestamp as date2_end,    -- Конец второй даты (можно менять)
        TO_CHAR('2025-12-31 21:00:00'::timestamp, 'YYYY-MM-DD') as date1_label,
        TO_CHAR('2026-01-07 21:00:00'::timestamp, 'YYYY-MM-DD') as date2_label
),
merchants_list AS (
    SELECT * FROM (VALUES
        ('ZT/Pelican Pay Cards KZT'),
        ('ZT/DukPay Limited Moonton T-Pay (desktop-QR) RUB'),
        ('ZT/DukPay Limited Moonton T-Pay RUB'),
        ('ZT/DukPay Limited Moonton SberPay (desktop-QR) RUB'),
        ('ZT/DukPay Limited Moonton SberPay RUB'),
        ('ZT/DukPay Limited Moonton RUB'),
        ('ZT/DukPay Limited Buffbuff T-Pay (desktop-QR) RUB'),
        ('ZT/DukPay Limited Buffbuff T-Pay RUB'),
        ('ZT/DukPay Limited Buffbuff RUB'),
        ('ZT/DukPay Limited Cards KZT'),
        ('ZT/SWOOSHTRANSFER Ltd T-Pay Funplus RUB'),
        ('ZT/SWOOSHTRANSFER Ltd T-Pay (desktop-QR) Funplus RUB'),
        ('ZT/SWOOSHTRANSFER Ltd Funplus RUB'),
        ('ZT/SWOOSHTRANSFER Ltd SberPay (push flow) Funplus RUB'),
        ('ZT/SWOOSHTRANSFER Ltd SberPay Funplus RUB'),
        ('ZT/SWOOSHTRANSFER Ltd Cards Poizon RUB'),
        ('ZT/SWOOSHTRANSFER Ltd T-Pay (desktop-QR) Poizon RUB'),
        ('ZT/SWOOSHTRANSFER Ltd T-Pay Poizon RUB'),
        ('ZT/SWOOSHTRANSFER Ltd SberPay (push flow) Poizon RUB'),
        ('ZT/SWOOSHTRANSFER Ltd SberPay Poizon RUB'),
        ('ZT/SWOOSHTRANSFER Ltd Cards DreamPlus RUB'),
        ('ZT/SWOOSHTRANSFER Ltd T-Pay DreamPlus RUB'),
        ('ZT/SWOOSHTRANSFER Ltd T-Pay (desktop-QR) DreamPlus RUB'),
        ('ZT/SWOOSHTRANSFER Ltd SberPay (push flow) DreamPlus RUB'),
        ('ZT/SWOOSHTRANSFER Ltd Cards Puzala RUB'),
        ('ZT/SWOOSHTRANSFER Ltd T-Pay Puzala RUB'),
        ('ZT/SWOOSHTRANSFER Ltd T-Pay (desktop-QR) Puzala RUB'),
        ('ZT/SWOOSHTRANSFER Ltd SberPay (push flow) Puzala RUB'),
        ('ZT/PANACEA BIOHACKING T-Pay RUB'),
        ('ZT/PANACEA BIOHACKING T-Pay (desktop-QR) RUB'),
        ('ZT/PANACEA BIOHACKING Cards RUB'),
        ('ZT/Fincom TEH LTD RUB'),
        ('ZT/Fincom TEH LTD SberPay RUB'),
        ('ZT/Fincom TEH LTD T-Pay (desktop-QR) RUB'),
        ('ZT/Fincom TEH LTD T-Pay RUB'),
        ('ZT/PMmax Technology Limited Cards KZT'),
        ('ZT/PMmax Technology Limited HUMO UZCard UZS'),
        ('ZT/PMmax Technology Limited Uzum UZS'),
        ('ZT/PMmax Technology Limited Payme UZS'),
        ('GFI/MONEYMAPLE TECH LTD Qris IDR'),
        ('GFI/MONEYMAPLE TECH LTD CIMB IDR'),
        ('GFI/MONEYMAPLE TECH LTD BNI IDR'),
        ('GFI/MONEYMAPLE TECH LTD BRI IDR'),
        ('GFI/MONEYMAPLE TECH LTD Mandiri IDR'),
        ('GFI/MONEYMAPLE TECH LTD Permata IDR'),
        ('GFI/MONEYMAPLE TECH LTD Dana IDR'),
        ('GFI/MONEYMAPLE TECH LTD OVO IDR')
    ) AS t(shop_name)
),
distinct_shop_ids AS (
    SELECT DISTINCT shop_id, shop_name
    FROM db_ifat 
    WHERE shop_name IN (SELECT shop_name FROM merchants_list)
      AND (created_at >= (SELECT date1_start FROM params) AND created_at < (SELECT date1_end FROM params)
           OR created_at >= (SELECT date2_start FROM params) AND created_at < (SELECT date2_end FROM params))
),
data_date1 AS (
    SELECT
        s.shop_id,
        s.shop_name,
        COUNT(*) AS total_date1
    FROM distinct_shop_ids s
    LEFT JOIN db_ifat x ON x.shop_name = s.shop_name 
        AND x.created_at >= (SELECT date1_start FROM params)
        AND x.created_at < (SELECT date1_end FROM params)
        AND x.operation_status_name IN ('success','error') 
        AND x.payment_type = 'create'
    GROUP BY s.shop_id, s.shop_name
),
data_date2 AS (
    SELECT
        s.shop_id,
        s.shop_name,
        COUNT(*) AS total_date2
    FROM distinct_shop_ids s
    LEFT JOIN db_ifat x ON x.shop_name = s.shop_name 
        AND x.created_at >= (SELECT date2_start FROM params)
        AND x.created_at < (SELECT date2_end FROM params)
        AND x.operation_status_name IN ('success','error') 
        AND x.payment_type = 'create'
    GROUP BY s.shop_id, s.shop_name
),
comparison AS (
    SELECT
        COALESCE(d1.shop_id, d2.shop_id) AS shop_id,
        COALESCE(d1.shop_name, d2.shop_name) AS shop_name,
        COALESCE(d1.total_date1, 0) AS total_date1,
        COALESCE(d2.total_date2, 0) AS total_date2,
        (COALESCE(d2.total_date2, 0) - COALESCE(d1.total_date1, 0)) AS diff
    FROM data_date1 d1
    FULL JOIN data_date2 d2 ON d1.shop_name = d2.shop_name
)
SELECT
    shop_id AS "ID",
    shop_name AS "Мерчант",
    total_date1 AS "date1",  -- Здесь вручную поменяйте дату
    total_date2 AS "date2",  -- Здесь вручную поменяйте дату
    diff AS "Δ (абс.)",
    CASE
        WHEN total_date1 = 0 AND total_date2 = 0 THEN '⚪️ 0 → 0'
        WHEN total_date1 = 0 THEN '🟢 +∞% (новый поток)'
        WHEN diff > 0 THEN '🟢 +' || ROUND(diff * 100.0 / NULLIF(total_date1, 0), 2) || '%'
        WHEN diff < 0 THEN '🔴 ' || ROUND(diff * 100.0 / NULLIF(total_date1, 0), 2) || '%'
        ELSE '⚪️ 0%'
    END AS "Изменение"
FROM comparison
ORDER BY total_date2 DESC, shop_name;