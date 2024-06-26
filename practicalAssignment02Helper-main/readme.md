# Practical assignment 2

### The purpose of this task

Learn how to optimize queries in MySQL.

### Requirements (_for 11 points_):

Provide optimization step-by-step query of a complex query with execution plan comparison.

1. In query to optimize you should use at least 2 joins (you have to join at least 3 tables).
2. You have to have at least 10000 rows in each table.
3. You should demonstrate 2 variants of the query: optimized and non-optimized.
4. Your 2 query variants have to return the same result.
5. You should use CTE for optimization.
6. You must use the index/indexes for optimization.
7. You must show a comparison of execution plans.
8. Your code  should be on Github. 
9. Explain your solution using the correct terminology. 
10. Be ready to answer questions about query optimization.

### Additional info
I suggest you look at my example of the task, which is described below (MySQL Optimization Demo).

### MySQL Optimization Demo

#### Requirements
- Python 3.9.6
- MySQL Server
- `mysql-connector-python` package
- `Faker` package
- `python-dotenv` package

### How to run
- Run **script_01_create_tables.sql** in your database.
- Set environment variables (host, user, password, database).
- Run: 
- ```sh 
  pip install -r requirements.txt
- Run **main.py** to insert fake data to the tables.
- Execute queries from **optimization_demo.sql** in your database using EXPLAIN.
