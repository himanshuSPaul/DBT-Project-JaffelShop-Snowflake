--- jaffelshop/models/mart/mart_customers.sql
--- ***********************************************************************
--- Author: himanshu
--- STAGING LAYER: stg_customers (INCREMENTAL)
--- Purpose: Clean and standardize raw customer data    
--- Optimization: Enhanced name parsing with validation
--- Key Features: Handles hyphenated names, data quality indicators
--- ***********************************************************************
--- Change Log:
--- ***********************************************************************
--- v0.1     --- 2026-01-01  : Initial version with basic name parsing
--- v0.2     --- 2026-01-01  : Enhanced name parsing to handle hyphens and added data quality indicators


-- {{ config(
--   meta={
--     'version': 2,
--     'status': 'current',
--     'deprecation_date': None,
--     'description': 'Enhanced name parsing with validation'
--   }
-- ) }}

WITH CUSTOMERS AS (
    SELECT 
        ID as CUSTOMER_ID,
        NAME AS CUSTOMER_NAME
    FROM {{ source('raw', 'raw_customers') }}
)

, PARSED_NAMES AS (
    SELECT  
        CUSTOMER_ID,
        CUSTOMER_NAME,
        LENGTH(CUSTOMER_NAME) as CUSTOMER_NAME_LENGTH,
        -- Robust name parsing that handles hyphens and apostrophes
        SPLIT_PART(REGEXP_REPLACE(CUSTOMER_NAME, '-', ' '), ' ', 1) as FIRST_NAME,
        CASE 
            WHEN ARRAY_SIZE(SPLIT(REGEXP_REPLACE(CUSTOMER_NAME, '-', ' '), ' ')) = 3 
                THEN SPLIT_PART(REGEXP_REPLACE(CUSTOMER_NAME, '-', ' '), ' ', 2)
            ELSE NULL
        END as MIDDLE_NAME,
        SPLIT_PART(REGEXP_REPLACE(CUSTOMER_NAME, '-', ' '), ' ', -1) as LAST_NAME,
        -- Data quality indicators
        CASE 
            WHEN CUSTOMER_ID IS NOT NULL 
                AND CUSTOMER_NAME IS NOT NULL 
                AND LENGTH(CUSTOMER_NAME) > 2
                AND LENGTH(SPLIT_PART(CUSTOMER_NAME, ' ', 1)) > 0
                AND LENGTH(SPLIT_PART(CUSTOMER_NAME, ' ', -1)) > 0
            THEN TRUE
            ELSE FALSE
        END as IS_VALID_NAME,
        CURRENT_TIMESTAMP() as CREATED_AT,
        CURRENT_TIMESTAMP() as UPDATED_AT
    FROM CUSTOMERS
)

SELECT  
    CUSTOMER_ID,
    CUSTOMER_NAME,
    FIRST_NAME,
    MIDDLE_NAME,
    LAST_NAME,
    CUSTOMER_NAME_LENGTH,
    IS_VALID_NAME,
    CREATED_AT,
    UPDATED_AT
FROM PARSED_NAMES
WHERE CUSTOMER_ID IS NOT NULL