I'll create a comprehensive step-by-step documentation in a markdown file. Let me write this for you:

```markdown
# dbt Project Setup & Data Transformation Guide

## Overview
This document outlines the complete step-by-step process of setting up a dbt (data build tool) project, connecting to Snowflake, and building a data transformation pipeline.

## Prerequisites
- Python 3.11 or 3.12 (dbt doesn't support Python 3.14+ yet)
- Snowflake account with credentials
- Basic understanding of SQL and data modeling

## Step-by-Step Implementation

### Phase 1: Environment Setup

#### Step 1: Python Virtual Environment
```bash
# Create virtual environment
python3.12 -m venv .venv

# Activate virtual environment
source .venv/bin/activate
```

#### Step 2: Install dbt and Dependencies
```bash
# Install dbt core and Snowflake adapter
pip install dbt-core dbt-snowflake

# Verify installation
dbt --version
```

### Phase 2: Project Initialization

#### Step 3: Create dbt Project
```bash
# Initialize new dbt project
dbt init my_dbt_projects
```

#### Step 4: Configure Snowflake Connection
Edit `~/.dbt/profiles.yml`:

```yaml
my_dbt_projects:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: YOUR_ACCOUNT_NAME
      user: YOUR_USERNAME
      password: YOUR_PASSWORD
      role: ACCOUNTADMIN
      database: DBT_PROJECTS
      warehouse: COMPUTE_WH
      schema: dbt_schema
      threads: 1
```

#### Step 5: Test Connection
```bash
# Verify Snowflake connection
dbt debug
```

### Phase 3: Database Setup

#### Step 6: Create Database in Snowflake
```sql
-- Execute in Snowflake worksheet
CREATE DATABASE DBT_PROJECTS;
```

#### Step 7: Load Sample Data
```sql
-- Create schema and table with sample data
USE DATABASE DBT_PROJECTS;
CREATE SCHEMA RAW_DATA;

-- Copy data from Snowflake sample database
CREATE TABLE DBT_PROJECTS.RAW_DATA.CUSTOMER AS
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER;
```

### Phase 4: Data Modeling

#### Step 8: Define Data Sources
Create `models/staging/sources.yml`:

```yaml
version: 2

sources:
  - name: raw_data
    database: DBT_PROJECTS
    schema: raw_data
    tables:
      - name: customer
```

#### Step 9: Create Staging Model
Create `models/staging/stg_customers.sql`:

```sql
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
```

#### Step 10: Create Mart Model
Create `models/marts/dim_customers.sql`:

```sql
WITH customer_stats AS (
    SELECT
        customer_id,
        customer_name,
        market_segment,
        account_balance,
        balance_status,
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
    CASE
        WHEN wealth_rank <= 100 THEN 'Platinum'
        WHEN wealth_rank <= 500 THEN 'Gold'
        WHEN wealth_rank <= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END as customer_tier
FROM customer_stats
```

### Phase 5: Data Quality & Testing

#### Step 11: Implement Data Tests
Create `models/staging/schema.yml`:

```yaml
version: 2

models:
  - name: stg_customers
    description: "Cleaned customer data from raw source"
    columns:
      - name: customer_id
        description: "Primary key for customer"
        tests:
          - unique
          - not_null
      - name: customer_name
        description: "Name of the customer"
        tests:
          - not_null
      - name: account_balance
        description: "Customer account balance"
        tests:
          - not_null
```

Create `models/marts/schema.yml`:

```yaml
version: 2

models:
  - name: dim_customers
    description: "Customer dimension table with analytics"
    columns:
      - name: customer_id
        description: "Primary key for customer"
        tests:
          - unique
          - not_null
      - name: customer_tier
        description: "Customer tier based on wealth rank"
        tests:
          - accepted_values:
              arguments:
                values: ['Platinum', 'Gold', 'Silver', 'Bronze']
```

### Phase 6: Execution & Validation

#### Step 12: Run Data Transformations
```bash
# Run all models
dbt run

# Run specific models
dbt run --select stg_customers
dbt run --select dim_customers
```

#### Step 13: Execute Data Tests
```bash
# Run all tests
dbt test

# Run specific tests
dbt test --select stg_customers
```

#### Step 14: Generate Documentation
```bash
# Generate documentation
dbt docs generate

# Serve documentation locally
dbt docs serve
```

## Project Structure
```
my_dbt_projects/
├── 📂 models/           # 🎯 MOST IMPORTANT - Your Data Models
├── 📂 analyses/         # 🔍 Exploratory SQL Queries
├── 📂 macros/           # 🛠️ Reusable Code Components
├── 📂 seeds/            # 🌱 Static Data Files
├── 📂 snapshots/        # 📊 Historical Data Tracking
├── 📂 tests/            # ✅ Data Quality Tests
├── 📂 target/           # 🗑️ Temporary Files (Auto-generated)
├── 📜 dbt_project.yml   # ⚙️ Project Configuration
└── 📜 .gitignore        # 🔒 Git Ignore Rules
```
## Data Transformation Pipeline
```
 RAW DATA (Snowflake Sample)          =     BRONZE LAYER (Raw)
     ↓                                          ↓
 EXTRACTION (Automatic via dbt)         =    DATA INGESTION
     ↓                                          ↓
 STAGING LAYER (stg_customers)         =     SILVER LAYER (Cleaned)
     ↓                                          ↓
 TRANSFORMATION LAYER (dim_customers)  =     GOLD LAYER (Business)
     ↓                                          ↓
 ANALYTICS LAYER (Business-ready data) =    CONSUMPTION LAYER
     ↓                                          ↓
 DATA QUALITY CHECKS (Tests)           =    QUALITY & GOVERNANCE
```

## Common Issues & Solutions

### 1. Python Version Compatibility
- Use Python 3.11 or 3.12
- Avoid Python 3.14+ (not supported by dbt yet)

### 2. Warehouse Configuration
- Ensure warehouse exists in Snowflake
- Common names: `COMPUTE_WH`, `DBT_WH`

### 3. Table Name Mismatches
- Verify exact table names in Snowflake
- Update sources.yml accordingly

### 4. Connection Issues
- Check credentials in profiles.yml
- Verify account URL format

## Best Practices Implemented

1. **Modular Design**: Separate staging and mart models
2. **Data Quality**: Comprehensive testing suite
3. **Documentation**: YAML files for metadata
4. **Version Control**: Proper project structure for Git
5. **Environment Management**: Virtual environment for dependencies
