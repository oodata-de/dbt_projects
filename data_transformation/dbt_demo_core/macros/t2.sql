{% macro t2_append() %}
    {% set fruits = [] %}
    {% do fruits.extend(['orange']) %}
    {% do log("DEBUG: fruits result: " ~ fruits ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}
{% endmacro %}

