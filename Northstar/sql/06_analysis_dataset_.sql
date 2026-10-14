USE northstar_analytics;

/*
FINAL ANALYSIS DATASET

This query joins the four source tables and creates the flat dataset
used for Google Sheets and Power BI.

Important:
Revenue and profit fields are calculated for every transaction row.
Filter status = 'Completed' when reporting completed-sales KPIs.
*/

SELECT
    s.sale_id,
    s.sale_date,
    DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
    QUARTER(s.sale_date) AS quarter,
    s.status,

    s.customer_id,
    c.customer_name,
    c.segment,
    c.state,
    c.region AS customer_region,
    c.lead_source,
    c.signup_date,

    s.product_id,
    p.product_name,
    p.category,
    s.quantity,
    p.unit_price,
    p.unit_cost,
    s.discount,

    s.sales_rep_id,
    sr.rep_name,
    sr.region AS sales_region,

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
ORDER BY
    s.sale_date,
    s.sale_id;
