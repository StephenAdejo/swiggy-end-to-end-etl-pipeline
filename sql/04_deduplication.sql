/******************************************************************************************
 *  File Name: 04_deduplication.sql
 *  Project:   Swiggy End-to-End ETL Pipeline
 *  Purpose:   Deduplicate staging records using window functions
 *  
 *  Author:    Stephen Adejo
 *  Date:      May 2026
 *  Version:   1.0
 *  
 *  Description:
 *  Implements deterministic, non-destructive deduplication using ROW_NUMBER()
 *  partitioned on the full business key. The latest record (highest id) is
 *  kept; duplicates are excluded — not deleted — preserving a full audit
 *  trail in the staging layer.
 *  
 *  Layer:     STAGING → CLEAN
 *  Next File: 05_fact_model.sql
 ******************************************************************************************/

USE swiggy_data;

-- =============================================
-- DEDUPLICATION LAYER (SAFE — NO DELETE)
-- =============================================

DROP TABLE IF EXISTS clean_swiggy_data;

CREATE TABLE clean_swiggy_data AS
SELECT
    id, state, city, location, restaurant_name,
    category, dish_name, order_date,
    price_inr, rating, rating_count, loaded_at
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY
                state, city, location,
                restaurant_name, category,
                dish_name, order_date,
                price_inr, rating, rating_count
            ORDER BY id DESC    -- Keep latest record
        ) AS rn
    FROM stg_swiggy_data
) t
WHERE rn = 1;

-- =============================================
-- QUICK VALIDATION
-- =============================================

SELECT COUNT(*) AS staging_rows FROM stg_swiggy_data;
SELECT COUNT(*) AS clean_rows   FROM clean_swiggy_data;
