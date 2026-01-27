--Title: Мониторинг зависших WP
select pid, created,client,partner_id,id,sid,provider_payid,next_processing, amount,commis,status,partner_status,provider,last_error,last_error_code,currency,payout_currency,instance,comment,process_count 
from db_wp_operations
where status not in ('TWO_PHASE_NEW', 'PAY_OK', 'MANUAL_OK', 'PAY_FAIL','MANUAL_FAIL', 'CHECK_FAIL', 'CANCELED', 'LIMIT_CHECK_FAIL') and created between '2023-01-01' and current_timestamp - '30m'::interval
--and last_error = 'Status not final or unknown response'
--and last_error = 'Дублирующая операция!'
--and provider != 'SredaPay-HalykBank-KZT'
--and provider != 'GFI-WallettoSEPA-EUR'
--and provider in ('Domus2-GlobalPaymentsUK-RUB','Domus2-GlobalPayments-RUB','Domus2-GlobalPayments(VC)-RUB')
--and provider = 'Moneytea-Walletto-EUR'
--and partner_id = '2592' and status != 'NEW'
--and last_error is not null
order by created asc;	
SELECT DISTINCT ON (pid) *
from db_wp_operations
where status not in ('PAY_OK', 'MANUAL_OK', 'PAY_FAIL','MANUAL_FAIL', 'CHECK_FAIL', 'CANCELED', 'LIMIT_CHECK_FAIL') and created >= '2021-10-14'
--and last_error = 'Status not final or unknown response'
and last_error = 'Дублирующая операция!'
order by pid asc