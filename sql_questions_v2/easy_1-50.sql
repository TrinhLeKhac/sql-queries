-- EASY SQL Questions (1-50)
-- Basic SELECT, WHERE, GROUP BY, ORDER BY, Simple JOINs, Basic Aggregations

-- 1. Find the second highest salary from the Employee table.
SELECT MAX(salary) AS SecondHighestSalary
FROM employees 
WHERE salary < (SELECT MAX(salary) FROM employees);

-- 2. Find duplicate records in a table.
SELECT name, COUNT(*)
FROM employees 
GROUP BY name
HAVING COUNT(*) > 1;

-- 3. Count employees in each department having more than 5 employees.
SELECT department_id, COUNT(*) AS num_employees
FROM employees
GROUP BY department_id 
HAVING COUNT(*) > 5;

-- 4. Find employees who joined in the last 6 months.
SELECT *
FROM employees
WHERE hire_date > CURRENT_DATE - INTERVAL '6 months';

-- 5. Get departments with no employees.
SELECT d.department_name 
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.id IS NULL;

-- 6. Find customers who have not made any purchase.
SELECT c.customer_id, c.name 
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id 
WHERE s.sale_id IS NULL;

-- 7. Find employees who don't have a department assigned.
SELECT *
FROM employees
WHERE department_id IS NULL;

-- 8. Get the number of employees hired each year.
SELECT EXTRACT(YEAR FROM hire_date) AS hire_year, COUNT(*) AS count 
FROM employees
GROUP BY hire_year 
ORDER BY hire_year;

-- 9. Find the department with the most employees.
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
ORDER BY employee_count DESC 
LIMIT 1;

-- 10. List all employees and their manager names.
SELECT e.name AS employee, m.name AS manager 
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;

-- 11. Find employees with no manager assigned (CEO level).
SELECT *
FROM employees
WHERE manager_id IS NULL;

-- 12. Calculate average salary by department.
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id;

-- 13. Find the first order date for each customer.
SELECT customer_id, MIN(order_date) AS first_order_date
FROM orders
GROUP BY customer_id;

-- 14. Find products that have never been ordered.
SELECT p.product_id, p.product_name 
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id 
WHERE s.sale_id IS NULL;

-- 15. Find the total sales per customer including those with zero sales.
SELECT c.customer_id, COALESCE(SUM(s.amount), 0) AS total_sales
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id;

-- 16. Find employees who earn more than the average salary.
SELECT *
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- 17. Get the most recent order date per customer.
SELECT customer_id, MAX(order_date) AS last_order_date
FROM orders
GROUP BY customer_id;

-- 18. Calculate total sales by product category.
SELECT p.category_id, SUM(s.amount) AS total_sales
FROM sales s
JOIN products p ON s.product_id = p.product_id 
GROUP BY p.category_id;

-- 19. Find the top 3 products by sales amount.
SELECT product_id, SUM(amount) AS total_sales 
FROM sales
GROUP BY product_id
ORDER BY total_sales DESC
LIMIT 3;

-- 20. Find the second highest salary in the company.
SELECT MAX(salary) AS second_highest_salary 
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- 21. Find the average number of orders per customer.
SELECT AVG(order_count) AS avg_orders_per_customer 
FROM (
    SELECT customer_id, COUNT(*) AS order_count 
    FROM orders
    GROUP BY customer_id 
) sub;

-- 22. Find the difference in days between the first and last order for each customer.
SELECT customer_id, MAX(order_date) - MIN(order_date) AS days_between
FROM orders
GROUP BY customer_id;

-- 23. Find employees whose names start and end with the same letter.
SELECT *
FROM employees
WHERE LEFT(name, 1) = RIGHT(name, 1);

-- 24. Calculate the number of orders placed on weekends vs weekdays.
SELECT CASE
    WHEN EXTRACT(DOW FROM order_date) IN (0,6) THEN 'Weekend' 
    ELSE 'Weekday'
END AS day_type,
COUNT(*) AS order_count 
FROM orders
GROUP BY day_type;

-- 25. Find customers with orders totaling more than $10,000.
SELECT customer_id, SUM(amount) AS total_amount 
FROM sales
GROUP BY customer_id 
HAVING SUM(amount) > 10000;

-- 26. Find the day with the highest number of new hires.
SELECT hire_date, COUNT(*) AS hires
FROM employees 
GROUP BY hire_date
ORDER BY hires DESC
LIMIT 1;

-- 27. Find employees who have not been assigned to any project.
SELECT e.*
FROM employees e
LEFT JOIN project_assignments pa ON e.id = pa.employee_id
WHERE pa.project_id IS NULL;

-- 28. Find the maximum salary gap between any two employees within the same department.
SELECT department_id, MAX(salary) - MIN(salary) AS salary_gap
FROM employees
GROUP BY department_id;

-- 29. Find customers with average order amount above $500.
SELECT customer_id, AVG(amount) AS avg_order_amount
FROM orders
GROUP BY customer_id 
HAVING AVG(amount) > 500;

-- 30. Find the total number of products sold each day.
SELECT sale_date, SUM(quantity) AS total_quantity_sold
FROM sales
GROUP BY sale_date 
ORDER BY sale_date;

-- 31. Find employees with the same salary as their manager.
SELECT e.name AS employee, m.name AS manager, e.salary
FROM employees e
JOIN employees m ON e.manager_id = m.id
WHERE e.salary = m.salary;

-- 32. Find the median salary of employees.
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary
FROM employees;

-- 33. Find orders where the total quantity exceeds 100 units.
SELECT order_id, SUM(quantity) AS total_quantity 
FROM order_items
GROUP BY order_id
HAVING SUM(quantity) > 100;

-- 34. Find the department with the lowest average salary.
SELECT department_id, AVG(salary) AS avg_salary 
FROM employees
GROUP BY department_id 
ORDER BY avg_salary
LIMIT 1;

-- 35. Find employees who have never taken any leave.
SELECT e.*
FROM employees e
LEFT JOIN leaves l ON e.id = l.employee_id 
WHERE l.leave_id IS NULL;

-- 36. Find the total discount given in each month.
SELECT DATE_TRUNC('month', order_date) AS month, 
       SUM(discount_amount) AS total_discount 
FROM orders
GROUP BY month 
ORDER BY month;

-- 37. Find products with sales only in the current month.
SELECT product_id 
FROM sales
GROUP BY product_id 
HAVING MAX(sale_date) >= DATE_TRUNC('month', CURRENT_DATE) 
   AND MIN(sale_date) >= DATE_TRUNC('month', CURRENT_DATE);

-- 38. Find employees who have never received a bonus.
SELECT e.*
FROM employees e
LEFT JOIN bonuses b ON e.id = b.employee_id
WHERE b.bonus_id IS NULL;

-- 39. Find the month with the highest sales in the current year.
SELECT DATE_TRUNC('month', sale_date) AS month, SUM(amount) AS total_sales
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = EXTRACT(YEAR FROM CURRENT_DATE) 
GROUP BY month
ORDER BY total_sales DESC
LIMIT 1;

-- 40. Find customers who have placed orders but never used a discount.
SELECT DISTINCT customer_id 
FROM orders
WHERE discount_used = FALSE;

-- 41. Find the average order amount per customer per year.
SELECT customer_id, 
       EXTRACT(YEAR FROM order_date) AS year, 
       AVG(amount) AS avg_order_amount
FROM orders
GROUP BY customer_id, year;

-- 42. Find employees who joined before their department was created.
SELECT e.*
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.hire_date < d.creation_date;

-- 43. Find the percentage of employees in each department.
WITH total_employees AS (SELECT COUNT(*) AS total FROM employees)
SELECT department_id, 
       COUNT(*) * 100.0 / (SELECT total FROM total_employees) AS percentage
FROM employees
GROUP BY department_id;

-- 44. Find customers who made orders totaling more than the average order amount.
WITH avg_order AS (
    SELECT AVG(amount) AS avg_amount 
    FROM orders
)
SELECT customer_id, SUM(amount) AS total_amount 
FROM orders
GROUP BY customer_id
HAVING SUM(amount) > (SELECT avg_amount FROM avg_order);

-- 45. Find the average time difference between order and delivery.
SELECT AVG(delivery_date - order_date) AS avg_delivery_time 
FROM orders
WHERE delivery_date IS NOT NULL;

-- 46. Find employees who have been promoted more than once.
SELECT employee_id, COUNT(*) AS promotion_count
FROM promotions 
GROUP BY employee_id
HAVING COUNT(*) > 1;

-- 47. Find customers with no sales records.
SELECT c.*
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id 
WHERE s.sale_id IS NULL;

-- 48. Find the number of employees with the same job title per department.
SELECT department_id, job_title, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id, job_title;

-- 49. Calculate average salary by department and job title.
SELECT department_id, job_title, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id, job_title;

-- 50. Find employees who have worked on more than 5 projects.
SELECT employee_id, COUNT(DISTINCT project_id) AS project_count
FROM project_assignments
GROUP BY employee_id
HAVING COUNT(DISTINCT project_id) > 5;