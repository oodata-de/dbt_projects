{# helper macros must be top-level (cannot be nested inside another macro) #}
{% macro _normalize_type(raw_type) %}
    {% set t = raw_type | default('') | upper %}
    {% if 'TEXT' in t or 'STRING' in t %}
        {{ return('STRING') }}
    {% elif 'NUMBER' in t or 'FLOAT' in t %}
        {{ return('NUMBER') }}
    {% elif 'DATE' in t or 'TIME' in t or 'TIMESTAMP_NTZ' in t or 'TIMESTAMP_LTZ' in t %}
        {{ return('DATETIME') }}
    {% else %}
        {{ return('STRING') }} {# fallback #}
    {% endif %}
{% endmacro %}

{% macro _policy_suffix(norm_type) %}
    {% if norm_type == 'STRING' %}
        {{ return('ST') }}
    {% elif norm_type == 'NUMBER' %}
        {{ return('NM') }}
    {% elif norm_type == 'DATETIME' %}
        {{ return('DT') }}
    {% else %}
        {{ return('ST') }}
    {% endif %}
{% endmacro %}

{% macro _policy_name(target_db, schema_name, norm_type) %}
    {% set suffix = _policy_suffix(norm_type) %}
    {{ return(target_db ~ '.' ~ (schema_name | upper) ~ '.PLCY_' ~ (schema_name | upper) ~ '_' ~ suffix) }}
{% endmacro %}

{% macro apply_dynamic_masking_policy_test(columns) %}
    {#- 
    Entry-point macro for use in a models post_hook 
    Example:
        {{ config(
            post_hook="{{ apply_dynamic_masking(['ssn','email']) }}"
        ) }}
    
    -#}

    {# Skip if relation not materialized yet (ephemeral) #}
    {% if this is not defined %}
        {% do log('apply_dynamic_masking: no relation (possibly ephemeral) -> skipping', info=True) %}
        {% do return(None) %}
    {% endif %}

    {# Require columns argument #}
    {% if columns is none %}
        {{ exceptions.raise_compiler_error("apply_dynamic_masking: columns argument is required.") }}
    {% endif %}

    {# Normalize column names to uppercase #}
    {% set desired_cols = columns | map('upper') | list %}

    {% if desired_cols | length == 0 %}
        {% do log('apply_dynamic_masking: no columns requested -> nothing to do', info=True) %}
        {% do return(None) %}
    {% endif %}

    {# Gather relation metadata #}
    {% set target_db = this.database %}
    {% set target_schema = this.schema %}
    {% set target_identifier = this.identifier %}
    {% set relation = api.Relation.create(
        database=target_db,
        schema=target_schema,
        identifier=target_identifier
    ) %}

    {# Determine relation type (TABLE / VIEW) #}
    {% set existing_relation = adapter.get_relation(
        database=relation.database,
        schema=relation.schema,
        identifier=relation.identifier
    ) %}
    {% if existing_relation is none %}
        {{ exceptions.raise_compiler_error("apply_dynamic_masking: relation " ~ relation ~ " not found.") }}
    {% endif %}
    {% set rel_type = existing_relation.type | upper %}
    {% if rel_type not in ['TABLE','VIEW'] %}
        {% do log('apply_dynamic_masking: relation type ' ~ rel_type ~ ' not supported -> skipping', info=True) %}
        {% do return(None) %}
    {% endif %}

    {# Single metadata query for column types + existing masking policies #}
    {% set col_sql %}
        select
            upper(column_name) as column_name,
            data_type,
            pr.policy_name as masking_policy
        from {{ target_db }}.{{ target_schema }}.information_schema.columns
        left join table(information_schema.policy_references(
            ref_entity_domain => 'TABLE',
            ref_entity_name => '{{ target_identifier }}'
        )) pr on pr.ref_column_name = columns.column_name and pr.ref_entity_name = columns.table_name
        where table_name = upper('{{ target_identifier }}')
    {% endset %}
    {% set col_results = run_query(col_sql) %}
    {% if col_results is none %}
        {{ exceptions.raise_compiler_error("apply_dynamic_masking: metadata query returned none") }}
    {% endif %}

    {# Convert results to dict: column_name -> {data_type, masking_policy} #}
    {% set meta = {} %}
    {% for row in col_results %}
        {% do meta.update({ row['COLUMN_NAME']: {
            'data_type': row['DATA_TYPE'],
            'masking_policy': row['MASKING_POLICY']
        } }) %}
    {% endfor %}

    {# Prepare operation lists #}
    {% set to_set = [] %}
    {% set to_unset = [] %}
    {% set missing_columns = [] %}

    {# Classify desired columns #}
    {% for col in desired_cols %}
        {% if col not in meta %}
            {% do missing_columns.append(col) %}
        {% else %}
            {% set norm = _normalize_type(meta[col]['data_type']) %}
            {# pass target_db and schema to _policy_name (helper is now top-level) #}
            {% set policy_fqn = _policy_name(target_db, target_schema, norm) %}
            {% do to_set.append({'column': col, 'policy': policy_fqn, 'norm': norm}) %}
        {% endif %}
    {% endfor %}

    {# Identify columns currently masked but no longer desired #}
    {% for col_name, info in meta.items() %}
        {% if info['masking_policy'] is not none and (col_name not in desired_cols) %}
            {% do to_unset.append(col_name) %}
        {% endif %}
    {% endfor %}

    {# Build and execute sequential ALTER statements #}
    {% set applied = 0 %}
    {% set removed = 0 %}

    {# Unset obsolete first #}
    {% for col in to_unset %}
        {% set unset_sql %}
            ALTER {{ rel_type }} {{ target_db }}.{{ target_schema }}.{{ target_identifier }}
            MODIFY COLUMN {{ col }} UNSET MASKING POLICY
        {% endset %}
        {% do run_query(unset_sql) %}
        {% set removed = removed + 1 %}
    {% endfor %}

    {# Apply (replace) desired policies #}
    {% for item in to_set %}
        {# First UNSET if a policy exists #}
        {% if meta[item['column']]['masking_policy'] is not none %}
            {% set pre_unset_sql %}
                ALTER {{ rel_type }} {{ target_db }}.{{ target_schema }}.{{ target_identifier }}
                MODIFY COLUMN {{ item['column'] }} UNSET MASKING POLICY
            {% endset %}
            {% do run_query(pre_unset_sql) %}
        {% endif %}
        {% set apply_sql %}
            ALTER {{ rel_type }} {{ target_db }}.{{ target_schema }}.{{ target_identifier }}
            MODIFY COLUMN {{ item['column'] }} SET MASKING POLICY {{ item['policy'] }}
        {% endset %}
        {% do run_query(apply_sql) %}
        {% set applied = applied + 1 %}
    {% endfor %}

    {# Summary log #}
    {% set summary %}
        apply_dynamic_masking summary:
        relation={{ target_db }}.{{ target_schema }}.{{ target_identifier }} type={{ rel_type }}
        desired_columns={{ desired_cols | join(',') }}
        applied={{ applied }} removed={{ removed }}
        missing_columns={{ missing_columns | join(',') if missing_columns|length>0 else 'none' }}
    {% endset %}
    {% do log(summary, info=True) %}

    {# Raise compiler error if any desired columns missing (fail fast) #}
    {% if missing_columns | length > 0 %}
        {{ exceptions.raise_compiler_error("apply_dynamic_masking: columns not found: " ~ (missing_columns | join(', '))) }}
    {% endif %}

    {{ return(None) }}
    
{% endmacro %}