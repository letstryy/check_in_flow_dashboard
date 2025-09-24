With dashboard as (
Select date, data_source, device, country, session_id,
min(event_timestamp) AS start_time
from dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn
where lower(conversion_funnel_funnelStep) = 'dashboard'
group by date, data_source, device, country, session_id
),
goodbye as (
Select a.date, a.data_source, a.device, a.country, a.session_id, min(a.event_timestamp) AS end_time
from dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn a
join dashboard d
on a.session_id = d.session_id and a.date = d.date and a.data_source = d.data_source
and a.device = d.device and a.country = d.country and a.event_timestamp >= d.start_time
where lower(conversion_funnel_funnelStep) = 'goodbye'
group by a.date, a.data_source, a.device, a.country, a.session_id
),
error_sessions as (
Select distinct session_id, date, data_source, device, country
from dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn
where event_name = 'error_evt'
)
Select d.country, d.data_source, d.device, d.date,
count(distinct d.session_id) AS dashboard_sessions,
count(distinct g.session_id) AS goodbye_sessions,
count(distinct e.session_id) AS error_sessions
from dashboard d
left join goodbye g
on d.session_id = g.session_id and d.date = g.date and d.data_source = g.data_source
and d.device = g.device and d.country = g.country
left join error_sessions e
on d.session_id = e.session_id and d.date = e.date and d.data_source = e.data_source
and d.device = e.device and d.country = e.country
group by d.country, d.data_source, d.device, d.date

