{% macro default_dimension_records(
    cols_type,
    sid_col,
    unknown_label='UNKNOWN',
    not_applicable_label='NOT APPLICABLE',
    all_label='ALL',
    numeric_literal=-10,
    date_literal="DATE '1900-01-01'",
    timestamp_literal="TO_TIMESTAMP('1900-01-01 00:00:00')"
) %}

    {#-- Validate input --#}
    {%- if not cols_type or cols_type | length == 0 -%}
        {{ exceptions.raise_compiler_error('default_dimension_records: cols_type cannot be empty') }}
    {%- endif -%}

    {%- if sid_col | length == 0 -%}
        {{ exceptions.raise_compiler_error('default_dimension_records: sid_col (name of column containing surrogate key) cannot be empty') }}
    {%- endif -%}

    {%- set labels = [unknown_label, not_applicable_label, all_label] -%}
    {%- set text_types = ['string', 'text', 'varchar', 'char'] -%}
    {%- set numeric_types = ['int', 'integer', 'number', 'float', 'decimal', 'numeric', 'bigint', 'smallint', 'double'] -%}
    {%- set date_types = ['date'] -%}
    {%- set ts_types = ['timestamp', 'datetime', 'timestamptz', 'timestamp_ntz', 'timestamp_ltz'] -%}

    {%- set selects = [] -%}

    {%- for idx in range(labels | length) -%}
        {%- set parts = [] -%}
        {%- do parts.append(idx ~ ' AS ' ~ sid_col) -%}
        {%- for col, data_type in cols_type.items() -%}
            {%- set dtype = data_type | lower -%}
            {%- set col_name = col -%}
            {%- if dtype in text_types -%}
                {%- do parts.append("'" ~ labels[idx] ~ "' AS " ~ col_name) -%}
            {%- elif dtype in numeric_types -%}
                {%- do parts.append(numeric_literal | string ~ ' AS ' ~ col_name) -%}
            {%- elif dtype in date_types -%}
                {%- do parts.append(date_literal ~ ' AS ' ~ col_name) -%}
            {%- elif dtype in ts_types -%}
                {%- do parts.append(timestamp_literal ~ ' AS ' ~ col_name) -%}
            {%- elif dtype == '' -%}
                {%- do parts.append('NULL AS ' ~ col_name) -%}
            {%- else -%}
                {%- do parts.append("'" ~ labels[idx] ~ "' AS " ~ col_name) -%}
            {%- endif -%}
        {%- endfor -%}
        {%- do selects.append('SELECT ' ~ (parts | join(', '))) -%}
    {%- endfor -%}

    {{ selects | join('\nUNION ALL\n') }}

{% endmacro %}