-- SQL Questions 61-90

-- 61. Write a query to find consecutive days where sales were above a threshold.
-- Find consecutive days with sales above $1000
WITH flagged_sales AS (
    SELECT sale_date, amount,
           CASE WHEN amount > 1000 THEN 1 ELSE 0 END AS flag 
    FROM sales
),
groups AS (
    SELECT sale_date, amount, flag,
           sale_date - INTERVAL (ROW_NUMBER() OVER (ORDER BY sale_date)) DAY AS grp 
    FROM flagged_sales
    WHERE flag = 1 
)
SELECT MIN(sale_date) AS start_date, 
       MAX(sale_date) AS end_date, 
       COUNT(*) AS consecutive_days
FROM groups
GROUP BY grp
ORDER BY consecutive_days DESC;

-- 62. Write a query to concatenate employee names in each department (string aggregation).
-- Concatenate employee names by department
SELECT department_id, STRING_AGG(name, ', ') AS employee_names
FROM employees
GROUP BY department_id;

-- 63. Find employees whose salary is above the average salary of their department but below the company-wide average.
-- Find employees above dept average but below company average
SELECT *
FROM employees e 
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
    WHERE department_id = e.department_id
)
AND salary < (SELECT AVG(salary) FROM employees);

-- 64. List the customers who purchased all products in a specific category.
-- Find customers who purchased all products in category 10
SELECT customer_id
FROM sales
WHERE product_id IN (SELECT product_id FROM products WHERE category_id = 10)
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (
    SELECT COUNT(DISTINCT product_id) 
    FROM products 
    WHERE category_id = 10
);

-- 65. Retrieve the Nth highest salary from the employees table.
-- Get the 3rd highest salary (replace N with desired rank)
SELECT DISTINCT salary
FROM employees 
ORDER BY salary DESC
LIMIT 1 OFFSET 2; -- N-1 for Nth highest

-- 66. Find employees with no corresponding entries in the salary_history table.
-- Find employees without salary history records
SELECT e.*
FROM employees e
LEFT JOIN salary_history sh ON e.id = sh.employee_id
WHERE sh.employee_id IS NULL;

-- 67. Show the department with the highest number of employees and the count.
-- Find department with most employees
SELECT department_id, COUNT(*) AS employee_count 
FROM employees
GROUP BY department_id 
ORDER BY employee_count DESC 
LIMIT 1;

-- 68. Write a recursive query to list all ancestors (managers) of a given employee.
-- Find all managers above employee ID 123
WITH RECURSIVE ancestors AS (
    SELECT id, name, manager_id
    FROM employees
    WHERE id = 123 -- given employee id
    UNION ALL
    SELECT e.id, e.name, e.manager_id
    FROM employees e
    JOIN ancestors a ON e.id = a.manager_id
)
SELECT * FROM ancestors;

-- 69. Calculate the median salary by department using window functions.
-- Calculate median salary per department
SELECT DISTINCT department_id, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) OVER (PARTITION BY department_id) AS median_salary 
FROM employees;

-- 70. Write a query to find the first purchase date and last purchase date for each customer, including customers who never purchased anything.
-- Get first and last purchase dates including customers with no purchases
SELECT c.customer_id,
       MIN(s.purchase_date) AS first_purchase,
       MAX(s.purchase_date) AS last_purchase 
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id 
GROUP BY c.customer_id;

-- 71. Find the percentage difference between each month's total sales and the previous month's total sales.
-- Calculate month-over-month sales percentage change
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales
    FROM sales 
    GROUP BY month
)
SELECT month, total_sales,
       (total_sales - LAG(total_sales) OVER (ORDER BY month)) * 100.0 / 
       LAG(total_sales) OVER (ORDER BY month) AS pct_change
FROM monthly_sales;

-- 72. Write a query to find employees who have the longest tenure within their department.
-- Find employees with longest tenure in each department
WITH tenure AS (
    SELECT *, 
           RANK() OVER (PARTITION BY department_id ORDER BY hire_date ASC) AS tenure_rank 
    FROM employees
)
SELECT *
FROM tenure
WHERE tenure_rank = 1;

-- 73. Generate a report that shows sales and sales growth percentage compared to the same month last year.
-- Compare sales growth to same month previous year
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    GROUP BY month
)
SELECT ms1.month, ms1.total_sales,
       ((ms1.total_sales - ms2.total_sales) * 100.0 / ms2.total_sales) AS growth_pct
FROM monthly_sales ms1
LEFT JOIN monthly_sales ms2 ON ms1.month = ms2.month + INTERVAL '1 year';

-- 74. Write a query to identify overlapping shifts for employees.
-- Find overlapping employee shifts
SELECT s1.employee_id, s1.shift_id AS shift1, s2.shift_id AS shift2
FROM shifts s1
JOIN shifts s2 ON s1.employee_id = s2.employee_id AND s1.shift_id < s2.shift_id
WHERE s1.start_time < s2.end_time AND s1.end_time > s2.start_time;

-- 75. Calculate the total revenue for each customer, and rank them from highest to lowest spender.
-- Rank customers by total revenue
SELECT customer_id, SUM(amount) AS total_revenue,
       RANK() OVER (ORDER BY SUM(amount) DESC) AS revenue_rank 
FROM sales
GROUP BY customer_id;

-- 76. Write a query to find the employee(s) who have never received a promotion.
-- Find employees with no promotion records
SELECT e.*
FROM employees e
LEFT JOIN promotions p ON e.id = p.employee_id 
WHERE p.employee_id IS NULL;

-- 77. Write a query to find the top 3 products with the highest total sales amount each month.
-- Find top 3 products by sales each month
WITH monthly_product_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    GROUP BY product_id, month
),
ranked_sales AS (
    SELECT *, 
           RANK() OVER (PARTITION BY month ORDER BY total_sales DESC) AS sales_rank
    FROM monthly_product_sales
)
SELECT product_id, month, total_sales 
FROM ranked_sales
WHERE sales_rank <= 3 
ORDER BY month, sales_rank;

-- 78. Find the customers who placed orders only in the last 30 days.
-- Find customers with orders only in last 30 days
SELECT DISTINCT customer_id 
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
  AND customer_id NOT IN (
      SELECT DISTINCT customer_id 
      FROM orders
      WHERE order_date < CURRENT_DATE - INTERVAL '30 days'
  );

-- 79. Find products that have never been ordered.
-- Find products with no order records
SELECT p.product_id, p.product_name 
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id 
WHERE o.order_id IS NULL;

-- 80. Find employees whose salary is above their department's average but below the overall average salary.
-- Find employees above dept average but below company average
SELECT *
FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees WHERE department_id = e.department_id)
  AND salary < (SELECT AVG(salary) FROM employees);

-- 81. Calculate the total sales amount and number of orders per customer in the last year.
-- Calculate customer sales metrics for last year
SELECT customer_id, COUNT(*) AS total_orders, SUM(amount) AS total_sales
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY customer_id;

-- 82. List the top 5 highest-paid employees per department.
-- Find top 5 highest paid employees per department
SELECT *
FROM (
    SELECT e.*,
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees e
) sub
WHERE rn <= 5;

-- 83. Write a query to identify "gaps and islands" in attendance records (consecutive dates present).
-- Find consecutive attendance periods (gaps and islands)
WITH attendance_groups AS (
    SELECT employee_id, attendance_date,
           attendance_date - INTERVAL (ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY attendance_date)) DAY AS grp 
    FROM attendance
)
SELECT employee_id, 
       MIN(attendance_date) AS start_date, 
       MAX(attendance_date) AS end_date, 
       COUNT(*) AS consecutive_days
FROM attendance_groups 
GROUP BY employee_id, grp
ORDER BY employee_id, start_date;

-- 84. Write a recursive query to list all descendants of a manager in an organizational hierarchy.
-- Find all subordinates under manager ID 100
WITH RECURSIVE descendants AS (
    SELECT id, name, manager_id 
    FROM employees
    WHERE manager_id = 100 -- starting manager id
    UNION ALL
    SELECT e.id, e.name, e.manager_id 
    FROM employees e
    INNER JOIN descendants d ON e.manager_id = d.id
)
SELECT * FROM descendants;

-- 85. Calculate a 3-month moving average of monthly sales per product.
-- Calculate 3-month moving average of sales by product
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    GROUP BY product_id, month
)
SELECT product_id, month, total_sales, 
       AVG(total_sales) OVER (PARTITION BY product_id ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
FROM monthly_sales;

-- 86. Write a query to find employees who have the same hire date as their managers.
-- Find employees hired on same date as their manager
SELECT e.name AS employee_name, m.name AS manager_name, e.hire_date
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.hire_date = m.hire_date;

-- 87. Write a query to find products with increasing sales over the last 3 months.
-- Find products with increasing sales trend over 3 months
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    GROUP BY product_id, month
),
ranked_sales AS (
    SELECT product_id, month, total_sales,
           ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY month DESC) AS rn 
    FROM monthly_sales
)
SELECT ms1.product_id
FROM ranked_sales ms1
JOIN ranked_sales ms2 ON ms1.product_id = ms2.product_id AND ms1.rn = 1 AND ms2.rn = 2
JOIN ranked_sales ms3 ON ms1.product_id = ms3.product_id AND ms3.rn = 3
WHERE ms3.total_sales < ms2.total_sales AND ms2.total_sales < ms1.total_sales;

-- 88. Write a query to get the nth highest salary per department.
-- Get 2nd highest salary per department (replace N with desired rank)
SELECT department_id, salary
FROM (
    SELECT department_id, salary, 
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn 
    FROM employees
) sub
WHERE rn = 2; -- Replace with N

-- 89. Find employees who have managed more than 3 projects.
-- Find managers with more than 3 projects
SELECT manager_id, COUNT(DISTINCT project_id) AS project_count
FROM projects
GROUP BY manager_id
HAVING COUNT(DISTINCT project_id) > 3;

-- 90. Write a query to calculate the difference in days between each employee's hire date and their manager's hire date.
-- Calculate hire date difference between employee and manager
SELECT e.name AS employee, m.name AS manager, 
       (e.hire_date - m.hire_date) AS days_difference 
FROM employees e
JOIN employees m ON e.manager_id = m.id;