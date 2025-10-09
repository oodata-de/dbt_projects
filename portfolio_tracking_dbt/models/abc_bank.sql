SELECT *
FROM {{ source('abc_bank', 'ABC_BANK_POSITION') }}