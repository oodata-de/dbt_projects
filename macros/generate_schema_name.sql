{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set model_name = node.name -%}
    {%- set prefix = model_name.split('_')[0] -%}
    {{ prefix }}
{%- endmacro %}