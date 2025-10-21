-- SQL Questions 241-270

-- 241. Calculate the moving average of sales over the last 3 days.
-- Calculate 3-day moving average of sales by product
SELECT sale_date, product_id, amount, 
       AVG(amount) OVER (PARTITION BY product_id ORDER BY sale_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_days 
FROM sales;

-- 242. Find the number of employees who share the same birthday.
-- Find employees with shared birthdays
SELECT birth_date, COUNT(*) AS count_employees
FROM employees 
GROUP BY birth_date
HAVING COUNT(*) > 1;

-- 243. Find customers who ordered the same product multiple times in one day.
-- Find customers with multiple same-product orders on same day
SELECT customer_id, product_id, order_date, COUNT(*) AS order_count
FROM sales
GROUP BY customer_id, product_id, order_date 
HAVING COUNT(*) > 1;

-- 244. Find the total sales for each product including products with zero sales.
-- Calculate total sales per product including zero sales
SELECT p.product_id, COALESCE(SUM(s.amount), 0) AS total_sales
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id;

-- 245. List the top 5 employees by number of projects in each department.
-- Find top project contributors per department
SELECT department_id, employee_id, project_count 
FROM (
    SELECT e.department_id, pa.employee_id,
           COUNT(DISTINCT pa.project_id) AS project_count, 
           ROW_NUMBER() OVER (PARTITION BY e.department_id ORDER BY COUNT(DISTINCT pa.project_id) DESC) AS rn
    FROM project_assignments pa
    JOIN employees e ON pa.employee_id = e.id 
    GROUP BY e.department_id, pa.employee_id 
) sub
WHERE rn <= 5;

-- 246. Find the day with the largest difference between maximum and minimum temperature.
-- Find day with highest temperature variance
SELECT weather_date, MAX(temperature) - MIN(temperature) AS temp_diff
FROM weather_data
GROUP BY weather_date
ORDER BY temp_diff DESC 
LIMIT 1;

-- 247. Find the 3 most recent orders per customer.
-- Get 3 latest orders per customer
SELECT order_id, customer_id, order_date
FROM (
    SELECT order_id, customer_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders
) sub
WHERE rn <= 3;

-- 248. Find products with sales only in a specific country.
-- Find products sold exclusively in one country
SELECT product_id 
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id 
GROUP BY product_id
HAVING COUNT(DISTINCT c.country) = 1;

-- 249. Find employees with a salary greater than all employees in department 10.
-- Find employees earning more than all dept 10 employees
SELECT *
FROM employees 
WHERE salary > ALL (
    SELECT salary 
    FROM employees 
    WHERE department_id = 10
);

-- 250. Find the percentage of employees in each department.
-- Calculate department employee distribution
WITH total_employees AS (SELECT COUNT(*) AS total FROM employees)
SELECT department_id, 
       COUNT(*) * 100.0 / (SELECT total FROM total_employees) AS percentage
FROM employees
GROUP BY department_id;

-- 251. Find the median salary per department.
-- Calculate median salary by department
SELECT department_id, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary 
FROM employees
GROUP BY department_id;

-- 252. Find the employee who worked the most hours in a project.
-- Find employee with highest project hours
SELECT employee_id, project_id, MAX(hours_worked) AS max_hours 
FROM project_assignments
GROUP BY employee_id, project_id 
ORDER BY max_hours DESC
LIMIT 1;

-- 253. Find the first order date for each customer.
-- Get earliest order date per customer
SELECT customer_id, MIN(order_date) AS first_order_date
FROM orders
GROUP BY customer_id;

-- 254. Find the second most expensive product per category.
-- Find second highest priced product per category
SELECT category_id, product_id, price 
FROM (
    SELECT category_id, product_id, price,
           ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rn 
    FROM products
) sub
WHERE rn = 2;

-- 255. Find employees with the highest salary in each job title.
-- Find top earner per job title
WITH max_salary_per_job AS (
    SELECT job_title, MAX(salary) AS max_salary
    FROM employees
    GROUP BY job_title
)
SELECT e.*
FROM employees e
JOIN max_salary_per_job m ON e.job_title = m.job_title AND e.salary = m.max_salary;

-- 256. Calculate the ratio of males to females in each department.
-- Calculate gender ratio by department
SELECT department_id,
       SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) * 1.0 / 
       NULLIF(SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END), 0) AS male_to_female_ratio 
FROM employees
GROUP BY department_id;

-- 257. Find customers who spent more than average in their country.
-- Find above-average spenders by country
WITH avg_spent_per_country AS (
    SELECT c.country, AVG(o.amount) AS avg_amount 
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id 
    GROUP BY c.country
)
SELECT c.customer_id, SUM(o.amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id 
JOIN avg_spent_per_country a ON c.country = a.country
GROUP BY c.customer_id, c.country, a.avg_amount 
HAVING SUM(o.amount) > a.avg_amount;

-- 258. Find employees who have not been assigned to any project in the last year.
-- Find employees without recent project assignments
SELECT e.*
FROM employees e
LEFT JOIN project_assignments pa ON e.id = pa.employee_id 
    AND pa.assignment_date >= CURRENT_DATE - INTERVAL '1 year' 
WHERE pa.project_id IS NULL;

-- 259. Find the top 3 customers by total order amount in each region.
-- Find top customers by region
SELECT region, customer_id, total_amount 
FROM (
    SELECT c.region, o.customer_id, SUM(o.amount) AS total_amount,
           ROW_NUMBER() OVER (PARTITION BY c.region ORDER BY SUM(o.amount) DESC) AS rn
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.region, o.customer_id 
) sub
WHERE rn <= 3;

-- 260. Find employees hired after their managers.
-- Find employees hired after their manager
SELECT e.name AS employee_name, m.name AS manager_name, 
       e.hire_date, m.hire_date AS manager_hire_date 
FROM employees e
JOIN employees m ON e.manager_id = m.id
WHERE e.hire_date > m.hire_date;

-- 261. Find customers who ordered all products from a specific category.
-- Find customers who purchased entire product category
WITH category_products AS (
    SELECT product_id 
    FROM products
    WHERE category_id = 1 -- replace with specific category_id
),
customer_products AS (
    SELECT customer_id, product_id 
    FROM sales
    WHERE product_id IN (SELECT product_id FROM category_products)
    GROUP BY customer_id, product_id
)
SELECT customer_id
FROM customer_products 
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (SELECT COUNT(*) FROM category_products);

-- 262. Find employees with the highest number of direct reports.
-- Find manager with most direct reports
SELECT manager_id, COUNT(*) AS report_count 
FROM employees
WHERE manager_id IS NOT NULL
GROUP BY manager_id
ORDER BY report_count DESC
LIMIT 1;

-- 263. Calculate the retention rate of customers month-over-month.
-- Calculate customer retention rate
WITH monthly_customers AS (
    SELECT customer_id, DATE_TRUNC('month', order_date) AS month
    FROM orders
    GROUP BY customer_id, month
),
retention AS (
    SELECT current.month AS current_month, current.customer_id
    FROM monthly_customers current
    JOIN monthly_customers previous ON current.customer_id = previous.customer_id
        AND current.month = previous.month + INTERVAL '1 month'
)
SELECT current_month, 
       COUNT(DISTINCT customer_id) * 100.0 / (
           SELECT COUNT(DISTINCT customer_id)
           FROM monthly_customers
           WHERE month = current_month - INTERVAL '1 month'
       ) AS retention_rate
FROM retention
GROUP BY current_month
ORDER BY current_month;

-- 264. Find the average time difference between order and delivery.
-- Calculate average delivery time
SELECT AVG(delivery_date - order_date) AS avg_delivery_time 
FROM orders
WHERE delivery_date IS NOT NULL;

-- 265. Find the department with the youngest average employee age.
-- Find department with youngest workforce
SELECT department_id, 
       AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))) AS avg_age
FROM employees
GROUP BY department_id 
ORDER BY avg_age
LIMIT 1;

-- 266. Find products that were sold in every quarter of the current year.
-- Find products sold in all quarters of current year
WITH quarterly_sales AS (
    SELECT product_id, DATE_TRUNC('quarter', sale_date) AS quarter 
    FROM sales
    WHERE EXTRACT(YEAR FROM sale_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY product_id, quarter 
)
SELECT product_id 
FROM quarterly_sales
GROUP BY product_id
HAVING COUNT(DISTINCT quarter) = 4;

-- 267. Find customers whose orders decreased consecutively for 3 months.
-- Find customers with declining order trend
WITH monthly_orders AS (
    SELECT customer_id, 
           DATE_TRUNC('month', order_date) AS month, 
           COUNT(*) AS order_count 
    FROM orders
    GROUP BY customer_id, month
),
orders_with_lag AS (
    SELECT customer_id, month, order_count, 
           LAG(order_count, 1) OVER (PARTITION BY customer_id ORDER BY month) AS prev_1, 
           LAG(order_count, 2) OVER (PARTITION BY customer_id ORDER BY month) AS prev_2
    FROM monthly_orders 
)
SELECT DISTINCT customer_id
FROM orders_with_lag
WHERE order_count < prev_1 AND prev_1 < prev_2;

-- 268. Find the employee(s) with the highest number of late arrivals.
-- Find employees with most tardiness
SELECT employee_id, COUNT(*) AS late_count 
FROM attendance
WHERE arrival_time > scheduled_start_time
GROUP BY employee_id 
ORDER BY late_count DESC
LIMIT 1;

-- 269. Find the most common product combinations in orders (pairs).
-- Find frequently ordered product pairs
WITH order_pairs AS (
    SELECT o1.order_id, o1.product_id AS product1, o2.product_id AS product2 
    FROM order_items o1
    JOIN order_items o2 ON o1.order_id = o2.order_id
        AND o1.product_id < o2.product_id 
)
SELECT product1, product2, COUNT(*) AS pair_count
FROM order_pairs
GROUP BY product1, product2
ORDER BY pair_count DESC
LIMIT 10;

-- 270. Find employees who have worked more than 40 hours in a week.
-- Find employees with overtime hours
WITH weekly_hours AS (
    SELECT employee_id, 
           DATE_TRUNC('week', work_date) AS week_start, 
           SUM(hours_worked) AS total_hours
    FROM work_logs
    GROUP BY employee_id, week_start
)
SELECT employee_id, week_start, total_hours 
FROM weekly_hours
WHERE total_hours > 40;