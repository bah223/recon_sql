WITH params AS (
    SELECT 
        '2026-01-30 00:00:00'::timestamp as period1_start,
        '2026-01-30 11:59:00'::timestamp as period1_end,
        '2026-02-05 00:00:00'::timestamp as period2_start,
        '2026-02-05 11:59:00'::timestamp as period2_end
),
selected_ids AS (
    SELECT id FROM (VALUES
        (1510),
        (4190),
        (4084),
        (4291),
        (4316),
        (4278)  
    ) AS t(id)
)
SELECT
    m.id AS "ID",
    COALESCE(p.name, 'ID: ' || m.id::text) AS "Мерчант",
    -- KZT данные
    COALESCE(period1_kzt.cnt, 0) AS "KZT date1",
    COALESCE(period2_kzt.cnt, 0) AS "KZT date2",
    (COALESCE(period2_kzt.cnt, 0) - COALESCE(period1_kzt.cnt, 0)) AS "KZT Δ (абс.)",
    CASE
        WHEN COALESCE(period1_kzt.cnt, 0) = 0 AND COALESCE(period2_kzt.cnt, 0) = 0 THEN '⚪️ 0 → 0'
        WHEN COALESCE(period1_kzt.cnt, 0) = 0 THEN '🟢 +∞% (новый поток)'
        WHEN (COALESCE(period2_kzt.cnt, 0) - COALESCE(period1_kzt.cnt, 0)) > 0 
            THEN '🟢 +' || ROUND((COALESCE(period2_kzt.cnt, 0) - COALESCE(period1_kzt.cnt, 0)) * 100.0 / NULLIF(COALESCE(period1_kzt.cnt, 0), 0), 2) || '%'
        WHEN (COALESCE(period2_kzt.cnt, 0) - COALESCE(period1_kzt.cnt, 0)) < 0 
            THEN '🔴 ' || ROUND((COALESCE(period2_kzt.cnt, 0) - COALESCE(period1_kzt.cnt, 0)) * 100.0 / NULLIF(COALESCE(period1_kzt.cnt, 0), 0), 2) || '%'
        ELSE '⚪️ 0%'
    END AS "KZT Изменение",
    -- RUB данные
    COALESCE(period1_rub.cnt, 0) AS "RUB date1",
    COALESCE(period2_rub.cnt, 0) AS "RUB date2",
    (COALESCE(period2_rub.cnt, 0) - COALESCE(period1_rub.cnt, 0)) AS "RUB Δ (абс.)",
    CASE
        WHEN COALESCE(period1_rub.cnt, 0) = 0 AND COALESCE(period2_rub.cnt, 0) = 0 THEN '⚪️ 0 → 0'
        WHEN COALESCE(period1_rub.cnt, 0) = 0 THEN '🟢 +∞% (новый поток)'
        WHEN (COALESCE(period2_rub.cnt, 0) - COALESCE(period1_rub.cnt, 0)) > 0 
            THEN '🟢 +' || ROUND((COALESCE(period2_rub.cnt, 0) - COALESCE(period1_rub.cnt, 0)) * 100.0 / NULLIF(COALESCE(period1_rub.cnt, 0), 0), 2) || '%'
        WHEN (COALESCE(period2_rub.cnt, 0) - COALESCE(period1_rub.cnt, 0)) < 0 
            THEN '🔴 ' || ROUND((COALESCE(period2_rub.cnt, 0) - COALESCE(period1_rub.cnt, 0)) * 100.0 / NULLIF(COALESCE(period1_rub.cnt, 0), 0), 2) || '%'
        ELSE '⚪️ 0%'
    END AS "RUB Изменение"
FROM selected_ids m
LEFT JOIN public.db_wp_partners p ON m.id = p.id
-- KZT период 1
LEFT JOIN (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_operations
    WHERE currency = 'KZT'
      AND status IN ('PAY_OK', 'PAY_FAIL', 'CHECK_FAIL')
      AND partner_id IN (SELECT id FROM selected_ids)
      AND created >= (SELECT period1_start FROM params)
      AND created < (SELECT period1_end FROM params)
    GROUP BY partner_id
) period1_kzt ON m.id = period1_kzt.partner_id
-- KZT период 2
LEFT JOIN (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_operations
    WHERE currency = 'KZT'
      AND status IN ('PAY_OK', 'PAY_FAIL', 'CHECK_FAIL')
      AND partner_id IN (SELECT id FROM selected_ids)
      AND created >= (SELECT period2_start FROM params)
      AND created < (SELECT period2_end FROM params)
    GROUP BY partner_id
) period2_kzt ON m.id = period2_kzt.partner_id
-- RUB период 1
LEFT JOIN (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_operations
    WHERE currency = 'RUB'
      AND status IN ('PAY_OK', 'PAY_FAIL', 'CHECK_FAIL')
      AND partner_id IN (SELECT id FROM selected_ids)
      AND created >= (SELECT period1_start FROM params)
      AND created < (SELECT period1_end FROM params)
    GROUP BY partner_id
) period1_rub ON m.id = period1_rub.partner_id
-- RUB период 2
LEFT JOIN (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_operations
    WHERE currency = 'RUB'
      AND status IN ('PAY_OK', 'PAY_FAIL', 'CHECK_FAIL')
      AND partner_id IN (SELECT id FROM selected_ids)
      AND created >= (SELECT period2_start FROM params)
      AND created < (SELECT period2_end FROM params)
    GROUP BY partner_id
) period2_rub ON m.id = period2_rub.partner_id
ORDER BY "KZT date1" DESC, "RUB date1" DESC, "Мерчант";