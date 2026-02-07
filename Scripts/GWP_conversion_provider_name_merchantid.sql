WITH order_flags AS (
  SELECT
    op.id,
    op.partner_id,
    pa.name AS partner_name,
    op.provider,
    MAX(CASE WHEN op.status IN ('INIT_OK','PROCESSING','PAY_PROCESSING') THEN 1 ELSE 0 END) AS has_create,
    MAX(CASE WHEN op.status IN ('PAY_OK','MANUAL_OK','INIT_FAIL','PAY_FAIL','MANUAL_FAIL') THEN 1 ELSE 0 END) AS has_pay,
    MAX(CASE WHEN op.status IN ('PAY_OK','MANUAL_OK') THEN 1 ELSE 0 END) AS has_success_pay,
    MAX(CASE WHEN op.status IN ('PAY_FAIL','MANUAL_FAIL') THEN 1 ELSE 0 END) AS has_error_pay
  FROM db_wp_pay_operations op
  JOIN db_wp_partners pa ON op.partner_id = pa.id
  WHERE op.created >= '2026-02-06 00:00:00'
    AND op.created <  '2026-02-07 00:00:00'
    AND op.partner_id = 3038
  GROUP BY op.id, op.partner_id, pa.name, op.provider
)
SELECT
  CAST('2026-02-06 00:00:00' AS date) AS date,
  ofl.partner_id,
  ofl.partner_name,
  ofl.provider,
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
GROUP BY ofl.partner_id, ofl.partner_name, ofl.provider
ORDER BY ofl.partner_id;