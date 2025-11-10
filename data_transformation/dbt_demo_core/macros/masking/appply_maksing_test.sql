{% macro apply_masking_test(masking_policies_dict) %}
    {# Usage (in a model):
       {{
         config(
           post_hook=[
             "{{ apply_dynamic_masking_policy_complex({'email':'PLCY_EMAIL_REDACT','phone':'SEC_MASK.PLCY_PHONE_HASH','loyalty_id':'PLCY_LOYALTY_MASK'}) }}"
           ]
         )
       }}
    #}

    {% if execute %}

        {# 1. Validate input dict #}
        {% if masking_policies_dict is none or masking_policies_dict | length == 0 %}
            {{ exceptions.raise_compiler_error("apply_dynamic_masking_policy_complex: masking_policies_dict is required and cannot be empty.") }}
        {% endif %}

        {# 2. Gather model metadata #}
        {% set database = this.database %}
        {% set schema   = this.schema %}
        {% set alias    = this.identifier %}
        -- {% set relation = adapter.get_relation(database=database, schema=schema, identifier=alias) %}
        -- {% if relation is none %}
        --     {{ exceptions.raise_compiler_error("apply_dynamic_masking_policy_complex: Relation " ~ database ~ "." ~ schema ~ "." ~ alias ~ " not found.") }}
        -- {% endif %}

        {# 3. Map materialization to Snowflake object type #}
        {% set materialization_map = {"table":"table","view":"view","incremental":"table","snapshot":"table","dynamic_table":"table"} %}
        {% set materialized = config.get('materialized', 'table') %}
        {% set object_type = materialization_map.get(materialized, 'table') %}

        {# 4. Describe once to get existing column + masking policy info #}
        {% set describe_sql %}
            describe {{ object_type }} {{ database }}.{{ schema }}.{{ alias }};
        {% endset %}
        {% set describe_res = run_query(describe_sql) %}
        {% do log("DEBUG: run_query result for describe sql: " ~ describe_res ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}
        {% if describe_res is none or describe_res.rows | length == 0 %}
            {{ exceptions.raise_compiler_error("apply_dynamic_masking_policy_complex: DESCRIBE returned no rows for " ~ database ~ "." ~ schema ~ "." ~ alias) }}
        {% endif %}

        {# Build dict: COLUMN_NAME_UPPER -> EXISTING_POLICY_UPPER (empty if none) #}
        {% set existing_policies = {} %}
        {% for r in describe_res.rows %}
            {% set col_name = r[0] | string %}
            {% set policy_name = (r[-2] | string) if r[-1] is not none else '' %}
            {% set _ = existing_policies.update({ col_name | upper : policy_name | upper }) %}
        {% endfor %}
        {% do log("DEBUG: existing_policies: " ~ existing_policies | tojson ~ " at " ~ modules.datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'), info=true) %}

        {# 5. Normalize masking policy mappings (qualify if needed) #}
        {% set final_mappings = {} %}
        {% for col_key, raw_policy in masking_policies_dict.items() %}
            {% if raw_policy is none or (raw_policy | trim) == '' %}
                {{ exceptions.raise_compiler_error("Masking policy value missing for column key '" ~ col_key ~ "'.") }}
            {% endif %}
            {% set col_upper = col_key | upper %}
            {% if existing_policies.get(col_upper) is none %}
                {{ exceptions.raise_compiler_error("Column '" ~ col_key ~ "' not found in " ~ database ~ "." ~ schema ~ "." ~ alias ~ ".") }}
            {% endif %}

            {% set parts = (raw_policy | trim).split('.') %}
            {% if parts | length == 3 %}
                {% set qualified = raw_policy %}
            {% elif parts | length == 1 %}
                {% set qualified = database ~ "." ~ schema ~ "." ~ parts[0] %}
            {% else %}
                {{ exceptions.raise_compiler_error("Invalid masking policy format '" ~ raw_policy ~ "' for column '" ~ col_key ~ "'. Expected POLICY or DB.SCHEMA.POLICY.") }}
            {% endif %}

            {% set _ = final_mappings.update({ col_key : qualified }) %}
        {% endfor %}

        {# 6. Apply policies (skip if already identical) #}
        {% for original_col, qualified_policy in final_mappings.items() %}
            {% set col_upper = original_col | upper %}
            {% set existing_policy_upper = existing_policies.get(col_upper) %}
            {% set qualified_upper = qualified_policy | upper %}
            {% set quoted_col = '"' ~ original_col ~ '"' if model.columns.get(original_col, {}).get('quote', false) else original_col %}

            {% if existing_policy_upper == qualified_upper %}
                {{ log(modules.datetime.datetime.now().strftime("%H:%M:%S") ~ " | SKIP masking (already applied) | " ~ qualified_policy ~ " | " ~ database ~ "." ~ schema ~ "." ~ alias ~ "." ~ original_col, info=True) }}
            {% else %}
                {% set alter_sql %}
                    alter {{ object_type }} {{ database }}.{{ schema }}.{{ alias }}
                    modify column {{ quoted_col }}
                    set masking policy {{ qualified_policy }} {% if var('use_force_applying_masking_policy','False') | upper in ['TRUE','YES'] %} force {% endif %};
                {% endset %}
                {{ log(modules.datetime.datetime.now().strftime("%H:%M:%S") ~ " | APPLY masking | " ~ qualified_policy ~ " | " ~ database ~ "." ~ schema ~ "." ~ alias ~ "." ~ original_col ~ " [force=" ~ var('use_force_applying_masking_policy','False') ~ "]", info=True) }}
                {% do run_query(alter_sql) %}
            {% endif %}
        {% endfor %}
    {% endif %}
{% endmacro %}
