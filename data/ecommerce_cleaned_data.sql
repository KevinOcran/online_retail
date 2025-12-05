--Table 1 --

CREATE TABLE positive_trasnactions(
InvoiceNo VARCHAR(50) PRIMARY KEY,
StockCode VARCHAR(50),
Description TEXT,
Quantity INTEGER,
InvoiceDate TIMESTAMP,
UnitPrice DECIMAL(10, 2),
CustomeID VARCHAR(50),
Country VARCHAR(50)
);


-- Table 2--

CREATE TABLE negative_trasnactions(
InvoiceNo VARCHAR(50) PRIMARY KEY,
StockCode VARCHAR(50),
Description TEXT,
Quantity INTEGER,
InvoiceDate TIMESTAMP,
UnitPrice DECIMAL(10, 2),
CustomeID VARCHAR(50),
Country VARCHAR(50)
);