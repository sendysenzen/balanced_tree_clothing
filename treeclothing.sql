-- 7th case study 

-- insert data on case details

-- A. High Level Sales Analysis
---------------------------------
-- A.1 What was the total quantity sold for all products?
SELECT 
    t1.prod_id,
    t2.product_name,
    SUM(qty) sum_qty
FROM sales t1
    INNER JOIN product_details t2
    ON t1.prod_id = t2.product_id
GROUP BY 1,2
ORDER BY 3 desc;

-- A.2 What is the total generated revenue for all products before discounts?
SELECT 
    SUM(qty*price) sum_revenue
FROM sales ;


-- A.3 What was the total discount amount for all products?
-- maybe the question should be: what was the total discounted amount for all products?
-- the question and the concept discount itself are a bit vague


-- B. Transaction Analysis
----------------------------
-- B.1 How many unique transactions were there?
SELECT
    COUNT (DISTINCT txn_id) 
FROM sales;


-- B.2 What is the average unique products purchased in each transaction?
WITH cte AS(
SELECT
    txn_id,
    COUNT(DISTINCT prod_id) unique_products
FROM sales
GROUP BY 1
)
SELECT
    ROUND(AVG(unique_products),2) avg_unique_prod
FROM cte


-- B.3 What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH cte AS (
SELECT
    txn_id,
    SUM(qty*price) revenue
FROM sales
    GROUP BY 1
)
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) ptile_25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue) ptile_50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue) ptile_75
FROM cte

-- B.4 What is the average discount value per transaction?
WITH cte AS(
SELECT
    txn_id,
    SUM(discount) tot_disc
FROM sales
    GROUP BY 1
)
SELECT 
    AVG(tot_disc)
FROM cte

-- B.5 What is the percentage split of all transactions for members vs non-members?
-- I took percentage from amount not the number of transactions. 
WITH cte AS (
SELECT 
    member,
    COUNT(DISTINCT txn_id) txn_num,
    SUM(qty*price) txn_amt
FROM sales
GROUP BY 1
)
SELECT
    member,
    txn_amt,
    ROUND(100*txn_amt / SUM(txn_amt) OVER()::NUMERIC,2) pct
FROM cte
GROUP BY 1,2;


-- B.6 What is the average revenue for member transactions and non-member transactions?
WITH cte AS (
SELECT 
    member,
    COUNT(DISTINCT txn_id) txn_num,
    SUM(qty*price) txn_amt
FROM sales
GROUP BY 1
)
SELECT
    member,
    ROUND(txn_amt::NUMERIC/txn_num::NUMERIC,2) avg_revenue
FROM cte
GROUP BY 1,2;



-- C. Product Analysis
-----------------------
-- C.1 What are the top 3 products by total revenue before discount?
SELECT sales.prod_id,
    product_details.product_name,
    SUM(sales.qty*sales.price) total_revenue
FROM sales 
INNER JOIN product_details
ON sales.prod_id = product_details.product_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3;

-- C.2 What is the total quantity, revenue and discount for each segment?
WITH cte AS (   
SELECT
    prod_id,
    SUM(qty) total_qty,
    SUM(qty*price) total_revenue,
    SUM(discount) total_discount
FROM sales
GROUP BY 1
)
SELECT 
    t1.segment_id,
    t1.segment_name,
    SUM(t2.total_qty) total_qty,
    SUM(t2.total_revenue) total_revenue,
    SUM(t2.total_discount) total_discount
FROM product_details t1
INNER JOIN cte t2
ON t1.product_id = t2.prod_id
GROUP BY 1,2;

-- C.3 What is the top selling product for each segment?
-- top selling means we are using revenue as parameter
WITH cte AS(
SELECT t1.prod_id,
    t2.product_name,
    t2.segment_id,
    t2.segment_name,
    SUM(t1.qty) total_qty,
    SUM(t1.qty*t1.price) total_revenue,
    RANK() OVER(PARTITION BY t2.segment_id ORDER BY SUM(t1.qty*t1.price) DESC ) rank_rev
FROM sales t1
INNER JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY 1,2,3,4
ORDER BY 3,6 DESC
) 
SELECT 
    segment_id,
    segment_name,
    prod_id,
    product_name,
    total_revenue
FROM cte
WHERE rank_rev = 1
ORDER BY 5 DESC;


-- C.4 What is the total quantity, revenue and discount for each category?
WITH cte AS (   
SELECT
    prod_id,
    SUM(qty) total_qty,
    SUM(qty*price) total_revenue,
    SUM(discount) total_discount
FROM sales
GROUP BY 1
)
SELECT 
    t1.category_id,
    t1.category_name,
    SUM(t2.total_qty) total_qty,
    SUM(t2.total_revenue) total_revenue,
    SUM(t2.total_discount) total_discount
FROM product_details t1
INNER JOIN cte t2
ON t1.product_id = t2.prod_id
GROUP BY 1,2;

-- C.5 What is the top selling product for each category?
WITH cte AS(
SELECT t1.prod_id,
    t2.product_name,
    t2.category_id,
    t2.category_name,
    SUM(t1.qty) total_qty,
    SUM(t1.qty*t1.price) total_revenue,
    RANK() OVER(PARTITION BY t2.category_id ORDER BY SUM(t1.qty*t1.price) DESC ) rank_rev
FROM sales t1
INNER JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY 1,2,3,4
ORDER BY 3,6 DESC
) 
SELECT 
    category_id,
    category_name,
    prod_id,
    product_name,
    total_revenue
FROM cte
WHERE rank_rev = 1
ORDER BY 5 DESC;


-- C.6 What is the percentage split of revenue by product for each segment?
WITH cte AS(
SELECT t1.prod_id,
    t2.product_name,
    t2.segment_id,
    t2.segment_name,
    SUM(t1.qty) total_qty,
    SUM(t1.qty*t1.price) total_revenue
FROM sales t1
INNER JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY 1,2,3,4
ORDER BY 3,6 DESC
) 
SELECT *,
    ROUND(100*total_revenue/SUM(total_revenue) OVER(PARTITION BY segment_id),2) segment_rev_percentage
FROM cte
ORDER BY segment_id, segment_rev_percentage DESC;

-- C.7 What is the percentage split of revenue by segment for each category?
WITH cte AS(
SELECT t2.segment_id,
    t2.segment_name,
    t2.category_id,
    t2.category_name,
    SUM(t1.qty) total_qty,
    SUM(t1.qty*t1.price) total_revenue
FROM sales t1
INNER JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY 1,2,3,4
ORDER BY 3,6 DESC
) 
SELECT *,
    ROUND(100*total_revenue/SUM(total_revenue) OVER(PARTITION BY category_id),2) cat_by_segment_percentage
FROM cte
ORDER BY category_id, cat_by_segment_percentage DESC;


-- C.8 What is the percentage split of total revenue by category?
WITH cte AS(
SELECT
    t2.category_id,
    t2.category_name,
    SUM(t1.qty) total_qty,
    SUM(t1.qty*t1.price) total_revenue
FROM sales t1
INNER JOIN product_details t2
ON t1.prod_id = t2.product_id
GROUP BY 1,2
ORDER BY 1,4 DESC
) 
SELECT *,
    ROUND(100*total_revenue/SUM(total_revenue) OVER(),2) cat_rev_percentage
FROM cte
ORDER BY category_id, cat_rev_percentage DESC;


-- C.9 What is the total transaction “penetration” for each product? (hint: penetration = number of transactions 
-- where at least 1 quantity of a product was purchased divided by total number of transactions)
SELECT 
    t1.prod_id,
    t2.product_name, 
    SUM(CASE WHEN t1.qty > 0 THEN 1 ELSE 0 END) penetration_sum
FROM sales t1
INNER JOIN product_details t2
ON t1.prod_id = t2.product_id 
GROUP BY 1,2
ORDER BY 3 DESC

SELECT * FROM sales

-- C.10 What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
-- this will be using ARRAY FUNCTIONS
-- see the documentation in: https://www.postgresql.org/docs/current/functions-array.html


-- 1st step: create a table of combination of 3 products.
-- total number of data in this 1st step shall follow Combination formula C(12,3) ~ 220 lines
DROP TABLE IF EXISTS combination_product;
CREATE TEMP TABLE combination_product AS
WITH RECURSIVE combination_product(combination, product_id, product_count) AS (
    SELECT
        ARRAY[product_id::TEXT] combination,
        product_id,
        1 AS product_count
    FROM product_details
    -- this is for only one product_id to get the product_id array and table columns that we want 
    -- (non-recursive query or base query)
    
    UNION ALL
    
    SELECT 
        array_append(t1.combination, t2.product_id),
        t2.product_id,
        t1.product_count + 1 -- the iteration
    FROM combination_product t1
    INNER JOIN product_details t2 
        ON t1.product_id < t2.product_id -- termination condition  
    WHERE t1.product_count <= 3 
    -- this one for the combination of 3 products (recursive query)
    )
SELECT * FROM combination_product 
WHERE product_count = 3
ORDER BY product_id;

-- next step: create an array for product id in every transaction & check whether the 
-- 3 combination list is included in each transactions product_id 
-- using array_agg
-- see here: https://www.postgresql.org/docs/9.5/functions-aggregate.html
DROP TABLE IF EXISTS cross_checking_products;
CREATE TEMP TABLE cross_checking_products AS
WITH cte_txn_products AS (
    SELECT
        txn_id,
        array_agg(prod_id::TEXT ORDER BY prod_id) product_list
    FROM sales
    GROUP BY 1
    )
SELECT 
    txn_id,
    combination,
    product_list
FROM cte_txn_products
    CROSS JOIN combination_product 
    WHERE combination <@ product_list ;
-- combination is in product_list

-- now we will find the most common combination by counting the 3 combination, we need to make 
-- sure the rank is not duplicate, the most common combination must be in rank 1.
-- let's say if there is 2 rank 1 then both of the combination must be included.    
WITH cte_ranked AS ( 
    SELECT
        combination, 
        COUNT(DISTINCT txn_id) txn_count, 
        RANK() OVER(ORDER BY COUNT(DISTINCT txn_id) DESC) combination_rank
    FROM cross_checking_products
    GROUP BY 1 -- fortunately there is only one ranking #1
    ), 
    cte_get_product AS ( 
    SELECT 
        UNNEST(combination) prod_id    
    FROM cte_ranked
    WHERE combination_rank = 1
)
SELECT 
    t1.prod_id,
    t2.product_name
FROM cte_get_product t1
INNER JOIN product_details t2
ON t1.prod_id = t2.product_id;


/*
Reporting Challenge
---------------------
Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team 
can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily 
run the samne analysis for February without many changes (if at all).

Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which 
table outputs relate to which question for full marks :)
*/

-- I will do above question later

/* 
Bonus Challenge
---------------
Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

*/

-- based on the views from these 2 columns, you would have assumed that the hierarchy is category, segment, style respectively
-- so there are 3 levels. I created column level to solve and understand this problem better

WITH RECURSIVE details (id,lvl, category_id, segment_id, style_id, category_name, segment_name, style_name) AS (
    SELECT 
        id,
        0 as lvl,
        id as category_id,
        NULL::INTEGER as segment_id,
        NULL::INTEGER as style_id,
        level_text as category_name,
        NULL::VARCHAR as segment_name,
        NULL::VARCHAR as style_name
    FROM product_hierarchy
    WHERE parent_id IS NULL
    -- non-recursive/anchor
    
    UNION ALL
    
    SELECT 
        t2.id,
        lvl+1 as lvl,
        t1.category_id,
        CASE WHEN t1.lvl = 1 then t1.id else t1.segment_id end segment_id,
        CASE WHEN t1.lvl = 1 then t2.id else t1.style_id end style_id,
        t1.category_name,
        CASE WHEN t1.lvl = 1 then t1.segment_name else t2.level_text end segment_name,
        CASE WHEN t1.lvl = 1 then t2.level_text else t1.style_name end style_name  
    FROM details t1
    INNER JOIN product_hierarchy t2 
        ON t1.id = t2.parent_id 
        AND t2.parent_id IS NOT NULL-- termination condition
)
SELECT
    t2.product_id, 
    t2.price,
    t1.category_id,
    t1.segment_id,
    t1.style_id,
    t1.style_name || ' ' || t1.segment_name || ' - ' || t1.category_name as product_name, 
    t1.category_name,
    t1.segment_name,
    t1.style_name
FROM details t1
INNER JOIN product_prices t2
    ON t1.id = t2.id
WHERE t1.style_id IS NOT NULL ;

-- NOTE: While I understand the concept of recursive but in advanced practice such this question,  
-- it is difficult to solve it without using trial and error
