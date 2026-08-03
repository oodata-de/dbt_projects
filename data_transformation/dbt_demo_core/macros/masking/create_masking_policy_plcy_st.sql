{% macro create_masking_policy_plcy_st(node_database,node_schema) %}

create masking policy if not exists {{node_database}}.{{node_schema}}.plcy_st as (val string) 
    returns string ->
        case
            when current_role() in ('DBT_EXECUTOR_ROLE', 'ANALYST_ROLE') then
                '********'
            else val
    end

{% endmacro %}