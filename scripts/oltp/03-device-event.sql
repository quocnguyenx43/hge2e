SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET default_tablespace = '';
SET default_with_oids = false;

CREATE TABLE device_events (
    event_id      SERIAL PRIMARY KEY,
    customer_id   VARCHAR(5) REFERENCES customers(customer_id),  -- keep consistent with Northwind PK
    device_id     VARCHAR(50) NOT NULL,                          -- unique device identifier
    device_type   VARCHAR(50) NOT NULL,                          -- e.g. 'mobile', 'tablet', 'sensor', 'POS'
    event_type    VARCHAR(50) NOT NULL,                          -- e.g. 'temperature', 'click', 'login', 'heartbeat'
    event_value   VARCHAR(100),                                  -- flexible for numbers or text
    ts            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- event timestamp
    metadata      JSONB                                          -- optional key/value details (location, OS, version)
);

INSERT INTO device_events (customer_id, device_id, device_type, event_type, event_value, ts, metadata)
VALUES
('ALFKI', 'dev_001', 'mobile', 'click', '/products/42', '2025-09-30 12:10:00', '{"referrer":"homepage"}'),
('ALFKI', 'dev_001', 'mobile', 'add_to_cart', '42', '2025-09-30 12:11:15', '{"qty":2}'),
('BERGS', 'dev_009', 'sensor', 'temperature', '28.5', '2025-09-30 12:12:45', '{"unit":"C","location":"warehouse-7"}'),
('BERGS', 'dev_009', 'sensor', 'heartbeat', 'OK', '2025-09-30 12:13:05', '{"interval_sec":60}');
