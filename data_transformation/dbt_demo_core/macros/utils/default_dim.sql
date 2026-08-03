{% macro default_dim(
    sid_col,
    cols_type=None,
    model_ref=None,
    unknown_label='UNKNOWN',
    not_applicable_label='NOT APPLICABLE',
    all_label='ALL',
    numeric_literal=-10,
    date_literal="DATE '1900-01-01'",
    timestamp_literal="TO_TIMESTAMP('1900-01-01 00:00:00')"

) %}
    {% if execute %}
        {{ log("default_dim: Starting macro", info=True) }}
        {{ log("sid_col: " ~ sid_col, info=True) }}
        {{ log("cols_type: " ~ cols_type, info=True) }}
        {{ log("model_ref: " ~ model_ref, info=True) }}

        {%- if not cols_type or cols_type | length == 0 -%}
            {{ exceptions.raise_compiler_error('default_dims: provide cols_type with the columns to populate') }}
        {%- endif -%}

        {%- set effective_model_ref = model_ref if model_ref is not none else this -%}
        {{ log("effective_model_ref: " ~ effective_model_ref, info=True) }}

        {%- set requested_columns = [] -%}
        {%- if cols_type is mapping -%}
            {%- for col_name in cols_type.keys() -%}
                {%- do requested_columns.append(col_name) -%}
            {%- endfor -%}
        {%- else -%}
            {%- for col_name in cols_type -%}
                {%- do requested_columns.append(col_name) -%}
            {%- endfor -%}
        {%- endif -%}

            {%- if sid_col not in requested_columns -%}
                {%- set requested_columns = [sid_col] + requested_columns -%}
            {%- endif -%}
        {%- set requested_columns = requested_columns | unique | list -%}
        {{ log("requested_columns: " ~ requested_columns, info=True) }}

        {%- set node_unique_id = model.unique_id | string -%}
        {{ log("node_unique_id: " ~ node_unique_id, info=True) }}

        {%- if node_unique_id is none -%}
            {{ exceptions.raise_compiler_error('default_dims: unable to determine unique_id for the current model; ensure the macro is called from within a model context') }}
        {%- endif -%}

        {%- set column_meta_map = {} -%}
        {%- if graph is defined -%}
            {%- if node_unique_id in graph.nodes -%}
                {%- set column_definitions = graph.nodes[node_unique_id]['columns'] -%}
            {%- elif node_unique_id in graph.sources -%}
                {%- set column_definitions = graph.sources[node_unique_id]['columns'] -%}
            {%- else -%}
                {%- set column_definitions = {} -%}
            {%- endif -%}
        {%- else -%}
            {%- set column_definitions = {} -%}
        {%- endif -%}
        {{ log("column_definitions: " ~ column_definitions, info=True) }}

        {%- if column_definitions | length == 0 -%}
            {{ exceptions.raise_compiler_error('default_dims: no column metadata found in graph for ' ~ node_unique_id) }}
        {%- endif -%}

        {%- for column_name, column_meta in column_definitions.items() -%}
            {%- if column_meta.data_type -%}
                {%- do column_meta_map.update({ column_name: column_meta.data_type }) -%}
            {%- endif -%}
        {%- endfor -%}
        {{ log("column_meta_map: " ~ column_meta_map, info=True) }}

        {%- set resolved_cols_type = {} -%}
        {%- for column_name in requested_columns -%}
            {%- set dtype = column_meta_map.get(column_name) -%}
            {%- if dtype -%}
                {%- do resolved_cols_type.update({ column_name: dtype }) -%}
            {%- else -%}
                {{ exceptions.raise_compiler_error('default_dims: data_type metadata missing for column "' ~ column_name ~ '" in model ' ~ node_unique_id) }}
            {%- endif -%}
        {%- endfor -%}
        {{ log("resolved_cols_type: " ~ resolved_cols_type, info=True) }}

        {%- if sid_col not in resolved_cols_type -%}
            {{ exceptions.raise_compiler_error('default_dims: sid_col "' ~ sid_col ~ '" not found in resolved column metadata') }}
        {%- endif -%}

        {%- set labels = [unknown_label, not_applicable_label, all_label] -%}
        {{ log("labels: " ~ labels, info=True) }}
        {%- set short_label_map_two = {
            (unknown_label): 'UN',
            (not_applicable_label): 'NA',
            (all_label): 'AL'
        } -%}
        {%- set short_label_map_medium = {
            (unknown_label): 'UN',
            (not_applicable_label): 'NA',
            (all_label): 'ALL'
        } -%}
        {%- set text_types = ['string', 'text', 'varchar', 'char'] -%}
        {%- set numeric_types = ['int', 'integer', 'number', 'float', 'decimal', 'numeric', 'bigint', 'smallint', 'double'] -%}
        {%- set date_types = ['date'] -%}
        {%- set ts_types = ['timestamp', 'datetime', 'timestamptz', 'timestamp_ntz', 'timestamp_ltz'] -%}
        {%- set selects = [] -%}

        {%- for idx in range(labels | length) -%}
            {%- set parts = [] -%}
            {%- do parts.append(idx ~ ' AS ' ~ sid_col) -%}
            {%- for col, data_type in resolved_cols_type.items() -%}
                {%- if col == sid_col -%}
                    {%- continue -%}
                {%- else -%}
                    {%- set dtype_raw = (data_type or '') | lower -%}
                    {%- set base_dtype = dtype_raw.split('(')[0] -%}
                    {%- set col_name = col -%}
                    {%- set label_value = labels[idx] -%}
                    {%- set override_val = cols_type.get(col) if cols_type is mapping else none -%}
                    {{ log("Processing col: " ~ col_name ~ ", data_type: " ~ data_type ~ ", base_dtype: " ~ base_dtype, info=True) }}
                    {%- if override_val == 'null' -%}
                        {%- do parts.append('NULL AS ' ~ col_name) -%}
                    {%- elif base_dtype in text_types -%}
                        {%- set max_len = none -%}
                        {%- if '(' in dtype_raw and ')' in dtype_raw -%}
                            {%- set len_str = dtype_raw[dtype_raw.find('(')+1 : dtype_raw.find(')')] | replace(' ', '') -%}
                            {%- set len_candidate = (len_str.split(',')[0]) -%}
                            {%- set parsed_len = len_candidate | int(0) -%}
                            {%- if parsed_len > 0 -%}
                                {%- set max_len = parsed_len -%}
                            {%- endif -%}
                        {%- endif -%}
                        {%- set label_override = label_value -%}
                        {%- if max_len is not none -%}
                            {%- if max_len == 1 -%}
                                {%- set label_override = 'N' -%}
                            {%- elif max_len == 2 -%}
                                {%- set label_override = short_label_map_two.get(label_value, label_value) -%}
                            {%- elif 2 < max_len < 14 -%}
                                {%- set label_override = short_label_map_medium.get(label_value, label_value) -%}
                            {%- else -%}
                                {%- set label_override = label_value -%}
                            {%- endif -%}
                            {%- if label_override | length > max_len -%}
                                {%- set label_override = label_override[:max_len] -%}
                            {%- endif -%}
                        {%- endif -%}
                        {{ log("col: " ~ col_name ~ ", label_override: " ~ label_override ~ ", max_len: " ~ max_len, info=True) }}
                        {%- do parts.append("'" ~ label_override ~ "' AS " ~ col_name) -%}
                    {%- elif base_dtype in numeric_types -%}
                        {%- do parts.append(numeric_literal | string ~ ' AS ' ~ col_name) -%}
                    {%- elif base_dtype in date_types -%}
                        {%- do parts.append(date_literal ~ ' AS ' ~ col_name) -%}
                    {%- elif base_dtype in ts_types -%}
                        {%- do parts.append(timestamp_literal ~ ' AS ' ~ col_name) -%}
                    {%- elif dtype_raw == '' -%}
                        {%- do parts.append('NULL AS ' ~ col_name) -%}
                    {%- else -%}
                        {%- do parts.append("'" ~ label_value ~ "' AS " ~ col_name) -%}
                    {%- endif -%}
                {%- endif -%}
            {%- endfor -%}
            {{ log("parts for idx " ~ idx ~ ": " ~ parts, info=True) }}
            {%- do selects.append('SELECT ' ~ (parts | join(', '))) -%}
        {%- endfor -%}

        {{ log("Final selects: " ~ selects, info=True) }}
        {{ selects | join('\nUNION ALL\n') }}

    {% endif %}
{% endmacro %}