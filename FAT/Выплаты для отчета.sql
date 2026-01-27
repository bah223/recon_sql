SELECT
    COALESCE(p.name, 'ID: ' || m.id::text) AS "Мерчант",
    COALESCE(d01.cnt, 0) AS "Дата1",
    COALESCE(d08.cnt, 0) AS "Дата2",
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
FROM (
    SELECT 1510 AS id
    UNION ALL SELECT 4190
    UNION ALL SELECT 4084
    UNION ALL SELECT 4291
) m
LEFT JOIN public.db_wp_partners p ON m.id = p.id
LEFT JOIN (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_operations
    WHERE currency = 'KZT'
      AND status = 'PAY_OK'
      AND partner_id IN (1510, 4190, 4084, 4291)
      AND created >= '2025-12-31 21:00:00'
      AND created < '2026-01-01 21:00:00'
    GROUP BY partner_id
) d01 ON m.id = d01.partner_id
LEFT JOIN (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_operations
    WHERE currency = 'KZT'
      AND status = 'PAY_OK'
      AND partner_id IN (1510, 4190, 4084, 4291)
      AND created >= '2026-01-07 21:00:00'
      AND created < '2026-01-08 21:00:00'
    GROUP BY partner_id
) d08 ON m.id = d08.partner_id
ORDER BY "Дата2" DESC, "Мерчант";