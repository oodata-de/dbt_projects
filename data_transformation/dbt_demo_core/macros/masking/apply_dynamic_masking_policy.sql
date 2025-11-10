{% macro apply_dynamic_masking_policy(columns, masking_policy) %}
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

        {% for column in columns %}
            {% set column = column | upper %}
            {% do log("DEBUG: table_type before alter sql: " ~ table_type, info=true) %}
            {% set sql %}
                ALTER {{ table_type }} {{ database }}.{{ schema }}.{{ table }}
                MODIFY COLUMN {{ column }}
                SET MASKING POLICY {{ database }}.{{ schema }}.{{ masking_policy }};
            {% endset %}
            {% do run_query(sql) %}
            {% do log("Applied masking policy " ~ masking_policy ~ " to " ~ column ~ " on " ~ table ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}
        {% endfor %}

        {% set query %}
            insert into dbt_dev.sch_dbt_test.hooks_log (hook_type, table_name, executed_at)
            values ('post-hook-masking-policy', '{{ table }}', current_timestamp);
        {% endset %}
        {% do run_query(query) %}
        {% do log("DEBUG: Hook run logged", info=true) %}
    {% endif %}
{% endmacro %}

{% macro temp_test() %}
  {% if execute %}
    {% set database = this.database %}
    {% set schema = this.schema %}
    {% set table = this.identifier %}
    {% set table_type_query %}
      select
        CASE t.table_type
          WHEN 'BASE TABLE' THEN 'TABLE'
          ELSE t.table_type
        END AS table_type
      from {{ database }}.information_schema.tables t
      where table_name = '{{ table | upper }}'
      limit 1;
    {% endset %}

    {% do log("DEBUG: temp_test table_type_query SQL: " ~ table_type_query, info=true) %}

    {% set result = run_query(table_type_query) %}
    {% do log("DEBUG: temp_test run_query result: " ~ result ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}

    {# if result return true if result of run query is not empty #}
    {% if result %}
      {%- for row in result.rows  -%}
        {% do log("DEBUG: temp_test row: " ~ row['TABLE_TYPE'], info = true) %}
        {% set table_type = row['TABLE_TYPE'] %}
        {% do log("DEBUG: temp_test table_type from query: " ~ table_type ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}
      {% endfor %}
    {% else %}
      {% do log("DEBUG: temp_test table_type not found, defaulting to 'TABLE'", info=true) %}
      {% set table_type = 'TABLE' %}
    {% endif %}
  {% endif %}
{% endmacro %}

