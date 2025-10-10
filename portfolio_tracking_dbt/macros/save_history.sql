{% macro save_history(
    input_rel,
    key_column,
    diff_column,
    load_ts_column = 'LOAD_TS_UTC',
    input_filter_expr = 'true',
    history_filter_expr = 'true',
    high_watermark_column = none,
    high_watermark_test = '>=',
    order_by_expr = none
) -%}

{{ config(materialized='incremental') }} -- append all the rows returned by our SQL code to the incremental model.

WITH

{%- if is_incremental() %} -- if table exists,
current_from_history as ( -- CTE to get the current records/HDIFF for each keyfrom history table
    {{current_from_history(
        history_rel = this,
        key_column = key_column,
        selection_expr = diff_column,
        load_ts_column = load_ts_column,
        history_filter_expr = history_filter_expr
    ) }}
),

load_from_input as (
-- join the input with the HIST on the HDIFF columns
-- and keep the rows where there is no match
-- When the HDIFF from the input and the HIST are the same, it means that we already have that version of the data stored. 
-- Then, we need to load from the input only the rows where the HKEY does not match between the input and HIST table
    SELECT i.*
    FROM {{input_rel}} as i
    LEFT OUTER JOIN current_from_history as h ON h.{{diff_column}} = i.{{diff_column}}
    WHERE h.{{diff_column}} is null
        and {{input_filter_expr}}
    {%- if high_watermark_column %}
        and {{high_watermark_column}} {{high_watermark_test}} (select max({{high_watermark_column}}) from {{ this }})
    {%- endif %}
)

{%- else %} -- if macro returns false (table does not yet exist), table is created
load_from_input as (
    -- load all from the input
    SELECT *
    FROM {{input_rel}}
    WHERE {{input_filter_expr}}
)
{%- endif %}

SELECT * FROM load_from_input
{%- if order_by_expr %}
ORDER BY {{order_by_expr}}  -- written to disk in the desired order to take advantage of Snowflake micro-partitions.
{%- endif %}

{%- endmacro %}