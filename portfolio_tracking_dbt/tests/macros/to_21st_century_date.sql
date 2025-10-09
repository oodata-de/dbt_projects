-- singular unit test for the to_21st_century_date macro. Other pattern scan be used to unit test macros
WITH

test_data as (
    SELECT '0021-09-23'::date as src_date,
        '2021-09-23'::date as expected_date
    UNION
    SELECT '1021-09-24', '1021-09-24'
    UNION
    SELECT '2021-09-25', '2021-09-25'
    UNION
    SELECT '-0021-09-26', '1979-09-26'
)

SELECT
    {{to_21st_century_date('src_date')}} as ok_date,
    expected_date,
    ok_date = expected_date as matching
FROM test_data

WHERE not matching