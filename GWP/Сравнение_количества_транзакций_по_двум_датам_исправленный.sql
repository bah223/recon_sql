--title: Сравнение платежей по мерчантам: 20.12.2025 vs 27.12.2025 (+ рост/падение)
--status:ok
WITH selected_partners AS (
    SELECT id, name
    FROM public.db_wp_partners
    WHERE id IN (
        3921, 4002, 3810, 3673, 4227, 3787, 3834, 3725, 3876, 3773,
        3651, 4042, 3245, 3240, 3243, 3244, 3239, 3247, 3246, 3035,
        3248, 3232, 3233, 3028, 3234, 3235, 3236, 3021, 3261, 3038,
        1510, 3953, 3954, 3956, 4190, 4000, 4192, 4084, 4211, 4202,
        4203, 4257, 4291, 4043, 4039
    )
),
payments_20251220 AS (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_pay_operations
    WHERE created >= '2025-12-20 00:00:00'
      AND created <  '2025-12-21 00:00:00'
      AND partner_id IN (SELECT id FROM selected_partners)
    GROUP BY partner_id
),
payments_20251227 AS (
    SELECT partner_id, COUNT(*) AS cnt
    FROM public.db_wp_pay_operations
    WHERE created >= '2025-12-27 00:00:00'
      AND created <  '2025-12-28 00:00:00'
      AND partner_id IN (SELECT id FROM selected_partners)
    GROUP BY partner_id
),
comparison AS (
    SELECT
        p.id AS partner_id,
        p.name AS merchant_name,
        COALESCE(d20.cnt, 0) AS cnt_20251220,
        COALESCE(d27.cnt, 0) AS cnt_20251227,
        COALESCE(d27.cnt, 0) - COALESCE(d20.cnt, 0) AS diff
    FROM selected_partners p
    LEFT JOIN payments_20251220 d20 ON p.id = d20.partner_id
    LEFT JOIN payments_20251227 d27 ON p.id = d27.partner_id
)
SELECT
    partner_id,
    merchant_name,
    cnt_20251220 AS "2025-12-20",
    cnt_20251227 AS "2025-12-27",
    diff AS "Δ (абс.)",
    CASE
        WHEN cnt_20251220 = 0 AND cnt_20251227 = 0 THEN '⚪️ 0 → 0'
        WHEN cnt_20251220 = 0 THEN '🟢 +∞% (новый поток)'
        WHEN diff > 0 THEN '🟢 +' || ROUND(diff * 100.0 / NULLIF(cnt_20251220, 0), 2) || '%'
        WHEN diff < 0 THEN '🔴 ' || ROUND(diff * 100.0 / NULLIF(cnt_20251220, 0), 2) || '%'
        ELSE '⚪️ 0%'
    END AS "Изменение"
FROM comparison
ORDER BY cnt_20251227 DESC, merchant_name;
