-- Запрос по платежам в RUB в процессинге GWP за период времени c 00:00 - 12:00, сравниваем количество транзакций дата1 и дата2 - рост и падение отображаем в процентах в выдаче.
-- В этом запросе меняем только даты
-- ок

WITH selected_partners AS (
    SELECT id, name
    FROM public.db_wp_partners
    WHERE id IN (
        4227, 3725, 3651, 4042, 3245, 3240, 3243, 3244, 3239, 3247, -- Здесь редактируем мерчантов для отчета можно добавить\убрать id
        3246, 3035, 3248, 3232, 3028, 3234, 3235, 3236, 3233, 3021,
        3038, 4039, 3953, 3954, 3956, 4000, 4192, 4211, 4202, 4276, -- 3038 Термокит - нет в нашей таблице ид
        4203, 4257, 4043, 4327, 4326, 3921, 4002, 3834, 3876, 4326,
        4246, 4252, 4069, 4085, 4065, 4116, 4119, 4066, 4068, 4067,
        4117, 4247, 4258, 4261, 4273, 4271, 4255, 4268, 4327, 3243, 4277, 4278, 4327, 4326
    )
),
partner_groups AS (
    SELECT 
        p.id,
        p.name,
        CASE 
            WHEN p.id IN (
                4246, 4252, 4069, 4085, 4065, 4116, 4119, 4066, 4068, 4067,
                4117, 4247, 4258, 4261, 4273, 4271, 4255, 4268
            ) THEN 'PAY365/ZT/Aghanim Inc. (все аккаунты: МТС, Билайн)'
            ELSE p.name
        END AS group_name
    FROM selected_partners p
),
params AS (
    SELECT 
        '2026-01-29'::date as date1,  -- Дата1 (00:00-12:00)
        '2026-02-05'::date as date2   -- Дата2 (00:00-12:00)
),
-- Половина суток: 00:00-12:00
created_date1 AS (
    SELECT po.partner_id, COUNT(*) AS cnt
    FROM public.db_wp_pay_operations po
    WHERE po.created >= (SELECT date1 FROM params)
      AND po.created <  (SELECT date1 FROM params) + INTERVAL '12 hours'
      AND po.partner_id IN (SELECT id FROM selected_partners)
    GROUP BY po.partner_id
),
created_date2 AS (
    SELECT po.partner_id, COUNT(*) AS cnt
    FROM public.db_wp_pay_operations po
    WHERE po.created >= (SELECT date2 FROM params)
      AND po.created <  (SELECT date2 FROM params) + INTERVAL '12 hours'
      AND po.partner_id IN (SELECT id FROM selected_partners)
    GROUP BY po.partner_id
),
partner_data AS (
    SELECT
        pg.id AS partner_id,
        pg.group_name,
        pg.name AS original_name,
        COALESCE(d1.cnt, 0) AS cnt_date1,
        COALESCE(d2.cnt, 0) AS cnt_date2
    FROM partner_groups pg
    LEFT JOIN created_date1 d1 ON pg.id = d1.partner_id
    LEFT JOIN created_date2 d2 ON pg.id = d2.partner_id
),
aggregated_data AS (
    SELECT
        group_name,
        STRING_AGG(partner_id::text, ', ' ORDER BY partner_id) AS all_shop_ids,
        SUM(cnt_date1) AS total_date1,
        SUM(cnt_date2) AS total_date2,
        SUM(cnt_date2) - SUM(cnt_date1) AS diff
    FROM partner_data
    GROUP BY group_name
)
SELECT
    all_shop_ids AS "ID магазинов",
    group_name AS "Мерчант / Группа",
    total_date1 AS "Транзакций (дата1 00:00-12:00)",
    total_date2 AS "Транзакций (дата2 00:00-12:00)",
    diff AS "Δ (абс.)",
    CASE
        WHEN total_date1 = 0 AND total_date2 = 0 THEN '⚪️ 0 → 0'
        WHEN total_date1 = 0 THEN '🟢 +∞% (первые транзакции)'
        WHEN diff > 0 THEN '🟢 +' || ROUND(diff * 100.0 / NULLIF(total_date1, 0), 2) || '%'
        WHEN diff < 0 THEN '🔴 ' || ROUND(diff * 100.0 / NULLIF(total_date1, 0), 2) || '%'
        ELSE '⚪️ 0%'
    END AS "Изменение"
FROM aggregated_data
ORDER BY 
    CASE WHEN group_name = 'PAY365/ZT/Aghanim Inc. (все аккаунты: МТС, Билайн)' THEN 1 ELSE 2 END,
    total_date2 DESC;