-- models/staging/stg_customers.sql

WITH raw_customers AS (
    SELECT
        c_custkey as customer_id,
        c_name as customer_name,
        c_address as customer_address,
        c_nationkey as nation_id,
        c_phone as phone_number,
        c_acctbal as account_balance,
        c_mktsegment as market_segment,
        c_comment as comments
    FROM {{ source('raw_data', 'customer') }}
),

cleaned_customers AS (
    SELECT
        customer_id,
        UPPER(customer_name) as customer_name,
        customer_address,
        nation_id,
        REGEXP_REPLACE(phone_number, '[^0-9]', '') as cleaned_phone,
        ROUND(account_balance, 2) as account_balance,
        market_segment,
        comments,
        CASE
            WHEN account_balance > 0 THEN 'Positive Balance'
            WHEN account_balance = 0 THEN 'Zero Balance'
            ELSE 'Negative Balance'
        END as balance_status
    FROM raw_customers
)

SELECT *
FROM cleaned_customers