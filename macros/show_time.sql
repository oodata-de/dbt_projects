{% macro show_time() %}
    {% set now = modules.datetime.datetime.now() %}
    {{ log("Current time: " ~ now, info=True) }} -- log print to CLI
    {{ return(now) }}
{% endmacro %}
