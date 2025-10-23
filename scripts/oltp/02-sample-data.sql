-- ===========================================================
--  Sample Data
-- ===========================================================

-- =========================
-- Customers (20)
-- =========================
INSERT INTO customers (name, email) VALUES
('Alice Johnson', 'alice.johnson@email.com'),
('Bob Smith', 'bob.smith@email.com'),
('Charlie Nguyen', 'charlie.nguyen@email.com'),
('Diana Tran', 'diana.tran@email.com'),
('Ethan Brown', 'ethan.brown@email.com'),
('Fiona Davis', 'fiona.davis@email.com'),
('George Miller', 'george.miller@email.com'),
('Hannah Lee', 'hannah.lee@email.com'),
('Ian Chen', 'ian.chen@email.com'),
('Jenny Kim', 'jenny.kim@email.com'),
('Kevin White', 'kevin.white@email.com'),
('Luna Garcia', 'luna.garcia@email.com'),
('Mark Wilson', 'mark.wilson@email.com'),
('Nina Patel', 'nina.patel@email.com'),
('Oscar Rivera', 'oscar.rivera@email.com'),
('Paula Adams', 'paula.adams@email.com'),
('Quinn Torres', 'quinn.torres@email.com'),
('Rachel Nguyen', 'rachel.nguyen@email.com'),
('Sam Harris', 'sam.harris@email.com'),
('Tina Lopez', 'tina.lopez@email.com');

-- =========================
-- Products (20)
-- =========================
INSERT INTO products (name, category, price) VALUES
('Laptop', 'Electronics', 1000.00),
('Wireless Mouse', 'Electronics', 25.00),
('Mechanical Keyboard', 'Electronics', 80.00),
('Monitor 24"', 'Electronics', 180.00),
('Smartphone', 'Electronics', 850.00),
('Desk Chair', 'Furniture', 150.00),
('Office Desk', 'Furniture', 220.00),
('Bookshelf', 'Furniture', 130.00),
('Table Lamp', 'Home', 45.00),
('Coffee Maker', 'Home', 90.00),
('Air Conditioner', 'Appliances', 600.00),
('Refrigerator', 'Appliances', 1100.00),
('Microwave', 'Appliances', 250.00),
('T-shirt', 'Clothing', 20.00),
('Jeans', 'Clothing', 45.00),
('Sneakers', 'Clothing', 70.00),
('Backpack', 'Accessories', 60.00),
('Wristwatch', 'Accessories', 120.00),
('Bluetooth Speaker', 'Electronics', 95.00),
('Headphones', 'Electronics', 65.00);

-- =========================
-- Orders (20)
-- =========================
INSERT INTO orders (customer_id, order_date, total_amount) VALUES
(1, '2025-10-01', 1025.00),
(2, '2025-10-02', 70.00),
(3, '2025-10-03', 1250.00),
(4, '2025-10-04', 220.00),
(5, '2025-10-05', 90.00),
(6, '2025-10-06', 180.00),
(7, '2025-10-07', 600.00),
(8, '2025-10-08', 250.00),
(9, '2025-10-09', 115.00),
(10, '2025-10-10', 950.00),
(11, '2025-10-11', 300.00),
(12, '2025-10-12', 75.00),
(13, '2025-10-13', 185.00),
(14, '2025-10-14', 200.00),
(15, '2025-10-15', 220.00),
(16, '2025-10-16', 1045.00),
(17, '2025-10-17', 130.00),
(18, '2025-10-18', 170.00),
(19, '2025-10-19', 450.00),
(20, '2025-10-20', 300.00);

-- =========================
-- Order Items (20)
-- =========================
INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
(1, 1, 1, 1000.00),
(1, 2, 1, 25.00),
(2, 16, 1, 70.00),
(3, 5, 1, 850.00),
(3, 4, 1, 180.00),
(3, 19, 1, 95.00),
(4, 7, 1, 220.00),
(5, 10, 1, 90.00),
(6, 4, 1, 180.00),
(7, 11, 1, 600.00),
(8, 13, 1, 250.00),
(9, 8, 1, 115.00),
(10, 1, 1, 900.00),
(10, 2, 2, 25.00),
(11, 6, 2, 150.00),
(12, 14, 3, 25.00),
(13, 17, 1, 60.00),
(14, 9, 2, 45.00),
(15, 7, 1, 220.00),
(16, 12, 1, 1045.00);

-- =========================
-- Payments (20)
-- =========================
INSERT INTO payments (order_id, payment_method, payment_status, amount_paid, transaction_id, paid_at) VALUES
(1, 'Credit Card', 'Completed', 1025.00, 'TX10001', '2025-10-01 09:00'),
(2, 'Cash', 'Completed', 70.00, 'TX10002', '2025-10-02 11:30'),
(3, 'Credit Card', 'Completed', 1250.00, 'TX10003', '2025-10-03 14:00'),
(4, 'Bank Transfer', 'Pending', 0.00, 'TX10004', '2025-10-04 12:00'),
(5, 'Credit Card', 'Failed', 90.00, 'TX10005', '2025-10-05 15:00'),
(6, 'Credit Card', 'Completed', 180.00, 'TX10006', '2025-10-06 10:30'),
(7, 'Bank Transfer', 'Completed', 600.00, 'TX10007', '2025-10-07 13:00'),
(8, 'Credit Card', 'Completed', 250.00, 'TX10008', '2025-10-08 09:45'),
(9, 'PayPal', 'Completed', 115.00, 'TX10009', '2025-10-09 11:15'),
(10, 'Credit Card', 'Completed', 950.00, 'TX10010', '2025-10-10 10:00'),
(11, 'Cash', 'Completed', 300.00, 'TX10011', '2025-10-11 14:20'),
(12, 'Credit Card', 'Completed', 75.00, 'TX10012', '2025-10-12 16:00'),
(13, 'Credit Card', 'Pending', 0.00, 'TX10013', '2025-10-13 09:00'),
(14, 'Bank Transfer', 'Completed', 200.00, 'TX10014', '2025-10-14 10:15'),
(15, 'PayPal', 'Completed', 220.00, 'TX10015', '2025-10-15 17:00'),
(16, 'Credit Card', 'Completed', 1045.00, 'TX10016', '2025-10-16 12:00'),
(17, 'Cash', 'Completed', 130.00, 'TX10017', '2025-10-17 10:45'),
(18, 'Credit Card', 'Failed', 170.00, 'TX10018', '2025-10-18 15:00'),
(19, 'Credit Card', 'Completed', 450.00, 'TX10019', '2025-10-19 09:30'),
(20, 'Bank Transfer', 'Completed', 300.00, 'TX10020', '2025-10-20 11:10');

-- =========================
-- User Activity (20)
-- =========================
INSERT INTO customer_activities (customer_id, activity_type, product_id, order_id, metadata, activity_time) VALUES
(1, 'LOGIN', NULL, NULL, '{"device":"mobile"}', '2025-10-01 08:00'),
(1, 'VIEW_PRODUCT', 1, NULL, '{"page":"details"}', '2025-10-01 08:05'),
(1, 'ADD_TO_CART', 1, NULL, '{}', '2025-10-01 08:07'),
(1, 'CHECKOUT', NULL, 1, '{}', '2025-10-01 08:10'),
(2, 'LOGIN', NULL, NULL, '{"device":"desktop"}', '2025-10-02 10:00'),
(2, 'VIEW_PRODUCT', 16, NULL, '{}', '2025-10-02 10:05'),
(2, 'PAYMENT', NULL, 2, '{"method":"Cash"}', '2025-10-02 11:35'),
(3, 'LOGIN', NULL, NULL, '{"device":"mobile"}', '2025-10-03 09:00'),
(3, 'VIEW_PRODUCT', 5, NULL, '{}', '2025-10-03 09:10'),
(3, 'ADD_TO_CART', 5, NULL, '{}', '2025-10-03 09:15'),
(3, 'CHECKOUT', NULL, 3, '{}', '2025-10-03 09:30'),
(4, 'LOGIN', NULL, NULL, '{}', '2025-10-04 10:00'),
(5, 'LOGIN', NULL, NULL, '{}', '2025-10-05 09:00'),
(5, 'VIEW_PRODUCT', 10, NULL, '{}', '2025-10-05 09:05'),
(5, 'ADD_TO_CART', 10, NULL, '{}', '2025-10-05 09:10'),
(6, 'LOGIN', NULL, NULL, '{}', '2025-10-06 08:50'),
(7, 'LOGIN', NULL, NULL, '{}', '2025-10-07 09:00'),
(8, 'LOGIN', NULL, NULL, '{}', '2025-10-08 09:00'),
(9, 'LOGIN', NULL, NULL, '{}', '2025-10-09 09:00'),
(10, 'LOGIN', NULL, NULL, '{}', '2025-10-10 09:00');
