{% macro set_run_window_variables() %}
    {# 
        Usage:
        {{ set_run_window_vars() }}
        This will set session variables run_start_ts and run_end_ts for use in your model.
    #}
    {% if execute %}
        {% set query %}
            SELECT MAX(end_ts) AS END_TS
            FROM {{ this.database }}.sch_dbt_metadata.model_execution_log
            WHERE model_name = '{{ this.database }}.{{ this.schema }}.{{ this.identifier }}'
              AND status = 'SUCCESS';
        {% endset %}
        {% set result = run_query(query) %}
        {% do log("DEBUG: run_query result: " ~ result ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}
        {% if result and result.rows | length > 0 and result.rows[0]['END_TS'] is not none %}
            {% set start_ts = "DATEADD(millisecond, 1, TO_TIMESTAMP('" ~ result.rows[0]['END_TS'] ~ "'))" %}
        {% else %}
            {% set start_ts = "TO_TIMESTAMP('1900-01-01 00:00:00')" %}
        {% endif %}
        {% set end_ts =  "CURRENT_TIMESTAMP()" %}
        {% do run_query("SET run_start_ts = " ~ start_ts ~ ";") %}
        {% do run_query("SET run_end_ts = " ~ end_ts ~ ";") %}
        {% do log("Set run_start_ts=" ~ start_ts ~ ", run_end_ts=" ~ end_ts, info=true) %}
    {% endif %}
{% endmacro %}