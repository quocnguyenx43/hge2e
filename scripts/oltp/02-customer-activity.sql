SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET default_tablespace = '';
SET default_with_oids = false;

CREATE TABLE customer_activity (
    activity_id      SERIAL PRIMARY KEY,
    customer_id      VARCHAR(5) NOT NULL REFERENCES customers(customer_id),
    session_id       VARCHAR(50) NOT NULL,
    activity_type    VARCHAR(30) NOT NULL,  -- e.g. 'page_view', 'search', 'add_to_cart', 'checkout'
    product_id       SMALLINT REFERENCES products(product_id),
    activity_time    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metadata         JSONB  -- flexible for extra info: device, referrer, geo, etc.
);

INSERT INTO customer_activity (customer_id, session_id, activity_type, product_id, activity_time, metadata)
VALUES
('ALFKI', 'sess_123', 'page_view', 42, '2025-09-30 09:10:00', '{"referrer": "homepage"}'),
('CENTC', 'sess_124', 'add_to_cart', 42, '2025-09-30 09:11:15', '{"qty": 2}'),
('ALFKI', 'sess_123', 'checkout', NULL, '2025-09-30 09:12:00', '{}'),
('EASTC', 'sess_125', 'purchase', NULL, '2025-09-30 09:12:45', '{"order_id": 11077}');
