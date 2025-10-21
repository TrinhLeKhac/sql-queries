-- SQL Questions 31-60

-- 31. Write a query to pivot rows into columns dynamically (if dynamic pivot is not supported, simulate it for fixed values).
-- Pivot job titles into columns by department
SELECT department_id,
       SUM(CASE WHEN job_title = 'Manager' THEN 1 ELSE 0 END) AS Managers,
       SUM(CASE WHEN job_title = 'Developer' THEN 1 ELSE 0 END) AS Developers,
       SUM(CASE WHEN job_title = 'Tester' THEN 1 ELSE 0 END) AS Testers 
FROM employees
GROUP BY department_id;

-- 32. Find customers who made purchases in every category available.
-- Find customers who purchased from all available categories
SELECT customer_id
FROM sales s
GROUP BY customer_id
HAVING COUNT(DISTINCT category_id) = (SELECT COUNT(DISTINCT category_id) FROM sales);

-- 33. Identify employees who haven't received a salary raise in more than a year.
-- Find employees without salary raise in over a year
SELECT e.name
FROM employees e
JOIN salary_history sh ON e.id = sh.employee_id
GROUP BY e.id, e.name
HAVING MAX(sh.raise_date) < CURRENT_DATE - INTERVAL '1 year';

-- 34. Write a query to rank salespeople by monthly sales, resetting the rank every month.
-- Rank salespeople by monthly sales with monthly reset
SELECT salesperson_id, sale_month, total_sales, 
       RANK() OVER (PARTITION BY sale_month ORDER BY total_sales DESC) AS monthly_rank
FROM (
    SELECT salesperson_id, 
           DATE_TRUNC('month', sale_date) AS sale_month, 
           SUM(amount) AS total_sales
    FROM sales
    GROUP BY salesperson_id, sale_month 
) AS monthly_sales;

-- 35. Calculate the percentage change in sales compared to the previous month for each product.
-- Calculate month-over-month sales percentage change by product
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

-- 36. Find employees who earn more than the average salary across the company but less than the highest salary in their department.
-- Find employees earning above company average but below department maximum
SELECT *
FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees)
  AND salary < (SELECT MAX(salary) FROM employees WHERE department_id = e.department_id);

-- 37. Retrieve the last 5 orders for each customer.
-- Get the 5 most recent orders per customer
SELECT *
FROM (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders o
) sub
WHERE rn <= 5;

-- 38. Find employees with no salary changes in the last 2 years.
-- Find employees with no salary changes in past 2 years
SELECT e.*
FROM employees e
LEFT JOIN salary_history sh ON e.id = sh.employee_id 
    AND sh.change_date >= CURRENT_DATE - INTERVAL '2 years' 
WHERE sh.employee_id IS NULL;

-- 39. Find the department with the lowest average salary.
-- Find department with minimum average salary
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id 
ORDER BY avg_salary
LIMIT 1;

-- 40. List employees whose names start and end with the same letter.
-- Find employees whose names start and end with same letter
SELECT *
FROM employees
WHERE LEFT(name, 1) = RIGHT(name, 1);

-- 41. Write a query to detect circular references in employee-manager hierarchy (cycles).
-- Detect circular references in management hierarchy
WITH RECURSIVE mgr_path (id, manager_id, path) AS (
    SELECT id, manager_id, ARRAY[id] 
    FROM employees
    WHERE manager_id IS NOT NULL 
    UNION ALL
    SELECT e.id, e.manager_id, path || e.id 
    FROM employees e
    JOIN mgr_path mp ON e.manager_id = mp.id 
    WHERE NOT e.id = ANY(path)
)
SELECT DISTINCT id
FROM mgr_path 
WHERE id = ANY(path);

-- 42. Write a query to get the running total of sales per customer, ordered by sale date.
-- Calculate running total of sales per customer by date
SELECT customer_id, sale_date, amount, 
       SUM(amount) OVER (PARTITION BY customer_id ORDER BY sale_date) AS running_total
FROM sales;

-- 43. Find the department-wise salary percentile (e.g., 90th percentile) using window functions.
-- Calculate 90th percentile salary by department
SELECT department_id, salary, 
       PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY salary) OVER (PARTITION BY department_id) AS pct_90_salary 
FROM employees;

-- 44. Find employees whose salary is a prime number.
-- Find employees with prime number salaries (conceptual approach)
WITH RECURSIVE primes AS (
    SELECT generate_series(2, (SELECT MAX(salary) FROM employees)) AS num
    EXCEPT
    SELECT num FROM (
        SELECT num, 
               generate_series(2, FLOOR(SQRT(num))) AS divisor
        FROM generate_series(2, (SELECT MAX(salary) FROM employees)) AS num
    ) AS factors
    WHERE num % divisor = 0
)
SELECT *
FROM employees
WHERE salary IN (SELECT num FROM primes);

-- 45. Find employees who have worked for multiple departments over time.
-- Find employees who worked in multiple departments
SELECT employee_id
FROM employee_department_history 
GROUP BY employee_id
HAVING COUNT(DISTINCT department_id) > 1;

-- 46. Use window function to find the difference between current row's sales and previous row's sales partitioned by product.
-- Calculate sales difference from previous row by product
SELECT product_id, sale_date, amount,
       amount - LAG(amount) OVER (PARTITION BY product_id ORDER BY sale_date) AS sales_diff 
FROM sales;

-- 47. Write a query to find all employees who are at the lowest level in the hierarchy (no subordinates).
-- Find employees with no subordinates (leaf nodes)
SELECT *
FROM employees e 
WHERE NOT EXISTS (
    SELECT 1 FROM employees sub WHERE sub.manager_id = e.id
);

-- 48. Find average order value per month and product category.
-- Calculate average order value by month and category
SELECT DATE_TRUNC('month', order_date) AS order_month, 
       category_id, 
       AVG(order_value) AS avg_order_value 
FROM orders
GROUP BY order_month, category_id;

-- 49. Write a query to create a running count of how many employees joined in each year.
-- Calculate running count of employees hired by year
SELECT join_year, COUNT(*) AS yearly_hires, 
       SUM(COUNT(*)) OVER (ORDER BY join_year) AS running_total_hires
FROM (
    SELECT EXTRACT(YEAR FROM hire_date) AS join_year
    FROM employees 
) sub
GROUP BY join_year 
ORDER BY join_year;

-- 50. Write a query to find the second most recent order date per customer.
-- Find second most recent order date per customer
SELECT customer_id, order_date 
FROM (
    SELECT customer_id, order_date, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders
) sub
WHERE rn = 2;

-- 51. Find employees who have never made a sale.
-- Find employees with no sales records
SELECT e.id, e.name
FROM employees e
LEFT JOIN sales s ON e.id = s.employee_id 
WHERE s.sale_id IS NULL;

-- 52. Find the average tenure of employees by department.
-- Calculate average employee tenure by department
SELECT department_id, 
       AVG(DATE_PART('year', CURRENT_DATE - hire_date)) AS avg_tenure_years
FROM employees
GROUP BY department_id;

-- 53. Get employees with salary in the top 10% in their department.
-- Find employees in top 10% salary within their department
SELECT *
FROM (
    SELECT e.*, 
           NTILE(10) OVER (PARTITION BY department_id ORDER BY salary DESC) AS decile 
    FROM employees e
) sub
WHERE decile = 1;

-- 54. Find customers who purchased more than once in the same day.
-- Find customers with multiple purchases on same day
SELECT customer_id, purchase_date, COUNT(*) AS purchase_count
FROM sales
GROUP BY customer_id, purchase_date 
HAVING COUNT(*) > 1;

-- 55. List all departments and their employee counts, including departments with zero employees.
-- List all departments with employee counts including zero
SELECT d.department_id, d.department_name, COUNT(e.id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name;

-- 56. Write a query to find duplicate rows based on multiple columns.
-- Find duplicate rows based on multiple columns
SELECT column1, column2, COUNT(*) 
FROM table_name
GROUP BY column1, column2 
HAVING COUNT(*) > 1;

-- 57. Write a recursive query to calculate factorial of a number (e.g., 5).
-- Calculate factorial of 5 using recursive query
WITH RECURSIVE factorial(n, fact) AS (
    SELECT 1, 1 
    UNION ALL
    SELECT n + 1, fact * (n + 1) 
    FROM factorial
    WHERE n < 5
)
SELECT fact FROM factorial WHERE n = 5;

-- 58. Write a query to calculate the cumulative percentage of total sales per product.
-- Calculate cumulative percentage of sales by product
SELECT product_id, sale_amount,
       SUM(sale_amount) OVER (ORDER BY sale_amount DESC) * 100.0 / 
       SUM(sale_amount) OVER () AS cumulative_pct 
FROM sales;

-- 59. Write a query to get employees who reported directly or indirectly to a given manager (hierarchy traversal).
-- Find all employees reporting to manager ID 101 (direct and indirect)
WITH RECURSIVE reporting AS (
    SELECT id, name, manager_id
    FROM employees
    WHERE manager_id = 101 -- replace 101 with manager's id
    UNION ALL
    SELECT e.id, e.name, e.manager_id 
    FROM employees e
    INNER JOIN reporting r ON e.manager_id = r.id
)
SELECT * FROM reporting;

-- 60. Find the average number of orders per customer and standard deviation.
-- Calculate average and standard deviation of orders per customer
SELECT AVG(order_count) AS avg_orders,
       STDDEV(order_count) AS stddev_orders 
FROM (
    SELECT customer_id, COUNT(*) AS order_count 
    FROM orders
    GROUP BY customer_id
) sub;