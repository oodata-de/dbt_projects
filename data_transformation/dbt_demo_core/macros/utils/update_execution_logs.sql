{% macro update_execution_logs() %}
    {# 
        Usage:
        {{ update_execution_logs() }}
        This will set session variables run_start_ts and run_end_ts for use in your model.
    #}
    {% if execute %}
        {% set query %}
            insert into dbt_dev.sch_dbt_metadata.model_execution_log (model_name, start_ts, end_ts, status, record_created_ts)
            values ('{{ this.database }}.{{ this.schema }}.{{ this.identifier }}', $run_start_ts, $run_end_ts, 'SUCCESS', current_timestamp());
        {% endset %}
        {% do run_query(query) %}
        {% do log("DEBUG: " '{{ this.identifier }}' "execution logged", info=true) %}
    {% endif %}
{% endmacro %}