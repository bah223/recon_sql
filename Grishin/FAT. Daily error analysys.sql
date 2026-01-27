--Title: Errors by provider
select to_char(date_trunc('day', created_at at time zone 'UTC'), 'DD/MM/YYYY') as "date",
driver_name, processing_error_message, count(order_id)
from db_ifat
where created_at >= current_date - '5d27h'::interval and order_status = '99'
--and shop_name like '%Dreidel%' and driver_name = 'Domus2-KiparisECOM'
--and driver_name = 'Domus2-Crederes'
group by date_trunc('day', created_at at time zone 'UTC'), driver_name, processing_error_message
order by driver_name asc, processing_error_message asc, date_trunc('day', created_at at time zone 'UTC') asc;
--Title: Errors by merchant
select to_char(date_trunc('day', created_at at time zone 'UTC'), 'DD/MM/YYYY') as "date",
driver_name, shop_name, processing_error_message, count(order_id)
from db_ifat
where created_at >= current_date - '5d27h'::interval and order_status = '99'
--and shop_name like '%Dreidel%' and driver_name = 'Domus2-KiparisECOM'
--and driver_name = 'Domus2-Crederes'
group by date_trunc('day', created_at at time zone 'UTC'), driver_name, processing_error_message, shop_name 
order by driver_name asc, shop_name asc, processing_error_message asc, date_trunc('day', created_at at time zone 'UTC') asc;
--Title: Conversion by merchant
select to_char(date_trunc('day', created_at at time zone 'UTC'), 'DD/MM/YYYY HH:MM:SS') as "date",
driver_name , shop_name , 
round(sum(case when payment_type = 'pay' and operation_status_name = 'success' then 1 else 0 end)*100.00/sum(case when payment_type = 'create' then 1 else 0 end),2) as "conversion",
sum(case when payment_type = 'pay' and operation_status_name = 'success' then system_amount  else 0 end) as "turnover"
from db_ifat
where created_at >= current_date  - '5d27h'::interval and user_email != 'it@win-pay.ru'
--and shop_name like '%Dreidel%' and driver_name = 'Domus2-KiparisECOM'
--and driver_name = 'Domus2-Crederes'
group by date_trunc('day', created_at at time zone 'UTC'), driver_name , shop_name
having sum(case when payment_type = 'create' then 1 else 0 end) >0
order by driver_name, shop_name, date_trunc('day', created_at at time zone 'UTC');

--Title: Conversion by provider/terminal
select to_char(date_trunc('day', created_at at time zone 'UTC'), 'DD/MM/YYYY HH:MM:SS') as "date",
driver_name , terminal,
round(sum(case when payment_type = 'pay' and operation_status_name = 'success' then 1 else 0 end)*100.00/sum(case when payment_type = 'create' then 1 else 0 end),2) as "conversion",
sum(case when payment_type = 'pay' and operation_status_name = 'success' then system_amount  else 0 end) as "turnover"
from db_ifat
where created_at >= current_date  - '5d27h'::interval and user_email != 'it@win-pay.ru'
--and shop_name like '%Dreidel%' and driver_name = 'Domus2-KiparisECOM'
--and driver_name = 'Domus2-Crederes'
group by date_trunc('day', created_at at time zone 'UTC'), driver_name , terminal 
having sum(case when payment_type = 'create' then 1 else 0 end) >0
order by driver_name, terminal, date_trunc('day', created_at at time zone 'UTC');
--Title: Количество ошибок по картам
select to_char(date_trunc('day', created_at at time zone 'UTC'), 'DD/MM/YYYY') as "date",
concat(pan6,'XXXXXX',pan4) as "panmask", count(order_id), bin_country 
from db_ifat
where created_at >= current_date  - '1d27h'::interval and user_email != 'it@win-pay.ru'
and order_status = '99'
--and shop_name like '%Dreidel%' and driver_name = 'Domus2-KiparisECOM'
--and driver_name = 'Domus2-Crederes' and processing_error_message like '%3Dv2 failed, status ''N'': not authenticated/account not verified  transaction denied%'
group by date_trunc('day', created_at at time zone 'UTC'), panmask , bin_country 
order by count(order_id) desc;
--Title: Количество ошибок по странам
select to_char(date_trunc('day', created_at at time zone 'UTC'), 'DD/MM/YYYY') as "date",
bin_country , count(order_id)
from db_ifat
where created_at >= current_date  - '1d27h'::interval and user_email != 'it@win-pay.ru'
and order_status = '99'
--and shop_name like '%Dreidel%' and driver_name = 'Domus2-KiparisECOM'
--and driver_name = 'Domus2-Crederes' and processing_error_message like '%3Dv2 failed, status ''N'': not authenticated/account not verified  transaction denied%'
group by date_trunc('day', created_at at time zone 'UTC'), bin_country  
order by count(order_id) desc;
