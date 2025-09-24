With dashboard as (
Select date, data_source, device, country, session_id,
'1. Dashboard' as step,
min(event_timestamp) as start_t
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn`
where lower(conversion_funnel_funnelStep) = 'dashboard'
group by date, data_source, device, country, session_id
),
regulatory as (
Select a.date, a.data_source, a.device, a.country, a.session_id, 
'2. Regulatory' as step, 
min(a.event_timestamp) as start_t
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn` a
join dashboard d
on a.session_id = d.session_id and a.event_timestamp >= d.start_t
and a.country = d.country and a.data_source = d.data_source
and a.device = d.device and a.date = d.date
where lower(conversion_funnel_funnelStep) = 'regulatory'
group by a.date, a.data_source, a.device, a.country, a.session_id
),
ancillary as (
Select  a.date, a.data_source, a.device, a.country, a.session_id, 
'3. Ancillary' AS step, 
min(a.event_timestamp) as start_t  
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn` a
join regulatory r
on a.session_id = r.session_id and a.event_timestamp >= r.start_t
and a.country = r.country and a.data_source = r.data_source
and a.device = r.device and a.date = r.date
where lower(conversion_funnel_funnelStep) = 'ancillary'
group by a.date, a.data_source, a.device, a.country, a.session_id
),
document as (
Select a.date, a.data_source, a.device, a.country, a.session_id, 
'4. Document' AS step, 
min(a.event_timestamp) as start_t  
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn` a
join ancillary an
on a.session_id = an.session_id and a.event_timestamp >= an.start_t
and a.country = an.country and a.data_source = an.data_source
and a.device = an.device and a.date = an.date
where lower(conversion_funnel_funnelStep) = 'documents'
group by a.date, a.data_source, a.device, a.country, a.session_id
),
goodbye as (
Select a.date, a.data_source, a.device, a.country, a.session_id, 
'5. Goodbye' as step, 
min(a.event_timestamp) as start_t  
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn` a
join document d
on a.session_id = d.session_id and a.event_timestamp >= d.start_t
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
Select * from ancillary
UNION ALL
Select * from document
UNION ALL
Select * from goodbye
),
error_events as (
Select distinct session_id, date, data_source, device, country,
LOWER(TRIM(conversion_funnel_funnelStep)) as error_step_name
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn`
where event_name = 'error_evt'
),
step_counts as (
Select f.country, f.date, f.data_source, f.device, f.step,
count(distinct f.session_id) as sessions,
count(distinct e.session_id) as error_sessions
from final f
left join error_events e
on f.session_id = e.session_id and f.date = e.date and f.data_source = e.data_source
and f.device = e.device and f.country = e.country
and LEFT(TRIM(LOWER(SUBSTR(f.step, 4))), 5) = LEFT(TRIM(LOWER(e.error_step_name)), 5)
group by f.country, f.date, f.data_source, f.device, f.step
),
step_with_prev as (
Select sc.*,
LAG(sc.sessions) OVER (PARTITION BY sc.country, sc.date, sc.data_source, sc.device ORDER BY sc.step) 
as prev_step_sessions
from step_counts sc
)
Select *
from step_with_prev

