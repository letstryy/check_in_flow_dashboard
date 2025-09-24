With step_times AS (
Select date, data_source, device, country, session_id,
case lower(conversion_funnel_funnelStep)
when 'dashboard' then '1. Dashboard'
when 'regulatory' then '2. Regulatory'
when 'ancillary' then '3. Ancillary'
when 'documents' then '4. Documents'
when 'goodbye' then '5. Goodbye'
end as step,
min(event_timestamp) as start_time, max(event_timestamp) as end_time
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn`
where lower(conversion_funnel_funnelStep) in ('dashboard', 'regulatory', 'ancillary', 'documents', 'goodbye')
group by date, data_source, device, country, session_id, step
having min(event_timestamp) <> max(event_timestamp)   
),
step_durations as (
Select date, data_source, device, country, step,
timestamp_diff(timestamp_micros(end_time), timestamp_micros(start_time), second)/60 as step_duration
from step_times
),
iqr_stats as (
Select step,
approx_quantiles(step_duration, 100)[offset(25)] AS q1,
APPROX_quantiles(step_duration, 100)[offset(75)] AS q3
from step_durations
group by step
)
Select d.date, d.data_source, d.device, d.country, d.step, d.step_duration
from step_durations d
join iqr_stats s
on d.step = s.step
where d.step_duration between(s.q1 - 1.5 * (s.q3 - s.q1)) and 10
