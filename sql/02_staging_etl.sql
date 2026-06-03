/******************************************************************************************
 *  File Name: 02_staging_etl.sql
 *  Project:   Swiggy End-to-End ETL Pipeline
 *  Purpose:   Transform raw data into staging layer with cleaning and standardisation
 *  
 *  Author:    Stephen Adejo
 *  Date:      May 2026
 *  Version:   1.0
 *  
 *  Description:
 *  Creates the ETL job log table, staging table with data type casting,
 *  LOWER/TRIM standardisation, NULL handling, and date formatting.
 *  Logs ETL start and loads cleaned data from raw into staging.
 *  
 *  Layer:     RAW → STAGING
 *  Next File: 03_data_quality.sql
 ******************************************************************************************/

USE swiggy_data;

-- =============================================
-- ETL JOB LOG TABLE
-- =============================================

DROP TABLE IF EXISTS etl_job_log;

CREATE TABLE etl_job_log (
    job_id        INT AUTO_INCREMENT PRIMARY KEY,
    job_name      VARCHAR(100) NOT NULL,
    start_time    TIMESTAMP NOT NULL,
    end_time      TIMESTAMP NULL,
    rows_loaded   INT,
    job_status    VARCHAR(50),
    error_message TEXT
);

-- =============================================
-- LOG ETL START
-- =============================================

INSERT INTO etl_job_log (job_name, start_time, job_status)
VALUES ('swiggy_etl_pipeline', NOW(), 'STARTED');

-- =============================================
-- STAGING TABLE (CLEAN + STANDARDIZED)
-- =============================================

DROP TABLE IF EXISTS stg_swiggy_data;

CREATE TABLE stg_swiggy_data (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    state           VARCHAR(100),
    city            VARCHAR(100),
    location        VARCHAR(255),
    restaurant_name VARCHAR(255),
    category        VARCHAR(150),
    dish_name       VARCHAR(255),
    order_date      DATE,
    price_inr       DECIMAL(10,2),
    rating          DECIMAL(3,2),
    rating_count    INT,
    loaded_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_city_location (city, location),
    INDEX idx_restaurant    (restaurant_name),
    INDEX idx_date          (order_date)

) ENGINE=InnoDB;

-- =============================================
-- LOAD + CLEAN RAW → STAGING
-- =============================================

TRUNCATE TABLE stg_swiggy_data;

INSERT INTO stg_swiggy_data (
    state, city, location, restaurant_name,
    category, dish_name, order_date,
    price_inr, rating, rating_count
)
SELECT
    NULLIF(LOWER(TRIM(state)),           '')    AS state,
    NULLIF(LOWER(TRIM(city)),            '')    AS city,
    NULLIF(LOWER(TRIM(location)),        '')    AS location,
    NULLIF(LOWER(TRIM(restaurant_name)), '')    AS restaurant_name,
    NULLIF(LOWER(TRIM(category)),        '')    AS category,
    NULLIF(LOWER(TRIM(dish_name)),       '')    AS dish_name,

    STR_TO_DATE(TRIM(order_date), '%d/%m/%Y')  AS order_date,

    CAST(NULLIF(TRIM(price_inr),    '') AS DECIMAL(10,2))  AS price_inr,
    CAST(NULLIF(TRIM(rating),       '') AS DECIMAL(3,2))   AS rating,
    CAST(NULLIF(TRIM(rating_count), '') AS SIGNED)         AS rating_count

FROM swiggy_data
WHERE STR_TO_DATE(TRIM(order_date), '%d/%m/%Y') IS NOT NULL;

-- =============================================
-- QUICK VALIDATION
-- =============================================

SELECT COUNT(*) AS staging_rows FROM stg_swiggy_data;
