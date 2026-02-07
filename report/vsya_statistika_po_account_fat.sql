-- =====================
-- ПАРАМЕТРЫ ДЛЯ ЗАПРОСА
-- =====================
-- :p_from        TIMESTAMP — начальная дата/время (включительно, >=)
-- :p_to          TIMESTAMP — конечная дата/время (исключая, <)
-- :p_account_ids (обязательный) text — список id аккаунтов через запятую, например '111,222,333'
--
-- Пример запуска с psql:
--   psql -v p_from="'2026-02-01 00:00:00'" -v p_to="'2026-02-02 00:00:00'" -v p_account_ids="'111,222,333'" -f vsya_statistika_po_account_fat.sql
--
-- В DBeaver: замените :p_from, :p_to, :p_account_ids на значения вручную.

WITH account_flags AS (
  SELECT
    account_id,
    MAX(account_name) AS account_name, -- если account_name не в исходной таблице, используйте JOIN
    MAX(CASE WHEN payment_type = 'create' THEN 1 ELSE 0 END) AS has_create,
    MAX(CASE WHEN payment_type = 'pay' THEN 1 ELSE 0 END) AS has_pay,
    MAX(CASE WHEN payment_type = 'pay' AND operation_status_name = 'success' THEN 1 ELSE 0 END) AS has_success_pay,
    MAX(CASE WHEN payment_type = 'pay' AND operation_status_name IN ('error') THEN 1 ELSE 0 END) AS has_error_pay
  FROM db_ifat
  WHERE created_at >= :p_from
    AND created_at <  :p_to
    AND payment_type IN ('create','pay')
    AND (
      :p_account_ids IS NULL
      OR COALESCE(account_id::text, '0') = ANY (string_to_array(:p_account_ids, ','))
    )
  GROUP BY account_id
)

SELECT
  CAST(:p_from AS date) AS date,
  af.account_id,
  af.account_name,
  SUM(af.has_success_pay) AS success_cnt,
  SUM(CASE WHEN af.has_pay = 1 AND af.has_success_pay = 0 THEN 1 ELSE 0 END) AS error_cnt,
  ROUND(
    CASE WHEN SUM(af.has_create) = 0 THEN 0
         ELSE SUM(af.has_success_pay)::numeric * 100.0 / SUM(af.has_create)
    END
  , 2) AS conversion,
  SUM(CASE WHEN af.has_create = 1 AND af.has_pay = 0 THEN 1 ELSE 0 END) AS unfinished_cnt,
  SUM(af.has_create) AS total_creates
FROM (
  SELECT
    CAST(:p_from AS date) AS date,
    af.account_id,
    af.account_name,
    SUM(af.has_success_pay) AS success_cnt,
    SUM(CASE WHEN af.has_pay = 1 AND af.has_success_pay = 0 THEN 1 ELSE 0 END) AS error_cnt,
    ROUND(
      CASE WHEN SUM(af.has_create) = 0 THEN 0
           ELSE SUM(af.has_success_pay)::numeric * 100.0 / SUM(af.has_create)
      END
    , 2) AS conversion,
    SUM(CASE WHEN af.has_create = 1 AND af.has_pay = 0 THEN 1 ELSE 0 END) AS unfinished_cnt,
    SUM(af.has_create) AS total_creates
  FROM account_flags af
  GROUP BY af.account_id, af.account_name

  UNION ALL

  SELECT
    CAST(:p_from AS date) AS date,
    0 AS account_id,
    'Итого'::text AS account_name,
    SUM(af.has_success_pay) AS success_cnt,
    SUM(CASE WHEN af.has_pay = 1 AND af.has_success_pay = 0 THEN 1 ELSE 0 END) AS error_cnt,
    ROUND(
      CASE WHEN SUM(af.has_create) = 0 THEN 0
           ELSE SUM(af.has_success_pay)::numeric * 100.0 / SUM(af.has_create)
      END
    , 2) AS conversion,
    SUM(CASE WHEN af.has_create = 1 AND af.has_pay = 0 THEN 1 ELSE 0 END) AS unfinished_cnt,
    SUM(af.has_create) AS total_creates
  FROM account_flags af
) t
ORDER BY CASE WHEN account_id = 0 THEN 1 ELSE 0 END, account_id;

-- Примечания:
--  - Если account_name нужно подтянуть из другой таблицы, добавьте JOIN в CTE account_flags.
--  - Если нужна фильтрация по части названия аккаунта — добавлю.
