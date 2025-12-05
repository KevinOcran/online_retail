
# Project Goal

The primary objective of this project was to transform a messy, raw e-commerce sales file into a clean, normalized, and load-ready dataset optimized for analytic querying. This was achieved using a two-phase pipeline: **Excel** for rapid data validation and initial cleansing, and **PostgreSQL** for robust data transformation and dimensional modeling.

## 🛠️ Tools Used

* **Excel:** Data inspection, initial cleansing, standardization, and partitioning.
* **PostgreSQL:** Data loading, type casting, feature engineering, and dimensional modeling.
* **GitHub:** Version control and final project presentation.

-----

## Phase 1: Data Cleansing and Validation (Excel)

The raw dataset was first loaded into Excel to quickly identify and rectify common data quality issues before database loading.

### Key Excel Steps

1. **Inspection:** Verified 541,910 total records across 8 columns.
2. **Handling Returns:** Rows with non-positive values in the **`Quantity`** and **`UnitPrice`** columns (which represent returns or cancellations) were isolated and moved to a separate sheet (**`ecommerce_returns.csv`**) to avoid skewing sales analysis.
3. **Missing Data:** All rows with missing **`CustomerID`** were removed from both the sales and returns datasets, as customer-level analysis was impossible without a valid ID.
4. **Standardization:** The **`InvoiceDate`** column was standardized and broken down into two new columns: **`InvoiceDateOnly`** and **`InvoiceTimeOnly`** for granular time analysis.

-----

## Phase 2: Dimensional Modeling (PostgreSQL)

The two cleaned CSV files were loaded into two fact tables in PostgreSQL (`sales_transactions` and `returns_transactions`). The final stage focused on structuring the data using a **Star Schema** model to enhance query performance and maintain data integrity.

### Key PostgreSQL Transformation Steps (in `cleanup_and_model.sql`)

#### 1\. Feature Engineering and Cleanup

```sql
-- Calculate SalesAmount (assuming Quantity and UnitPrice are already numeric)
ALTER TABLE sales_transactions ADD COLUMN "SalesAmount" DECIMAL(10, 2);
UPDATE sales_transactions SET "SalesAmount" = "Quantity" * "UnitPrice";

-- Remove unidentified returns (adjust 'N/A' based on your Excel replacement value)
DELETE FROM returns_transactions WHERE "CustomerID" IS NULL OR "CustomerID" = 'N/A';
```

#### 2\. Customer Dimension (`dim_customer`)

```sql
-- Create dimension table with unique CustomerID/Country pairs
CREATE TABLE dim_customer AS
SELECT DISTINCT "CustomerID", "Country"
FROM sales_transactions
WHERE "CustomerID" IS NOT NULL;

-- Add Surrogate Key (PostgreSQL SERIAL type for auto-increment)
ALTER TABLE dim_customer ADD COLUMN "CustomerSK" SERIAL;
ALTER TABLE dim_customer ADD PRIMARY KEY ("CustomerSK");

-- Keep the composite business key as a unique constraint
ALTER TABLE dim_customer ADD UNIQUE ("CustomerID", "Country");

-- Add foreign key column to the fact table
ALTER TABLE sales_transactions ADD COLUMN "CustomerSK" INTEGER;

-- Populate CustomerSK using the PostgreSQL UPDATE...FROM join syntax
UPDATE sales_transactions AS t1
SET "CustomerSK" = t2."CustomerSK"
FROM dim_customer AS t2
WHERE t1."CustomerID" = t2."CustomerID"
  AND t1."Country" = t2."Country";

-- Final Cleanup of Fact Table
ALTER TABLE sales_transactions DROP COLUMN "CustomerID";
ALTER TABLE sales_transactions DROP COLUMN "Country";
```

#### 3\. Product Dimension (`dim_product`)

```sql
-- Create dimension table with unique StockCode/Description pairs
CREATE TABLE dim_product AS
SELECT DISTINCT "StockCode", "Description"
FROM sales_transactions
WHERE "StockCode" IS NOT NULL;

-- Add Surrogate Key (PostgreSQL SERIAL type for auto-increment)
ALTER TABLE dim_product ADD COLUMN "ProductSK" SERIAL;
ALTER TABLE dim_product ADD PRIMARY KEY ("ProductSK");

-- Add foreign key column to the fact table
ALTER TABLE sales_transactions ADD COLUMN "ProductSK" INTEGER;

-- Populate ProductSK using the PostgreSQL UPDATE...FROM join syntax
UPDATE sales_transactions AS t1
SET "ProductSK" = t2."ProductSK"
FROM dim_product AS t2
WHERE t1."StockCode" = t2."StockCode"
  AND t1."Description" = t2."Description";

-- Final Cleanup of Fact Table
ALTER TABLE sales_transactions DROP COLUMN "StockCode";
ALTER TABLE sales_transactions DROP COLUMN "Description";
```

*(Note: These same foreign key population and cleanup steps must also be applied to the `returns_transactions` table.)*

-----

## Final Data Model and Validation

The resulting model is optimized for quick analytical reporting.

### Validation Query (Total Net Revenue by Country)

This query demonstrates the functionality of the Star Schema model by joining the fact tables to the dimension table to calculate **Net Sales** (Sales - Returns) by Country.

```sql
SELECT
    dc.Country,
    SUM(f1."SalesAmount") AS TotalGrossSales,
    COALESCE(SUM(f2."SalesAmount"), 0) AS TotalReturns, -- COALESCE handles NULL if no returns exist
    SUM(f1."SalesAmount") + COALESCE(SUM(f2."SalesAmount"), 0) AS TotalNetRevenue
FROM
    sales_transactions AS f1
JOIN
    dim_customer AS dc ON f1."CustomerSK" = dc."CustomerSK"
LEFT JOIN
    returns_transactions AS f2 ON f1."CustomerSK" = f2."CustomerSK" -- Joining on the shared dimension keys
GROUP BY
    dc.Country
ORDER BY
    TotalNetRevenue DESC;
```

-----

### Repository Files

* **`sales_cleaned_excel.csv`:** The main sales data after Excel cleanup.
* **`returns_cleaned_excel.csv`:** The returns data after Excel cleanup.
* **`cleanup_and_model.sql`:** All PostgreSQL steps used to create and populate the final Star Schema tables.
