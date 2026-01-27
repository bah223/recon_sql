--title: Acquiring error
select user_email, shop_name, site_name, driver_name, processing_error_message, count(order_id),bin_country,terminal 
FROM db_ifat
WHERE created_at >= current_timestamp  - '4h0m'::interval
--created_at between '2024-04-25 21:00:00' and '2024-11-24 20:59:59'
and payment_type = 'pay'
GROUP by user_email, shop_name, site_name, driver_name, processing_error_message,bin_country 
, terminal 
order by count(order_id) desc
;

--title: BIN
select
current_timestamp,
user_email,
--business_name,
site_name, driver_name, terminal, bin_country, issuer_name, order_status, count(order_id), real_site_name 
FROM fatpay_ops
where created_at >= current_timestamp - '4h0m'::interval
and order_status = '3'
--and user_email = 'payments@retail.bet'
GROUP by user_email, site_name, driver_name, terminal, bin_country, issuer_name, order_status, real_site_name 
order by count(order_id) desc
;

--title: Total by terminals
SELECT user_email, business_name, site_name, driver_name, terminal, service_id, count(*),sum(system_amount), system_currency, real_site_name 
FROM fatpay_ops
WHERE created_at >= current_date - '3h'::interval
--created_at >= current_date - '1 month'::interval and terminal = '17448'
--created_at between '2023-10-11 21:00:00' and '2023-10-12 20:59:59'
and order_status = '3' and operation_status_name = 'success' and payment_type = 'pay'
group by terminal, user_email,business_name, site_name, driver_name, terminal, service_id, system_currency , real_site_name 
order by system_currency asc , business_name asc , sum(system_amount) desc
;
--title: Total by Merchant
SELECT user_email, business_name, count(order_id),sum(system_amount), system_currency, driver_name, real_site_name --, shop_name 
FROM db_ifat
WHERE created_at >= current_date - '3h'::interval
and order_status in ('3') and operation_status_name = 'success' and payment_type = 'pay'
group by user_email,business_name, driver_name, system_currency, real_site_name-- , shop_name 
order by system_currency asc , driver_name asc, business_name asc , sum(system_amount) desc;
