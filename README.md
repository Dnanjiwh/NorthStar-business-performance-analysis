# Northstar Business Performance Analysis

## The Problem

![Northstar Business Performance Dashboard](images/northstar_dashboard.png)

Northstar's sales started falling in Q4.

I wanted to figure out what was actually behind the decline. Was the company getting fewer orders? Were customers spending less? Was one product category struggling? Was the problem concentrated in one region or customer group?

I used MySQL to investigate 2,400 sales transactions, Google Sheets to check and compare my results, and Power BI to build the final dashboard.

What I found was that this wasn't mainly an average order value problem. Northstar had fewer customers buying in Q4, and the customers who were active were ordering slightly less often. The decline also showed up across every region and product category, although some areas were hit harder than others.


## The Data

The dataset contains sales activity for 2026 and is split across four tables:

- sales
- customers
- products
- sales_reps

There are 2,400 sales transactions, 650 customers, 9 products, and 8 sales reps.

The data includes order dates, order status, customer location, lead source, product category, quantity, price, cost, discounts, and sales rep information.

I joined the four tables in MySQL and created one analysis dataset that I later used in Google Sheets and Power BI.


## Tools I Used

- MySQL / MySQL Workbench
- SQL
- Google Sheets
- Power BI
- Power Query
- DAX
- VS Code


## How I Investigated It

I started by getting a baseline for the year using completed sales.

```sql
SELECT
    ROUND(SUM(
        s.quantity * p.unit_price * (1 - s.discount)
    ), 2) AS completed_revenue,
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
```

| Metric | 2026 |
|---|---:|
| Completed Revenue | $437,759.40 |
| Completed Orders | 2,292 |
| Unique Customers | 635 |
| Average Order Value | $190.99 |

From there, I broke revenue down by month.

```sql
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
```

Revenue was fairly inconsistent throughout the year, but the clearest pattern came at the end. It fell from about $41.8K in September to $36.9K in October, $32.4K in November, and $26.8K in December.

Average order value didn't fall nearly as much, so I started looking at order volume instead.


### I checked cancellations

One of my first thoughts was that more cancelled orders might explain the drop.

I compared cancelled orders with total orders by month.

```sql
SELECT
    DATE_FORMAT(sale_date, '%Y-%m') AS month,
    COUNT(CASE
        WHEN status = 'Cancelled' THEN sale_id
    END) AS cancelled_orders,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * COUNT(CASE
            WHEN status = 'Cancelled' THEN sale_id
        END) / COUNT(*),
        2
    ) AS cancellation_rate
FROM sales
GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
ORDER BY month;
```

Cancellation rates did increase toward the end of the year, reaching about 8% in December. But cancellations weren't large enough to explain the entire decline.

The bigger issue was that fewer orders were being placed in the first place.

That led me to look at who was buying and where those orders were disappearing.


### I compared Q3 and Q4 customers

I compared the number of purchasing customers with total order activity.

```sql
SELECT
    QUARTER(sale_date) AS quarter,
    COUNT(DISTINCT customer_id) AS active_customers,
    COUNT(*) AS orders,
    ROUND(
        COUNT(*) / COUNT(DISTINCT customer_id),
        2
    ) AS orders_per_customer
FROM sales
WHERE QUARTER(sale_date) IN (3, 4)
GROUP BY QUARTER(sale_date)
ORDER BY quarter;
```

| Metric | Q3 | Q4 |
|---|---:|---:|
| Active Customers | 435 | 366 |
| Orders | 665 | 528 |
| Orders per Customer | 1.53 | 1.44 |

The number that stood out to me was active customers.

Northstar went from 435 purchasing customers in Q3 to 366 in Q4, a decline of about 16%.

Orders per customer also fell, but much less. That made customer activity a bigger part of the story than purchase frequency.


### I looked at product categories

Next I wanted to know whether one product category was dragging down the business.

I used conditional aggregation to compare Q3 and Q4 in the same result.

```sql
SELECT
    p.category,
    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 3 THEN s.sale_id
    END) AS q3_orders,
    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 4 THEN s.sale_id
    END) AS q4_orders
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
WHERE s.status = 'Completed'
GROUP BY p.category
ORDER BY p.category;
```

Using completed orders in my final dashboard:

| Category | Q3 | Q4 | Change |
|---|---:|---:|---:|
| Audio | 200 | 170 | -15.0% |
| Home | 234 | 179 | -23.5% |
| Wearables | 207 | 143 | -30.9% |

Wearables had the largest percentage decline.

But every category was down, so this wasn't just a Wearables problem.


### I checked the regions

I found a similar pattern geographically.

```sql
SELECT
    c.region,
    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 3 THEN s.sale_id
    END) AS q3_orders,
    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 4 THEN s.sale_id
    END) AS q4_orders
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
WHERE s.status = 'Completed'
GROUP BY c.region
ORDER BY c.region;
```

Completed orders declined across the Northeast, Midwest, South, and West between Q3 and Q4.

That made it less likely that one struggling territory was responsible for the overall decline.


### I looked at lead source

I also compared customers based on their original lead source.

```sql
SELECT
    c.lead_source,
    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 3 THEN s.sale_id
    END) AS q3_orders,
    COUNT(CASE
        WHEN QUARTER(s.sale_date) = 4 THEN s.sale_id
    END) AS q4_orders
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
WHERE s.status = 'Completed'
GROUP BY c.lead_source
ORDER BY q3_orders DESC;
```

Google Ads had one of the largest drops in completed orders, while Organic Search also showed a large decline between Q3 and Q4.

I wouldn't say this means Google Ads or Organic Search caused the problem.

The dataset tells me where a customer originally came from, but it doesn't include things like website traffic, ad spend, conversion rates, campaign changes, or retention data. I would need those before making a claim about marketing performance.


## What I Found

The biggest takeaway for me was that Q4 looks more like a customer and order volume problem than a pricing or average order value problem.

A few things stood out:

- Revenue fell steadily from September through December.
- The number of active customers dropped from 435 in Q3 to 366 in Q4.
- Customers who were still purchasing also ordered slightly less often.
- Every product category declined.
- Wearables had the largest category decline in completed orders.
- Every region declined, so the problem wasn't isolated geographically.
- Some lead-source groups declined more than others, especially Google Ads and Organic Search.


## What I'd Look At Next

If this were a real company and I were continuing the analysis, the first thing I'd want is more customer and marketing data.

I'd want to know how many Q3 customers returned in Q4 versus how many stopped purchasing completely.

I'd also want traffic, conversion, ad spend, and campaign data for Google Ads and Organic Search. That would help separate an acquisition problem from a retention problem.

For Wearables, I'd check inventory levels, promotions, pricing changes, returns, and whether specific products accounted for most of the decline.

The current data shows where the decline happened. Those additional datasets would help explain why.


## Google Sheets

I used Google Sheets as a second way to check some of my SQL results and practice working with the analysis outside of the database.

I created pivot tables for monthly and quarterly performance, calculated Q3 to Q4 percentage changes, created charts, and used XLOOKUP to retrieve product information.

This also helped me catch differences in how I was defining metrics, especially the difference between all orders and completed orders.
Link:
https://docs.google.com/spreadsheets/d/1mE_lyPzenCpfV8kGVjAQTufc9_qu27N06CEYyHRTVu8/edit?usp=sharing

## Power BI Dashboard

I built the final dashboard in Power BI using the dataset created from my SQL joins.

The dashboard includes:

- Completed Revenue
- Completed Orders
- Unique Customers
- Average Order Value
- Monthly Completed Revenue
- Q3 vs Q4 Completed Orders by Category
- Q3 vs Q4 Completed Orders by Region
- Q3 vs Q4 Completed Orders by Lead Source

I also added filters for quarter, region, category, and lead source.

The Q3 vs Q4 charts stay fixed as comparison views while the other parts of the dashboard can be filtered.


## What I Learned

The biggest thing I learned from this project wasn't a specific SQL command.

It was how quickly you can jump to the wrong explanation if you stop at the first interesting number.

At different points I looked at cancellations, regions, product categories, lead sources, customers, and sales reps. Some of those explained part of the decline, but none explained everything on their own.

I also got more comfortable separating what the data shows from what I think might be happening.

For example, I can show that customers associated with certain lead sources purchased less in Q4. I can't show that those marketing channels caused the decline without additional data.

That distinction is something I would carry into my next analysis.