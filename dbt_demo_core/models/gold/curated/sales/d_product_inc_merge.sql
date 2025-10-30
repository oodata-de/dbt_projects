{{ 
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='product_id',
        merge_exclude_columns = ['product_sid']
    ) 
}}

with distinct_product as (
    SELECT product_id AS PRODUCT_ID,
      UPPER(TRIM(product_name)) AS PRODUCT_NAME,
      UPPER(TRIM(category)) AS CATEGORY,
      CASE WHEN unit_price < 0 THEN NULL ELSE unit_price END AS unit_price,
      in_stock AS IN_STOCK_FLAG
    FROM {{ source('salesdb', 'products') }} p
    {% if is_incremental() %}
    where _el_timestamp >= (select coalesce(max(_process_timestamp), '1900-01-01') from {{ this }})
    {% endif %}
)

SELECT {{ increment_sequence() }} as product_sid, 
    PRODUCT_ID, 
    PRODUCT_NAME, 
    CATEGORY, 
    UNIT_PRICE, 
    IN_STOCK_FLAG,
    {{ dbt_utils.generate_surrogate_key([
            'product_name', 'category', 'unit_price', 'in_stock_flag'])
    }} as _sha256_val,
    current_timestamp() AS _process_timestamp
FROM distinct_product

