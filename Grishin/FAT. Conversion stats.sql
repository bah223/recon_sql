select
shop_name ,
date(created_at at time zone 'UTC') as "date",
count(order_id) as "all",
driver_name,
--terminal,
business_name,
--processing_error_message ,
--bin_country ,
--issuer_name ,
sum(case when operation_status_name = 'success' and payment_type = 'pay' then 1 else 0 END) AS "success",
sum(case when order_status in (98,99) then 1 else 0 END) AS "error",
round(sum(case when operation_status_name in ('success') and payment_type = 'pay' then 1 else 0 end)*100.00 / count(order_id), 2) as "conversion",
sum(case when operation_status_name in ('success') and payment_type = 'pay' then system_amount else 0 end) as "turnover",
system_currency 
from
fatpay_ops
where
--created_at between '2023-04-30 21:00:00' and '2023-05-31 20:59:59'
--created_at >= current_timestamp - '9h' :: interval
created_at >= current_date - '1d3h' :: interval 
and payment_type in ('pay') --and operation_status_name = 'error'
and order_status != '0'
group by
--processing_error_message ,
shop_name,
"date",
--terminal --- fsdfsdfsdf
driver_name ,
--bin_country ,
--issuer_name,
business_name,
system_currency 
order by "conversion" desc;
select 
  business_name,
  count(order_id) as "all deposite",
  sum(case when operation_status_name = 'success' and payment_type = 'pay' then 1 else 0 END) AS "success",
  sum(case when operation_status_name = 'error' and payment_type = 'pay' then 1 else 0 END) AS "error",
  concat(count(order_id), '/', SUM(case when operation_status_name = 'success' and payment_type = 'pay' then 1 else 0 END), '/', SUM(case when operation_status_name = 'error' and payment_type = 'pay' then 1 else 0 END)) as "succ", 
  round(sum(case when operation_status_name in ('success') and payment_type = 'pay' then 1 else 0 end)*100.00 / count(order_id), 2) as "���������"
FROM
  db_ifat 
where 
  created_at >= current_timestamp - '4h' :: interval
--created_at between '2021-08-01 21:00:00' and '2021-08-04 21:00:00'
--and driver_name = 'Cauri'
  and payment_type = 'pay'
  and order_status != '0'
  and user_email != 'it@win-pay.ru'
GROUP by 
  --driver_name
  business_name 
order by 4 desc;