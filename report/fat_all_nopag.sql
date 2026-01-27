-- Запрос по платежам  RUB в процессинге FAT за период времени в UTC -3, сравниваем количество транзакций дата1 и дата2 - рост и падение отображаем в процентах в выдаче.
-- ок

WITH params AS (
    SELECT 
        '2026-01-10 21:00:00'::timestamp as date1_start,
        '2026-01-11 21:00:00'::timestamp as date1_end,
        '2026-01-17 21:00:00'::timestamp as date2_start,
        '2026-01-18 21:00:00'::timestamp as date2_end
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
-- Оптимизированный поиск shop_id только в нужных датах
shop_ids AS (
    SELECT DISTINCT shop_id, shop_name
    FROM db_ifat 
    WHERE shop_name IN (SELECT shop_name FROM merchants_list)
      AND (
          updated_at >= (SELECT date1_start FROM params) 
          AND updated_at < (SELECT date1_end FROM params)
          OR updated_at >= (SELECT date2_start FROM params) 
          AND updated_at < (SELECT date2_end FROM params)
      )
)
SELECT
    COALESCE(si.shop_id, 0) AS "ID",
    ml.shop_name AS "Мерчант",
    COALESCE(d1.cnt, 0) AS "date1",
    COALESCE(d2.cnt, 0) AS "date2",
    (COALESCE(d2.cnt, 0) - COALESCE(d1.cnt, 0)) AS "Δ (абс.)",
    CASE
        WHEN COALESCE(d1.cnt, 0) = 0 AND COALESCE(d2.cnt, 0) = 0 THEN '⚪️ 0 → 0'
        WHEN COALESCE(d1.cnt, 0) = 0 THEN '🟢 +∞% (новый поток)'
        WHEN (COALESCE(d2.cnt, 0) - COALESCE(d1.cnt, 0)) > 0 
            THEN '🟢 +' || ROUND((COALESCE(d2.cnt, 0) - COALESCE(d1.cnt, 0)) * 100.0 / NULLIF(COALESCE(d1.cnt, 0), 0), 2) || '%'
        WHEN (COALESCE(d2.cnt, 0) - COALESCE(d1.cnt, 0)) < 0 
            THEN '🔴 ' || ROUND((COALESCE(d2.cnt, 0) - COALESCE(d1.cnt, 0)) * 100.0 / NULLIF(COALESCE(d1.cnt, 0), 0), 2) || '%'
        ELSE '⚪️ 0%'
    END AS "Изменение"
FROM merchants_list ml
LEFT JOIN shop_ids si ON ml.shop_name = si.shop_name
LEFT JOIN (
    -- Считаем операции для date1
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
) d1 ON ml.shop_name = d1.shop_name
LEFT JOIN (
    -- Считаем операции для date2
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
) d2 ON ml.shop_name = d2.shop_name
ORDER BY "date2" DESC, "Мерчант";