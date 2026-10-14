USE northstar_analytics;

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    state CHAR(2),
    region VARCHAR(20),
    lead_source VARCHAR(50),
    signup_date DATE
);

CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price DECIMAL(10,2),
    unit_cost DECIMAL(10,2)
);

CREATE TABLE sales_reps (
    sales_rep_id VARCHAR(10) PRIMARY KEY,
    rep_name VARCHAR(100),
    region VARCHAR(20),
    hire_date DATE
);

CREATE TABLE sales (
    sale_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    product_id VARCHAR(10),
    sales_rep_id VARCHAR(10),
    sale_date DATE,
    quantity INT,
    discount DECIMAL(5,2),
    status VARCHAR(20),

    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    FOREIGN KEY (sales_rep_id)
        REFERENCES sales_reps(sales_rep_id)
);