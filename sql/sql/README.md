# SQL Pipeline Scripts

This folder contains all the SQL scripts for the **Swiggy End-to-End ETL Pipeline**.

## 📋 Execution Order

| Order | Script Name                  | Purpose                                      | Layer              |
|-------|-----------------------------|----------------------------------------------|--------------------|
| 1     | `01_raw_inspection.sql`     | Raw data exploration & profiling             | RAW                |
| 2     | `02_staging_etl.sql`        | Data cleaning and standardization            | RAW → STAGING      |
| 3     | `03_data_quality.sql`       | Data quality checks and validation           | STAGING            |
| 4     | `04_deduplication.sql`      | Deduplication using window functions         | STAGING → CLEAN    |
| 5     | `05_fact_model.sql`         | Build analytics-ready fact table             | CLEAN → FACT       |
| 6     | `06_analytics_queries.sql`  | Business questions and KPI calculations      | FACT               |

## 🛠️ How to Execute

1. Run the scripts **in order** (1 to 6)
2. Use **MySQL Workbench** or any MySQL client
3. Each script creates or populates tables for the next layer

## 📌 Design Principles

- **Layered Architecture**: Raw → Staging → Clean → Fact
- Modular and reusable scripts
- Strong focus on data quality and deduplication
- Clear documentation and professional headers in every file
- Built to evolve into a full star schema

## 🔍 Key Learnings Applied

- Proper handling of join explosion
- Deterministic deduplication with `ROW_NUMBER()`
- Standardization best practices (`LOWER`, `TRIM`, `NULLIF`)
- Grain definition for fact tables

---

**Author**: Stephen Adejo  
**Project**: Swiggy End-to-End ETL Pipeline
