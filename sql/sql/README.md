# SQL Pipeline Scripts

This folder contains all the SQL scripts for the **Swiggy End-to-End ETL Pipeline**.

The pipeline is designed using a **layered data architecture (RAW → STAGING → CLEAN → FACT)** and follows analytics engineering best practices for building reliable and scalable data models.

---

## 📋 Execution Order

| Order | Script Name                  | Purpose                                      | Layer              |
|-------|-----------------------------|----------------------------------------------|--------------------|
| 1     | `01_raw_inspection.sql`     | Raw data profiling and schema exploration    | RAW                |
| 2     | `02_staging_etl.sql`        | Data cleaning and standardization            | RAW → STAGING      |
| 3     | `03_data_quality.sql`       | Data validation and integrity checks         | STAGING            |
| 4     | `04_deduplication.sql`      | Remove duplicates using window functions     | STAGING → CLEAN    |
| 5     | `05_fact_model.sql`         | Build analytics-ready star schema fact table | CLEAN → FACT       |
| 6     | `06_analytics_queries.sql`  | Business KPIs and analytical insights        | FACT               |

---

## 🛠️ How to Execute

1. Run the scripts **strictly in order (1 → 6)** to maintain data integrity across layers  
2. Use **MySQL 8+ / MySQL Workbench** or any compatible SQL client  
3. Ensure each layer completes successfully before moving to the next stage  
4. Validate outputs using row counts and null checks at each step  

---

## 📌 Design Principles

- **Layered Architecture**: Clear separation of RAW → STAGING → CLEAN → FACT  
- **Modular SQL Design**: Each script is independent and reusable  
- **Data Quality First**: Strong validation, cleaning, and consistency checks  
- **Deterministic Processing**: Reproducible transformations using window functions  
- **Star Schema Ready**: Fact table designed for analytical workloads  

---

## 🔍 Key Learnings Applied

- Handling and preventing **join explosion in transformations**  
- Using `ROW_NUMBER()` for deterministic deduplication  
- Standardizing data using `LOWER()`, `TRIM()`, `NULLIF()`  
- Defining correct **data grain for fact table design**  
- Structuring SQL like a real-world analytics engineering pipeline  

---

## 🚀 Outcome

This pipeline produces a clean, analytics-ready dataset that supports:
- Revenue and order trend analysis  
- Restaurant and city performance tracking  
- Category-level insights  
- KPI dashboards and reporting layers  

---

**Author**: Stephen Adejo  
**Project**: Swiggy End-to-End ETL Pipeline  
**Domain**: Data Analytics / Analytics Engineering  
