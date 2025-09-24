With ordered_steps as (
Select session_id, date, data_source, device, country,
lower(conversion_funnel_funnelStep) as step, page_pageInfo_pageName as page_name,
event_timestamp
from `dummy-airlines-recruitment.DigitalAnalyst_UseCase.CheckIn`
),
next_diff_step as (
Select o1.session_id, o1.date, o1.data_source, o1.device, o1.country, o1.step as previous_step,
o1.event_timestamp as previous_time, min(o2.event_timestamp) as next_step_time
from ordered_steps o1
left join ordered_steps o2
on o1.session_id = o2.session_id
and o2.event_timestamp > o1.event_timestamp
and o2.step != o1.step
and o1.data_source = o2.data_source 
and o1.device = o2.device
and o1.country = o2.country
group by o1.session_id, o1.date, o1.data_source, o1.device, o1.country, o1.step, o1.event_timestamp
),
next_step_with_name as (
Select nd.session_id, nd.date, nd.data_source, nd.device, nd.country,
nd.previous_step, nd.previous_time, os_next.step as next_step
from next_diff_step nd
left join ordered_steps os_next
on nd.session_id = os_next.session_id
and nd.next_step_time = os_next.event_timestamp
and nd.device = os_next.device 
and nd.country = os_next.country 
and nd.data_source = os_next.data_source
),
step_counts as (
Select date, data_source, device, country, previous_step, count(distinct session_id) as total_sessions
from next_step_with_name
where previous_step != 'connect'
group by date, data_source, device, country, previous_step
),
connect_before_step as (
Select date, data_source, device, country, previous_step,
count(distinct session_id) as sessions_leading_to_connect_error
from next_step_with_name
where previous_step != 'connect' and next_step = 'connect'
group by date, data_source, device, country, previous_step
)
Select sc.date, sc.data_source, sc.device, sc.country, sc.previous_step,
sc.total_sessions, coalesce(c.sessions_leading_to_connect_error, 0) as sessions_leading_to_connect_error
from step_counts sc
left join connect_before_step c
on sc.date = c.date and sc.data_source = c.data_source and sc.device = c.device
and sc.country = c.country and sc.previous_step = c.previous_step

