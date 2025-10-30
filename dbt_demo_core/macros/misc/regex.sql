{# A macro to extract a substring using regex #}
{% macro regex() %}
    {% set my_string = "s3://example/path" %}
    {% set pattern = "s3://[a-z0-9-_/.]+" %}
    {% set re = modules.re %}
    {% set is_match = re.match(pattern, my_string, re.IGNORECASE) %}
    {% if not is_match %}
        {%- do exceptions.raise_compiler_error(
            my_string ~' is not a valid path'
        ) -%}
        --{{ log("The string matches the pattern.", info=True) }}
    {% else %}
        {{ log("Yayaya.", info=True) }}
    {% endif %}
{% endmacro %}
