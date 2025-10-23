-- ===========================================================
--  PostgreSQL OLTP Schema
-- ===========================================================

-- Use database oltp
\c oltp;

-- Drop old tables if they exist (for re-runs)
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS customer_activities CASCADE;

-- =========================
-- Customers
-- =========================
CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) UNIQUE NOT NULL,
    created_at    TIMESTAMP DEFAULT NOW()
);

-- =========================
-- Products
-- =========================
CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    category      VARCHAR(50),
    price         NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    created_at    TIMESTAMP DEFAULT NOW()
);

-- =========================
-- Orders
-- =========================
CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    total_amount  NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
    created_at    TIMESTAMP DEFAULT NOW()
);

-- =========================
-- Order Items
-- =========================
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    INT NOT NULL REFERENCES products(product_id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    price         NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

-- =========================
-- Payments
-- =========================
CREATE TABLE payments (
    payment_id     SERIAL PRIMARY KEY,
    order_id       INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL,                    -- 'Credit Card', 'Bank Transfer', 'Cash', etc.
    payment_status VARCHAR(30) NOT NULL DEFAULT 'Pending',  -- 'Pending', 'Completed', 'Failed'
    amount_paid    NUMERIC(12,2) NOT NULL CHECK (amount_paid >= 0),
    transaction_id VARCHAR(100),
    paid_at        TIMESTAMP DEFAULT NOW()
);

-- =========================
-- User Activity
-- =========================
CREATE TABLE customer_activities (
    activity_id    SERIAL PRIMARY KEY,
    customer_id    INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    activity_type  VARCHAR(50) NOT NULL,                -- 'VIEW_PRODUCT', 'ADD_TO_CART', 'CHECKOUT', 'PAYMENT', 'LOGIN'
    product_id     INT REFERENCES products(product_id), -- optional (null for non-product actions)
    order_id       INT REFERENCES orders(order_id),     -- optional (null if not tied to an order)
    activity_time  TIMESTAMP DEFAULT NOW(),
    metadata       JSONB DEFAULT '{}'                   -- extra details (e.g., {"device":"mobile","ip":"192.168.0.1"})
);

-- =========================
-- Indexes
-- =========================
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_customer_activities_customer_id ON customer_activities(customer_id);
CREATE INDEX idx_customer_activities_type ON customer_activities(activity_type);
CREATE INDEX idx_customer_activities_time ON customer_activities(activity_time);
