-- Возвращает самую позднюю операцию за указанный день по МСК
SELECT MAX(created_at) AS last_operation_time
FROM db_ifat
WHERE shop_name = 'ZT/Pelican Pay Cards KZT'
  AND created_at >= '2025-12-27 21:00:00'
  AND created_at < '2025-12-28 21:00:00';