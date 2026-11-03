-- =====================================================================
-- Amazon Products: Analysis Queries (MySQL 8.0)
-- Run 01_data_cleaning.sql first. All queries use the amazon_final table.
-- No window functions are used.
-- =====================================================================
USE amazon;


-- Q1. How many products are in each main category?
SELECT main_category, COUNT(*) AS total_products
FROM amazon_final
GROUP BY main_category
ORDER BY total_products DESC;


-- Q2. Which main categories give the biggest average discount?
-- (Categories with fewer than 30 products are skipped. Their averages
--  are not reliable.)
SELECT main_category,
       COUNT(*)                                   AS total_products,
       ROUND(AVG(clean_discount_percentage), 1)   AS avg_discount_pct
FROM amazon_final
GROUP BY main_category
HAVING COUNT(*) >= 30
ORDER BY avg_discount_pct DESC;


-- Q3. Average price and rating by main category
SELECT main_category,
       ROUND(AVG(clean_price), 0)   AS avg_price,
       ROUND(AVG(clean_rating), 2)  AS avg_rating
FROM amazon_final
GROUP BY main_category
HAVING COUNT(*) >= 30
ORDER BY avg_price DESC;


-- Q4. Top 10 subcategories by number of products
SELECT subcategory, COUNT(*) AS total_products
FROM amazon_final
GROUP BY subcategory
ORDER BY total_products DESC
LIMIT 10;


-- Q5. Top 10 most-reviewed products
-- (Some variants of the same item share one rating count, so ties are
--  possible.)
SELECT product_id, product_name, clean_rating_count, clean_rating
FROM amazon_final
ORDER BY clean_rating_count DESC
LIMIT 10;


-- Q6. Top 10 highest-rated products with at least 1,000 ratings
-- (The 1,000 minimum stops a product with 3 reviews from winning.)
SELECT product_id, product_name, clean_rating, clean_rating_count
FROM amazon_final
WHERE clean_rating_count >= 1000
ORDER BY clean_rating DESC, clean_rating_count DESC
LIMIT 10;


-- Q7. Top 10 biggest savings in rupees
SELECT product_id, product_name,
       clean_actual_price,
       clean_price,
       (clean_actual_price - clean_price) AS amount_saved
FROM amazon_final
ORDER BY amount_saved DESC
LIMIT 10;


-- Q8. How are products spread across price ranges?
SELECT
    CASE
        WHEN clean_price <= 500  THEN '1. Up to 500'
        WHEN clean_price <= 1000 THEN '2. 501 - 1,000'
        WHEN clean_price <= 5000 THEN '3. 1,001 - 5,000'
        ELSE                          '4. Above 5,000'
    END AS price_range,
    COUNT(*) AS total_products
FROM amazon_final
GROUP BY price_range
ORDER BY price_range;


-- Q9. Do bigger discounts mean better or worse ratings?
SELECT
    CASE
        WHEN clean_discount_percentage <= 20 THEN '1. 0-20%'
        WHEN clean_discount_percentage <= 40 THEN '2. 21-40%'
        WHEN clean_discount_percentage <= 60 THEN '3. 41-60%'
        ELSE                                      '4. 61-100%'
    END AS discount_band,
    COUNT(*)                     AS total_products,
    ROUND(AVG(clean_rating), 2)  AS avg_rating
FROM amazon_final
GROUP BY discount_band
ORDER BY discount_band;


-- Q10. What share of products in each category is discounted 50% or more?
SELECT main_category,
       COUNT(*) AS total_products,
       SUM(clean_discount_percentage >= 50) AS heavily_discounted,
       ROUND(SUM(clean_discount_percentage >= 50) * 100 / COUNT(*), 1) AS pct_heavily_discounted
FROM amazon_final
GROUP BY main_category
HAVING COUNT(*) >= 30
ORDER BY pct_heavily_discounted DESC;
