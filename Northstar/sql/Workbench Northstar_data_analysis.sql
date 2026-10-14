USE northstar_analytics;

SELECT
    ROUND(
        SUM(s.quantity * p.unit_price * (1 - s.discount)),
        2
    ) AS total_revenue,

    COUNT(DISTINCT s.sale_id) AS completed_orders,

    COUNT(DISTINCT s.customer_id) AS unique_customers,

    ROUND(
        SUM(s.quantity * p.unit_price * (1 - s.discount))
        / COUNT(DISTINCT s.sale_id),
        2
    ) AS average_order_value

FROM sales s

JOIN products p
    ON s.product_id = p.product_id

WHERE s.status = 'Completed';

/* 2. Monthly splurge */
SELECT
    DATE_FORMAT(s.sale_date, '%Y-%m') AS month,

    ROUND(
        SUM(s.quantity * p.unit_price * (1 - s.discount)),
        2
    ) AS revenue,

    COUNT(DISTINCT s.sale_id) AS completed_orders,

    COUNT(DISTINCT s.customer_id) AS unique_customers,

    ROUND(
        SUM(s.quantity * p.unit_price * (1 - s.discount))
        / COUNT(DISTINCT s.sale_id),
        2
    ) AS average_order_value

FROM sales s

JOIN products p
    ON s.product_id = p.product_id

WHERE s.status = 'Completed'

GROUP BY DATE_FORMAT(s.sale_date, '%Y-%m')

ORDER BY month;

/* Monthly Cancellation Rate */
SELECT
    DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
       
	SUM(s.status = 'Cancelled') AS cancelled_order,

    COUNT(DISTINCT s.sale_id) AS total_orders,

    Round(SUM(s.status = 'Cancelled') * (100 / COUNT(DISTINCT s.sale_id))) AS Cancellation_rate

FROM sales s

JOIN products p
    ON s.product_id = p.product_id

GROUP BY DATE_FORMAT(s.sale_date, '%Y-%m')

ORDER BY month;

/*regional order breakdown */

SELECT
DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
COUNT(DISTINCT s.sale_id) AS total_orders,
SUM(s.status = 'Completed') AS completed_orders ,
SUM(s.status = 'Cancelled') AS canceled_orders,
region
FROM sales s 
Join sales_reps sr
ON s.sales_rep_id = sr.sales_rep_id
GROUP BY month, region
ORDER BY month; 

/*SELECT
 p.category,
COUNT(CASE WHEN QUARTER (s.sale_date) = 3 THEN S.sale_id END) AS Q3_orders,
COUNT(CASE WHEN QUARTER (s.sale_date) = 4 THEN S.sale_id END) AS Q4_orders,

COUNT(CASE WHEN QUARTER (s.sale_date) = 4 THEN S.sale_id END)
-
COUNT(CASE WHEN QUARTER (s.sale_date) = 3 THEN S.sale_id END)  AS order_change,
Round(
(COUNT(CASE WHEN QUARTER (s.sale_date) = 4 THEN S.sale_id END)
-
COUNT(CASE WHEN QUARTER (s.sale_date) = 3 THEN S.sale_id END) 
) / COUNT(CASE WHEN QUARTER (s.sale_date) = 3 THEN S.sale_id END) * 100, 2)
AS percent_change
FROM sales s
JOIN customers c
    ON s.product_id = p.product_id

JOIN sales_reps sr
    ON s.sales_rep_id = sr.sales_rep_id

WHERE QUARTER(s.sale_date) IN (3, 4)

GROUP BY category

ORDER BY percent_change; */

/*order volume from customers acquired through a particular lead source*/

SELECT
DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
COUNT(DISTINCT s.sale_id) AS total_orders,
SUM(s.status = 'Completed') AS completed_orders ,
SUM(s.status = 'Cancelled') AS canceled_orders,
region
FROM sales s 
Join sales_reps sr
ON s.sales_rep_id = sr.sales_rep_id
GROUP BY month, region
ORDER BY month; 

/* SELECT
    c.lead_source,
    COUNT(*) AS orders
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
GROUP BY c.lead_source; */


SELECT
    c.lead_source,
    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 3 THEN s.sale_id
    END) AS Q3_orders,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 4 THEN s.sale_id
    END) AS Q4_orders

FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id

WHERE QUARTER(s.sale_date) IN (3, 4)

GROUP BY c.lead_source; 

/* customer order vs order frequency*/

SELECT
Quarter(s.sale_date) AS quarter,
    COUNT(DISTINCT s.customer_id) AS unique_customers,
    COUNT(DISTINCT s.sale_id) AS orders,
   Round (COUNT(DISTINCT s.sale_id) / COUNT(DISTINCT s.customer_id) ,2)AS orders_per_customer
	FROM sales s
WHERE QUARTER(s.sale_date) IN (3, 4)
GROUP BY QUARTER; 

/* rep performance by quarter */
SELECT
    sr.rep_name,
    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 3 THEN s.sale_id
    END) AS Q3_orders,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 4 THEN s.sale_id
    END) AS Q4_orders

FROM sales s
JOIN sales_reps sr
    ON s.sales_rep_id = sr.sales_rep_id

WHERE QUARTER(s.sale_date) IN (3, 4)

GROUP BY sr.rep_name; 

USE northstar_analytics;

SELECT
    -- Sale information
    s.sale_id,
    s.sale_date,
    DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
    QUARTER(s.sale_date) AS quarter,
    s.status,

    -- Customer information
    s.customer_id,
    c.customer_name,
    c.segment,
    c.state,
    c.region AS customer_region,
    c.lead_source,
    c.signup_date,

    -- Product information
    s.product_id,
    p.product_name,
    p.category,
    s.quantity,
    p.unit_price,
    p.unit_cost,
    s.discount,

    -- Sales representative information
    s.sales_rep_id,
    sr.rep_name,
    sr.region AS sales_region,

    -- Financial calculations
    ROUND(
        s.quantity * p.unit_price,
        2
    ) AS gross_revenue,

    ROUND(
        s.quantity * p.unit_price * (1 - s.discount),
        2
    ) AS net_revenue,

    ROUND(
        s.quantity * p.unit_cost,
        2
    ) AS total_cost,

    ROUND(
        (s.quantity * p.unit_price * (1 - s.discount))
        - (s.quantity * p.unit_cost),
        2
    ) AS profit

FROM sales s

JOIN customers c
    ON s.customer_id = c.customer_id

JOIN products p
    ON s.product_id = p.product_id

JOIN sales_reps sr
    ON s.sales_rep_id = sr.sales_rep_id

ORDER BY s.sale_date, s.sale_id;