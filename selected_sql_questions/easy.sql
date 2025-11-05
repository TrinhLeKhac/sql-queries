-- Basic SELECT, WHERE, GROUP BY, JOINs, and simple aggregations

-- 1. Find the second highest salary from the Employee table.
SELECT MAX(salary) AS SecondHighestSalary
FROM employees 
WHERE salary < (SELECT MAX(salary) FROM employees);

-- 2. Retrieve employees who earn more than their manager.
SELECT e.name AS Employee, e.salary, m.name AS Manager, m.salary AS ManagerSalary 
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.salary > m.salary;

-- 3. Get departments with no employees.
SELECT d.department_name 
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.id IS NULL;

-- 4. Write a query to find the median salary.
-- Solution 1
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary
FROM employees;

-- Solution 2
WITH total AS (
	SELECT COUNT(*) AS n FROM public.employees
),
emp_with_rnb AS (
	SELECT salary, ROW_NUMBER() OVER (ORDER BY salary) AS rnb
	FROM public.employees
),
emp_with_rnb_and_total AS (
	SELECT e.*, t.n FROM emp_with_rnb e
	JOIN total t ON TRUE
)
SELECT AVG(salary) AS median_salary FROM emp_with_rnb_and_total
WHERE rnb IN (
	CASE WHEN n % 2 = 0 THEN n/2 ELSE (n+1)/2 END,
  	CASE WHEN n % 2 = 0 THEN n/2 + 1 ELSE (n+1)/2 END
);

-- 5. Write a query to perform a conditional aggregation (count males and females in each department)
SELECT department_id,
       SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_count,
       SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM employees
GROUP BY department_id;

-- 6. Write a query to rank employees based on salary with ties handled properly.
SELECT name, salary,
       RANK() OVER (ORDER BY salary DESC) AS salary_rank 
FROM employees;

-- 7. Find customers who purchased more than once in the same day.
SELECT customer_id, purchase_date, COUNT(*) AS purchase_count
FROM sales
GROUP BY customer_id, purchase_date 
HAVING COUNT(*) > 1;

-- 8. Find the department with the lowest average salary.
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id 
ORDER BY avg_salary
LIMIT 1;

-- 9. List employees whose names start and end with the same letter.
SELECT *
FROM employees
WHERE LEFT(name, 1) = RIGHT(name, 1);

-- 10. Find the total sales per customer including those with zero sales.
SELECT c.customer_id, COALESCE(SUM(s.amount), 0) AS total_sales
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id;

-- 11. Find customers with no orders in the last year.
-- Solution 1
SELECT customer_id 
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_date >= CURRENT_DATE - INTERVAL '1 year'
WHERE o.order_id IS NULL;

-- Solution 2
WITH order_last_year AS (
	SELECT * FROM orders WHERE order_date > CURRENT_DATE - INTERVAL '1 year'
)
SELECT COUNT (DISTINCT c.customer_id)
FROM customers c
LEFT JOIN order_last_year o
ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 12. Find employees who were hired before their managers.
SELECT e.name AS employee, m.name AS manager, 
       e.hire_date, m.hire_date AS manager_hire_date 
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.hire_date < m.hire_date;

-- 13. Get the number of employees hired each year.
SELECT EXTRACT(YEAR FROM hire_date) AS hire_year, COUNT(*) AS count 
FROM employees
GROUP BY EXTRACT(YEAR FROM hire_date) -- Postgres allows GROUP BY alias (hire year), but HAVING doesn't allow
ORDER BY hire_year;

-- 14. Find the average number of orders per customer.
SELECT AVG(order_count) AS avg_orders_per_customer 
FROM (
    SELECT customer_id, COUNT(*) AS order_count 
    FROM orders
    GROUP BY customer_id 
) sub;

-- 15. Get cumulative count of orders per customer over time.
SELECT customer_id, order_date,
       COUNT(*) OVER (PARTITION BY customer_id ORDER BY order_date) AS cumulative_orders 
FROM orders;

-- 16. Find customers who ordered products only from one category.
SELECT customer_id
FROM sales s
JOIN products p ON s.product_id = p.product_id 
GROUP BY customer_id
HAVING COUNT(DISTINCT p.category_id) = 1;

-- 17. Find the top N customers by total sales amount.
SELECT customer_id, SUM(amount) AS total_sales 
FROM sales
GROUP BY customer_id
ORDER BY total_sales DESC
LIMIT 5; -- Replace with N

-- 18. Find the month with the highest sales in the current year.
SELECT DATE_TRUNC('month', sale_date) AS month, SUM(amount) AS total_sales
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = EXTRACT(YEAR FROM CURRENT_DATE) 
GROUP BY month
ORDER BY total_sales DESC
LIMIT 1;

-- 19. Find employees with salaries higher than their department average.
SELECT e.*
FROM employees e
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id
) d ON e.department_id = d.department_id
WHERE e.salary > d.avg_salary;

-- 19. Find customers who ordered products from at least 3 different categories.
SELECT customer_id
FROM sales s
JOIN products p ON s.product_id = p.product_id 
GROUP BY customer_id
HAVING COUNT(DISTINCT p.category_id) >= 3;

-- 20. List all customers who have never ordered product X.
SELECT customer_id 
FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM sales
    WHERE product_id = 'X'
);

-- 21. Find the employee with the maximum salary in each department.
-- Solution 1
WITH dept_max AS (
    SELECT department_id, MAX(salary) AS max_salary
    FROM employees
    GROUP BY department_id
)
SELECT e.*
FROM employees e
JOIN dept_max d ON e.department_id = d.department_id AND e.salary = d.max_salary;

-- Solution 2
SELECT * FROM (
	SELECT *, MAX(salary) OVER (PARTITION BY department_id) AS max_salary FROM employees) sub
WHERE salary = max_salary;

-- 22. Find customers with sales in at least 3 different years.
SELECT customer_id 
FROM sales
GROUP BY customer_id
HAVING COUNT(DISTINCT EXTRACT(YEAR FROM sale_date)) >= 3;

-- 23. Calculate the number of employees hired each month in the last year.
SELECT DATE_TRUNC('month', hire_date) AS month, COUNT(*) AS hires
FROM employees
WHERE hire_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY month 
ORDER BY month;

-- 24. Find the rank of employees based on salary within their department.
SELECT *, 
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank 
FROM employees;

-- 25. Find customers who ordered the most products in 2023.
SELECT customer_id, SUM(quantity) AS total_quantity
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2023 
GROUP BY customer_id
ORDER BY total_quantity DESC 
LIMIT 1;

-- 26. Find customers with no orders in the last year.
SELECT customer_id
FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '1 year'
);

-- 27. Find products ordered only by customers from one country.
SELECT product_id 
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
GROUP BY product_id
HAVING COUNT(DISTINCT c.country) = 1;

-- 28. Find customers who have placed orders but never paid by credit card.
SELECT DISTINCT customer_id
FROM orders
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM orders 
    WHERE payment_method = 'Credit Card'
);

-- 29. Find employees who have not taken any leave in the last 6 months.
SELECT e.id, e.name 
FROM employees e
LEFT JOIN leaves l ON e.id = l.employee_id 
    AND l.leave_date >= CURRENT_DATE - INTERVAL '6 months'
WHERE l.leave_id IS NULL;
