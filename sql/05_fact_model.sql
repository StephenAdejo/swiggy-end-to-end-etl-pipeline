/******************************************************************************************
 *  File Name: 05_fact_model.sql
 *  Project:   Swiggy End-to-End ETL Pipeline
 *  Purpose:   Build analytics-ready flat fact table and full star schema
 *  
 *  Author:    Stephen Adejo
 *  Date:      May 2026
 *  Version:   1.0
 *  
 *  Description:
 *  Creates the intermediate flat fact table (fact_swiggy_flat), then builds
 *  the full star schema: five dimension tables (dim_date, dim_location,
 *  dim_restaurant, dim_category, dim_dish) and the grain-level fact table
 *  (fact_orders_star). Unknown sentinel records are inserted into every
 *  dimension to preserve referential integrity when source data is incomplete.
 *  Ends with referential integrity validation and ETL job log update.
 *  
 *  Grain:     One row = one ordered dish at a restaurant, at a location, on a date
 *  Layer:     CLEAN → FACT → STAR SCHEMA
 *  Next File: 06_analytics_queries.sql
 ******************************************************************************************/

USE swiggy_data;

-- =============================================
-- INTERMEDIATE FLAT FACT TABLE
-- =============================================

DROP TABLE IF EXISTS fact_swiggy_flat;

CREATE TABLE fact_swiggy_flat AS
SELECT
    state, city, location, restaurant_name,
    category, dish_name, order_date,
    price_inr, rating, rating_count
FROM clean_swiggy_data;

-- =============================================
-- DROP & RECREATE STAR SCHEMA TABLES
-- =============================================

DROP TABLE IF EXISTS fact_orders_star;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_location;
DROP TABLE IF EXISTS dim_restaurant;
DROP TABLE IF EXISTS dim_category;
DROP TABLE IF EXISTS dim_dish;

-- =============================================
-- DIMENSION: Date
-- =============================================

CREATE TABLE dim_date (
    date_id    INT AUTO_INCREMENT PRIMARY KEY,
    full_date  DATE        NOT NULL,
    year       INT         NOT NULL,
    month      INT         NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter_num INT        NOT NULL,
    day_num    INT         NOT NULL,
    week_num   INT         NOT NULL,

    UNIQUE KEY uk_full_date (full_date)
);

-- =============================================
-- DIMENSION: Location
-- =============================================

CREATE TABLE dim_location (
    location_id   INT AUTO_INCREMENT PRIMARY KEY,
    state_name    VARCHAR(100) NOT NULL,
    city_name     VARCHAR(100) NOT NULL,
    location_name VARCHAR(200) NOT NULL,

    UNIQUE KEY uk_location (state_name, city_name, location_name)
) ENGINE=InnoDB;

-- =============================================
-- DIMENSION: Restaurant
-- =============================================

CREATE TABLE dim_restaurant (
    restaurant_id   INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_name VARCHAR(255) NOT NULL UNIQUE
);

-- =============================================
-- DIMENSION: Category
-- =============================================

CREATE TABLE dim_category (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL UNIQUE
);

-- =============================================
-- DIMENSION: Dish
-- =============================================

CREATE TABLE dim_dish (
    dish_id   INT AUTO_INCREMENT PRIMARY KEY,
    dish_name VARCHAR(255) NOT NULL UNIQUE
);

-- =============================================
-- FACT TABLE
-- =============================================
-- GRAIN: One row = one ordered dish
--        for a restaurant at a location on a specific date.

CREATE TABLE fact_orders_star (
    order_id      INT AUTO_INCREMENT PRIMARY KEY,

    date_id       INT NOT NULL,
    location_id   INT NOT NULL,
    restaurant_id INT NOT NULL,
    category_id   INT NOT NULL,
    dish_id       INT NOT NULL,

    price_inr     DECIMAL(10,2) NOT NULL,
    rating        DECIMAL(3,2),
    rating_count  INT,

    etl_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    batch_id      VARCHAR(100),
    source_system VARCHAR(100),

    FOREIGN KEY (date_id)       REFERENCES dim_date(date_id),
    FOREIGN KEY (location_id)   REFERENCES dim_location(location_id),
    FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
    FOREIGN KEY (category_id)   REFERENCES dim_category(category_id),
    FOREIGN KEY (dish_id)       REFERENCES dim_dish(dish_id),

    INDEX idx_date_id       (date_id),
    INDEX idx_location_id   (location_id),
    INDEX idx_restaurant_id (restaurant_id),
    INDEX idx_category_id   (category_id),
    INDEX idx_dish_id       (dish_id),
    INDEX idx_sales_analysis (date_id, restaurant_id, category_id)

) ENGINE=InnoDB;

-- =============================================
-- TRUNCATE ALL (SAFE RE-RUN)
-- =============================================

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE fact_orders_star;
TRUNCATE TABLE dim_date;
TRUNCATE TABLE dim_location;
TRUNCATE TABLE dim_restaurant;
TRUNCATE TABLE dim_category;
TRUNCATE TABLE dim_dish;
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================
-- POPULATE: dim_date
-- =============================================

INSERT INTO dim_date (full_date, year, month, month_name, quarter_num, day_num, week_num)
SELECT DISTINCT
    order_date,
    YEAR(order_date),
    MONTH(order_date),
    MONTHNAME(order_date),
    QUARTER(order_date),
    DAY(order_date),
    WEEK(order_date, 1)    -- Monday as first day
FROM fact_swiggy_flat
WHERE order_date IS NOT NULL;

-- =============================================
-- POPULATE: dim_location
-- =============================================

-- Unknown sentinel (id=1, fallback for missing data)
INSERT INTO dim_location (state_name, city_name, location_name)
VALUES ('unknown', 'unknown', 'unknown');

INSERT INTO dim_location (state_name, city_name, location_name)
SELECT DISTINCT state, city, location
FROM fact_swiggy_flat
WHERE state IS NOT NULL AND city IS NOT NULL AND location IS NOT NULL;

-- =============================================
-- POPULATE: dim_restaurant
-- =============================================

INSERT INTO dim_restaurant (restaurant_name) VALUES ('unknown');

INSERT INTO dim_restaurant (restaurant_name)
SELECT DISTINCT restaurant_name
FROM fact_swiggy_flat
WHERE restaurant_name IS NOT NULL;

-- =============================================
-- POPULATE: dim_category
-- =============================================

INSERT INTO dim_category (category_name) VALUES ('unknown');

INSERT INTO dim_category (category_name)
SELECT DISTINCT category
FROM fact_swiggy_flat
WHERE category IS NOT NULL;

-- =============================================
-- POPULATE: dim_dish
-- =============================================

INSERT INTO dim_dish (dish_name) VALUES ('unknown');

INSERT INTO dim_dish (dish_name)
SELECT DISTINCT dish_name
FROM fact_swiggy_flat
WHERE dish_name IS NOT NULL;

-- =============================================
-- POPULATE: fact_orders_star
-- =============================================

INSERT INTO fact_orders_star (
    date_id, location_id, restaurant_id,
    category_id, dish_id,
    price_inr, rating, rating_count
)
SELECT
    d.date_id,
    COALESCE(l.location_id,   1)  AS location_id,
    COALESCE(r.restaurant_id, 1)  AS restaurant_id,
    COALESCE(c.category_id,   1)  AS category_id,
    COALESCE(di.dish_id,      1)  AS dish_id,

    CAST(sf.price_inr AS DECIMAL(10,2))  AS price_inr,
    CAST(sf.rating    AS DECIMAL(3,2))   AS rating,
    sf.rating_count

FROM fact_swiggy_flat sf

JOIN dim_date d
    ON sf.order_date = d.full_date

LEFT JOIN dim_location l
    ON  sf.state    = l.state_name
    AND sf.city     = l.city_name
    AND sf.location = l.location_name

LEFT JOIN dim_restaurant r
    ON sf.restaurant_name = r.restaurant_name

LEFT JOIN dim_category c
    ON sf.category = c.category_name

LEFT JOIN dim_dish di
    ON sf.dish_name = di.dish_name

WHERE sf.price_inr IS NOT NULL;

-- =============================================
-- QUICK DIM INSPECTION
-- =============================================

SELECT * FROM dim_date        LIMIT 10;
SELECT * FROM dim_location    LIMIT 10;
SELECT * FROM dim_restaurant  LIMIT 10;
SELECT * FROM dim_category    LIMIT 10;
SELECT * FROM dim_dish        LIMIT 10;

-- =============================================
-- ROW COUNT VALIDATION
-- =============================================

SELECT COUNT(*) AS clean_rows     FROM clean_swiggy_data;
SELECT COUNT(*) AS flat_fact_rows FROM fact_swiggy_flat;
SELECT COUNT(*) AS star_fact_rows FROM fact_orders_star;

-- =============================================
-- UNKNOWN DIMENSION MONITORING
-- =============================================

SELECT COUNT(*) AS unknown_location_records   FROM fact_orders_star WHERE location_id   = 1;
SELECT COUNT(*) AS unknown_restaurant_records FROM fact_orders_star WHERE restaurant_id = 1;
SELECT COUNT(*) AS unknown_category_records   FROM fact_orders_star WHERE category_id   = 1;
SELECT COUNT(*) AS unknown_dish_records       FROM fact_orders_star WHERE dish_id       = 1;

-- =============================================
-- REFERENTIAL INTEGRITY VALIDATION
-- =============================================

-- Any fact rows with no matching date?
SELECT * FROM fact_orders_star fo
LEFT JOIN dim_date d ON fo.date_id = d.date_id
WHERE d.date_id IS NULL;

-- Any fact rows with no matching location?
SELECT * FROM fact_orders_star fo
LEFT JOIN dim_location l ON fo.location_id = l.location_id
WHERE l.location_id IS NULL;

-- Any fact rows with no matching restaurant?
SELECT * FROM fact_orders_star fo
LEFT JOIN dim_restaurant r ON fo.restaurant_id = r.restaurant_id
WHERE r.restaurant_id IS NULL;

-- Any fact rows with no matching category?
SELECT * FROM fact_orders_star fo
LEFT JOIN dim_category c ON fo.category_id = c.category_id
WHERE c.category_id IS NULL;

-- Any fact rows with no matching dish?
SELECT * FROM fact_orders_star fo
LEFT JOIN dim_dish di ON fo.dish_id = di.dish_id
WHERE di.dish_id IS NULL;

-- =============================================
-- DUPLICATE DIMENSION KEY CHECKS
-- =============================================

SELECT state_name, city_name, location_name, COUNT(*)
FROM dim_location
GROUP BY state_name, city_name, location_name
HAVING COUNT(*) > 1;

SELECT restaurant_name, COUNT(*)
FROM dim_restaurant
GROUP BY restaurant_name
HAVING COUNT(*) > 1;

SELECT category_name, COUNT(*)
FROM dim_category
GROUP BY category_name
HAVING COUNT(*) > 1;

SELECT dish_name, COUNT(*)
FROM dim_dish
GROUP BY dish_name
HAVING COUNT(*) > 1;

-- =============================================
-- LOG ETL SUCCESS
-- =============================================

UPDATE etl_job_log
SET
    end_time    = NOW(),
    rows_loaded = (SELECT COUNT(*) FROM fact_orders_star),
    job_status  = 'SUCCESS'
WHERE job_id = (SELECT MAX(job_id) FROM etl_job_log);

SELECT * FROM etl_job_log;
