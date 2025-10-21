-- MEDIUM SQL Questions (51-100)
-- Window Functions, CTEs, Advanced JOINs, Subqueries, Date Functions

-- 51. Retrieve employees who earn more than their manager.
SELECT e.name AS Employee, e.salary, m.name AS Manager, m.salary AS ManagerSalary 
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.salary > m.salary;

-- 52. Running total of salaries by department.
SELECT name, department_id, salary, 
       SUM(salary) OVER (PARTITION BY department_id ORDER BY id) AS running_total 
FROM employees;

-- 53. Write a query to rank employees based on salary with ties handled properly.
SELECT name, salary,
       RANK() OVER (ORDER BY salary DESC) AS salary_rank 
FROM employees;

-- 54. Calculate the difference between current row and previous row's salary (lag function).
SELECT name, salary,
       salary - LAG(salary) OVER (ORDER BY id) AS salary_diff
FROM employees;

-- 55. Find the most recent purchase per customer using window functions.
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY purchase_date DESC) AS rn 
    FROM sales
) sub
WHERE rn = 1;

-- 56. Write a query to perform a conditional aggregation (count males and females in each department)
SELECT department_id,
       COUNT(CASE WHEN gender = 'M' THEN 1 END) AS male_count,
       COUNT(CASE WHEN gender = 'F' THEN 1 END) AS female_count
FROM employees
GROUP BY department_id;

-- 57. Calculate cumulative distribution (CDF) of salaries.
SELECT name, salary,
       CUME_DIST() OVER (ORDER BY salary) AS salary_cdf
FROM employees;

-- 58. Find the Nth highest salary from the employees table.
SELECT DISTINCT salary
FROM employees 
ORDER BY salary DESC
LIMIT 1 OFFSET 2; -- For 3rd highest (N-1)

-- 59. Get employees with salary in the top 10% in their department.
SELECT *
FROM (
    SELECT e.*, 
           NTILE(10) OVER (PARTITION BY department_id ORDER BY salary DESC) AS decile 
    FROM employees e
) sub
WHERE decile = 1;

-- 60. List the top 5 highest-paid employees per department.
SELECT *
FROM (
    SELECT e.*,
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees e
) sub
WHERE rn <= 5;

-- 61. Calculate the moving average of salaries over the last 3 employees ordered by hire date.
SELECT name, hire_date, salary,
       AVG(salary) OVER (ORDER BY hire_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_salary 
FROM employees;

-- 62. Find departments with the highest average salary.
WITH avg_salaries AS (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id
)
SELECT *
FROM avg_salaries
WHERE avg_salary = (SELECT MAX(avg_salary) FROM avg_salaries);

-- 63. Write a query to get the first and last purchase date for each customer.
SELECT customer_id,
       MIN(purchase_date) AS first_purchase, 
       MAX(purchase_date) AS last_purchase
FROM sales
GROUP BY customer_id;

-- 64. Find employees whose salary is above the average salary of their department but below the company-wide average.
SELECT *
FROM employees e 
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
    WHERE department_id = e.department_id
)
AND salary < (SELECT AVG(salary) FROM employees);

-- 65. Retrieve the last 5 orders for each customer.
SELECT *
FROM (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders o
) sub
WHERE rn <= 5;

-- 66. Calculate the percentage change in sales compared to the previous month for each product.
SELECT product_id, sale_month, total_sales, 
       (total_sales - LAG(total_sales) OVER (PARTITION BY product_id ORDER BY sale_month)) * 100.0 /
       LAG(total_sales) OVER (PARTITION BY product_id ORDER BY sale_month) AS pct_change 
FROM (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS sale_month, 
           SUM(amount) AS total_sales 
    FROM sales
    GROUP BY product_id, sale_month 
) monthly_sales;

-- 67. Find employees who earn more than the average salary across the company but less than the highest salary in their department.
SELECT *
FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees)
  AND salary < (SELECT MAX(salary) FROM employees WHERE department_id = e.department_id);

-- 68. Find the second most recent order date per customer.
SELECT customer_id, order_date 
FROM (
    SELECT customer_id, order_date, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders
) sub
WHERE rn = 2;

-- 69. Find the average tenure of employees by department.
SELECT department_id, 
       AVG(DATE_PART('year', CURRENT_DATE - hire_date)) AS avg_tenure_years
FROM employees
GROUP BY department_id;

-- 70. Find customers who purchased more than once in the same day.
SELECT customer_id, purchase_date, COUNT(*) AS purchase_count
FROM sales
GROUP BY customer_id, purchase_date 
HAVING COUNT(*) > 1;

-- 71. Calculate the total revenue for each customer, and rank them from highest to lowest spender.
SELECT customer_id, SUM(amount) AS total_revenue,
       RANK() OVER (ORDER BY SUM(amount) DESC) AS revenue_rank 
FROM sales
GROUP BY customer_id;

-- 72. Find the top 3 products with the highest total sales amount each month.
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

-- 73. Find the customers who placed orders only in the last 30 days.
SELECT DISTINCT customer_id 
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
  AND customer_id NOT IN (
      SELECT DISTINCT customer_id 
      FROM orders
      WHERE order_date < CURRENT_DATE - INTERVAL '30 days'
  );

-- 74. Calculate the total sales amount and number of orders per customer in the last year.
SELECT customer_id, COUNT(*) AS total_orders, SUM(amount) AS total_sales
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY customer_id;

-- 75. Find the percentage difference between each month's total sales and the previous month's total sales.
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

-- 76. Write a query to find employees who have the longest tenure within their department.
WITH tenure AS (
    SELECT *, 
           RANK() OVER (PARTITION BY department_id ORDER BY hire_date ASC) AS tenure_rank 
    FROM employees
)
SELECT *
FROM tenure
WHERE tenure_rank = 1;

-- 77. Calculate the median salary by department using window functions.
SELECT DISTINCT department_id, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) OVER (PARTITION BY department_id) AS median_salary 
FROM employees;

-- 78. Find employees who were hired before their managers.
SELECT e.name AS employee, m.name AS manager, 
       e.hire_date, m.hire_date AS manager_hire_date 
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.hire_date < m.hire_date;

-- 79. List departments with average salary greater than the overall average.
SELECT department_id, AVG(salary) AS avg_salary 
FROM employees
GROUP BY department_id
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees);

-- 80. Find customers with the longest gap between two consecutive orders.
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

-- 81. Write a query to pivot rows into columns dynamically.
SELECT department_id,
       SUM(CASE WHEN job_title = 'Manager' THEN 1 ELSE 0 END) AS Managers,
       SUM(CASE WHEN job_title = 'Developer' THEN 1 ELSE 0 END) AS Developers,
       SUM(CASE WHEN job_title = 'Tester' THEN 1 ELSE 0 END) AS Testers 
FROM employees
GROUP BY department_id;

-- 82. Find customers who made purchases in every category available.
SELECT customer_id
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY customer_id
HAVING COUNT(DISTINCT p.category_id) = (SELECT COUNT(DISTINCT category_id) FROM products);

-- 83. Write a query to rank salespeople by monthly sales, resetting the rank every month.
SELECT salesperson_id, sale_month, total_sales, 
       RANK() OVER (PARTITION BY sale_month ORDER BY total_sales DESC) AS monthly_rank
FROM (
    SELECT salesperson_id, 
           DATE_TRUNC('month', sale_date) AS sale_month, 
           SUM(amount) AS total_sales
    FROM sales
    GROUP BY salesperson_id, sale_month 
) AS monthly_sales;

-- 84. Identify employees who haven't received a salary raise in more than a year.
SELECT e.name
FROM employees e
JOIN salary_history sh ON e.id = sh.employee_id
GROUP BY e.id, e.name
HAVING MAX(sh.raise_date) < CURRENT_DATE - INTERVAL '1 year';

-- 85. Find employees with no salary changes in the last 2 years.
SELECT e.*
FROM employees e
LEFT JOIN salary_history sh ON e.id = sh.employee_id 
    AND sh.change_date >= CURRENT_DATE - INTERVAL '2 years' 
WHERE sh.employee_id IS NULL;

-- 86. Write a query to concatenate employee names in each department (string aggregation).
SELECT department_id, STRING_AGG(name, ', ') AS employee_names
FROM employees
GROUP BY department_id;

-- 87. List the customers who purchased all products in a specific category.
SELECT customer_id
FROM sales
WHERE product_id IN (SELECT product_id FROM products WHERE category_id = 10)
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (
    SELECT COUNT(DISTINCT product_id) 
    FROM products 
    WHERE category_id = 10
);

-- 88. Find employees with no corresponding entries in the salary_history table.
SELECT e.*
FROM employees e
LEFT JOIN salary_history sh ON e.id = sh.employee_id
WHERE sh.employee_id IS NULL;

-- 89. Show the department with the highest number of employees and the count.
SELECT department_id, COUNT(*) AS employee_count 
FROM employees
GROUP BY department_id 
ORDER BY employee_count DESC 
LIMIT 1;

-- 90. Write a query to find the first purchase date and last purchase date for each customer, including customers who never purchased anything.
SELECT c.customer_id,
       MIN(s.purchase_date) AS first_purchase,
       MAX(s.purchase_date) AS last_purchase 
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id 
GROUP BY c.customer_id;

-- 91. Generate a report that shows sales and sales growth percentage compared to the same month last year.
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

-- 92. Write a query to identify overlapping shifts for employees.
SELECT s1.employee_id, s1.shift_id AS shift1, s2.shift_id AS shift2
FROM shifts s1
JOIN shifts s2 ON s1.employee_id = s2.employee_id AND s1.shift_id < s2.shift_id
WHERE s1.start_time < s2.end_time AND s1.end_time > s2.start_time;

-- 93. Find the difference between each order amount and the previous order amount per customer.
SELECT customer_id, order_date, amount,
       amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS diff 
FROM orders;

-- 94. Find customers who purchased both Product A and Product B.
SELECT customer_id
FROM sales
WHERE product_id IN ('A', 'B') 
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = 2;

-- 95. Find the top N customers by total sales amount.
SELECT customer_id, SUM(amount) AS total_sales 
FROM sales
GROUP BY customer_id
ORDER BY total_sales DESC
LIMIT 5; -- Replace with N

-- 96. Write a query to display all employees who have worked on a project longer than 6 months.
SELECT employee_id
FROM project_assignments
WHERE end_date - start_date > INTERVAL '6 months';

-- 97. Get the average salary of employees hired each year.
SELECT EXTRACT(YEAR FROM hire_date) AS year, AVG(salary) AS avg_salary 
FROM employees
GROUP BY year 
ORDER BY year;

-- 98. Find employees with salaries higher than their department average.
SELECT e.*
FROM employees e
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id
) d ON e.department_id = d.department_id
WHERE e.salary > d.avg_salary;

-- 99. Find the difference between each row's value and the previous row's value in sales.
SELECT sale_date, amount,
       amount - LAG(amount) OVER (ORDER BY sale_date) AS diff 
FROM sales;

-- 100. List employees who have been in the company for more than 10 years.
SELECT *
FROM employees
WHERE CURRENT_DATE - hire_date > INTERVAL '10 years';