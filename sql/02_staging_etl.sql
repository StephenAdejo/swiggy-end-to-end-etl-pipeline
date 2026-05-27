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
 *  Creates staging tables with data type casting, LOWER/TRIM standardisation,
 *  NULL handling, and date formatting.
 *  
 *  Layer:     RAW → STAGING
 *  Next File: 03_data_quality.sql
 ******************************************************************************************/
-- =============================================
-- ETL JOB LOG TABLE
-- =============================================

DROP TABLE IF EXISTS etl_job_log;

CREATE TABLE etl_job_log (

    job_id INT AUTO_INCREMENT PRIMARY KEY,

    job_name VARCHAR(100) NOT NULL,

    start_time TIMESTAMP NOT NULL,

    end_time TIMESTAMP NULL,

    rows_loaded INT,

    job_status VARCHAR(50),

    error_message TEXT
);


-- =============================================
--  RAW INSPECTION (OPTIONAL)
-- =============================================
SELECT 
    *
FROM
    swiggy_data
    LIMIT 50;
    
DESCRIBE swiggy_data;

-- =============================================
-- STAGING TABLE (CLEAN + STANDARDIZED)
-- =============================================
DROP TABLE IF EXISTS stg_swiggy_data;

CREATE TABLE stg_swiggy_data (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    state             VARCHAR(100),
    city              VARCHAR(100),
    location          VARCHAR(255),
    restaurant_name   VARCHAR(255),
    category          VARCHAR(150),
    dish_name         VARCHAR(255),
    order_date        DATE,
    price_inr         DECIMAL(10,2) ,
    rating            DECIMAL(3,2),
    rating_count      INT,
    loaded_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_city_location (city, location),
    INDEX idx_restaurant (restaurant_name),
    INDEX idx_date (order_date)
    
) ENGINE=InnoDB;

-- =============================================
-- LOG ETL START
-- =============================================

INSERT INTO etl_job_log (
    job_name,
    start_time,
    job_status
)
VALUES (
    'swiggy_etl_pipeline',
    NOW(),
    'STARTED'
);

