USE northstar_analytics;

/*
NORTHSTAR BUSINESS PERFORMANCE ANALYSIS

Goal:
Investigate why Northstar's performance weakened in Q4 2026.

A few metric definitions used in this file:
- Completed revenue only includes rows where status = 'Completed'.
- Completed orders only include rows where status = 'Completed'.
- Customer activity in Section 5 uses all order statuses because the question
  is whether overall purchasing/order activity changed between Q3 and Q4.
*/



/* 1. REVENUE CALCULATION CHECK
 Question: Am I calculating gross and net revenue correctly?
*/

SELECT
    s.sale_id,
    s.quantity,
    p.product_name,
    p.unit_price,
    s.discount,
    ROUND(s.quantity * p.unit_price, 2) AS gross_revenue,
    ROUND(
        s.quantity * p.unit_price * (1 - s.discount),
        2
    ) AS net_revenue
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
WHERE s.status = 'Completed'
LIMIT 10;



/* 2. EXECUTIVE KPIs
 Question: What did the business do overall in 2026?
*/

SELECT
    ROUND(
        SUM(s.quantity * p.unit_price * (1 - s.discount)),
        2
    ) AS completed_revenue,

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

/* Expected results:
 Completed revenue: 437759.40
 Completed orders: 2292
 Unique customers: 635
 Average order value: 190.99


 3. MONTHLY PERFORMANCE
 Question: When did revenue and order volume start weakening?
 */

SELECT
    DATE_FORMAT(s.sale_date, '%Y-%m') AS month,

    ROUND(
        SUM(s.quantity * p.unit_price * (1 - s.discount)),
        2
    ) AS completed_revenue,

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
  AND YEAR(s.sale_date) = 2026
GROUP BY DATE_FORMAT(s.sale_date, '%Y-%m')
ORDER BY month;



/* 4. CANCELLATIONS
Question: Did rising cancellations explain the Q4 decline?
*/

SELECT
    DATE_FORMAT(sale_date, '%Y-%m') AS month,

    COUNT(CASE
        WHEN status = 'Completed' THEN 1
    END) AS completed_orders,

    COUNT(CASE
        WHEN status = 'Cancelled' THEN 1
    END) AS cancelled_orders,

    COUNT(*) AS total_orders,

    ROUND(
        100.0 * COUNT(CASE
            WHEN status = 'Cancelled' THEN 1
        END) / COUNT(*),
        2
    ) AS cancellation_rate
FROM sales
WHERE YEAR(sale_date) = 2026
GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
ORDER BY month;



 /*5. Q3 VS Q4 CUSTOMER ACTIVITY
 Question: Were fewer customers buying in Q4?

 Note:
 This section uses all order statuses to measure total order activity.
 That is why these totals are different from completed-order totals
 used in later sections and in the final Power BI dashboard.
 */

SELECT
    QUARTER(sale_date) AS quarter,

    COUNT(DISTINCT customer_id) AS active_customers,

    COUNT(*) AS total_orders,

    ROUND(
        COUNT(*) / COUNT(DISTINCT customer_id),
        2
    ) AS orders_per_customer
FROM sales
WHERE YEAR(sale_date) = 2026
  AND QUARTER(sale_date) IN (3, 4)
GROUP BY QUARTER(sale_date)
ORDER BY quarter;

/* Results from the analysis:
 Q3: 435 customers, 665 orders, 1.53 orders/customer
 Q4: 366 customers, 528 orders, 1.44 orders/customer
*/


/* 6. Q3 VS Q4 BY PRODUCT CATEGORY
 Question: Was one product category responsible for the decline?
 */


SELECT
    p.category,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 3 THEN 1
    END) AS q3_completed_orders,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 4 THEN 1
    END) AS q4_completed_orders,

    ROUND(
        100.0 * (
            COUNT(CASE WHEN QUARTER(s.sale_date) = 4 THEN 1 END)
            - COUNT(CASE WHEN QUARTER(s.sale_date) = 3 THEN 1 END)
        )
        / NULLIF(
            COUNT(CASE WHEN QUARTER(s.sale_date) = 3 THEN 1 END),
            0
        ),
        2
    ) AS percent_change
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
WHERE s.status = 'Completed'
  AND YEAR(s.sale_date) = 2026
  AND QUARTER(s.sale_date) IN (3, 4)
GROUP BY p.category
ORDER BY p.category;

/* Dashboard results:
 Audio:     200 to 170
 Home:      234 to 179
 Wearables: 207 to 143



 7. Q3 VS Q4 BY CUSTOMER REGION
 Question: Was the decline concentrated in one region?
 Uses COMPLETED orders.
*/

SELECT
    c.region,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 3 THEN 1
    END) AS q3_completed_orders,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 4 THEN 1
    END) AS q4_completed_orders,

    ROUND(
        100.0 * (
            COUNT(CASE WHEN QUARTER(s.sale_date) = 4 THEN 1 END)
            - COUNT(CASE WHEN QUARTER(s.sale_date) = 3 THEN 1 END)
        )
        / NULLIF(
            COUNT(CASE WHEN QUARTER(s.sale_date) = 3 THEN 1 END),
            0
        ),
        2
    ) AS percent_change
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
WHERE s.status = 'Completed'
  AND YEAR(s.sale_date) = 2026
  AND QUARTER(s.sale_date) IN (3, 4)
GROUP BY c.region
ORDER BY c.region;



/* 8. Q3 VS Q4 BY LEAD SOURCE
 Question: Which customer acquisition groups weakened most?
 Uses the customer's original lead source and COMPLETED orders.
 This shows association, not proof that a channel caused the decline.
*/

SELECT
    c.lead_source,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 3 THEN 1
    END) AS q3_completed_orders,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 4 THEN 1
    END) AS q4_completed_orders,

    ROUND(
        100.0 * (
            COUNT(CASE WHEN QUARTER(s.sale_date) = 4 THEN 1 END)
            - COUNT(CASE WHEN QUARTER(s.sale_date) = 3 THEN 1 END)
        )
        / NULLIF(
            COUNT(CASE WHEN QUARTER(s.sale_date) = 3 THEN 1 END),
            0
        ),
        2
    ) AS percent_change
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
WHERE s.status = 'Completed'
  AND YEAR(s.sale_date) = 2026
  AND QUARTER(s.sale_date) IN (3, 4)
GROUP BY c.lead_source
ORDER BY q3_completed_orders DESC;



/* 9. REGION + CATEGORY EXPLORATION
 Question: Were certain category/region combinations hit harder?

 This reproduces one of the exploratory checks from the investigation.
 It uses ALL order statuses, so do not compare these counts directly
 with completed-order dashboard totals.
*/

SELECT
    c.region,
    p.category,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 3 THEN 1
    END) AS q3_orders,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 4 THEN 1
    END) AS q4_orders,

    ROUND(
        100.0 * (
            COUNT(CASE WHEN QUARTER(s.sale_date) = 4 THEN 1 END)
            - COUNT(CASE WHEN QUARTER(s.sale_date) = 3 THEN 1 END)
        )
        / NULLIF(
            COUNT(CASE WHEN QUARTER(s.sale_date) = 3 THEN 1 END),
            0
        ),
        2
    ) AS percent_change
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN products p
    ON s.product_id = p.product_id
WHERE YEAR(s.sale_date) = 2026
  AND QUARTER(s.sale_date) IN (3, 4)
GROUP BY
    c.region,
    p.category
ORDER BY
    c.region,
    p.category;



/*10. SALES REP EXPLORATION
Question: Was the decline mostly tied to one sales rep?

 This exploratory check uses ALL order statuses.
*/

SELECT
    sr.rep_name,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 3 THEN 1
    END) AS q3_orders,

    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 4 THEN 1
    END) AS q4_orders,

    ROUND(
        100.0 * (
            COUNT(CASE WHEN QUARTER(s.sale_date) = 4 THEN 1 END)
            - COUNT(CASE WHEN QUARTER(s.sale_date) = 3 THEN 1 END)
        )
        / NULLIF(
            COUNT(CASE WHEN QUARTER(s.sale_date) = 3 THEN 1 END),
            0
        ),
        2
    ) AS percent_change
FROM sales s
JOIN sales_reps sr
    ON s.sales_rep_id = sr.sales_rep_id
WHERE YEAR(s.sale_date) = 2026
  AND QUARTER(s.sale_date) IN (3, 4)
GROUP BY sr.rep_name
ORDER BY q3_orders DESC;


/*
CONCLUSIONS

The Q4 slowdown was broad rather than isolated to one category, region,
or sales rep. Revenue fell mainly because order volume weakened.
Customer activity also declined, while average completed-order value
stayed relatively stable.

Lead-source results show where customer groups weakened, but this dataset
does not include traffic, ad spend, conversion, or retention data, so it
cannot establish that a marketing channel caused the decline.
*/
