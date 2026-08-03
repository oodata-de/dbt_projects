{% macro test_default_macro() %}
    {{ print(default_dimension_records(
        {
            'transaction_type_sid': 'int',
            'transaction_type_code': 'string',
            'transaction_type_name': 'string',
            'source_name': 'string'
        },
        'transaction_type_sid'
    )) }}
{% endmacro %}