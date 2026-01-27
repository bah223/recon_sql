--title: FAT — Сравнение трафика (01.01.2026 vs 08.01.2026)
--status:ok
WITH merchants AS (
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
data_01 AS (
    SELECT
        m.shop_name,
        SUM(CASE WHEN x.operation_status_name IN ('success','error') AND x.payment_type = 'create' THEN 1 ELSE 0 END) AS total_01
    FROM merchants m
    LEFT JOIN db_ifat x ON x.shop_name = m.shop_name
        AND x.created_at >= '2025-12-31 21:00:00'  -- 01.01.2026 МСК
        AND x.created_at <  '2026-01-01 21:00:00'
    GROUP BY m.shop_name
),
data_08 AS (
    SELECT
        m.shop_name,
        SUM(CASE WHEN x.operation_status_name IN ('success','error') AND x.payment_type = 'create' THEN 1 ELSE 0 END) AS total_08
    FROM merchants m
    LEFT JOIN db_ifat x ON x.shop_name = m.shop_name
        AND x.created_at >= '2026-01-07 21:00:00'  -- 08.01.2026 МСК
        AND x.created_at <  '2026-01-08 21:00:00'
    GROUP BY m.shop_name
)
SELECT
    d1.shop_name AS "Мерчант",
    COALESCE(d1.total_01, 0) AS "Всего 01.01.2026",
    COALESCE(d8.total_08, 0) AS "Всего 08.01.2026",
    (COALESCE(d8.total_08, 0) - COALESCE(d1.total_01, 0)) AS "Δ (абс.)",
    ROUND(
        (COALESCE(d8.total_08, 0) - COALESCE(d1.total_01, 0)) * 100.0
        / NULLIF(COALESCE(d1.total_01, 0), 0),
        2
    ) AS "Изменение %"
FROM data_01 d1
FULL JOIN data_08 d8 ON d1.shop_name = d8.shop_name
ORDER BY "Изменение %" DESC NULLS LAST;