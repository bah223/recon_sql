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
  WHERE created_at >= '2026-02-06 00:00:00'
    AND created_at <  '2026-02-07 00:00:00'
    AND payment_type IN ('create','pay')
    AND (
      COALESCE(shop_id::text, '0') = ANY (string_to_array('1444,1443,1446,1445,1447,1502,1501,1503,1550,1507,1508,1509,1289,1257,1258,1386,1677,1678,1679,1680,1767,1769,1768,1547,1365,1366,1364,1462,1381,1350,1352,1351,1463,1387,1513,1511,1512,1613,1514,1515,1516,1617,1376,1643,1377,1375,1554,1555,1556,1558,1479,1480,1484,1483,1485,1486,1481,1482,1648,1593,1664,1665,1666,1667,1729,1739,1705,1171,1170,1169,1168,1167,1742,1746,1749,1775,1774,1778,1777,1776,1779,1761,938,937,940,944,942,1735,1732', ','))
    )
  GROUP BY order_id, COALESCE(shop_id,0), shop_name, driver_name
)
SELECT
  CAST('2026-02-06 00:00:00' AS date) AS date,
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
ORDER BY ofl.shop_id;