select 
op.provider,
--bb.isocountry,
--bb.bank,
count(op.id) as "Total",
sum(case when status in ('PAY_OK', 'MANUAL_OK') then 1 else 0 end) as "Success", 
sum(case when status in ('PAY_FAIL','MANUAL_FAIL') then 1 else 0 end) as "Error",
--bb.isocountry ,
--to_char(date_trunc('month', op.created), 'MM/YYYY') as "m/y",
round (sum(case when status in ('PAY_OK', 'MANUAL_OK') then 1 else 0 end)*100.00 / count(op.id) ,2 ) as "%",
sum(case when status in ('PAY_OK', 'MANUAL_OK')then amount else 0 end) as "Turnover",
op.currency
from public.db_wp_operations op
join binbase bb  on substring(op.client, 1, 6)  = bb.bin
where op.created between '2025-12-01 00:00:00' and '2026-01-31 23:59:59' --and op.currency in ('EUR','USD') 

GROUP BY op.currency, op.provider  --bb.bank --date_trunc('month', op.created)
--having count(op.id) >= '40'