-- SQL Questions 121-150

-- 121. Find the first order date for each customer.
-- Get the earliest order date per customer
SELECT customer_id, MIN(order_date) AS first_order_date
FROM orders
GROUP BY customer_id;

-- 122. Find employees who have been promoted more than twice.
-- Find employees with more than 2 promotions
SELECT employee_id, COUNT(*) AS promotion_count
FROM promotions
GROUP BY employee_id
HAVING COUNT(*) > 2;

-- 123. Find employees who have not been assigned to any project.
-- Find employees with no project assignments
SELECT e.*
FROM employees e
LEFT JOIN project_assignments pa ON e.id = pa.employee_id
WHERE pa.project_id IS NULL;

-- 124. Find the total sales per customer including those with zero sales.
-- Calculate total sales per customer including zero sales
SELECT c.customer_id, COALESCE(SUM(s.amount), 0) AS total_sales
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id;

-- 125. Find the highest salary by department and the employee(s) who earn it.
-- Find highest paid employees per department
WITH dept_max AS (
    SELECT department_id, MAX(salary) AS max_salary 
    FROM employees
    GROUP BY department_id
)
SELECT e.*
FROM employees e
JOIN dept_max d ON e.department_id = d.department_id AND e.salary = d.max_salary;

-- 126. Find customers with no orders in the last year.
-- Find customers without orders in past year
SELECT customer_id 
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_date >= CURRENT_DATE - INTERVAL '1 year'
WHERE o.order_id IS NULL;

-- 127. Find employees whose salary is within 10% of the highest salary in their department.
-- Find employees earning within 10% of department maximum
WITH dept_max AS (
    SELECT department_id, MAX(salary) AS max_salary 
    FROM employees
    GROUP BY department_id
)
SELECT e.*
FROM employees e
JOIN dept_max d ON e.department_id = d.department_id
WHERE e.salary >= 0.9 * d.max_salary;

-- 128. Find the running total of sales by date.
-- Calculate running total of sales by date
SELECT sale_date, 
       SUM(amount) OVER (ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total 
FROM sales
ORDER BY sale_date;

-- 129. Find employees who earn more than the average salary of the entire company.
-- Find employees earning above company average
SELECT *
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- 130. Get the last 3 orders placed by each customer.
-- Get 3 most recent orders per customer
SELECT *
FROM (
    SELECT o.*, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders o
) sub
WHERE rn <= 3;

-- 131. Find the difference in days between the earliest and latest orders per customer.
-- Calculate days between first and last order per customer
SELECT customer_id, MAX(order_date) - MIN(order_date) AS days_between
FROM orders
GROUP BY customer_id;

-- 132. Find employees who have worked on all projects.
-- Find employees assigned to every project
SELECT employee_id 
FROM project_assignments
GROUP BY employee_id
HAVING COUNT(DISTINCT project_id) = (SELECT COUNT(*) FROM projects);

-- 133. Find customers who placed orders only in the last 6 months.
-- Find customers with orders exclusively in past 6 months
SELECT customer_id
FROM orders
GROUP BY customer_id
HAVING MIN(order_date) >= CURRENT_DATE - INTERVAL '6 months';

-- 134. Get the total number of orders per day, including days with zero orders.
-- Count orders per day including zero-order days
WITH dates AS (
    SELECT generate_series(MIN(order_date), MAX(order_date), INTERVAL '1 day') AS day 
    FROM orders
)
SELECT d.day, COUNT(o.order_id) AS order_count
FROM dates d
LEFT JOIN orders o ON d.day = o.order_date 
GROUP BY d.day
ORDER BY d.day;

-- 135. Find the department with the most employees.
-- Find department with highest employee count
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
ORDER BY employee_count DESC 
LIMIT 1;

-- 136. Write a query to find gaps in employee IDs.
-- Find missing employee IDs in sequence
WITH numbered AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
    FROM employees
)
SELECT rn + 1 AS missing_id 
FROM numbered
WHERE id != rn;

-- 137. Find employees who were hired before their managers.
-- Find employees hired before their manager
SELECT e.name AS employee, m.name AS manager, 
       e.hire_date, m.hire_date AS manager_hire_date 
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.hire_date < m.hire_date;

-- 138. List departments with average salary greater than the overall average.
-- Find departments with above-average salaries
SELECT department_id, AVG(salary) AS avg_salary 
FROM employees
GROUP BY department_id
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees);

-- 139. Find employees with the highest number of dependents.
-- Find employees with most dependents
SELECT employee_id, COUNT(*) AS dependent_count
FROM dependents 
GROUP BY employee_id
ORDER BY dependent_count DESC 
LIMIT 1;

-- 140. Find customers with the longest gap between two consecutive orders.
-- Find customers with longest gap between consecutive orders
WITH ordered_orders AS (
    SELECT customer_id, order_date,
           LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date 
    FROM orders
),
gaps AS (
    SELECT customer_id, order_date - prev_order_date AS gap_days
    FROM ordered_orders
    WHERE prev_order_date IS NOT NULL
)
SELECT customer_id, MAX(gap_days) AS longest_gap
FROM gaps
GROUP BY customer_id
ORDER BY longest_gap DESC 
LIMIT 1;

-- 141. Find customers who ordered all products in a category.
-- Find customers who ordered every product in category 1
SELECT customer_id
FROM sales
WHERE product_id IN (SELECT product_id FROM products WHERE category_id = 1)
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (SELECT COUNT(*) FROM products WHERE category_id = 1);

-- 142. Get the most recent order date per customer.
-- Get latest order date per customer
SELECT customer_id, MAX(order_date) AS last_order_date
FROM orders
GROUP BY customer_id;

-- 143. List all employees and their manager names.
-- List employees with their manager names
SELECT e.name AS employee, m.name AS manager 
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;

-- 144. Find employees with the same salary as their manager.
-- Find employees earning same as their manager
SELECT e.name AS employee, m.name AS manager, e.salary
FROM employees e
JOIN employees m ON e.manager_id = m.id
WHERE e.salary = m.salary;

-- 145. List products with sales above the average sales amount.
-- Find products with above-average sales
WITH avg_sales AS (
    SELECT AVG(amount) AS avg_amount 
    FROM sales
)
SELECT product_id, SUM(amount) AS total_sales 
FROM sales
GROUP BY product_id
HAVING SUM(amount) > (SELECT avg_amount FROM avg_sales);

-- 146. Get the number of employees hired each year.
-- Count employee hires by year
SELECT EXTRACT(YEAR FROM hire_date) AS hire_year, COUNT(*) AS count 
FROM employees
GROUP BY hire_year 
ORDER BY hire_year;

-- 147. Find the number of employees with the same job title per department.
-- Count employees by job title within each department
SELECT department_id, job_title, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id, job_title;

-- 148. Find employees with no manager assigned.
-- Find employees without a manager (likely CEO/top level)
SELECT *
FROM employees
WHERE manager_id IS NULL;

-- 149. Calculate average salary by department and job title.
-- Calculate average salary by department and job title
SELECT department_id, job_title, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id, job_title;

-- 150. Find the median salary of employees.
-- Calculate median salary across all employees
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary
FROM employees;