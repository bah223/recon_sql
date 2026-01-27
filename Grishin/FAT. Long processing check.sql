--Title: Операций с финализацией дольше часа
select avg(completed_at - created_at) as "difference", order_id 
from db_ifat 
where driver_name = 'Domus2-Xpate' and created_at >= '2025-12-01' and payment_type = 'pay' and order_status = '3' and completed_at - created_at  > '01:00:00'
group by order_id;
--Title: Статистика долгой финализации
select --to_char(date_trunc('month',created_at at time zone 'UTC'), 'DD/MM/YYYY') as "date",
sum(case when updated_at  - created_at < '00:01:00' then 1 else 0 end) as "Менее 7 минут",
sum(case when updated_at  - created_at >= '00:01:00' then 1 else 0 end) as "Более 7 минут",
avg(updated_at  - created_at) as "difference",
round(sum(case when updated_at  - created_at < '00:01:00' then 1 else 0 end)*100.00 / count(order_id),2) as "%%"
from db_ifat 
where driver_name  = 'Domus2-Xpate' and created_at at time zone 'UTC' between '2025-11-01 00:00:00' and '2025-12-31 23:59:59.999' and payment_type = 'pay' and order_status in ('99')
--and business_name = 'Platio Limited'
--group by date_trunc('month',created_at at time zone 'UTC')
;
--Title: Выборка зависших в create
select to_char(date_trunc('day',created_at at time zone 'UTC'), 'DD/MM/YYYY') as "����", order_id
from db_ifat 
where driver_name in ('Finaster','Domus2-Finaster') and created_at at time zone 'UTC' between '2025-12-01 00:00:00' and '2025-12-31 23:59:59.999' and order_status !='98'-- and payment_type = 'pay' and order_status in ('3')
group by date_trunc('day',created_at at time zone 'UTC'), order_id 
having count(order_id) = 1