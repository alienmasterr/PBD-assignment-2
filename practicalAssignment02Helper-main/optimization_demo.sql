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

