select
--order_id,
  to_char(date_trunc('day', created_at at time zone 'UTC'), 'DD/MM/YYYY') as "Date",--bin_country ,
  --substring(pan6,1,1) as "PS",
--bin_country ,
  driver_name,
  --shop_name ,
  --issuer_name,
  --terminal,
 business_name,
-- merchant_site ,
  --shop_name,
  --count(order_id),
 -- processing_error_message ,
  --count(order_id),
  SUM(case when operation_status_name in ('success','error') and payment_type = 'create' then 1 else 0 END) AS "count",
  SUM(case when operation_status_name = 'success' and payment_type = 'pay' then 1 else 0 END) AS "success",
  SUM(case when order_status in ('98','99') then 1 else 0 END) AS "error",
  system_currency as "Валюта", 
  round(sum(case when operation_status_name in ('success') and payment_type in('pay') then 1 else 0 end)*100.00 / sum(case when payment_type = 'create' then 1 else Null END), 2) AS "Конверсия",
  round(sum(case when operation_status_name in ('success') and payment_type in('pay') then 1 else 0 end)*100.00 / count(order_id), 2) AS "Conversion-2",
  SUM(case when operation_status_name = 'success' and payment_type = 'pay' then system_amount else 0 END) AS "Оборот",
  --,merchant_site 
  avg(case when operation_status_name = 'success' and payment_type = 'pay' then system_amount else 0 END) as "Средний чек"
FROM
  db_ifat
where 
  created_at between '2024-05-15 21:00:00' and '2024-10-30 20:59:59' and user_email !='it@win-pay.ru'
 and driver_name = 'GFI-Xpate'-- and bin_country = 'POLAND'
  --and order_status = '99'
  --and business_name = 'AZIMUTONE LIMITED'
  --and bin_country = 'ITALY'
 --and bin_country in ('SAUDI ARABIA','UNITED ARAB EMIRATES','KUWAIT','QATAR','OMAN','BAHRAIN','JAPAN')
  --and payment_type = 'pay' and operation_status_name = 'success'
 -- and shop_name like '%GFI%'
  --and terminal in ('CardGateFS')
 -- and shop_name = 'GFI/FINASTER TRANSFER LTD USD'
 --and driver_name = 'Domus2-KiparisECOM' and terminal = 'CardGateFS'
-- and driver_name = 'Domus2-Butler'
  --and pan6 not like '4%'
 --and system_currency in ('EUR','USD')
  --and bin_country = 'FRANCE' and business_name = 'Force Soft DMCC' and driver_name in ('Walletto','GFI-INF-Walletto', 'Decta', 'Cauri-GFI-Decta') and payment_type != 'expired'
GROUP by
--order_id,
 date_trunc('day', created_at at time zone 'UTC'),
 --"PS",
--processing_error_message ,
  driver_name,
  --terminal,
 business_name, 
  --shop_name,
  system_currency
  --, merchant_site 
  --, bin_country 
  --,issuer_name 
 --having sum(case when operation_status_name in ('success','error') and payment_type = 'create' then 1 else 0 end) > 0
  order by "Конверсия" desc
  ;
  select
--order_id,
  to_char(date_trunc('day', created_at at time zone 'UTC'), 'DD/MM/YYYY') as "Date",--bin_country ,
  --substring(pan6,1,1) as "PS",
--bin_country ,
  driver_name,
  --shop_name ,
  --issuer_name,
  --terminal,
 business_name,
-- merchant_site ,
  --shop_name,
  --count(order_id),
 -- processing_error_message ,
  --count(order_id),
  SUM(case when operation_status_name in ('success','error') and payment_type = 'create' then 1 else 0 END) AS "count",
  SUM(case when operation_status_name = 'success' and payment_type = 'pay' then 1 else 0 END) AS "success",
  SUM(case when order_status in ('98','99') then 1 else 0 END) AS "error",
  system_currency as "Валюта", 
  round(sum(case when operation_status_name in ('success') and payment_type in('pay') then 1 else 0 end)*100.00 / sum(case when payment_type = 'create' then 1 else Null END), 2) AS "Конверсия",
  round(sum(case when operation_status_name in ('success') and payment_type in('pay') then 1 else 0 end)*100.00 / count(order_id), 2) AS "Conversion-2",
  SUM(case when operation_status_name = 'success' and payment_type = 'pay' then system_amount else 0 END) AS "Оборот",
  --,merchant_site 
  avg(case when operation_status_name = 'success' and payment_type = 'pay' then system_amount else 0 END) as "Средний чек"
FROM
  db_quick_fat
where 
  created_at between '2024-05-12 21:00:00.000' and '2024-10-30 20:59:59.999' and user_email !='it@win-pay.ru'
 --and driver_name = 'Hyperion'-- and bin_country = 'POLAND'
  --and order_status = '99'
  --and business_name = 'AZIMUTONE LIMITED'
  --and bin_country = 'ITALY'
 --and bin_country in ('SAUDI ARABIA','UNITED ARAB EMIRATES','KUWAIT','QATAR','OMAN','BAHRAIN','JAPAN')
  --and payment_type = 'pay' and operation_status_name = 'success'
 -- and shop_name like '%GFI%'
  --and terminal in ('CardGateFS')
 -- and shop_name = 'GFI/FINASTER TRANSFER LTD USD'
 --and driver_name = 'Domus2-KiparisECOM' and terminal = 'CardGateFS'
-- and driver_name = 'Domus2-Butler'
  --and pan6 not like '4%'
 --and system_currency in ('EUR','USD')
  --and bin_country = 'FRANCE' and business_name = 'Force Soft DMCC' and driver_name in ('Walletto','GFI-INF-Walletto', 'Decta', 'Cauri-GFI-Decta') and payment_type != 'expired'
GROUP by
--order_id,
 date_trunc('day', created_at at time zone 'UTC'),
 --"PS",
--processing_error_message ,
  driver_name,
  --terminal,
 business_name, 
  --shop_name,
  system_currency
  --, merchant_site 
  --, bin_country 
  --,issuer_name 
 having sum(case when operation_status_name in ('success','error') and payment_type = 'create' then 1 else 0 end) > 0
  order by "Конверсия" desc