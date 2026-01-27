--title: Оборот мерчантов
(
select
  public.db_wp_partners.name,
  --date(payment_time),
  x.provider,
  x.status,
  count(*),
  sum(amount)
from
  public.db_wp_operations x,
  public.db_wp_partners
where
  x.status not like 'NEW'
  and x.payment_time >= CURRENT_DATE - '1d'::interval
  --and x.payment_time between '2024-02-09 00:00:00' and '2024-12-30 23:59:59' 
  and public.db_wp_partners.id = x.partner_id
group by
    public.db_wp_partners.name,
    --date(payment_time),
    x.provider,
    x.status,
    public.db_wp_partners.id
  order by sum(amount) desc
  ) union all
  (
  select
  'Итог по провайдеру' as name,
  --date(payment_time),
  x.provider,
  x.status,
  count(*),
  sum(amount)
from
  public.db_wp_operations x,
  public.db_wp_partners
where
  x.payment_time >= CURRENT_DATE - '1d'::interval
  --x.payment_time between '2024-02-09 00:00:00' and '2024-12-31 23:59:59' 
  and public.db_wp_partners.id = x.partner_id
  group by x.provider, x.status --date(payment_time)
  order by x.provider asc, sum(amount) desc
  )
  ;
 --title: Стата по провайдерам
select provider, status, last_error, last_error_code, count(*) 
FROM
public.db_wp_operations
where status in('PAY_FAIL','CHECK_FAIL','PAY_PROCESSING','PAY_OK', 'NEW')
--and created >= '2024-03-25 13:30:00'
--and created >= CURRENT_DATE - '1d'::interval
and created >= current_timestamp - '1h'::interval
group by provider, status, last_error, last_error_code
order by count(*) desc
;

--title: Стата по партнерам
select
x.partner_id,
public.db_wp_partners.name,
x.provider,
x.status,
count(*),
sum(amount) 
FROM
public.wp_operations x,
public.db_wp_partners
where
created between '2025-12-01 00:00:00' and '2025-12-31 23:59:59'
and provider not like '%Cyberplat-BB%' and public.db_wp_partners.id = x.partner_id --and provider = 'Cyberplat-Narat-RUB'
group by x.provider, x.status, public.db_wp_partners.name, x.partner_id
order by name;

--title: Стата по эмитентам
select op.provider , bb.bank, bb.isocountry , count(op.id), substring(client, 1, 1), op.status ,op.last_error
from db_wp_operations op
join binbase bb on substring(op.client,1,6) = bb.bin 
where op.status in ('PAY_FAIL','PAY_OK')
and op.created >= current_timestamp - '15h'::interval
--and op.created between '2023-03-06 00:00:00' and '2023-03-31 23:59:59'
--and bb.isocountry  = 'AZERBAIJAN' 
group by op.provider , bb.bank , bb.isocountry , substring(client, 1, 1), op.status ,op.last_error 
order by count(op.id) desc;
