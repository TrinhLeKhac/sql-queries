-- SQL Questions 211-240

-- 211. Find customers with average order amount above $500.
-- Find high-value customers with average orders over $500
SELECT customer_id, AVG(amount) AS avg_order_amount
FROM orders
GROUP BY customer_id 
HAVING AVG(amount) > 500;

-- 212. Find orders where the total quantity exceeds 100 units.
-- Find large orders with total quantity over 100
SELECT order_id, SUM(quantity) AS total_quantity 
FROM order_items
GROUP BY order_id
HAVING SUM(quantity) > 100;

-- 213. Find products whose sales have doubled compared to the previous month.
-- Find products with 100% month-over-month sales growth
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    GROUP BY product_id, month
),
sales_comparison AS (
    SELECT product_id, month, total_sales, 
           LAG(total_sales) OVER (PARTITION BY product_id ORDER BY month) AS prev_month_sales 
    FROM monthly_sales
)
SELECT product_id, month
FROM sales_comparison
WHERE prev_month_sales IS NOT NULL 
  AND total_sales >= 2 * prev_month_sales;

-- 214. Write a query to find employees who worked on more than 3 projects in 2023.
-- Find employees with high project activity in 2023
SELECT employee_id, COUNT(DISTINCT project_id) AS project_count
FROM project_assignments
WHERE assignment_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY employee_id
HAVING COUNT(DISTINCT project_id) > 3;

-- 215. Find customers whose last order was placed more than 1 year ago.
-- Find inactive customers with no recent orders
SELECT customer_id, MAX(order_date) AS last_order_date
FROM orders
GROUP BY customer_id
HAVING MAX(order_date) < CURRENT_DATE - INTERVAL '1 year';

-- 216. Find the average salary increase percentage per department.
-- Calculate average salary increase by department
SELECT e.department_id, 
       AVG((e.salary - p.old_salary) / p.old_salary * 100) AS avg_increase_pct
FROM employees e
JOIN promotions p ON e.id = p.employee_id 
GROUP BY e.department_id;

-- 217. Find employees who have never been promoted.
-- Find employees with no promotion history
SELECT *
FROM employees
WHERE id NOT IN (SELECT DISTINCT employee_id FROM promotions);

-- 218. Find products ordered by all customers.
-- Find universally ordered products
SELECT product_id 
FROM sales
GROUP BY product_id
HAVING COUNT(DISTINCT customer_id) = (SELECT COUNT(*) FROM customers);

-- 219. Find customers with orders totaling more than $5000 in the last 6 months.
-- Find high-value customers in recent period
SELECT customer_id, SUM(amount) AS total_amount 
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY customer_id 
HAVING SUM(amount) > 5000;

-- 220. Find the rank of employees based on salary within their department.
-- Rank employees by salary within department
SELECT *, 
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank 
FROM employees;

-- 221. Find customers who purchased a product but never reordered it.
-- Find one-time product purchasers
WITH order_counts AS (
    SELECT customer_id, product_id, COUNT(*) AS order_count
    FROM sales
    GROUP BY customer_id, product_id
)
SELECT customer_id, product_id 
FROM order_counts
WHERE order_count = 1;

-- 222. Find the day with the highest number of new hires.
-- Find peak hiring day
SELECT hire_date, COUNT(*) AS hires
FROM employees 
GROUP BY hire_date
ORDER BY hires DESC
LIMIT 1;

-- 223. Find the number of employees who have worked in more than one department.
-- Count employees with multi-department experience
SELECT COUNT(DISTINCT employee_id) AS multi_dept_employees
FROM employee_department_history 
GROUP BY employee_id
HAVING COUNT(DISTINCT department_id) > 1;

-- 224. Find customers who ordered the most products in 2023.
-- Find top customer by product quantity in 2023
SELECT customer_id, SUM(quantity) AS total_quantity
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2023 
GROUP BY customer_id
ORDER BY total_quantity DESC 
LIMIT 1;

-- 225. Find the average days taken to ship orders per shipping method.
-- Calculate average shipping time by method
SELECT shipping_method, AVG(shipping_date - order_date) AS avg_shipping_days
FROM orders
GROUP BY shipping_method;

-- 226. Find employees with overlapping project assignments.
-- Find employees with concurrent project assignments
SELECT pa1.employee_id, pa1.project_id, pa2.project_id AS overlapping_project
FROM project_assignments pa1
JOIN project_assignments pa2 ON pa1.employee_id = pa2.employee_id 
    AND pa1.project_id < pa2.project_id
WHERE pa1.start_date <= pa2.end_date AND pa1.end_date >= pa2.start_date;

-- 227. Find the total number of unique customers per product category.
-- Count unique customers by product category
SELECT p.category_id, COUNT(DISTINCT s.customer_id) AS unique_customers
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.category_id;

-- 228. Find customers whose orders increased by at least 20% compared to the previous month.
-- Find customers with significant order growth
WITH monthly_orders AS (
    SELECT customer_id, 
           DATE_TRUNC('month', order_date) AS month, 
           COUNT(*) AS order_count 
    FROM orders
    GROUP BY customer_id, month
),
orders_comparison AS (
    SELECT customer_id, month, order_count,
           LAG(order_count) OVER (PARTITION BY customer_id ORDER BY month) AS prev_order_count 
    FROM monthly_orders
)
SELECT customer_id, month
FROM orders_comparison
WHERE prev_order_count IS NOT NULL 
  AND order_count >= 1.2 * prev_order_count;

-- 229. Find employees with no projects assigned in the last 6 months.
-- Find employees without recent project assignments
SELECT e.*
FROM employees e
LEFT JOIN project_assignments pa ON e.id = pa.employee_id 
    AND pa.start_date >= CURRENT_DATE - INTERVAL '6 months' 
WHERE pa.project_id IS NULL;

-- 230. Find the number of employees who have changed departments more than twice.
-- Count employees with frequent department changes
SELECT COUNT(DISTINCT employee_id) AS frequent_changers
FROM employee_department_history 
GROUP BY employee_id
HAVING COUNT(DISTINCT department_id) > 2;

-- 231. Find the product with the highest average rating.
-- Find top-rated product
SELECT product_id, AVG(rating) AS avg_rating 
FROM product_reviews
GROUP BY product_id
ORDER BY avg_rating DESC 
LIMIT 1;

-- 232. Find customers who have placed orders but never used a discount.
-- Find customers who never used discounts
SELECT DISTINCT customer_id 
FROM orders
WHERE discount_used = FALSE;

-- 233. Find employees who have worked on every project in their department.
-- Find employees assigned to all departmental projects
SELECT e.id, e.name
FROM employees e
JOIN projects p ON e.department_id = p.department_id
LEFT JOIN project_assignments pa ON e.id = pa.employee_id AND p.project_id = pa.project_id 
GROUP BY e.id, e.name, p.department_id
HAVING COUNT(p.project_id) = COUNT(pa.project_id);

-- 234. Find the average order amount excluding the top 5% largest orders.
-- Calculate average order excluding outliers
WITH ordered_orders AS (
    SELECT amount,
           NTILE(100) OVER (ORDER BY amount DESC) AS percentile 
    FROM orders
)
SELECT AVG(amount) AS avg_excluding_top5pct
FROM ordered_orders
WHERE percentile > 5;

-- 235. Find the top 3 employees with the highest salary increase over last year.
-- Find employees with highest salary growth
WITH salary_last_year AS (
    SELECT employee_id, salary AS last_year_salary 
    FROM salaries
    WHERE year = EXTRACT(YEAR FROM CURRENT_DATE) - 1
),
salary_this_year AS (
    SELECT employee_id, salary AS this_year_salary
    FROM salaries
    WHERE year = EXTRACT(YEAR FROM CURRENT_DATE)
)
SELECT t.employee_id, t.this_year_salary - l.last_year_salary AS salary_increase
FROM salary_this_year t
JOIN salary_last_year l ON t.employee_id = l.employee_id
ORDER BY salary_increase DESC
LIMIT 3;

-- 236. Find employees with the longest consecutive workdays.
-- Find employees with longest consecutive work periods
WITH workdays AS (
    SELECT employee_id, work_date,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY work_date) - 
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY work_date) AS grp 
    FROM attendance
),
consecutive_days AS (
    SELECT employee_id, COUNT(*) AS consecutive_days
    FROM workdays
    GROUP BY employee_id, grp
)
SELECT employee_id, MAX(consecutive_days) AS max_consecutive_days 
FROM consecutive_days 
GROUP BY employee_id;

-- 237. Find all managers who do not manage any employee.
-- Find managers without direct reports
SELECT DISTINCT manager_id
FROM employees
WHERE manager_id NOT IN (SELECT DISTINCT id FROM employees WHERE manager_id IS NOT NULL);

-- 238. Find the average salary of employees hired each month.
-- Calculate average salary by hire month
SELECT EXTRACT(YEAR FROM hire_date) AS year, 
       EXTRACT(MONTH FROM hire_date) AS month, 
       AVG(salary) AS avg_salary
FROM employees
GROUP BY year, month 
ORDER BY year, month;

-- 239. Find the first 5 orders after a customer's registration date.
-- Get initial orders after customer registration
SELECT order_id, customer_id, order_date 
FROM (
    SELECT order_id, customer_id, order_date, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS rn 
    FROM orders
    JOIN customers c ON orders.customer_id = c.customer_id
    WHERE order_date >= c.registration_date
) sub
WHERE rn <= 5;

-- 240. Find customers who placed orders every month for the last 6 months.
-- Find consistently active customers
WITH months AS (
    SELECT generate_series(
        DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '5 months',
        DATE_TRUNC('month', CURRENT_DATE), 
        INTERVAL '1 month'
    ) AS month
),
customer_months AS (
    SELECT customer_id, DATE_TRUNC('month', order_date) AS month
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT customer_id
FROM customer_months cm
JOIN months m ON cm.month = m.month 
GROUP BY customer_id
HAVING COUNT(DISTINCT cm.month) = 6;