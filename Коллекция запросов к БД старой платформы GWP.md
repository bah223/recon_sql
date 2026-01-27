
```sql
-- ==================================================================
-- WP — 1. Количество транзакций по мерчанту (МСК)
-- ==================================================================
-- Считает ВСЕ операции (любой статус) за указанный день по МСК.
-- partner_id — ID мерчанта из public.db_wp_partners.
-- Дата: 28.12.2025 → UTC диапазон: 27.12.2025 21:00:00 – 28.12.2025 21:00:00
SELECT COUNT(*) AS total_transactions
FROM public.db_wp_pay_operations
WHERE partner_id = 3035
  AND created >= '2025-12-27 21:00:00'
  AND created < '2025-12-28 21:00:00';


-- ==================================================================
-- WP — 2. Конверсия по мерчанту (МСК)
-- ==================================================================
-- Конверсия = (успешные / всего) * 100%
-- Успешные статусы: 'PAY_OK', 'MANUAL_OK'
-- Если операций нет — конверсия = NULL (без деления на ноль)
SELECT
  COUNT(*) AS total_transactions,
  COUNT(*) FILTER (WHERE status IN ('PAY_OK', 'MANUAL_OK')) AS success_transactions,
  ROUND(
    COUNT(*) FILTER (WHERE status IN ('PAY_OK', 'MANUAL_OK')) * 100.0
    / NULLIF(COUNT(*), 0),
    2
  ) AS conversion_percent
FROM public.db_wp_pay_operations
WHERE partner_id = 3035
  AND created >= '2025-12-27 21:00:00'
  AND created < '2025-12-28 21:00:00';


-- ==================================================================
-- WP — 3. Последняя операция по мерчанту (МСК)
-- ==================================================================
-- Возвращает самую позднюю операцию за указанный день по МСК.
-- Если операций нет — вернёт NULL.
SELECT MAX(created) AS last_operation_time
FROM public.db_wp_pay_operations
WHERE partner_id = 3035
  AND created >= '2025-12-27 21:00:00'
  AND created < '2025-12-28 21:00:00';


-- ==================================================================
-- WP — 4. Полная аналитика по одному мерчанту (МСК)
-- ==================================================================
-- Всё в одном запросе: количество, конверсия, последняя операция.
-- Легко копировать и менять partner_id + дату.
SELECT
  3035 AS partner_id,
  'PAY365/DonatePay_SBP_API-RUB' AS merchant_name,
  COUNT(*) AS total_transactions,
  COUNT(*) FILTER (WHERE status IN ('PAY_OK', 'MANUAL_OK')) AS success_transactions,
  ROUND(
    COUNT(*) FILTER (WHERE status IN ('PAY_OK', 'MANUAL_OK')) * 100.0
    / NULLIF(COUNT(*), 0),
    2
  ) AS conversion_percent,
  MAX(created) AS last_operation_time
FROM public.db_wp_pay_operations
WHERE partner_id = 3035
  AND created >= '2025-12-27 21:00:00'
  AND created < '2025-12-28 21:00:00';


-- ==================================================================
-- WP — 5. Полная аналитика по нескольким мерчантам (МСК)
-- ==================================================================
-- Как добавить мерчанта:
--   1. Узнай его partner_id:
--      SELECT id, name FROM public.db_wp_partners WHERE name ILIKE '%...%';
--   2. Добавь строку в VALUES: (ID, 'Название')
--   3. Готово!
WITH merchants AS (
  SELECT * FROM (VALUES
    (3035, 'PAY365/DonatePay_SBP_API-RUB'),
    (3239, 'PAY365/Mosparking(МТС)-RUB'),
    (3233, 'PAY365/ТК_Центр_Stoloto(МТС)-RUB')
    -- ↑ ДОБАВЛЯЙ СЮДА
  ) AS t(partner_id, merchant_name)
)
SELECT
  m.merchant_name AS "Мерчант",
  m.partner_id AS "ID",
  COUNT(*) AS "Всего",
  COUNT(*) FILTER (WHERE x.status IN ('PAY_OK', 'MANUAL_OK')) AS "Успешных",
  ROUND(
    COUNT(*) FILTER (WHERE x.status IN ('PAY_OK', 'MANUAL_OK')) * 100.0
    / NULLIF(COUNT(*), 0),
    2
  ) AS "Конверсия, %",
  MAX(x.created) AS "Последняя операция"
FROM merchants m
LEFT JOIN public.db_wp_pay_operations x
  ON x.partner_id = m.partner_id
  AND x.created >= '2025-12-27 21:00:00'
  AND x.created < '2025-12-28 21:00:00'
GROUP BY m.partner_id, m.merchant_name
ORDER BY "Всего" DESC;