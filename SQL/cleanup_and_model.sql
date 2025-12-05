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
SET ProductSK = t2.ProductSK 
FROM dim_product AS t2 
WHERE StockCode = t2.StockCode 
AND Description = t2.Description;

-- Final Cleanup of Fact Table
ALTER TABLE sales_transactions DROP COLUMN "StockCode";
ALTER TABLE sales_transactions DROP COLUMN "Description";




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
WHERE CustomerID = t2.CustomerID
  AND t1.Country = t2.Country;

-- Final Cleanup of Fact Table
ALTER TABLE sales_transactions DROP COLUMN "CustomerID";
ALTER TABLE sales_transactions DROP COLUMN "Country";








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



