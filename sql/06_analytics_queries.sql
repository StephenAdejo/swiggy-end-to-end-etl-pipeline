/******************************************************************************************
 *  File Name: 06_analytics_queries.sql
 *  Project:   Swiggy End-to-End ETL Pipeline
 *  Purpose:   Business analytics queries and KPI calculations
 *  
 *  Author:    Stephen Adejo
 *  Date:      May 2026
 *  Version:   1.0
 *  
 *  Description:
 *  Contains analytical queries to answer core business questions:
 *    - Monthly and quarterly order trends
 *    - Revenue by city and state
 *    - Top restaurants by volume and rating
 *    - Most ordered dishes and food categories
 *    - Customer rating distribution
 *    - Average spend per order across locations
 *  
 *  Layer:     FACT
 *  Depends:   05_fact_model.sql must complete successfully first
 ******************************************************************************************/

USE swiggy_data;

-- =============================================
-- 1. MONTHLY ORDER TRENDS
-- =============================================

SELECT
    d.year,
    d.month,
    d.month_name,
    COUNT(*)                         AS total_orders,
    ROUND(SUM(f.price_inr), 2)       AS total_revenue_inr,
    ROUND(AVG(f.price_inr), 2)       AS avg_order_value_inr
FROM fact_orders_star f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- =============================================
-- 2. QUARTERLY ORDER TRENDS
-- =============================================

SELECT
    d.year,
    d.quarter_num,
    COUNT(*)                         AS total_orders,
    ROUND(SUM(f.price_inr), 2)       AS total_revenue_inr
FROM fact_orders_star f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter_num
ORDER BY d.year, d.quarter_num;

-- =============================================
-- 3. REVENUE BY CITY
-- =============================================

SELECT
    l.city_name,
    l.state_name,
    COUNT(*)                         AS total_orders,
    ROUND(SUM(f.price_inr), 2)       AS total_revenue_inr,
    ROUND(AVG(f.price_inr), 2)       AS avg_order_value_inr
FROM fact_orders_star f
JOIN dim_location l ON f.location_id = l.location_id
WHERE l.city_name <> 'unknown'
GROUP BY l.city_name, l.state_name
ORDER BY total_revenue_inr DESC
LIMIT 20;

-- =============================================
-- 4. REVENUE BY STATE
-- =============================================

SELECT
    l.state_name,
    COUNT(*)                         AS total_orders,
    ROUND(SUM(f.price_inr), 2)       AS total_revenue_inr
FROM fact_orders_star f
JOIN dim_location l ON f.location_id = l.location_id
WHERE l.state_name <> 'unknown'
GROUP BY l.state_name
ORDER BY total_revenue_inr DESC;

-- =============================================
-- 5. TOP RESTAURANTS BY ORDER VOLUME
-- =============================================

SELECT
    r.restaurant_name,
    COUNT(*)                         AS total_orders,
    ROUND(SUM(f.price_inr), 2)       AS total_revenue_inr,
    ROUND(AVG(f.rating), 2)          AS avg_rating
FROM fact_orders_star f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
WHERE r.restaurant_name <> 'unknown'
GROUP BY r.restaurant_name
ORDER BY total_orders DESC
LIMIT 20;

-- =============================================
-- 6. TOP RESTAURANTS BY AVERAGE RATING
-- =============================================

SELECT
    r.restaurant_name,
    ROUND(AVG(f.rating), 2)          AS avg_rating,
    COUNT(*)                         AS total_orders
FROM fact_orders_star f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
WHERE r.restaurant_name <> 'unknown'
  AND f.rating IS NOT NULL
GROUP BY r.restaurant_name
HAVING total_orders >= 10           -- Minimum order threshold for reliable rating
ORDER BY avg_rating DESC
LIMIT 20;

-- =============================================
-- 7. MOST ORDERED DISHES
-- =============================================

SELECT
    di.dish_name,
    COUNT(*)                         AS total_orders,
    ROUND(AVG(f.price_inr), 2)       AS avg_price_inr
FROM fact_orders_star f
JOIN dim_dish di ON f.dish_id = di.dish_id
WHERE di.dish_name <> 'unknown'
GROUP BY di.dish_name
ORDER BY total_orders DESC
LIMIT 20;

-- =============================================
-- 8. ORDERS AND REVENUE BY FOOD CATEGORY
-- =============================================

SELECT
    c.category_name,
    COUNT(*)                         AS total_orders,
    ROUND(SUM(f.price_inr), 2)       AS total_revenue_inr,
    ROUND(AVG(f.price_inr), 2)       AS avg_price_inr
FROM fact_orders_star f
JOIN dim_category c ON f.category_id = c.category_id
WHERE c.category_name <> 'unknown'
GROUP BY c.category_name
ORDER BY total_orders DESC;

-- =============================================
-- 9. CUSTOMER RATING DISTRIBUTION
-- =============================================

SELECT
    CASE
        WHEN rating >= 4.5 THEN '4.5 - 5.0 (Excellent)'
        WHEN rating >= 4.0 THEN '4.0 - 4.4 (Good)'
        WHEN rating >= 3.0 THEN '3.0 - 3.9 (Average)'
        WHEN rating >= 2.0 THEN '2.0 - 2.9 (Poor)'
        ELSE                     'Below 2.0 (Very Poor)'
    END                          AS rating_band,
    COUNT(*)                     AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM fact_orders_star
WHERE rating IS NOT NULL
GROUP BY rating_band
ORDER BY MIN(rating) DESC;

-- =============================================
-- 10. AVERAGE SPEND PER ORDER BY LOCATION
-- =============================================

SELECT
    l.state_name,
    l.city_name,
    l.location_name,
    COUNT(*)                         AS total_orders,
    ROUND(AVG(f.price_inr), 2)       AS avg_spend_inr
FROM fact_orders_star f
JOIN dim_location l ON f.location_id = l.location_id
WHERE l.location_name <> 'unknown'
GROUP BY l.state_name, l.city_name, l.location_name
ORDER BY avg_spend_inr DESC
LIMIT 30;
