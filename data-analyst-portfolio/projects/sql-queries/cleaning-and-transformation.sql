-- =============================================
-- 1. JOIN DATA DARI MULTIPLE TABLES
-- =============================================

-- Gabungkan data orders dengan customer information
SELECT 
    db1.`Order Date`, 
    db1.`Customer ID`, 
    db1.`Product ID`,
    db1.Quantity,
    db2.`Customer Name`,
    db2.Email,
    db2.Country
FROM raw_data db1
JOIN customers db2 ON db1.`Customer ID` = db2.`Customer ID`;

-- =============================================
-- 2. BUAT STAGING TABLE DENGAN JOIN LENGKAP
-- =============================================

WITH staging_data AS (
    SELECT 
        db1.`Order Date`, 
        db1.`Customer ID`, 
        db1.`Product ID`,
        db1.Quantity,
        db2.`Customer Name`,
        db2.Email,
        db2.Country
    FROM raw_data db1
    JOIN customers db2 ON db1.`Customer ID` = db2.`Customer ID`
)
SELECT 
    tb1.*, 
    tb2.`Coffee Type`, 
    tb2.`Roast Type`, 
    tb2.`Size`, 
    tb2.`Unit Price`
FROM staging_data tb1
JOIN products tb2 ON tb1.`Product ID` = tb2.`Product ID`;

-- =============================================
-- 3. CREATE MAIN EDITED_DATA TABLE
-- =============================================

CREATE TABLE edited_data AS
WITH staging_data AS (
    SELECT 
        db1.`Order Date`, 
        db1.`Customer ID`, 
        db1.`Product ID`,
        db1.Quantity,
        db2.`Customer Name`,
        db2.Email,
        db2.Country
    FROM raw_data db1
    JOIN customers db2 ON db1.`Customer ID` = db2.`Customer ID`
)
SELECT 
    tb1.*, 
    tb2.`Coffee Type`, 
    tb2.`Roast Type`, 
    tb2.`Size`, 
    tb2.`Unit Price`
FROM staging_data tb1
JOIN products tb2 ON tb1.`Product ID` = tb2.`Product ID`;

-- =============================================
-- 4. CHECK PRODUCTS TABLE
-- =============================================

SELECT * FROM products;

-- =============================================
-- 5. IDENTIFIKASI DUPLICATES DENGAN ROW_NUMBER
-- =============================================

SELECT *, ROW_NUMBER() OVER(ORDER BY `Customer Name`)
FROM raw_data;

-- =============================================
-- 6. CREATE DEDUPLICATED TABLE
-- =============================================

CREATE TABLE edited_data2 AS
WITH edited_cte AS (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY `Order Date`, `Customer ID`, `Product ID`, `Quantity`
        ) AS row_num
    FROM edited_data
)
SELECT * FROM edited_cte;

-- =============================================
-- 7. STANDARDIZE DATE FORMAT
-- =============================================

-- Perbaiki format tahun dan konversi ke DATE type
UPDATE edited_data
SET `Order Date` = CONCAT(LEFT(`Order Date`, 6), "20", RIGHT(`Order Date`, 2));

UPDATE edited_data
SET `Order Date` = STR_TO_DATE(`Order Date`, "%d-%m-%Y");

-- Ubah tipe data kolom tanggal
ALTER TABLE edited_data
MODIFY COLUMN `Order Date` DATE;

-- =============================================
-- 8. VERIFIKASI DUPLICATES
-- =============================================

SELECT * FROM edited_data2 WHERE row_num > 1;

-- =============================================
-- 9. ANALISIS DATA CUSTOMER
-- =============================================

SELECT * FROM edited_data;

SELECT 
    `Customer Name`, 
    COUNT(`Customer Name`) as times
FROM edited_data
GROUP BY `Customer Name`
ORDER BY times DESC;

-- =============================================
-- 10. POPULATE MISSING EMAILS
-- =============================================

-- Cari email yang bisa di-populate dari records dengan nama yang sama
SELECT 
    tb1.Email,
    tb2.Email
FROM edited_data tb1
JOIN edited_data tb2 ON tb1.`Customer Name` = tb2.`Customer Name`
WHERE tb1.Email = ""
AND (tb2.Email IS NOT NULL AND tb2.Email != "");
