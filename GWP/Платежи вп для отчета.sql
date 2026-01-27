WITH selected_partners AS (
    SELECT id, name
    FROM public.db_wp_partners
    WHERE id IN (
        4227, 3725, 3651, 4042, 3245, 3240, 3243, 3244, 3239, 3247,
        3246, 3035, 3248, 3232, 3028, 3234, 3235, 3236, 3233, 3021,
        3038, 4039, 3953, 3954, 3956, 4000, 4192, 4084, 4211, 4202,
        4203, 4257, 4043, 4327, 4326,
        3921, 4002, 3834, 3876
    )
),
params AS (
    SELECT 
        '2026-01-08 21:00:00'::timestamp as date1_start,
        '2026-01-09 21:00:00'::timestamp as date1_end,
        '2026-01-15 21:00:00'::timestamp as date2_start,
        '2026-01-16 21:00:00'::timestamp as date2_end
),
payments_date1 AS (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_pay_operations
    WHERE created >= (SELECT date1_start FROM params)
      AND created <  (SELECT date1_end FROM params)
      AND partner_id IN (SELECT id FROM selected_partners)
    GROUP BY partner_id
),
payments_date2 AS (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_pay_operations
    WHERE created >= (SELECT date2_start FROM params)
      AND created <  (SELECT date2_end FROM params)
      AND partner_id IN (SELECT id FROM selected_partners)
    GROUP BY partner_id
),
comparison AS (
    SELECT
        p.id AS partner_id,
        p.name AS merchant_name,
        COALESCE(d1.cnt, 0) AS cnt_date1,
        COALESCE(d2.cnt, 0) AS cnt_date2,
        COALESCE(d2.cnt, 0) - COALESCE(d1.cnt, 0) AS diff
    FROM selected_partners p
    LEFT JOIN payments_date1 d1 ON p.id = d1.partner_id
    LEFT JOIN payments_date2 d2 ON p.id = d2.partner_id
)
SELECT
    partner_id,
    merchant_name,
    cnt_date1 AS "date1",  -- Здесь вручную поменяйте названия дат
    cnt_date2 AS "date2",  -- Здесь вручную поменяйте названия дат
    diff AS "Δ (абс.)",
    CASE
        WHEN cnt_date1 = 0 AND cnt_date2 = 0 THEN '⚪️ 0 → 0'
        WHEN cnt_date1 = 0 THEN '🟢 +∞% (новый поток)'
        WHEN diff > 0 THEN '🟢 +' || ROUND(diff * 100.0 / NULLIF(cnt_date1, 0), 2) || '%'
        WHEN diff < 0 THEN '🔴 ' || ROUND(diff * 100.0 / NULLIF(cnt_date1, 0), 2) || '%'
        ELSE '⚪️ 0%'
    END AS "Изменение"
FROM comparison
ORDER BY cnt_date2 DESC, merchant_name;