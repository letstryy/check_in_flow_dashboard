with step_events as (
  select
    session_id,
    lower(conversion_funnel_funnelStep) as step,
    min(event_timestamp) as step_start_time
  from `CheckIn`
  group by session_id, step
),
session_funnel as (
  select
    session_id,
    string_agg(step, ' → ' order by step_start_time) as funnel_path
  from step_events
  group by session_id
)
select
  funnel_path,
  count(distinct session_id) as session_count
from session_funnel
group by funnel_path
order by session_count desc
