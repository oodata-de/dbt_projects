{% macro apply_dynamic_masking_policy_complex(columns, masking_policy) %}
    {#-
      Entry-point macro for use in a models post_hook.
      Example:
          {{ config(
              post_hook="{{ apply_dynamic_masking_policy(['ssn','email'], 'my_masking_policy') }}"
          ) }}
    -#}
    {% if execute %}
        {# Require columns argument #}
        {% if columns is none or columns | length == 0 %}
            {{ exceptions.raise_compiler_error("apply_dynamic_masking_policy: columns argument is required.") }}
        {% endif %}

        {# Gather metadata #}
        {% set database = this.database %}
        {% set schema = this.schema %}
        {% set table = this.identifier %}
        {% set relation_obj = load_relation(this) %}

        {% do log("DEBUG: relation: " ~ relation_obj ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}

        {% if relation_obj is not none %}
            {% set table_type = (relation_obj.type | upper) %}
            {% do log("DEBUG: table_type from relation: " ~ table_type ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}
        {% else %}
            {% set table_type_query %}
                select CASE t.table_type
                    WHEN 'BASE TABLE' THEN 'TABLE'
                    ELSE t.table_type
                END AS table_type
                from {{ database }}.information_schema.tables t
                where t.table_name = '{{ table | upper }}'
                limit 1;
            {% endset %}

            {% do log("DEBUG: table_type_query SQL: " ~ table_type_query, info=true) %}
            {% set res = run_query(table_type_query) %}
            {% do log("DEBUG: run_query result: " ~ res ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}

            {% if res %}
                {% set table_type = res.rows[0]['TABLE_TYPE'] %}
                {% do log("DEBUG: table_type from query: " ~ table_type ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}
            {% else %}
                {% do log("DEBUG: table_type not found, defaulting to 'TABLE'", info=true) %}
                {% set table_type = 'TABLE' %}
            {% endif %}
        {% endif %}

        {# Query column types for only the columns to be masked #}
        {% set col_list = columns | map('upper') | join("','") %}
        {% set col_query %}
            select column_name, data_type
            from {{ database }}.information_schema.columns
            where table_name = '{{ table | upper }}'
              and table_schema = '{{ schema | upper }}'
              and column_name in ('{{ col_list }}')
        {% endset %}
        {% do log("DEBUG: col_query SQL: " ~ col_query, info=true) %}
        {% set col_res = run_query(col_query) %}
        {% do log("DEBUG: column metadata result: " ~ col_res, info=true) %}

        {# Build a dict of column_name -> data_type #}
        {% set col_types = {} %}
        {% if col_res and col_res.rows | length > 0 %}
            {% for row in col_res.rows %}
                {% set _ = col_types.update({ row['COLUMN_NAME'] : row['DATA_TYPE'] }) %}
            {% endfor %}
            {% do log("DEBUG: col_types dict: " ~ col_types, info=true) %}
        {% endif %}

        {% for column in columns %}
            {% set column = column | upper %}
            {% do log("DEBUG: column being processed: " ~ column, info=true) %}
            {% set col_type = col_types.get(column) %}
            {% if col_type is not none %}
                {% set type_code = (
                    'st' if col_type in ['VARCHAR', 'TEXT', 'STRING']
                    else 'nm' if col_type in ['NUMBER', 'INT', 'INTEGER', 'FLOAT', 'DECIMAL']
                    else 'dt' if col_type in ['DATE', 'TIMESTAMP', 'DATETIME']
                    else 'st'
                ) %}
                {% set masking_policy = 'plcy_' ~ schema ~ '_' ~ type_code %}
                {% set sql %}
                    ALTER {{ table_type }} {{ database }}.{{ schema }}.{{ table }}
                    MODIFY COLUMN {{ column }}
                    SET MASKING POLICY {{ database }}.{{ schema }}.{{ masking_policy }};
                {% endset %}
                {% do run_query(sql) %}
                {% do log("Applied masking policy " ~ masking_policy ~ " to " ~ column ~ " on " ~ table ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}
            {% else %}
                {{ exceptions.raise_compiler_error("apply_dynamic_masking_policy: Column '" ~ col_name ~ "' not found in metadata for table " ~ table) }}
            {% endif %}
        {% endfor %}

        {% set query %}
            insert into dbt_dev.sch_dbt_test.hooks_log (hook_type, table_name, executed_at)
            values ('post-hook-masking-policy', '{{ table }}', current_timestamp);
        {% endset %}
        {% do run_query(query) %}
        {% do log("DEBUG: Hook run logged", info=true) %}
    {% endif %}
{% endmacro %}

