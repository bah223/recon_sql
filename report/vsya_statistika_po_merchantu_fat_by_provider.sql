
-- =====================
-- ПАРАМЕТРЫ ДЛЯ ЗАПРОСА
-- =====================
-- :p_from      TIMESTAMP — начальная дата/время (включительно, >=)
-- :p_to        TIMESTAMP — конечная дата/время (исключая, <)
-- :p_shop_id   (optional) numeric — один id мерчанта (если NULL — не фильтруем по id)
-- :p_shop_ids  (optional) text — список id через запятую, например '123,456,789' (если не NULL — фильтруем по этим id)
-- :p_shop_name (optional) text — часть названия мерчанта (ILIKE '%...%'), если NULL — не фильтруем по названию
--
-- Примеры запуска с psql:
--   psql -v p_from="'2026-02-01 00:00:00'" -v p_to="'2026-02-02 00:00:00'" -v p_shop_id="123" -v p_shop_ids="NULL" -v p_shop_name="NULL" -f vsya_statistika_po_merchantu_fat_by_provider.sql
--   psql -v p_from="'2026-02-01 00:00:00'" -v p_to="'2026-02-02 00:00:00'" -v p_shop_id="NULL" -v p_shop_ids="'123,456,789'" -v p_shop_name="NULL" -f vsya_statistika_po_merchantu_fat_by_provider.sql
--   psql -v p_from="'2026-02-01 00:00:00'" -v p_to="'2026-02-02 00:00:00'" -v p_shop_id="NULL" -v p_shop_ids="NULL" -v p_shop_name="'MyShop'" -f vsya_statistika_po_merchantu_fat_by_provider.sql
--
-- Тестовый пример (мерчанты 1729,1730,1731 за 6 февраля 2026):
--   psql -v p_from="'2026-02-06 00:00:00'" -v p_to="'2026-02-07 00:00:00'" -v p_shop_id="NULL" -v p_shop_ids="'1729,1730,1731'" -v p_shop_name="NULL" -f vsya_statistika_po_merchantu_fat_by_provider.sql

WITH order_flags AS (
  SELECT
    order_id,
    COALESCE(shop_id, 0) AS shop_id,
    COALESCE(shop_name, '') AS shop_name,
    driver_name AS provider_name,
    MAX(CASE WHEN payment_type = 'create' THEN 1 ELSE 0 END) AS has_create,
    MAX(CASE WHEN payment_type = 'pay' THEN 1 ELSE 0 END) AS has_pay,
    MAX(CASE WHEN payment_type = 'pay' AND operation_status_name = 'success' THEN 1 ELSE 0 END) AS has_success_pay,
    MAX(CASE WHEN payment_type = 'pay' AND operation_status_name IN ('error') THEN 1 ELSE 0 END) AS has_error_pay
  FROM db_ifat
  WHERE created_at >= :p_from
    AND created_at <  :p_to
    AND payment_type IN ('create','pay')
    -- Фильтрация по мерчанту: по списку id, по одному id или по части названия (если переданы)
    AND (
      :p_shop_ids IS NULL
      OR COALESCE(shop_id::text, '0') = ANY (string_to_array(:p_shop_ids, ','))
    )
    AND (:p_shop_id IS NULL OR COALESCE(shop_id,0) = :p_shop_id)
    AND (:p_shop_name IS NULL OR shop_name ILIKE ('%' || :p_shop_name || '%'))
  GROUP BY order_id, COALESCE(shop_id,0), shop_name, COALESCE(service_id,0), driver_name
)

SELECT
  CAST(:p_from AS date) AS date,
  ofl.shop_id,
  ofl.shop_name,
  -- ofl.provider_id, -- убрано по требованию
  ofl.provider_name,
  SUM(ofl.has_success_pay) AS success_cnt,
  SUM(CASE WHEN ofl.has_pay = 1 AND ofl.has_success_pay = 0 THEN 1 ELSE 0 END) AS error_cnt,
  ROUND(
    CASE WHEN SUM(ofl.has_create) = 0 THEN 0
         ELSE SUM(ofl.has_success_pay)::numeric * 100.0 / SUM(ofl.has_create)
    END
  , 2) AS conversion,
  SUM(CASE WHEN ofl.has_create = 1 AND ofl.has_pay = 0 THEN 1 ELSE 0 END) AS unfinished_cnt,
  SUM(ofl.has_create) AS total_creates
FROM (
  SELECT
    CAST(:p_from AS date) AS date,
    ofl.shop_id,
    ofl.shop_name,
    ofl.provider_name,
    SUM(ofl.has_success_pay) AS success_cnt,
    SUM(CASE WHEN ofl.has_pay = 1 AND ofl.has_success_pay = 0 THEN 1 ELSE 0 END) AS error_cnt,
    ROUND(
      CASE WHEN SUM(ofl.has_create) = 0 THEN 0
           ELSE SUM(ofl.has_success_pay)::numeric * 100.0 / SUM(ofl.has_create)
      END
    , 2) AS conversion,
    SUM(CASE WHEN ofl.has_create = 1 AND ofl.has_pay = 0 THEN 1 ELSE 0 END) AS unfinished_cnt,
    SUM(ofl.has_create) AS total_creates
  FROM order_flags ofl
  GROUP BY ofl.shop_id, ofl.shop_name, ofl.provider_name

  UNION ALL

  -- Итого по всем shop/provider
  SELECT
    CAST(:p_from AS date) AS date,
    0 AS shop_id,
    'Итого'::text AS shop_name,
    'ALL'::text AS provider_name,
    SUM(ofl.has_success_pay) AS success_cnt,
    SUM(CASE WHEN ofl.has_pay = 1 AND ofl.has_success_pay = 0 THEN 1 ELSE 0 END) AS error_cnt,
    ROUND(
      CASE WHEN SUM(ofl.has_create) = 0 THEN 0
           ELSE SUM(ofl.has_success_pay)::numeric * 100.0 / SUM(ofl.has_create)
      END
    , 2) AS conversion,
    SUM(CASE WHEN ofl.has_create = 1 AND ofl.has_pay = 0 THEN 1 ELSE 0 END) AS unfinished_cnt,
    SUM(ofl.has_create) AS total_creates
  FROM order_flags ofl
) t
ORDER BY CASE WHEN shop_id = 0 THEN 1 ELSE 0 END, shop_id, provider_name;
-- Примечания:
--  - Этот вариант считает незавершёнными те order_id, у которых была create-операция, но не было ни одной pay-операции.
--  - Если нужно считать "незавершёнными" иначе (например, create и только error pay), скажите — поправлю логику.
--  - Для psql-передачи параметров используйте: psql -v p_from="'2026-02-01 00:00:00'" -v p_to="'2026-02-02 00:00:00'" -v p_shop_id="NULL" -v p_shop_name="NULL" -f ...
