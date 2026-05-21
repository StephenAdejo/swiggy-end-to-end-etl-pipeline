/******************************************************************************************
 *  File Name: 04_deduplication.sql
 *  Project:   Swiggy End-to-End ETL Pipeline
 *  Purpose:   Deduplicate records using window functions
 *  
 *  Author:    Stephen Adejo
 *  Date:      May 2026
 *  Version:   1.0
 *  
 *  Description:
 *  Implements deterministic deduplication strategy using ROW_NUMBER() 
 *  to handle join explosion and duplicate records.
 *  
 *  Layer:     STAGING → CLEAN
 *  Next File: 05_fact_model.sql
 ******************************************************************************************/
