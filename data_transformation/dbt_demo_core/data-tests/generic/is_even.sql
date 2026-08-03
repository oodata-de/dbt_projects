-- This is a generic dbt test that checks whether all values in the specified column of a model are even numbers.
-- Similar to built-in tests like 'not_null' or 'unique', this test can be applied to any model and column by specifying them in the test configuration.
-- Test accepts model and column_name as arguments. Test is added to the yml file.

{% test is_even(model, column_name) %}

with validation as (

    select
        {{ column_name }} as even_field

    from {{ model }}

),

validation_errors as (

    select
        even_field

    from validation
    -- if this is true, then even_field is actually odd!
    where (even_field % 2) = 1

)

select *
from validation_errors

{% endtest %}