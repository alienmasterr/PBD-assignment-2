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


-- не оптимізовано

-- In query to optimize you should use at least 2 joins (you have to join at least 3 tables)
SELECT
    clients.surname AS client_surname,
    clients.name as client_name,
    --порушуємо нормальну форму.
    GROUP_CONCAT(products.product_name) AS product_names,
    GROUP_CONCAT(orders.order_date) AS order_dates
FROM
    opt_orders orders
JOIN
    --джойнимо 2 таблички (клієнти і ордери) за айдішкою клієнта
    opt_clients clients ON orders.client_id = clients.id
JOIN
    --джойними 2 таблички (продукти і ордери) за айдішкою продукту
    opt_products products ON orders.product_id = products.product_id
WHERE
    --фільтруємо, все що знайшли
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