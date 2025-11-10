{% macro default_dimension_records(col_type_dict, sid_col) %}

    {# col_type_dict: dict of column_name -> type (string, int, date, timestamp)
       sid_col: name of the surrogate key column
    #}

    {% set text_map = ['UNKNOWN', 'NOT APPLICABLE', 'ALL'] %}
    {% set int_map = [-10, -10, -10] %}
    {% set date_map = ["TO_DATE('1900-01-01')", "TO_DATE('1900-01-01')", "TO_DATE('1900-01-01')"] %}
    {% set ts_map = ["TO_TIMESTAMP('1900-01-01 00:00:00')", "TO_TIMESTAMP('1900-01-01 00:00:00')", "TO_TIMESTAMP('1900-01-01 00:00:00')"] %}

    {% set select_statements = [] %}
    {% for i in range(3) %}
        {% set select_parts = [] %}
        {% for col, typ in col_type_dict.items() %}
            {% if col == sid_col %}
                {% do select_parts.extend([i|string ~ ' AS ' ~ col]) %}
            {% elif typ | lower in ['string', 'text', 'varchar'] %}
                {% do select_parts.extend(["'" ~ text_map[i] ~ "' AS " ~ col]) %}
            {% elif typ | lower in ['int', 'integer', 'number', 'float', 'decimal'] %}
                {% do select_parts.extend([int_map[i]|string ~ ' AS ' ~ col]) %}
            {% elif typ | lower == 'date' %}
                {% do select_parts.extend([date_map[i] ~ ' AS ' ~ col]) %}
            {% elif typ | lower in ['timestamp', 'datetime'] %}
                {% do select_parts.extend([ts_map[i] ~ ' AS ' ~ col]) %}
            {% else %}
                {% do select_parts.extend(["'UNKNOWN' AS " ~ col]) %}
            {% endif %}
        {% endfor %}
        {% set select_stmt = 'SELECT ' ~ select_parts | join(', ') %}
        {% do select_statements.extend([select_stmt]) %}
    {% endfor %}
    {{ select_statements | join('\nUNION ALL\n') }}
    
{% endmacro %}