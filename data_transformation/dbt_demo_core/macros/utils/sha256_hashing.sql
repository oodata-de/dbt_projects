{% macro sha256_hashing(field_list) %}

    {%- set default_null_value = "" -%}
    {%- set fields = [] -%}
    {%- for field in field_list -%}
        {%- do fields.append(
            "coalesce(cast(" ~ field ~ " as string), '" ~ default_null_value ~ "')"
        ) -%}

        {%- if not loop.last %}
            {%- do fields.append("'||'") -%}
        {%- endif -%}

    {%- endfor -%}
    sha2({{ fields | join(' || ') }}, 256)

{% endmacro %}