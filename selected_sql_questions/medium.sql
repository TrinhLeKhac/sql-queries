-- Window functions, CTEs, advanced JOINs, and subqueries

-- 1. Running total of salaries by department.
SELECT name, department_id, salary, 
       SUM(salary) OVER (PARTITION BY department_id ORDER BY id) AS running_total 
FROM employees;

-- 2. Find the longest consecutive streak of daily logins for each user.
-- Solution 1
WITH login_dates AS (
    SELECT user_id, login_date,
           login_date - INTERVAL (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date)) DAY AS grp
    FROM user_logins 
)
SELECT user_id, COUNT(*) AS streak_length, 
       MIN(login_date) AS start_date, 
       MAX(login_date) AS end_date
FROM login_dates 
GROUP BY user_id, grp
ORDER BY streak_length DESC;

-- Solution 2
WITH cte_1 AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) AS rnb
    FROM user_logins
),
cte_2 AS (
	SELECT user_id, (login_date - rnb * INTERVAL '1 day')::date AS delta_day, COUNT(*) AS consecutive_cnt FROM cte_1
	GROUP BY user_id, delta_day
	ORDER BY user_id, delta_day
)
SELECT user_id, MAX(consecutive_cnt) AS max_consecutive_cnt
FROM cte_2
GROUP BY user_id
ORDER BY user_id;

-- 3. Calculate cumulative distribution (CDF) of salaries.
SELECT name, salary,
       CUME_DIST() OVER (ORDER BY salary) AS salary_cdf
FROM employees;


-- 4. Identify overlapping date ranges for bookings.
SELECT b1.booking_id, b2.booking_id
FROM bookings b1
JOIN bookings b2 ON b1.booking_id < b2.booking_id 
WHERE b1.start_date <= b2.end_date
  AND b1.end_date >= b2.start_date;

-- 5. Aggregate JSON data (if supported) to list all employee names in a department as a JSON array.
SELECT department_id, JSON_AGG(name) AS employee_names
FROM employees
GROUP BY department_id;

-- 6. Calculate the moving average of salaries over the last 3 employees ordered by hire date.
SELECT name, hire_date, salary,
       AVG(salary) OVER (ORDER BY hire_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_salary 
FROM employees;

-- 7. Find the most recent purchase per customer using window functions.
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY purchase_date DESC) AS rn 
    FROM sales
) sub
WHERE rn = 1;

-- 8. Write a query to pivot rows into columns dynamically (if dynamic pivot is not supported, simulate it for fixed values).
SELECT department_id,
       SUM(CASE WHEN job_title = 'Manager' THEN 1 ELSE 0 END) AS Managers,
       SUM(CASE WHEN job_title = 'Developer' THEN 1 ELSE 0 END) AS Developers,
       SUM(CASE WHEN job_title = 'Tester' THEN 1 ELSE 0 END) AS Testers 
FROM employees
GROUP BY department_id;

-- 9. Find customers who made purchases in every category available.
--Solution 1
WITH cnt AS (
	SELECT COUNT(DISTINCT category_id) AS n_cate FROM sales
),
agg_cte AS (
	SELECT customer_id, COUNT(DISTINCT category_id) AS n_distinct_cate
	FROM sales GROUP BY customer_id
),
total_cte AS (
	SELECT a.*, cnt.* FROM agg_cte a JOIN cnt ON TRUE
)
SELECT * FROM total_cte WHERE n_distinct_cate = n_cate;

-- Solution 2
SELECT customer_id
FROM sales s
GROUP BY customer_id
HAVING COUNT(DISTINCT category_id) = (SELECT COUNT(DISTINCT category_id) FROM sales);

-- 10. Write a query to rank salespeople by monthly sales, resetting the rank every month.
SELECT salesperson_id, sale_month, total_sales, 
       RANK() OVER (PARTITION BY sale_month ORDER BY total_sales DESC) AS monthly_rank
FROM (
    SELECT salesperson_id, 
           DATE_TRUNC('month', sale_date) AS sale_month, 
           SUM(amount) AS total_sales
    FROM sales
    GROUP BY salesperson_id, sale_month 
) AS monthly_sales;

-- 11. Calculate the percentage change in sales compared to the previous month for each product.
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

-- 12. Find employees who earn more than the average salary across the company but less than the highest salary in their department.
-- Solution 1
SELECT *
FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees)
  AND salary < (SELECT MAX(salary) FROM employees WHERE department_id = e.department_id);

-- Solution 2
WITH max_salary_cte AS (
	SELECT department_id, MAX(salary) AS max_salary
	FROM employees GROUP BY department_id
)
SELECT e.department_id, e.id AS emp_id, e.salary, m.max_salary AS max_dept_salary, sub.avg_salary_total
FROM employees e
JOIN max_salary_cte m
ON e.department_id = m.department_id
JOIN (SELECT AVG(salary) AS avg_salary_total FROM employees) sub ON TRUE
WHERE e.salary < m.max_salary AND e.salary > sub.avg_salary_total;

-- 13. Write a query to get the running total of sales per customer, ordered by sale date.
SELECT customer_id, sale_date, amount, 
       SUM(amount) OVER (PARTITION BY customer_id ORDER BY sale_date) AS running_total
FROM sales;

-- 14. Find the department-wise salary percentile (e.g., 90th percentile) using window functions.
SELECT department_id, PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY salary) AS pct_90
FROM employees GROUP BY department_id;

-- 15. Write a query to find all employees who are at the lowest level in the hierarchy (no subordinates).
-- EXISTS/NOT EXISTS vs IN/NOT IN (handle NULL)
SELECT *
FROM employees e 
WHERE NOT EXISTS (
    SELECT 1 FROM employees sub WHERE sub.manager_id = e.id
);

-- 16. Write a query to find the second most recent order date per customer.
SELECT customer_id, order_date 
FROM (
    SELECT customer_id, order_date, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders
) sub
WHERE rn = 2;

-- 17. Write a recursive query to calculate factorial of a number (e.g., 5).
-- Solution 1
WITH RECURSIVE factorial(n, fact) AS (
    SELECT 1, 1 
    UNION ALL
    SELECT n + 1, fact * (n + 1) 
    FROM factorial
    WHERE n < 5
)
SELECT fact FROM factorial WHERE n = 5;

-- Solution 2
WITH RECURSIVE factorial(n, fact) AS (
	-- base
	SELECT 1 AS n, 1 AS fact

	UNION ALL

	-- recursive
	SELECT f.n + 1 AS n, f.fact * (f.n + 1) AS fact
	FROM factorial f
	WHERE f.n < 10
)
SELECT * FROM factorial;

-- 18. Write a query to calculate the cumulative percentage of total sales per product.
SELECT product_id, sale_date,
SUM(amount) OVER (PARTITION BY product_id ORDER BY sale_date) AS cum_amount,
SUM(amount) OVER (PARTITION BY product_id) AS total_amount,
SUM(amount) OVER (PARTITION BY product_id ORDER BY sale_date) * 100.0 / SUM(amount) OVER (PARTITION BY product_id) AS cum_pct
FROM sales;

-- 19. Find the average number of orders per customer and standard deviation.
SELECT AVG(order_count) AS avg_orders,
       STDDEV(order_count) AS stddev_orders 
FROM (
    SELECT customer_id, COUNT(*) AS order_count 
    FROM orders
    GROUP BY customer_id
) sub;

-- 20. Write a query to find consecutive days where sales were above a threshold.
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

-- 21. Write a query to concatenate employee names in each department (string aggregation).
SELECT department_id, STRING_AGG(name, ', ') AS employee_names
FROM employees
GROUP BY department_id;

-- 22. List the customers who purchased all products in a specific category.
-- Solution 1
SELECT customer_id
FROM sales
WHERE product_id IN (SELECT product_id FROM products WHERE category_id = 10)
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (
    SELECT COUNT(DISTINCT product_id) 
    FROM products 
    WHERE category_id = 10
);

-- Solution 2
SELECT customer_id
FROM sales WHERE category_id = 10
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (SELECT COUNT(DISTINCT product_id) FROM products WHERE category_id = 10);

-- 23. Find the percentage difference between each month's total sales and the previous month's total sales.
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

-- 24. Generate a report that shows sales and sales growth percentage compared to the same month last year.
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

-- 25. Write a query to find the top 3 products with the highest total sales amount each month.
-- Solution 1
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

-- Solution 2
WITH cte AS (
	SELECT DATE_TRUNC('month', sale_date) AS sale_month, product_id, SUM(amount) AS total_amount
	FROM sales
	GROUP BY sale_month, product_id
	ORDER BY sale_month, product_id
)
SELECT sale_month, product_id FROM (
	SELECT * , ROW_NUMBER() OVER (PARTITION BY sale_month ORDER BY total_amount DESC) AS rnb FROM cte) sub
WHERE rnb <= 3;

-- 26. Write a query to identify "gaps and islands" in attendance records (consecutive dates present).
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

-- 27. Write a query to find products with increasing sales over the last 3 months.
-- Solution 1
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

-- Solution 2
WITH monthly_sales AS (
	SELECT product_id, DATE_TRUNC('month', sale_date) AS sale_month, SUM(amount) AS total_amount
	FROM sales GROUP BY product_id, sale_month
)
SELECT m1.product_id,
m1.sale_month AS m_1, m2.sale_month AS m_2, m3.sale_month AS m_3,
m1.total_amount AS amount_1, m2.total_amount AS amount_2, m3.total_amount AS amount_3
FROM monthly_sales m1
INNER JOIN monthly_sales m2 ON m1.product_id = m2.product_id AND m1.total_amount < m2.total_amount AND m1.sale_month = m2.sale_month - INTERVAL '1 month'
INNER JOIN monthly_sales m3 ON m1.product_id = m3.product_id AND m2.total_amount < m3.total_amount AND m2.sale_month = m3.sale_month - INTERVAL '1 month'
WHERE m3.sale_month = CURRENT_DATE - INTERVAL '1 months';
;

-- 28. Identify employees who had overlapping project assignments.
SELECT p1.employee_id, p1.project_id AS project1, p2.project_id AS project2
FROM project_assignments p1
JOIN project_assignments p2 ON p1.employee_id = p2.employee_id AND p1.project_id < p2.project_id
WHERE p1.start_date < p2.end_date AND p1.end_date > p2.start_date;

-- 29. List employees who earn more than all their subordinates.
-- Solution 1
SELECT e.id, e.name, e.salary 
FROM employees e
WHERE e.salary > ALL (
    SELECT salary
    FROM employees sub
    WHERE sub.manager_id = e.id
);

-- Solution 2
SELECT e1.id AS manage_id, e2.id AS emp_id, e1.salary AS manager_salary, e2.salary AS emp_salary
FROM employees e1 -- manager
JOIN employees e2 -- employee
ON e1.id = e2.manager_id
WHERE e1.salary > (SELECT MAX(salary) FROM employees e WHERE e1.id = e.manager_id) -- corralated sub-query
ORDER BY e1.id, e2.id;

-- Solution 3
WITH cte AS (
	SELECT e1.id AS manage_id, e2.id AS emp_id, e1.salary AS manager_salary, e2.salary AS emp_salary
	FROM employees e1 -- manager
	JOIN employees e2 -- employee
	ON e1.id = e2.manager_id
)
SELECT manage_id, manager_salary, MAX(emp_salary) AS max_salary
FROM cte
GROUP BY manage_id, manager_salary
HAVING manager_salary > MAX(emp_salary)
ORDER BY manage_id;

-- 30. Find the moving median of daily sales over the last 7 days for each product.
-- Solution 1 - Postgres not support
WITH daily_sales AS (
    SELECT product_id, sale_date, SUM(amount) AS total_sales
    FROM sales
    GROUP BY product_id, sale_date
)
SELECT product_id, sale_date, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) 
       OVER (PARTITION BY product_id ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_median 
FROM daily_sales;

-- Solution 2
WITH daily_sales AS (
    SELECT product_id, sale_date, SUM(amount) AS total_sales
    FROM sales
    GROUP BY product_id, sale_date
)
SELECT d1.product_id,
       d1.sale_date,
       (
           SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY d2.total_sales)
           FROM daily_sales d2
           WHERE d2.product_id = d1.product_id
             AND d2.sale_date BETWEEN d1.sale_date - INTERVAL '6 day' AND d1.sale_date
       ) AS moving_median_7_days
FROM daily_sales d1
ORDER BY d1.product_id, d1.sale_date;

-- 31. Write a query to generate a calendar table with all dates for the current year.
SELECT generate_series(
    DATE_TRUNC('year', CURRENT_DATE), 
    DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year' - INTERVAL '1 day', 
    INTERVAL '1 day'
) AS calendar_date;

-- Another
WITH RECURSIVE series(n) AS (
	-- base
	SELECT 1
	UNION ALL
	-- recursive
	SELECT s.n + 1 FROM series s
	WHERE s.n < 10
)
SELECT * FROM generate_series(1, 10, 1);
WITH series_2(n) AS (
	VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)
)

-- 32. Write a query to pivot monthly sales data for each product into columns.
SELECT product_id,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 1 THEN amount ELSE 0 END) AS Jan,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 2 THEN amount ELSE 0 END) AS Feb,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 3 THEN amount ELSE 0 END) AS Mar,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 4 THEN amount ELSE 0 END) AS Apr,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 5 THEN amount ELSE 0 END) AS May,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 6 THEN amount ELSE 0 END) AS Jun,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 7 THEN amount ELSE 0 END) AS Jul,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 8 THEN amount ELSE 0 END) AS Aug,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 9 THEN amount ELSE 0 END) AS Sep,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 10 THEN amount ELSE 0 END) AS Oct,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 11 THEN amount ELSE 0 END) AS Nov,
       SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 12 THEN amount ELSE 0 END) AS Dec 
FROM sales
GROUP BY product_id;

-- 33. List customers who placed orders in January but not in February.
WITH jan_orders AS (
    SELECT DISTINCT customer_id 
    FROM orders
    WHERE EXTRACT(MONTH FROM order_date) = 1
),
feb_orders AS (
    SELECT DISTINCT customer_id
    FROM orders 
    WHERE EXTRACT(MONTH FROM order_date) = 2
)
SELECT customer_id
FROM jan_orders
WHERE customer_id NOT IN (SELECT customer_id FROM feb_orders);

-- 34. Find employees who joined in the same month and year.
SELECT e1.id AS emp1_id, e2.id AS emp2_id, e1.hire_date
FROM employees e1
JOIN employees e2 ON e1.id < e2.id
  AND EXTRACT(MONTH FROM e1.hire_date) = EXTRACT(MONTH FROM e2.hire_date)
  AND EXTRACT(YEAR FROM e1.hire_date) = EXTRACT(YEAR FROM e2.hire_date);

-- 35. Find the second highest salary per department without using window functions.
SELECT department_id, MAX(salary) AS second_highest_salary
FROM employees e1
WHERE salary < (
    SELECT MAX(salary)
    FROM employees e2
    WHERE e2.department_id = e1.department_id
)
GROUP BY department_id;

-- 36. Get the total number of orders per day, including days with zero orders.
WITH dates AS (
    SELECT generate_series(MIN(order_date), MAX(order_date), INTERVAL '1 day') AS day 
    FROM orders
)
SELECT d.day, COUNT(o.order_id) AS order_count
FROM dates d
LEFT JOIN orders o ON d.day = o.order_date 
GROUP BY d.day
ORDER BY d.day;

-- 36. Find customers with the longest gap between two consecutive orders.
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

-- 37. Find employees whose salaries are between the 25th and 75th percentile.
WITH percentiles AS (
    SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) AS p25,
           PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) AS p75
    FROM employees
)
SELECT e.*
FROM employees e, percentiles p
WHERE e.salary BETWEEN p.p25 AND p.p75;

-- 38. Find products with sales only in the current month.
SELECT product_id 
FROM sales
GROUP BY product_id 
HAVING MAX(sale_date) < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
   AND MIN(sale_date) >= DATE_TRUNC('month', CURRENT_DATE);

-- 39. Find employees with consecutive workdays.
WITH attendance AS (
    SELECT employee_id, work_date, 
           work_date - INTERVAL (ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY work_date)) DAY AS grp 
    FROM work_log
)
SELECT employee_id, COUNT(*) AS consecutive_days
FROM attendance
GROUP BY employee_id, grp 
HAVING COUNT(*) > 1;

-- 40. Find the top 3 employees with the highest salary increase over last year.
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