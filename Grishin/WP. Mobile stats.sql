--Title: Winline / General stats
select  to_char(date_trunc('day', created), 'DD/MM/YYYY') as "date",--Закомментить строку, если требуется общий оборот за период без разделения по датам
pa.id,pa.name,
count(op.id) as "Total",
sum(case when op.status in ('INIT_OK','PROCESSING','PAY_PROCESSING') then 1 else 0 end) as "Not finished",
sum(case when op.status in ('PAY_OK','MANUAL_OK') then 1 else 0 end) as "Success",
sum(case when op.status in ('INIT_FAIL','PAY_FAIL','MANUAL_FAIL') then 1 else 0 end) as "Fail",
sum(case when op.status in ('PAY_OK', 'MANUAL_OK') then op.amount else 0 end) as "Turnover",
op.currency
from db_wp_pay_operations op
join db_wp_partners pa on op.partner_id = pa.id
where op.created between '2025-12-01 00:00:00' and '2025-12-31 23:59:59'
--and provider in ('paybox')
--and op.partner_id in ('3076','3077','3071','3070')
group by op.currency, pa."name", pa.id 
,date_trunc('day', created) order by date_trunc('day', created) asc --Закомментить строку, если требуется общий оборот за период без разделения по датам
;
--Title: Winline / Weekly report
select sum(case when op.status in ('PAY_OK','MANUAL_OK') then 1 else 0 end) as "Success",
sum(case when op.status in ('PAY_OK', 'MANUAL_OK') then op.amount else 0 end) as "turnover"
from db_wp_pay_operations op
join db_wp_partners pa on op.partner_id = pa.id
where op.created between '2025-12-01 00:00:00' and '2025-12-31 23:59:59';
--Title: Willine / turnover stats
select count(op.id) as "Total",
sum(case when op.status = 'INIT_OK' then 1 else 0 end) as "Not finished",
sum(case when op.status in ('PAY_OK','MANUAL_OK') then 1 else 0 end) as "Success",
sum(case when op.status in ('INIT_FAIL','PAY_FAIL','MANUAL_FAIL') then 1 else 0 end) as "Fail",
sum(case when op.status in ('PAY_OK', 'MANUAL_OK') then op.amount else 0 end) as "turnover"
from db_wp_pay_operations op
join db_wp_partners pa on op.partner_id = pa.id
where op.created between '2025-12-01 00:00:00' and '2025-12-31 23:59:59';
--Title: Error selection
select op.id, op.pid,op.status, op.last_error, pa."name" , op.phone,
case when substring(op.phone,1,4) in ('7700','7708') then 'Altel' when substring(op.phone,1,4) in ('7701','7702','7775','7778') then 'Kcell_Activ' when substring(op.phone,1,4) in ('7707','7747') then 'Tele2' else 'No data' end as "Operator"
from db_wp_pay_operations op
join db_wp_partners pa on op.partner_id = pa.id
where op.created >= '2023-04-17' and op.status in ('INIT_OK','PAY_OK','MANUAL_OK','INIT_FAIL','PAY_FAIL','MANUAL_FAIL');
--Title: Error count
select count(id), last_error 
from db_wp_pay_operations
where created >= '2025-12-01' and status in ('PAY_FAIL', 'MANUAL_FAIL')
group by last_error 
order by count(id) desc;