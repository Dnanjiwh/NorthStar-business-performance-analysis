
/*SELECT DATABASE();
SHOW TABLES;
SELECT * FROM products LIMIT 5;
USE northstar_analytics;
-- Validate imported row counts
SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers
UNION ALL
SELECT 'products', COUNT(*)
FROM products
UNION ALL
SELECT 'sales_reps', COUNT(*)
FROM sales_reps
UNION ALL
SELECT 'sales', COUNT(*)
FROM sales;*/

-- Validate csv data
SELECT DATABASE();
USE northstar_analytics;
SELECT customer_id
FROM sales;

-- Check for any missing critical values

SELECT
    SUM(customer_id IS NULL) AS missing_customer,
    SUM(product_id IS NULL) AS missing_product,
    SUM(sales_rep_id IS NULL) AS missing_rep,
    SUM(sale_date IS NULL) AS missing_date,
    SUM(quantity IS NULL) AS missing_quantity
FROM sales;

-- CHeck transaction statuses

SELECT status,
COUNT(*) AS transactions
FROM sales
GROUP BY status;

SHOW TABLES;



SELECT
    MIN(sale_date) AS first_sale,
    MAX(sale_date) AS last_sale
FROM sales;

-- Inspect discounts and quantities

SELECT
MIN(quantity) AS min_quantity,
MAX(quantity) AS max_quantity,
ROUND(AVG(quantity), 2) AS avg_quantity,
MIN(discount) AS min_discount,
MAX(discount) AS max_discount
FROM sales;



