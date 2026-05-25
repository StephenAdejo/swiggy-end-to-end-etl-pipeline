/******************************************************************************************
 *  File Name: 01_raw_inspection.sql
 *  Project:   Swiggy End-to-End ETL Pipeline
 *  Purpose:   Initial raw data inspection, profiling, and basic exploration
 *  
 *  Author:    Stephen Adejo
 *  Date:      May 2026
 *  Version:   1.0
 *  
 *  Description:
 *  This script explores the raw Swiggy dataset to understand structure, 
 *  data types, row count, and identify initial data quality issues.
 *  
 *  Layer:     RAW
 *  Next File: 02_staging_etl.sql
 ******************************************************************************************/
-- =============================================
-- 1. USE DATABASE
-- =============================================
USE swiggy_data;

-- =============================================
-- 2. RAW INSPECTION (OPTIONAL)
-- =============================================
SELECT * FROM swiggy_data;
DESCRIBE swiggy_data;
