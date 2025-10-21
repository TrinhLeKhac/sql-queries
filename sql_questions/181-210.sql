-- SQL Questions 181-210

-- 181. List employees who have been in the company for more than 10 years.
-- Find long-tenured employees (over 10 years)
SELECT *
FROM employees
WHERE CURRENT_DATE - hire_date > INTERVAL '10 years';

-- 182. Find the department with the most promotions.
-- Find department with highest promotion count
SELECT e.department_id, COUNT(*) AS promotion_count
FROM promotions p
JOIN employees e ON p.employee_id = e.id 
GROUP BY e.department_id
ORDER BY promotion_count DESC
LIMIT 1;

-- 183. Find customers who ordered products from at least 3 different categories.
-- Find customers purchasing from multiple categories
SELECT customer_id
FROM sales s
JOIN products p ON s.product_id = p.product_id 
GROUP BY customer_id
HAVING COUNT(DISTINCT p.category_id) >= 3;

-- 184. Find the average gap (in days) between orders per customer.
-- Calculate average days between orders per customer
WITH ordered_orders AS (
    SELECT customer_id, order_date,
           LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date
    FROM orders
),
gaps AS (
    SELECT customer_id, order_date - prev_order_date AS gap
    FROM ordered_orders
    WHERE prev_order_date IS NOT NULL 
)
SELECT customer_id, AVG(gap) AS avg_gap_days 
FROM gaps
GROUP BY customer_id;

-- 185. List all customers who have never ordered product X.
-- Find customers who never ordered a specific product
SELECT customer_id 
FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM sales
    WHERE product_id = 'X'
);

-- 186. Calculate total revenue and number of orders per country.
-- Calculate revenue and order metrics by country
SELECT c.country, COUNT(o.order_id) AS order_count, SUM(o.amount) AS total_revenue 
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY c.country;

-- 187. Find the employees who were hired on the same day as their managers.
-- Find employees hired same day as their manager
SELECT e.name AS employee, m.name AS manager, e.hire_date
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.hire_date = m.hire_date;

-- 188. Find the top 3 products by quantity sold in each category.
-- Find top 3 products by quantity per category
SELECT category_id, product_id, total_quantity 
FROM (
    SELECT p.category_id, s.product_id,
           SUM(s.quantity) AS total_quantity, 
           ROW_NUMBER() OVER (PARTITION BY p.category_id ORDER BY SUM(s.quantity) DESC) AS rn
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY p.category_id, s.product_id 
) sub
WHERE rn <= 3;

-- 189. Find the difference in days between the first and last order for each customer.
-- Calculate days between first and last order per customer
SELECT customer_id, MAX(order_date) - MIN(order_date) AS days_between
FROM orders
GROUP BY customer_id;

-- 190. Find customers who have increased their order volume every month for the last 3 months.
-- Find customers with consistent monthly order growth
WITH monthly_orders AS (
    SELECT customer_id, 
           DATE_TRUNC('month', order_date) AS month, 
           COUNT(*) AS orders_count 
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY customer_id, month
)
SELECT customer_id
FROM monthly_orders 
GROUP BY customer_id
HAVING COUNT(*) = 3
   AND MIN(orders_count) < MAX(orders_count);
-- Note: Needs detailed window check for strict increase

-- 191. Find employees who have the same salary as the average salary in their job title.
-- Find employees earning their job title average
SELECT e.*
FROM employees e 
JOIN (
    SELECT job_title, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY job_title
) j ON e.job_title = j.job_title 
WHERE e.salary = j.avg_salary;

-- 192. Write a query to calculate the difference in salary between employees and their managers.
-- Calculate salary difference between employee and manager
SELECT e.name, m.name AS manager_name, 
       e.salary, m.salary AS manager_salary, 
       e.salary - m.salary AS salary_diff
FROM employees e
JOIN employees m ON e.manager_id = m.id;

-- 193. List the departments with no employees.
-- Find departments without any employees
SELECT d.*
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id 
WHERE e.id IS NULL;

-- 194. Find the employee with the maximum salary in each department.
-- Find highest paid employee per department
WITH dept_max AS (
    SELECT department_id, MAX(salary) AS max_salary
    FROM employees
    GROUP BY department_id
)
SELECT e.*
FROM employees e
JOIN dept_max d ON e.department_id = d.department_id AND e.salary = d.max_salary;

-- 195. Find customers with orders on every day in the last week.
-- Find customers with daily orders in past week
WITH days AS (
    SELECT generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, INTERVAL '1 day') AS day
)
SELECT customer_id
FROM orders o
JOIN days d ON o.order_date = d.day
GROUP BY customer_id
HAVING COUNT(DISTINCT o.order_date) = 7;

-- 196. Find the product that has been sold in the highest quantity in a single order.
-- Find product with highest single-order quantity
SELECT product_id, MAX(quantity) AS max_quantity_in_order 
FROM sales
GROUP BY product_id
ORDER BY max_quantity_in_order DESC 
LIMIT 1;

-- 197. Find employees who joined before their department was created.
-- Find employees hired before department creation
SELECT e.*
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.hire_date < d.creation_date;

-- 198. Find customers with sales in at least 3 different years.
-- Find customers with multi-year purchase history
SELECT customer_id 
FROM sales
GROUP BY customer_id
HAVING COUNT(DISTINCT EXTRACT(YEAR FROM sale_date)) >= 3;

-- 199. Find employees whose salary is above the company's average but below their department's average.
-- Find employees above company average but below department average
WITH company_avg AS (SELECT AVG(salary) AS avg_salary FROM employees),
dept_avg AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id 
)
SELECT e.*
FROM employees e, company_avg ca 
JOIN dept_avg da ON e.department_id = da.department_id
WHERE e.salary > ca.avg_salary AND e.salary < da.avg_salary;

-- 200. Find the average order amount per customer per year.
-- Calculate average order amount by customer and year
SELECT customer_id, 
       EXTRACT(YEAR FROM order_date) AS year, 
       AVG(amount) AS avg_order_amount
FROM orders
GROUP BY customer_id, year;

-- 201. Find employees who have worked on at least one project with a budget over $1,000,000.
-- Find employees on high-budget projects
SELECT DISTINCT pa.employee_id 
FROM project_assignments pa
JOIN projects p ON pa.project_id = p.project_id
WHERE p.budget > 1000000;

-- 202. Find the most recent promotion date per employee.
-- Get latest promotion date per employee
SELECT employee_id, MAX(promotion_date) AS last_promotion_date
FROM promotions 
GROUP BY employee_id;

-- 203. Find customers who made orders totaling more than the average order amount.
-- Find customers with above-average total orders
WITH avg_order AS (
    SELECT AVG(amount) AS avg_amount 
    FROM orders
)
SELECT customer_id, SUM(amount) AS total_amount 
FROM orders
GROUP BY customer_id
HAVING SUM(amount) > (SELECT avg_amount FROM avg_order);

-- 204. Find products never ordered.
-- Find products with no order history
SELECT product_id
FROM products
WHERE product_id NOT IN (SELECT DISTINCT product_id FROM sales);

-- 205. Find the month with the lowest sales in the past year.
-- Find lowest sales month in past year
SELECT DATE_TRUNC('month', sale_date) AS month, SUM(amount) AS total_sales 
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '1 year' 
GROUP BY month
ORDER BY total_sales
LIMIT 1;

-- 206. Calculate the number of employees hired each month in the last year.
-- Count monthly hires in past year
SELECT DATE_TRUNC('month', hire_date) AS month, COUNT(*) AS hires
FROM employees
WHERE hire_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY month 
ORDER BY month;

-- 207. Find the department with the highest number of projects.
-- Find department with most projects
SELECT department_id, COUNT(*) AS project_count 
FROM projects
GROUP BY department_id
ORDER BY project_count DESC
LIMIT 1;

-- 208. Find employees who do not have dependents.
-- Find employees with no dependents
SELECT e.*
FROM employees e
LEFT JOIN dependents d ON e.id = d.employee_id
WHERE d.dependent_id IS NULL;

-- 209. Get the total sales amount for each product category including categories with zero sales.
-- Calculate total sales per category including zero sales
SELECT c.category_id, COALESCE(SUM(s.amount), 0) AS total_sales
FROM categories c
LEFT JOIN products p ON c.category_id = p.category_id
LEFT JOIN sales s ON p.product_id = s.product_id 
GROUP BY c.category_id;

-- 210. Find employees who have been promoted but their salary didn't increase.
-- Find employees promoted without salary increase
SELECT e.id, e.name 
FROM employees e
JOIN promotions p ON e.id = p.employee_id 
WHERE e.salary <= (
    SELECT salary_before 
    FROM promotion_history 
    WHERE employee_id = e.id 
    ORDER BY promotion_date DESC 
    LIMIT 1
);