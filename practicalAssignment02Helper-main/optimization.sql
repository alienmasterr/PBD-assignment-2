-- не оптимізовано

-- In query to optimize you should use at least 2 joins (you have to join at least 3 tables)
SELECT
    clients.surname AS client_surname,
    clients.name as client_name,
    GROUP_CONCAT(products.product_name) AS product_names,
    GROUP_CONCAT(orders.order_date) AS order_dates
FROM
    opt_orders orders
JOIN
    opt_clients clients ON orders.client_id = clients.id
JOIN
    opt_products products ON orders.product_id = products.product_id
WHERE
    clients.status = 'active'
    AND LENGTH(clients.email) >= 10
    AND clients.phone LIKE '096%'
    AND clients.name LIKE 'A%'
    AND orders.order_date LIKE '2024-%'
GROUP BY
    clients.surname,
    clients.name;


--    оптимізовано
CREATE INDEX idx_client_status_email_phone_name ON opt_clients(status, email(10), phone, name);
CREATE INDEX idx_order_client_id ON opt_orders(client_id);
CREATE INDEX idx_order_product_id ON opt_orders(product_id);

WITH ActiveClients AS (
    SELECT
        id,
        surname,
        email,
        phone,
        name
    FROM
        opt_clients
    WHERE
        status = 'active'
        AND LENGTH(email) >= 10
        AND phone LIKE '096%'
        AND name LIKE 'A%'
)
SELECT
    ac.surname AS client_surname,
    ac.name AS client_name,
    p.product_name,
    orders.order_date
FROM
    opt_orders orders
JOIN
    ActiveClients ac ON orders.client_id = ac.id
JOIN
    opt_products p ON orders.product_id = p.product_id
WHERE
    orders.order_date LIKE '2024-%';

-- неоптимізована
EXPLAIN
SELECT
    clients.surname AS client_surname,
    clients.name as client_name,
    GROUP_CONCAT(products.product_name) AS product_names,
    GROUP_CONCAT(orders.order_date) AS order_dates
FROM
    opt_orders orders
JOIN
    opt_clients clients ON orders.client_id = clients.id
JOIN
    opt_products products ON orders.product_id = products.product_id
WHERE
    clients.status = 'active'
    AND LENGTH(clients.email) >= 10
    AND clients.phone LIKE '096%'
    AND clients.name LIKE 'A%'
    AND orders.order_date LIKE '2024-%'
GROUP BY
    clients.surname,
    clients.name;

-- optimized
EXPLAIN
WITH ActiveClients AS (
    SELECT
        id,
        surname,
        email,
        phone,
        name
    FROM
        opt_clients
    WHERE
        status = 'active'
        AND LENGTH(email) >= 10
        AND phone LIKE '096%'
        AND name LIKE 'Al%'
)
SELECT
    ac.surname AS client_surname,
    ac.name AS client_name,
    p.product_name,
    orders.order_date
FROM
    opt_orders orders
JOIN
    ActiveClients ac ON orders.client_id = ac.id
JOIN
    opt_products p ON orders.product_id = p.product_id
WHERE
    orders.order_date LIKE '2024-%';