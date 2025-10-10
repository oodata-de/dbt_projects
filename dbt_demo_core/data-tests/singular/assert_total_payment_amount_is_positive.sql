-- Singular tests is specific to a model and a column. They run by default when you run dbt test.
-- Refunds have a negative amount, so the total amount should always be >= 0.
-- Therefore return records where this isn't true (positive ) to make the test fail
select
    id
    , sum(amount)
from {{ ref('fact_orders' )}}
group by 1
having not(sum(amount) >= 0)