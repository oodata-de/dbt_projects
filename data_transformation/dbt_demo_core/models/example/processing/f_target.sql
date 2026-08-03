{{ config(
    materialized='incremental',
    unique_key='id'
) }}

select f1.id, 
    f1.col1, 
    f1.col2, 
    f2.col3, 
    f3.col4
from {{ source('pro', 'f_source1') }} f1
left join {{ source('pro', 'f_source2') }} f2 on f1.id = f2.id
left join {{ source('pro', 'f_source3') }} f3 on f3.id = f2.col3

{% if is_incremental() %}
where 1=1
  and f1.processdate >= (select max(processdate) from {{ this }})
  or f2.processdate >= (select max(processdate) from {{ this }})
  or f3.processdate >= (select max(processdate) from {{ this }})
{% endif %}