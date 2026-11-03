-- =====================================================================
-- Amazon Products: Data Cleaning (MySQL 8.0)
-- Raw data : amazon.csv (1,465 rows, 16 columns)
-- Output   : amazon_final (1,351 unique products, correct data types)
-- No window functions are used anywhere in this project.
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 1: Create the database and a raw table
-- Everything is loaded as text first. Prices like "₹1,099" and values
-- like "64%" would fail to load into numeric columns.
-- ---------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS amazon;
USE amazon;

DROP TABLE IF EXISTS amazon;
CREATE TABLE amazon (
    product_id          VARCHAR(20),
    product_name        TEXT,
    category            TEXT,
    discounted_price    VARCHAR(20),
    actual_price        VARCHAR(20),
    discount_percentage VARCHAR(10),
    rating              VARCHAR(10),
    rating_count        VARCHAR(20),
    about_product       TEXT,
    user_id             TEXT,
    user_name           TEXT,
    review_id           TEXT,
    review_title        TEXT,
    review_content      MEDIUMTEXT,
    img_link            TEXT,
    product_link        TEXT
) CHARACTER SET utf8mb4;


-- ---------------------------------------------------------------------
-- STEP 2: Load the CSV into the raw table
-- Change the path to where amazon.csv is on YOUR computer.
-- Use forward slashes (/), even on Windows.
-- If you get Error 2068, run this first (as root):
--     SET GLOBAL local_infile = 1;
-- and add OPT_LOCAL_INFILE=1 in Workbench:
--     Database > Manage Connections > Advanced > Others
-- then reconnect.
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'D:/DOWNLOADS/archive (1)/amazon.csv'
INTO TABLE amazon
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Check: expect 1465
SELECT COUNT(*) AS rows_loaded FROM amazon;


-- ---------------------------------------------------------------------
-- STEP 3: Back up the raw data
-- Never clean your only copy of the data.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS amazon_raw;
CREATE TABLE amazon_raw AS SELECT * FROM amazon;

-- Check: expect 1465
SELECT COUNT(*) AS backup_rows FROM amazon_raw;


-- ---------------------------------------------------------------------
-- STEP 4: Profile the data (look for problems, change nothing)
-- ---------------------------------------------------------------------

-- 4a. Ratings that are not numbers (expect 1 row, the value "|")
SELECT product_id, rating
FROM amazon
WHERE rating NOT REGEXP '^[0-9.]+$';

-- 4b. Blank rating counts (expect 2 rows)
SELECT product_id, rating_count
FROM amazon
WHERE rating_count = '' OR rating_count IS NULL;

-- 4c. Duplicate product IDs (these rows add up to 114 extra rows)
SELECT product_id, COUNT(*) AS times
FROM amazon
GROUP BY product_id
HAVING COUNT(*) > 1;

-- 4d. Rows vs unique products (expect 1465 vs 1351)
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT product_id) AS unique_products
FROM amazon;


-- ---------------------------------------------------------------------
-- STEP 5: Create amazon_clean
--  * Prices      : remove everything except digits and dots, then
--                  convert to DECIMAL   (₹1,099 -> 1099.00)
--  * Discount    : remove the % sign    (64%    -> 64.00)
--  * Rating      : the invalid "|" becomes NULL
--  * Rating count: remove commas, blanks become NULL
--  * Category    : split into main category and subcategory
--  Unneeded columns (descriptions, links, reviews) are left out.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS amazon_clean;
CREATE TABLE amazon_clean AS
SELECT
    product_id,
    product_name,
    CAST(REGEXP_REPLACE(discounted_price, '[^0-9.]', '') AS DECIMAL(10,2)) AS clean_price,
    CAST(REGEXP_REPLACE(actual_price, '[^0-9.]', '')     AS DECIMAL(10,2)) AS clean_actual_price,
    CAST(REPLACE(discount_percentage, '%', '')           AS DECIMAL(5,2))  AS clean_discount_percentage,
    CAST(NULLIF(rating, '|')                             AS DECIMAL(3,1))  AS clean_rating,
    CAST(NULLIF(REPLACE(rating_count, ',', ''), '')      AS UNSIGNED)      AS clean_rating_count,
    SUBSTRING_INDEX(category, '|', 1)                                      AS main_category,
    SUBSTRING_INDEX(SUBSTRING_INDEX(category, '|', 2), '|', -1)            AS subcategory
FROM amazon;

-- Check: expect 1465 rows, and decimal types for the price columns
SELECT COUNT(*) AS clean_rows FROM amazon_clean;
DESCRIBE amazon_clean;


-- ---------------------------------------------------------------------
-- STEP 6: Remove duplicates -> amazon_final
-- GROUP BY product_id merges rows with the same product into one row.
-- MAX() just picks one value per column. Duplicates carry the same
-- values (rating_count can differ by a few), so MAX keeps the largest.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS amazon_final;
CREATE TABLE amazon_final AS
SELECT
    product_id,
    MAX(product_name)               AS product_name,
    MAX(clean_price)                AS clean_price,
    MAX(clean_actual_price)         AS clean_actual_price,
    MAX(clean_discount_percentage)  AS clean_discount_percentage,
    MAX(clean_rating)               AS clean_rating,
    MAX(clean_rating_count)         AS clean_rating_count,
    MAX(main_category)              AS main_category,
    MAX(subcategory)                AS subcategory
FROM amazon_clean
GROUP BY product_id;


-- ---------------------------------------------------------------------
-- STEP 7: Final quality check
-- Expected: 1351 | 1351 | 1 | 2 | 39.00 | 77990.00
-- ---------------------------------------------------------------------
SELECT
    COUNT(*)                         AS total_rows,
    COUNT(DISTINCT product_id)       AS unique_products,
    SUM(clean_rating IS NULL)        AS missing_ratings,
    SUM(clean_rating_count IS NULL)  AS missing_rating_counts,
    MIN(clean_price)                 AS min_price,
    MAX(clean_price)                 AS max_price
FROM amazon_final;
