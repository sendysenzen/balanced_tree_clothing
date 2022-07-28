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
-- C.10 What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?


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


/* 
Bonus Challenge
---------------
Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

*/

