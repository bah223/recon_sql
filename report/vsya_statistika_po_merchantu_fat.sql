
-- ПАРАМЕТРЫ ВРЕМЕНИ
-- :p_from и :p_to должны быть TIMESTAMP (дата + время). Формат примера: '2026-02-01 00:00:00'
-- Семантика диапазона: все транзакции с created_at в интервале [:p_from, :p_to)
-- Пример запуска через psql (замените значения на нужные):
-- psql -v p_from="'2026-02-01 00:00:00'" -v p_to="'2026-02-02 00:00:00'" -f recon_sql/report/vsya_statistika_po_merchantu_fat.sql
-- Пример подстановки литералов (для быстрой проверки) — замените :p_from/:p_to в WHERE на литералы:
-- WHERE created_at >= '2026-02-01 00:00:00' AND created_at < '2026-02-02 00:00:00'

-- Колонки выдачи:
-- 1) date          - дата, взятая из параметра :p_from (date)
-- 2) shop_id       - id магазина
-- 3) success_cnt   - общее число успешных транзакций (payment_type='pay' и operation_status_name='success')
-- 4) error_cnt     - общее число неуспешных транзакций (payment_type='pay' и operation_status_name='error')
-- 5) conversion    - конверсия в процентах = successful / total_creates * 100 (округлено до 2 знаков)
-- 6) unfinished_cnt- незавершённые транзакции = creates - pays

-- Примечания:
--  - Таблица: db_ifat (см. другие запросы в репозитории)
--  - Под "create" понимаем начальную операцию (payment_type='create').
--  - "unfinished" рассчитывается как количество create без финальной pay-операции (approximated as creates - pays).

SELECT
  CAST(:p_from AS date) AS date,  -- в колонке `date` хранится дата начала периода (дата из :p_from)
  COALESCE(shop_id, 0) AS shop_id,
  SUM(CASE WHEN payment_type = 'pay' AND operation_status_name = 'success' THEN 1 ELSE 0 END) AS success_cnt,
  SUM(CASE WHEN payment_type = 'pay' AND operation_status_name IN ('error') THEN 1 ELSE 0 END) AS error_cnt,
  ROUND(
    CASE WHEN SUM(CASE WHEN payment_type = 'create' THEN 1 ELSE 0 END) = 0 THEN 0
         ELSE SUM(CASE WHEN payment_type = 'pay' AND operation_status_name = 'success' THEN 1 ELSE 0 END)::numeric * 100.0
              / SUM(CASE WHEN payment_type = 'create' THEN 1 ELSE 0 END)
    END
  , 2) AS conversion,
  (SUM(CASE WHEN payment_type = 'create' THEN 1 ELSE 0 END) - SUM(CASE WHEN payment_type = 'pay' THEN 1 ELSE 0 END)) AS unfinished_cnt
FROM db_ifat
WHERE created_at >= :p_from
  AND created_at <  :p_to
  AND payment_type IN ('create','pay')
GROUP BY COALESCE(shop_id, 0)
ORDER BY shop_id;
