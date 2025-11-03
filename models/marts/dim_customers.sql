-- models/marts/dim_customers.sql

WITH customer_stats AS (
    SELECT
        customer_id,
        customer_name,
        market_segment,
        account_balance,
        balance_status,
        -- Add analytics
        COUNT(*) OVER (PARTITION BY market_segment) as segment_count,
        AVG(account_balance) OVER (PARTITION BY market_segment) as avg_segment_balance,
        RANK() OVER (ORDER BY account_balance DESC) as wealth_rank
    FROM {{ ref('stg_customers') }}
)

SELECT
    customer_id,
    customer_name,
    market_segment,
    account_balance,
    balance_status,
    segment_count,
    avg_segment_balance,
    wealth_rank,
    -- Customer tier based on balance
    CASE
        WHEN wealth_rank <= 100 THEN 'Platinum'
        WHEN wealth_rank <= 500 THEN 'Gold'
        WHEN wealth_rank <= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END as customer_tier
FROM customer_stats