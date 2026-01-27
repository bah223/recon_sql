--Title: ¬ыборка пиковых периодов (минута)
select count(order_id), date_trunc('minute',created_at)
from db_ifat
where created_at >= '2024-05-01' and order_status = '0'
group by date_trunc('minute',created_at)
order by count(order_id) desc
;
--Title: ¬ыборка операций в секунду по пиковым периодам
select count(order_id), date_trunc('second',created_at)
from db_ifat
where created_at >= '2024-05-01' and order_status = '0'
group by date_trunc('second',created_at), date_trunc('minute',created_at)
having date_trunc('minute',created_at) in ('2024-05-03 11:06:00.000','2024-05-03 11:10:00.000','2024-06-10 17:52:00.000','2024-05-03 11:12:00.000','2024-06-10 17:53:00.000')
order by count(order_id) desc
;
--Title: ¬ыборка операций в секунду за весь период
select count(order_id), date_trunc('second',created_at)
from db_ifat
where created_at >= '2024-05-01' and order_status = '0'
group by date_trunc('second',created_at)
order by count(order_id) desc
;
--Title: —реднее количество операций в секунду по пиковым периодам
select round(avg(ops_per_second),2), minute
from (select count(order_id) as ops_per_second, date_trunc('minute',created_at) as minute
from db_ifat
where created_at >= '2024-05-01' and order_status = '0'
group by date_trunc('second',created_at), date_trunc('minute',created_at)
having date_trunc('minute',created_at) in ('2024-05-03 11:06:00.000','2024-05-03 11:10:00.000','2024-06-10 17:52:00.000','2024-05-03 11:12:00.000','2024-06-10 17:53:00.000')
) as ops
group by ops.minute
;
