-- Запрос по выплатам по KZT за период времени, сравниваем количество транзакций дата1 и дата2 - рост и падение отображаем в процентах в выдаче.
-- Учитываем нулевые аккаунты и все выплаты по всем статусам.
-- ок

WITH params AS (
    SELECT 
        '2026-01-21 00:00:00'::timestamp as period1_start,
        '2026-01-21 23:59:00'::timestamp as period1_end,
        '2026-01-28 00:00:00'::timestamp as period2_start,
        '2026-01-28 23:59:00'::timestamp as period2_end
),
selected_ids AS (
    SELECT id FROM (VALUES
        (1510),
        (4190),
        (4084),
        (4291)
    ) AS t(id)
)
SELECT
    m.id AS "ID",
    COALESCE(p.name, 'ID: ' || m.id::text) AS "Мерчант",
    COALESCE(period1.cnt, 0) AS "date1",
    COALESCE(period2.cnt, 0) AS "date2",
    (COALESCE(period2.cnt, 0) - COALESCE(period1.cnt, 0)) AS "Δ (абс.)",
    CASE
        WHEN COALESCE(period1.cnt, 0) = 0 AND COALESCE(period2.cnt, 0) = 0 THEN '⚪️ 0 → 0'
        WHEN COALESCE(period1.cnt, 0) = 0 THEN '🟢 +∞% (новый поток)'
        WHEN (COALESCE(period2.cnt, 0) - COALESCE(period1.cnt, 0)) > 0 
            THEN '🟢 +' || ROUND((COALESCE(period2.cnt, 0) - COALESCE(period1.cnt, 0)) * 100.0 / NULLIF(COALESCE(period1.cnt, 0), 0), 2) || '%'
        WHEN (COALESCE(period2.cnt, 0) - COALESCE(period1.cnt, 0)) < 0 
            THEN '🔴 ' || ROUND((COALESCE(period2.cnt, 0) - COALESCE(period1.cnt, 0)) * 100.0 / NULLIF(COALESCE(period1.cnt, 0), 0), 2) || '%'
        ELSE '⚪️ 0%'
    END AS "Изменение"
FROM selected_ids m
LEFT JOIN public.db_wp_partners p ON m.id = p.id
LEFT JOIN (
    -- Считаем ВСЕ выплатные операции в KZT (PAY_OK + PAY_FAIL + CHECK_FAIL)
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_operations
    WHERE currency = 'KZT'
      AND status IN ('PAY_OK', 'PAY_FAIL', 'CHECK_FAIL')
      AND partner_id IN (SELECT id FROM selected_ids)
      AND created >= (SELECT period1_start FROM params)
      AND created < (SELECT period1_end FROM params)
    GROUP BY partner_id
) period1 ON m.id = period1.partner_id
LEFT JOIN (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_operations
    WHERE currency = 'KZT'
      AND status IN ('PAY_OK', 'PAY_FAIL', 'CHECK_FAIL')
      AND partner_id IN (SELECT id FROM selected_ids)
      AND created >= (SELECT period2_start FROM params)
      AND created < (SELECT period2_end FROM params)
    GROUP BY partner_id
) period2 ON m.id = period2.partner_id
ORDER BY "date1" DESC, "Мерчант";