{% macro test_macro() %}
    {% if execute %}

        {% set relation_obj = load_relation( this ) %}
        {% if relation_obj is not none %}
            {{ log("my_model has already been built", info=true) }}
            {{ log("my_model is view: " ~ relation_obj.is_view, info=true) }}
            {{ log("relation_exists: " ~ relation_obj, info=true) }}
        {% else %}
            {{ log("my_model doesn't exist in the warehouse. Maybe it was dropped?", info=true) }}
        {% endif %}

        {%- set source_relation = adapter.get_relation(
            database=this.database,
            schema=this.schema,
            identifier=this.identifier) 
        -%}

        {{ log("Source Relation: " ~ source_relation, info=true) }}
        {{ log("Source Relation Type: " ~ source_relation.type, info=true) }}

        {{ log("Materialization: " ~ this.config.materialized, info=true) }}

        {% set query %}
            insert into dbt_dev.sch_dbt_test.hooks_log (hook_type, table_name, executed_at)
            values ('post-hook-test-macro', 'hardcoded', current_timestamp);
        {% endset %}

        {% do run_query(query) %}

    {% endif %}
{% endmacro %}

{% macro log_post_hook(table_name) %}
    insert into dbt_dev.sch_dbt_test.hooks_log (hook_type, table_name, executed_at)
    values ('post-hook', '{{table_name}}', current_timestamp);
{% endmacro %}