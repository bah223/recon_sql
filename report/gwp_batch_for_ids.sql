-- GWP batch report for given partner ids (with totals)

WITH order_flags AS (
  SELECT
    op.id AS order_id,
    COALESCE(op.partner_id, 0) AS partner_id,
    pa.name AS partner_name,
    op.provider,
    MAX(CASE WHEN op.status IN ('INIT_OK','PROCESSING','PAY_PROCESSING') THEN 1 ELSE 0 END) AS has_create,
    MAX(CASE WHEN op.status IN ('PAY_OK','MANUAL_OK','INIT_FAIL','PAY_FAIL','MANUAL_FAIL') THEN 1 ELSE 0 END) AS has_pay,
    MAX(CASE WHEN op.status IN ('PAY_OK','MANUAL_OK') THEN 1 ELSE 0 END) AS has_success_pay,
    MAX(CASE WHEN op.status IN ('PAY_FAIL','MANUAL_FAIL') THEN 1 ELSE 0 END) AS has_error_pay,
    MAX(op.amount) AS order_amount,
    MAX(CASE WHEN op.status IN ('PAY_OK','MANUAL_OK') THEN op.amount ELSE 0 END) AS order_amount_success
  FROM db_wp_pay_operations op
  JOIN db_wp_partners pa ON op.partner_id = pa.id
  WHERE op.created >= '2026-02-06 00:00:00'
    AND op.created <  '2026-02-07 00:00:00'
    AND op.partner_id IN (
      3921,4002,3810,3673,4227,3787,3834,3725,3876,3773,3651,4042,3245,3240,3243,3244,
      3239,3247,3246,3035,3248,3232,3028,3234,3235,3236,3233,3021,3261,3038,1510,
      4039,3953,3954,3956,4190,4000,4192,4084,4211,4202,4257,4291,4043,4327,4326,
      4316,4276,4277,4278
    )
  GROUP BY op.id, op.partner_id, pa.name, op.provider
)

  SELECT
    CAST('2026-02-06 00:00:00' AS date) AS report_date,
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
    SUM(ofl.has_create) AS total_creates,
    SUM(ofl.order_amount) AS turnover_all,
    SUM(ofl.order_amount_success) AS turnover_success
  FROM order_flags AS ofl
  GROUP BY ofl.partner_id, ofl.partner_name, ofl.provider

  UNION ALL

  SELECT
    CAST('2026-02-06 00:00:00' AS date) AS report_date,
    0 AS partner_id,
    'Итого'::text AS partner_name,
    'ALL'::text AS provider,
    SUM(ofl.has_success_pay) AS success_cnt,
    SUM(CASE WHEN ofl.has_pay = 1 AND ofl.has_success_pay = 0 THEN 1 ELSE 0 END) AS error_cnt,
    ROUND(
      CASE WHEN SUM(ofl.has_create) = 0 THEN 0
           ELSE SUM(ofl.has_success_pay)::numeric * 100.0 / SUM(ofl.has_create)
      END
    , 2) AS conversion,
    SUM(CASE WHEN ofl.has_create = 1 AND ofl.has_pay = 0 THEN 1 ELSE 0 END) AS unfinished_cnt,
    SUM(ofl.has_create) AS total_creates,
    SUM(ofl.order_amount) AS turnover_all,
    SUM(ofl.order_amount_success) AS turnover_success
  FROM order_flags AS ofl

  UNION ALL

  -- totals for single partner (3921)
  SELECT
    CAST('2026-02-06 00:00:00' AS date) AS report_date,
    3921 AS partner_id,
    ('Итого партнёра ' || 3921)::text AS partner_name,
    'ALL'::text AS provider,
    SUM(ofl.has_success_pay) AS success_cnt,
    SUM(CASE WHEN ofl.has_pay = 1 AND ofl.has_success_pay = 0 THEN 1 ELSE 0 END) AS error_cnt,
    ROUND(
      CASE WHEN SUM(ofl.has_create) = 0 THEN 0
           ELSE SUM(ofl.has_success_pay)::numeric * 100.0 / SUM(ofl.has_create)
      END
    , 2) AS conversion,
    SUM(CASE WHEN ofl.has_create = 1 AND ofl.has_pay = 0 THEN 1 ELSE 0 END) AS unfinished_cnt,
    SUM(ofl.has_create) AS total_creates,
    SUM(ofl.order_amount) AS turnover_all,
    SUM(ofl.order_amount_success) AS turnover_success
  FROM order_flags AS ofl
  WHERE ofl.partner_id = 3921
ORDER BY CASE WHEN partner_id = 0 THEN 1 ELSE 0 END, partner_id, provider;

-- Example: single-merchant turnover (partner_id = 3038)
WITH order_flags_one AS (
  SELECT
    op.id AS order_id,
    op.partner_id,
    pa.name AS partner_name,
    op.provider,
    MAX(op.amount) AS amount,
    MAX(CASE WHEN op.status IN ('PAY_OK','MANUAL_OK') THEN op.amount ELSE 0 END) AS amount_success,
    MAX(op.currency) AS currency
  FROM db_wp_pay_operations op
  JOIN db_wp_partners pa ON op.partner_id = pa.id
  WHERE op.created >= '2026-02-06 00:00:00'
    AND op.created < '2026-02-07 00:00:00'
    AND op.partner_id = 3038
  GROUP BY op.id, op.partner_id, pa.name, op.provider
)

SELECT
  CAST('2026-02-06 00:00:00' AS date) AS report_date,
  ofl.partner_id,
  ofl.partner_name,
  ofl.provider,
  SUM(ofl.amount_success) AS turnover_success,
  SUM(ofl.amount) - SUM(ofl.amount_success) AS turnover_failed,
  SUM(ofl.amount) AS turnover_all,
  MAX(ofl.currency) AS currency
FROM order_flags_one AS ofl
GROUP BY ofl.partner_id, ofl.partner_name, ofl.provider
ORDER BY ofl.partner_id;
