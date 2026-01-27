-- Считает ВСЕ операции (любой статус и тип) за указанный день по МСК
-- Для 28.12.2025 → UTC диапазон: 27.12.2025 21:00:00 – 28.12.2025 21:00:00
SELECT COUNT(*) AS total_transactions
FROM db_ifat
WHERE shop_name = 'ZT/Pelican Pay Cards KZT'
  AND created_at >= '2025-12-27 21:00:00'
  AND created_at < '2025-12-28 21:00:00';