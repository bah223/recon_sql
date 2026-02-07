-- Запрос по платежам  RUB в процессинге FAT за период времени в UTC -3, сравниваем количество транзакций дата1 и дата2 - рост и падение отображаем в процентах в выдаче.
-- ок

WITH params AS (
    SELECT 
        '2026-01-28 21:00:00'::timestamp as date1_start,
        '2026-01-29 21:00:00'::timestamp as date1_end,
        '2026-02-04 21:00:00'::timestamp as date2_start,
        '2026-02-05 21:00:00'::timestamp as date2_end
),
merchants_list AS (
    SELECT * FROM (values
    	('ZT/PLAYMAG-FZCO Cards KZT'),
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
        ('GFI/MONEYMAPLE TECH LTD OVO IDR'),
        ('NP-ZT/CRYSTAL FUTURE OU SberPay RUB'),
        ('NP-DPS/CRYSTAL FUTURE OU QRPh PHP'),
        ('NP-DPS/CRYSTAL FUTURE OU Maya PHP'),
        ('NP-DPS/CRYSTAL FUTURE OU GCash PHP'),
        ('NP-D2/CRYSTAL FUTURE OU QRIS IDR'),
        ('NP-D2/CRYSTAL FUTURE OU ShopeePay IDR'),
        ('ZT/AIMO COMPANY LIMITED Cards (BuffBuff) RUB'),
        ('ZT/AIMO COMPANY LIMITED Cards (MLBB) RUB'),
        ('ZT/AIMO COMPANY LIMITED TPay (BuffBuff) RUB'),
        ('ZT/AIMO COMPANY LIMITED TPay (desktop-QR) (MLBB) RUB'),
        ('ZT/AIMO COMPANY LIMITED TPay (MLBB) RUB'),
        ('ZT/AIMO COMPANY LIMITED TPay (desktop-QR) (BuffBuff) RUB'),
        ('ZT-Carusell/ATS ATES TUGLA SAN VE TIC LTD STI LLP Cards RUB'),
        ('ZT-Carusell/ATS ATES TUGLA SAN VE TIC LTD STI LLP T-Pay RUB'),
        ('ZT/INGALA Limited (Galaxy) Cards RUB'),
        ('ZT-Carusell/ATS ATES TUGLA SAN VE TIC LTD STI LLP T-Pay (desktop-QR) RUB'),
        ('ZT-Carusell/ATS ATES TUGLA SAN VE TIC LTD STI LLP SberPay RUB'),
        ('Carusell/Cnlgaming Limited (Viet QR) VND'),
        ('Carusell/Cnlgaming Limited (Viet QR) (2) VND'),
        ('D2-GFI/Rapyd Holdings Pte Ltd. GCash PHP'),
        ('GFI/Rapyd Holdings Pte Ltd. BPI PHP'),
        ('GFI/Rapyd Holdings Pte Ltd. Maya PHP'),
        ('GFI/Rapyd Holdings Pte Ltd. QRPh PHP'),
        ('ZT/Zaya Solutions Limited Cards RUB'),
        ('ZT/Zaya Solutions Limited Cards KZT')
        
        --('ZT/THANOS PAYMENTS SOLUTIONS L.L.C-FZ KZT')
    ) AS t(shop_name)
),
-- Сначала получаем данные за периоды (они уже фильтруют по датам)
period1_data AS (
    SELECT 
        shop_name,
        COUNT(*) as cnt,
        MAX(shop_id) as shop_id  -- Берём любой shop_id из транзакций
    FROM db_ifat
    WHERE shop_name IN (SELECT shop_name FROM merchants_list)
      AND payment_type = 'create'
      AND operation_status_name IN ('success', 'error')
      AND created_at >= (SELECT date1_start FROM params)
      AND created_at < (SELECT date1_end FROM params)
    GROUP BY shop_name
),
period2_data AS (
    SELECT 
        shop_name,
        COUNT(*) as cnt,
        MAX(shop_id) as shop_id  -- Берём любой shop_id из транзакций
    FROM db_ifat
    WHERE shop_name IN (SELECT shop_name FROM merchants_list)
      AND payment_type = 'create'
      AND operation_status_name IN ('success', 'error')
      AND created_at >= (SELECT date2_start FROM params)
      AND created_at < (SELECT date2_end FROM params)
    GROUP BY shop_name
),
-- Получаем ID из найденных транзакций
found_shop_ids AS (
    SELECT DISTINCT shop_id, shop_name 
    FROM (
        SELECT shop_id, shop_name FROM period1_data WHERE shop_id IS NOT NULL
        UNION 
        SELECT shop_id, shop_name FROM period2_data WHERE shop_id IS NOT NULL
    ) t
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
ORDER BY COALESCE(p2.cnt, 0) DESC, ml.shop_name;