-- SQL Questions 151-180

-- 151. Find employees who have been promoted more than once.
-- Find employees with multiple promotions
SELECT employee_id, COUNT(*) AS promotion_count
FROM promotions 
GROUP BY employee_id
HAVING COUNT(*) > 1;

-- 152. Calculate total sales by product category.
-- Calculate total sales amount per product category
SELECT p.category_id, SUM(s.amount) AS total_sales
FROM sales s
JOIN products p ON s.product_id = p.product_id 
GROUP BY p.category_id;

-- 153. Find the top 3 products by sales amount.
-- Find top 3 products by total sales
SELECT product_id, SUM(amount) AS total_sales 
FROM sales
GROUP BY product_id
ORDER BY total_sales DESC
LIMIT 3;

-- 154. Get employees who joined after their department was created.
-- Find employees hired after department creation
SELECT e.*
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.hire_date > d.creation_date;

-- 155. Find customers with no sales records.
-- Find customers who never made a purchase
SELECT c.*
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id 
WHERE s.sale_id IS NULL;

-- 156. Find the second highest salary in the company.
-- Find second highest salary across all employees
SELECT MAX(salary) AS second_highest_salary 
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- 157. Find products with sales only in the current month.
-- Find products sold exclusively in current month
SELECT product_id 
FROM sales
GROUP BY product_id 
HAVING MAX(sale_date) >= DATE_TRUNC('month', CURRENT_DATE) 
   AND MIN(sale_date) >= DATE_TRUNC('month', CURRENT_DATE);

-- 158. Find employees with consecutive workdays.
-- Find employees with consecutive work periods
WITH attendance AS (
    SELECT employee_id, work_date, 
           work_date - INTERVAL (ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY work_date)) DAY AS grp 
    FROM work_log
)
SELECT employee_id, COUNT(*) AS consecutive_days
FROM attendance
GROUP BY employee_id, grp 
HAVING COUNT(*) > 1;

-- 159. Find the average number of orders per customer.
-- Calculate average orders per customer
SELECT AVG(order_count) AS avg_orders_per_customer 
FROM (
    SELECT customer_id, COUNT(*) AS order_count 
    FROM orders
    GROUP BY customer_id 
) sub;

-- 160. Find employees who have worked on more than 5 projects.
-- Find employees assigned to more than 5 projects
SELECT employee_id, COUNT(DISTINCT project_id) AS project_count
FROM project_assignments
GROUP BY employee_id
HAVING COUNT(DISTINCT project_id) > 5;

-- 161. Find the total number of products sold each day.
-- Calculate total product quantity sold per day
SELECT sale_date, SUM(quantity) AS total_quantity_sold
FROM sales
GROUP BY sale_date 
ORDER BY sale_date;

-- 162. Find customers with orders totaling more than $10,000.
-- Find high-value customers with orders over $10,000
SELECT customer_id, SUM(amount) AS total_amount 
FROM sales
GROUP BY customer_id 
HAVING SUM(amount) > 10000;

-- 163. Find employees who have never received a bonus.
-- Find employees with no bonus records
SELECT e.*
FROM employees e
LEFT JOIN bonuses b ON e.id = b.employee_id
WHERE b.bonus_id IS NULL;

-- 164. Find the department with the lowest average salary.
-- Find department with minimum average salary
SELECT department_id, AVG(salary) AS avg_salary 
FROM employees
GROUP BY department_id 
ORDER BY avg_salary
LIMIT 1;

-- 165. Get cumulative count of orders per customer over time.
-- Calculate cumulative order count per customer
SELECT customer_id, order_date,
       COUNT(*) OVER (PARTITION BY customer_id ORDER BY order_date) AS cumulative_orders 
FROM orders;

-- 166. Find customers who ordered products only from one category.
-- Find customers who purchased from single category only
SELECT customer_id
FROM sales s
JOIN products p ON s.product_id = p.product_id 
GROUP BY customer_id
HAVING COUNT(DISTINCT p.category_id) = 1;

-- 167. Write a query to display employee names alongside their manager names, including those without managers.
-- Display employees with their managers including those without managers
SELECT e.name AS employee_name, m.name AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;

-- 168. Find products with sales increasing every month for the last 3 months.
-- Find products with consistent monthly sales growth over 3 months
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    WHERE sale_date >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY product_id, month
)
SELECT product_id 
FROM monthly_sales
GROUP BY product_id 
HAVING COUNT(*) = 3
   AND MIN(total_sales) < MAX(total_sales);
-- Note: This is a simplified check; exact implementation may vary by database

-- 169. Write a recursive query to get all descendants of a manager.
-- Find all subordinates under a specific manager
WITH RECURSIVE subordinates AS (
    SELECT id, name, manager_id 
    FROM employees
    WHERE id = 100 -- replace with specific manager_id
    UNION ALL
    SELECT e.id, e.name, e.manager_id 
    FROM employees e
    JOIN subordinates s ON e.manager_id = s.id
)
SELECT * FROM subordinates
WHERE id != 100; -- exclude the manager themselves

-- 170. Find the department with the highest variance in salaries.
-- Find department with highest salary variance
SELECT department_id, VAR_SAMP(salary) AS salary_variance
FROM employees
GROUP BY department_id 
ORDER BY salary_variance DESC 
LIMIT 1;

-- 171. Calculate the difference between each order amount and the previous order amount per customer.
-- Calculate order amount difference from previous order per customer
SELECT customer_id, order_date, amount,
       amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS diff 
FROM orders;

-- 172. Find customers who purchased both Product A and Product B.
-- Find customers who bought both specific products
SELECT customer_id
FROM sales
WHERE product_id IN ('A', 'B') 
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = 2;

-- 173. Find the top N customers by total sales amount.
-- Find top 5 customers by total sales (replace N with desired number)
SELECT customer_id, SUM(amount) AS total_sales 
FROM sales
GROUP BY customer_id
ORDER BY total_sales DESC
LIMIT 5; -- Replace with N

-- 174. Find the month with the highest sales in the current year.
-- Find peak sales month in current year
SELECT DATE_TRUNC('month', sale_date) AS month, SUM(amount) AS total_sales
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = EXTRACT(YEAR FROM CURRENT_DATE) 
GROUP BY month
ORDER BY total_sales DESC
LIMIT 1;

-- 175. Write a query to display all employees who have worked on a project longer than 6 months.
-- Find employees with long-term project assignments
SELECT employee_id
FROM project_assignments
WHERE end_date - start_date > INTERVAL '6 months';

-- 176. Find the nth highest salary in a company (e.g., 5th highest).
-- Find 5th highest salary (replace with desired rank)
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
OFFSET 4 ROWS FETCH NEXT 1 ROW ONLY; -- For 5th highest (n-1)

-- 177. Get the average salary of employees hired each year.
-- Calculate average salary by hire year
SELECT EXTRACT(YEAR FROM hire_date) AS year, AVG(salary) AS avg_salary 
FROM employees
GROUP BY year 
ORDER BY year;

-- 178. Find employees whose salaries are between the 25th and 75th percentile.
-- Find employees in middle salary range (25th-75th percentile)
WITH percentiles AS (
    SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) AS p25,
           PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) AS p75
    FROM employees
)
SELECT e.*
FROM employees e, percentiles p
WHERE e.salary BETWEEN p.p25 AND p.p75;

-- 179. Find employees with salaries higher than their department average.
-- Find employees earning above their department average
SELECT e.*
FROM employees e
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id
) d ON e.department_id = d.department_id
WHERE e.salary > d.avg_salary;

-- 180. Find the difference between each row's value and the previous row's value in sales.
-- Calculate sales amount difference from previous row
SELECT sale_date, amount,
       amount - LAG(amount) OVER (ORDER BY sale_date) AS diff 
FROM sales;