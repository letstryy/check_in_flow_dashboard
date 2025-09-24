With dashboard as (
Select date, data_source, device, country, session_id,
'1. Dashboard' as step,
min(event_timestamp) as event_t,
sum(error_count) as error_count
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn`
where lower(conversion_funnel_funnelStep) = 'dashboard'
group by date, data_source, device, country, session_id
),
regulatory as (
Select a.date, a.data_source, a.device, a.country, a.session_id, 
'2. Regulatory' as step, 
min(a.event_timestamp) as event_t,
sum(a.error_count) as error_count
FROM `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn` a
join dashboard d
on a.session_id = d.session_id and a.event_timestamp >= d.event_t and a.country = d.country 
and a.data_source = d.data_source AND a.device = d.device and a.date = d.date
where lower(conversion_funnel_funnelStep) = 'regulatory'
group by a.date, a.data_source, a.device, a.country, a.session_id
),
attestation as (
Select a.date, a.data_source, a.device, a.country, a.session_id, 
'3. Attestation' as step, 
min(a.event_timestamp) as event_t,
sum(a.error_count) as error_count
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn` a
join dashboard d
on a.session_id = d.session_id and a.event_timestamp >= d.event_t and a.country = d.country 
and a.data_source = d.data_source and a.device = d.device and a.date = d.date
where lower(conversion_funnel_funnelStep) = 'attestation'
group by a.date, a.data_source, a.device, a.country, a.session_id
),
ancillary as (
Select a.date, a.data_source, a.device, a.country, a.session_id, 
'3. Ancillary' AS step, 
min(a.event_timestamp) as event_t,
sum(a.error_count) as error_count
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn` a
join dashboard d
on a.session_id = d.session_id and a.event_timestamp >= d.event_t and a.country = d.country 
and a.data_source = d.data_source and a.device = d.device and a.date = d.date
where lower(conversion_funnel_funnelStep) = 'ancillary'
group by a.date, a.data_source, a.device, a.country, a.session_id
),
document as (
Select a.date, a.data_source, a.device, a.country, a.session_id, 
'4. Document' AS step, 
min(a.event_timestamp) as event_t,
sum(a.error_count) as error_count
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn` a
join dashboard d
on a.session_id = d.session_id and a.event_timestamp >= d.event_t
and a.country = d.country and a.data_source = d.data_source 
and a.device = d.device and a.date = d.date
where lower(conversion_funnel_funnelStep) = 'documents'
group by a.date, a.data_source, a.device, a.country, a.session_id
),
goodbye as (
Select a.date, a.data_source, a.device, a.country, a.session_id, 
'5. Goodbye' as step, 
min(a.event_timestamp) as event_t,
sum(a.error_count) as error_count
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn` a
join dashboard d
on a.session_id = d.session_id and a.event_timestamp >= d.event_t
and a.country = d.country and a.data_source = d.data_source 
and a.device = d.device and a.date = d.date
where lower(conversion_funnel_funnelStep) = 'goodbye'
group by a.date, a.data_source, a.device, a.country, a.session_id
),
final as (
Select * from dashboard
UNION ALL
Select * from regulatory
UNION ALL
Select * from attestation
UNION ALL
Select * from ancillary
UNION ALL
Select * from document
UNION ALL
Select * from goodbye
),
dashboard_total as (
Select country, data_source, device, date, count(distinct session_id) as dashboard_sessions
from dashboard
group by country, data_source, device, date
),
step_counts as (
Select f.country, f.data_source, f.device, f.date, f.step,
avg(error_count) as avg_error_count,
count(distinct f.session_id) as sessions
from final f
group by f.country, f.data_source, f.device, f.date, f.step
)
Select sc.country, sc.data_source, sc.device, sc.date, sc.step, sc.sessions, dt.dashboard_sessions,
avg_error_count
from step_counts sc
join dashboard_total dt
on sc.country = dt.country and sc.data_source = dt.data_source and sc.device = dt.device 
and sc.date = dt.date
