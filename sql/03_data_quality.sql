/******************************************************************************************
 *  File Name: 03_data_quality.sql
 *  Project:   Swiggy End-to-End ETL Pipeline
 *  Purpose:   Perform data quality checks and persist results as a queryable table
 *  
 *  Author:    Stephen Adejo
 *  Date:      May 2026
 *  Version:   1.0
 *  
 *  Description:
 *  Runs 8 DQ checks against the staging layer and stores results in
 *  dq_swiggy_report. Checks include: null counts per column, invalid
 *  ratings, negative prices, future-dated orders, and duplicate records.
 *  Results are persisted so quality metrics are queryable and comparable
 *  across pipeline runs.
 *  
 *  Layer:     STAGING
 *  Next File: 04_deduplication.sql
 ******************************************************************************************/

USE swiggy_data;

-- =============================================
-- DATA QUALITY REPORT (PRODUCTION STANDARD)
-- =============================================

DROP TABLE IF EXISTS dq_swiggy_report;

CREATE TABLE dq_swiggy_report AS
SELECT
    NOW()                                                           AS run_time,
    COUNT(*)                                                        AS total_rows,

    -- Null / empty checks per column
    SUM(state           IS NULL OR state           = '')           AS null_state,
    SUM(city            IS NULL OR city            = '')           AS null_city,
    SUM(location        IS NULL OR location        = '')           AS null_location,
    SUM(restaurant_name IS NULL OR restaurant_name = '')           AS null_restaurant,
    SUM(category        IS NULL OR category        = '')           AS null_category,
    SUM(dish_name       IS NULL OR dish_name       = '')           AS null_dish,
    SUM(price_inr       IS NULL)                                   AS null_price,
    SUM(rating          IS NULL)                                   AS null_rating,
    SUM(rating_count    IS NULL)                                   AS null_rating_count,

    -- Domain validity checks
    SUM(CASE WHEN rating < 1 OR rating > 5 THEN 1 ELSE 0 END)     AS invalid_ratings,
    SUM(price_inr < 0)                                             AS negative_price_records,
    SUM(CASE WHEN order_date > CURRENT_DATE THEN 1 ELSE 0 END)    AS future_dated_orders,

    -- Duplicate detection (composite business key)
    COUNT(*) - COUNT(DISTINCT CONCAT_WS('|',
        state, city, location, restaurant_name,
        category, dish_name, order_date, price_inr
    ))                                                             AS duplicate_records

FROM stg_swiggy_data;

-- =============================================
-- INSPECT DQ RESULTS
-- =============================================

SELECT * FROM dq_swiggy_report;
