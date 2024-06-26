CREATE DATABASE IF NOT EXISTS opt_db;
USE opt_db;

CREATE TABLE IF NOT EXISTS opt_clients (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    status ENUM('active', 'inactive') NOT NULL
);

CREATE TABLE IF NOT EXISTS opt_products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    product_category ENUM('Category1', 'Category2', 'Category3', 'Category4', 'Category5') NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS opt_orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_date DATE NOT NULL,
    client_id CHAR(36),
    product_id INT,
    FOREIGN KEY (client_id) REFERENCES opt_clients(id),
    FOREIGN KEY (product_id) REFERENCES opt_products(product_id)
);

select * from opt_clients;
select * from opt_orders;
select * from opt_products;

--query is a request to get data from a database

-- не оптимізовано

SELECT
    clients.id,
    clients.name,
    clients.surname,
    clients.email,
    products.product_name,
    orders.order_date
FROM
    opt_clients AS clients
JOIN
    opt_orders AS orders ON clients.id = orders.client_id
JOIN
    opt_products AS products ON orders.product_id = products.product_id
WHERE
    clients.status = 'active'
    AND clients.name LIKE 'Anne'
    and clients.surname like 'M%'
    AND orders.order_date LIKE '2024-02%'

AND
        -- підзапит
    orders.order_date IN (
        SELECT order_date
        FROM opt_orders

        WHERE client_id = clients.id
    );



--    оптимізовано
CREATE INDEX idx_clients_status ON opt_clients(status);
CREATE INDEX idx_orders_client_id ON opt_orders(client_id);
CREATE INDEX idx_orders_product_id ON opt_orders(product_id);

WITH ClientOrders AS (
    SELECT
        orders.order_id,
        orders.order_date,
        orders.client_id,
        orders.product_id
    FROM
        opt_orders orders
    JOIN
        opt_clients clients ON orders.client_id = clients.id
    WHERE
        clients.status = 'active'
        AND clients.name LIKE 'Anne'
    	and clients.surname like 'M%'
    	AND orders.order_date LIKE '2024-02%'
)
SELECT
    clientOrders.client_id AS id,
    clients.name,
    clients.surname,
    clients.email,
    products.product_name,
    clientOrders.order_date
FROM
    ClientOrders AS clientOrders
JOIN
    opt_clients AS clients ON clientOrders.client_id = clients.id
JOIN
    opt_products AS products ON clientOrders.product_id = products.product_id
WHERE
    clientOrders.order_date IN (
        SELECT order_date
        -- 1
        FROM ClientOrders
        WHERE client_id = clientOrders.client_id
    )
AND
    clientOrders.client_id IN (
        SELECT client_id
        -- 2
        FROM ClientOrders
        WHERE order_date = clientOrders.order_date
    );


-- неоптимізована
EXPLAIN
SELECT
    clients.id,
    clients.name,
    clients.surname,
    clients.email,
    products.product_name,
    orders.order_date
FROM
    opt_clients AS clients
JOIN
    opt_orders AS orders ON clients.id = orders.client_id
JOIN
    opt_products AS products ON orders.product_id = products.product_id
WHERE
    clients.status = 'active'
    AND clients.name LIKE 'Anne'
    and clients.surname like 'M%'
    AND orders.order_date LIKE '2024-02%'

AND
        -- підзапит
    orders.order_date IN (
        SELECT order_date
        FROM opt_orders

        WHERE client_id = clients.id
    );

-- optimized
EXPLAIN
WITH ClientOrders AS (
    SELECT
        orders.order_id,
        orders.order_date,
        orders.client_id,
        orders.product_id
    FROM
        opt_orders orders
    JOIN
        opt_clients clients ON orders.client_id = clients.id
    WHERE
        clients.status = 'active'
        AND clients.name LIKE 'Anne'
    	and clients.surname like 'M%'
    	AND orders.order_date LIKE '2024-02%'
)
SELECT
    clientOrders.client_id AS id,
    clients.name,
    clients.surname,
    clients.email,
    products.product_name,
    clientOrders.order_date
FROM
    ClientOrders AS clientOrders
JOIN
    opt_clients AS clients ON clientOrders.client_id = clients.id
JOIN
    opt_products AS products ON clientOrders.product_id = products.product_id
WHERE
    clientOrders.order_date IN (
        SELECT order_date
        -- 1
        FROM ClientOrders
        WHERE client_id = clientOrders.client_id
    )
AND
    clientOrders.client_id IN (
        SELECT client_id
        -- 2
        FROM ClientOrders
        WHERE order_date = clientOrders.order_date
    );


-- приклади з гітхаба

-- Bad example
SELECT
    (SELECT CONCAT(product_name, ": ", cnt)
     FROM (SELECT product_name, COUNT(*) AS cnt
           FROM (SELECT o.order_id, o.order_date, p.product_id, p.product_name
                 FROM opt_orders o
                 JOIN opt_products p ON o.product_id = p.product_id
                 WHERE o.order_date > '2023-01-01') AS sub1
           GROUP BY product_name) AS sub2
     WHERE cnt = (SELECT MIN(cnt)
                  FROM (SELECT COUNT(*) AS cnt
                        FROM (SELECT o.order_id, o.order_date, p.product_id, p.product_name
                              FROM opt_orders o
                              JOIN opt_products p ON o.product_id = p.product_id
                              WHERE o.order_date > '2023-01-01') AS sub3
                        GROUP BY product_name) AS sub4)
     LIMIT 1) AS min_cnt,

    (SELECT CONCAT(product_name, ": ", cnt)
     FROM (SELECT product_name, COUNT(*) AS cnt
           FROM (SELECT o.order_id, o.order_date, p.product_id, p.product_name
                 FROM opt_orders o
                 JOIN opt_products p ON o.product_id = p.product_id
                 WHERE o.order_date > '2023-01-01') AS sub1
           GROUP BY product_name) AS sub2
     WHERE cnt = (SELECT MAX(cnt)
                  FROM (SELECT COUNT(*) AS cnt
                        FROM (SELECT o.order_id, o.order_date, p.product_id, p.product_name
                              FROM opt_orders o
                              JOIN opt_products p ON o.product_id = p.product_id
                              WHERE o.order_date > '2023-01-01') AS sub3
                        GROUP BY product_name) AS sub4)
     LIMIT 1) AS max_cnt;


-- Good example

CREATE INDEX idx_opt_orders_order_date
    ON opt_orders(order_date);

with cte as (
	select o.order_id, o.order_date, p.product_id, p.product_name
	from opt_orders  as o
	join opt_products  as p
	on o.product_id = p.product_id
	where o.order_date > '2023-01-01'
)
,

cnt_products as  (
select product_name, count(*) as cnt
from cte
group by product_name
)

select

(select concat(product_name, ": ", cnt) from cnt_products where cnt = (select min(cnt) as min_cnt from cnt_products) limit 1) as min_cnt,
(select concat(product_name, ": ", cnt) from cnt_products where cnt = (select max(cnt) as max_cnt from cnt_products) limit 1) as max_cnt

;

-- приклади з гітхаба