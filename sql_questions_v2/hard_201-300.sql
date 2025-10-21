-- Hard SQL Questions 201-300
-- Recursive CTEs, complex analytics, advanced optimization, and expert-level queries

-- 201. Recursive query to find the full reporting chain for each employee.
WITH RECURSIVE reporting_chain AS (
    SELECT id, name, manager_id, 1 AS level 
    FROM employees
    WHERE manager_id IS NULL 
    UNION ALL
    SELECT e.id, e.name, e.manager_id, rc.level + 1 
    FROM employees e
    JOIN reporting_chain rc ON e.manager_id = rc.id
)
SELECT * FROM reporting_chain
ORDER BY level, id;

-- 202. Write a query to find gaps in a sequence of numbers (missing IDs).
SELECT (id + 1) AS missing_id 
FROM employees e1
WHERE NOT EXISTS (
    SELECT 1 FROM employees e2 WHERE e2.id = e1.id + 1
)
ORDER BY missing_id;

-- 203. Compare two tables and find rows with differences in any column.
SELECT *
FROM table1 t1
FULL OUTER JOIN table2 t2 ON t1.id = t2.id
WHERE t1.col1 IS DISTINCT FROM t2.col1 
   OR t1.col2 IS DISTINCT FROM t2.col2 
   OR t1.col3 IS DISTINCT FROM t2.col3;

-- 204. Find employees whose salary is a prime number.
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

-- 205. Detect hierarchical depth of each employee in the org chart.
WITH RECURSIVE employee_depth AS (
    SELECT id, name, manager_id, 1 AS depth 
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.id, e.name, e.manager_id, ed.depth + 1 
    FROM employees e
    JOIN employee_depth ed ON e.manager_id = ed.id
)
SELECT * FROM employee_depth;

-- 206. Write a query to perform a self-join to find pairs of employees in the same department.
SELECT e1.name AS Employee1, e2.name AS Employee2, e1.department_id
FROM employees e1
JOIN employees e2 ON e1.department_id = e2.department_id AND e1.id < e2.id;

-- 207. Write a query to detect circular references in employee-manager hierarchy (cycles).
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

-- 208. Write a query to get employees who reported directly or indirectly to a given manager (hierarchy traversal).
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

-- 209. Write a recursive query to list all ancestors (managers) of a given employee.
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

-- 210. Write a recursive query to list all descendants of a manager in an organizational hierarchy.
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

-- 211. Write a recursive query to find all employees and their level of reporting (distance from CEO).
WITH RECURSIVE hierarchy AS (
    SELECT id, name, manager_id, 1 AS level 
    FROM employees
    WHERE manager_id IS NULL -- CEO level 
    UNION ALL
    SELECT e.id, e.name, e.manager_id, h.level + 1 
    FROM employees e
    JOIN hierarchy h ON e.manager_id = h.id
)
SELECT * FROM hierarchy
ORDER BY level, manager_id;

-- 212. Write a query to identify duplicate rows (all columns) in a table.
SELECT *, COUNT(*) OVER (PARTITION BY col1, col2, col3) AS cnt
FROM table_name
WHERE cnt > 1;
-- Note: Replace col1, col2, col3 with actual column names

-- 213. Write a recursive query to compute the total budget under each manager (including subordinates).
WITH RECURSIVE manager_budget AS (
    SELECT id, manager_id, budget
    FROM departments
    UNION ALL
    SELECT d.id, d.manager_id, mb.budget 
    FROM departments d
    JOIN manager_budget mb ON d.manager_id = mb.id
)
SELECT manager_id, SUM(budget) AS total_budget 
FROM manager_budget
GROUP BY manager_id;

-- 214. Write a query to detect gaps in a sequence of invoice numbers.
WITH numbered_invoices AS (
    SELECT invoice_number, 
           ROW_NUMBER() OVER (ORDER BY invoice_number) AS rn
    FROM invoices
)
SELECT invoice_number + 1 AS missing_invoice 
FROM numbered_invoices ni
WHERE (invoice_number + 1) NOT IN (
    SELECT invoice_number 
    FROM numbered_invoices 
    WHERE rn = ni.rn + 1
);

-- 215. Find employees whose salary is above the company's average but below their department's average.
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

-- 216. Find employees who have worked on at least one project with a budget over $1,000,000.
SELECT DISTINCT pa.employee_id 
FROM project_assignments pa
JOIN projects p ON pa.project_id = p.project_id
WHERE p.budget > 1000000;

-- 217. Find customers who made orders totaling more than the average order amount.
WITH avg_order AS (
    SELECT AVG(amount) AS avg_amount 
    FROM orders
)
SELECT customer_id, SUM(amount) AS total_amount 
FROM orders
GROUP BY customer_id
HAVING SUM(amount) > (SELECT avg_amount FROM avg_order);

-- 218. Find customers with orders on every day in the last week.
WITH days AS (
    SELECT generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, INTERVAL '1 day') AS day
)
SELECT customer_id
FROM orders o
JOIN days d ON o.order_date = d.day
GROUP BY customer_id
HAVING COUNT(DISTINCT o.order_date) = 7;

-- 219. Find customers who have increased their order volume every month for the last 3 months.
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

-- 220. Write a recursive query to get all descendants of a manager.
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

-- 221. Find the department with the highest variance in salaries.
SELECT department_id, VAR_SAMP(salary) AS salary_variance
FROM employees
GROUP BY department_id 
ORDER BY salary_variance DESC 
LIMIT 1;

-- 222. Calculate the difference between each order amount and the previous order amount per customer.
SELECT customer_id, order_date, amount,
       amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS diff 
FROM orders;

-- 223. Find customers who purchased both Product A and Product B.
SELECT customer_id
FROM sales
WHERE product_id IN ('A', 'B') 
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = 2;

-- 224. Write a query to display all employees who have worked on a project longer than 6 months.
SELECT employee_id
FROM project_assignments
WHERE end_date - start_date > INTERVAL '6 months';

-- 225. Find products with sales increasing every month for the last 3 months.
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

-- 226. Write a query to find employees who worked on more than 3 projects in 2023.
SELECT employee_id, COUNT(DISTINCT project_id) AS project_count
FROM project_assignments
WHERE assignment_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY employee_id
HAVING COUNT(DISTINCT project_id) > 3;

-- 227. Find the average salary increase percentage per department.
SELECT e.department_id, 
       AVG((e.salary - p.old_salary) / p.old_salary * 100) AS avg_increase_pct
FROM employees e
JOIN promotions p ON e.id = p.employee_id 
GROUP BY e.department_id;

-- 228. Find products ordered by all customers.
SELECT product_id 
FROM sales
GROUP BY product_id
HAVING COUNT(DISTINCT customer_id) = (SELECT COUNT(*) FROM customers);

-- 229. Find customers who purchased a product but never reordered it.
WITH order_counts AS (
    SELECT customer_id, product_id, COUNT(*) AS order_count
    FROM sales
    GROUP BY customer_id, product_id
)
SELECT customer_id, product_id 
FROM order_counts
WHERE order_count = 1;

-- 230. Find the number of employees who have worked in more than one department.
SELECT COUNT(DISTINCT employee_id) AS multi_dept_employees
FROM employee_department_history 
GROUP BY employee_id
HAVING COUNT(DISTINCT department_id) > 1;

-- 231. Find employees with overlapping project assignments.
SELECT pa1.employee_id, pa1.project_id, pa2.project_id AS overlapping_project
FROM project_assignments pa1
JOIN project_assignments pa2 ON pa1.employee_id = pa2.employee_id 
    AND pa1.project_id < pa2.project_id
WHERE pa1.start_date <= pa2.end_date AND pa1.end_date >= pa2.start_date;

-- 232. Find customers whose orders increased by at least 20% compared to the previous month.
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

-- 233. Find the number of employees who have changed departments more than twice.
SELECT COUNT(DISTINCT employee_id) AS frequent_changers
FROM employee_department_history 
GROUP BY employee_id
HAVING COUNT(DISTINCT department_id) > 2;

-- 234. Find employees who have worked on every project in their department.
SELECT e.id, e.name
FROM employees e
JOIN projects p ON e.department_id = p.department_id
LEFT JOIN project_assignments pa ON e.id = pa.employee_id AND p.project_id = pa.project_id 
GROUP BY e.id, e.name, p.department_id
HAVING COUNT(p.project_id) = COUNT(pa.project_id);

-- 235. Find the average order amount excluding the top 5% largest orders.
WITH ordered_orders AS (
    SELECT amount,
           NTILE(100) OVER (ORDER BY amount DESC) AS percentile 
    FROM orders
)
SELECT AVG(amount) AS avg_excluding_top5pct
FROM ordered_orders
WHERE percentile > 5;

-- 236. Find the top 3 employees with the highest salary increase over last year.
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

-- 237. Find employees with the longest consecutive workdays.
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

-- 238. Find all managers who do not manage any employee.
SELECT DISTINCT manager_id
FROM employees
WHERE manager_id NOT IN (SELECT DISTINCT id FROM employees WHERE manager_id IS NOT NULL);

-- 239. Find the average salary of employees hired each month.
SELECT EXTRACT(YEAR FROM hire_date) AS year, 
       EXTRACT(MONTH FROM hire_date) AS month, 
       AVG(salary) AS avg_salary
FROM employees
GROUP BY year, month 
ORDER BY year, month;

-- 240. Find the first 5 orders after a customer's registration date.
SELECT order_id, customer_id, order_date 
FROM (
    SELECT order_id, customer_id, order_date, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS rn 
    FROM orders
    JOIN customers c ON orders.customer_id = c.customer_id
    WHERE order_date >= c.registration_date
) sub
WHERE rn <= 5;

-- 241. Find customers who placed orders every month for the last 6 months.
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

-- 242. Calculate the moving average of sales over the last 3 days.
SELECT sale_date, product_id, amount, 
       AVG(amount) OVER (PARTITION BY product_id ORDER BY sale_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_days 
FROM sales;

-- 243. Find the number of employees who share the same birthday.
SELECT birth_date, COUNT(*) AS count_employees
FROM employees 
GROUP BY birth_date
HAVING COUNT(*) > 1;

-- 244. Find customers who ordered the same product multiple times in one day.
SELECT customer_id, product_id, order_date, COUNT(*) AS order_count
FROM sales
GROUP BY customer_id, product_id, order_date 
HAVING COUNT(*) > 1;

-- 245. Find the total sales for each product including products with zero sales.
SELECT p.product_id, COALESCE(SUM(s.amount), 0) AS total_sales
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id;

-- 246. List the top 5 employees by number of projects in each department.
SELECT department_id, employee_id, project_count 
FROM (
    SELECT e.department_id, pa.employee_id,
           COUNT(DISTINCT pa.project_id) AS project_count, 
           ROW_NUMBER() OVER (PARTITION BY e.department_id ORDER BY COUNT(DISTINCT pa.project_id) DESC) AS rn
    FROM project_assignments pa
    JOIN employees e ON pa.employee_id = e.id 
    GROUP BY e.department_id, pa.employee_id 
) sub
WHERE rn <= 5;

-- 247. Find the day with the largest difference between maximum and minimum temperature.
SELECT weather_date, MAX(temperature) - MIN(temperature) AS temp_diff
FROM weather_data
GROUP BY weather_date
ORDER BY temp_diff DESC 
LIMIT 1;

-- 248. Find the 3 most recent orders per customer.
SELECT order_id, customer_id, order_date
FROM (
    SELECT order_id, customer_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders
) sub
WHERE rn <= 3;

-- 249. Find products with sales only in a specific country.
SELECT product_id 
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id 
GROUP BY product_id
HAVING COUNT(DISTINCT c.country) = 1;

-- 250. Find employees with a salary greater than all employees in department 10.
SELECT *
FROM employees 
WHERE salary > ALL (
    SELECT salary 
    FROM employees 
    WHERE department_id = 10
);

-- 251. Find the percentage of employees in each department.
WITH total_employees AS (SELECT COUNT(*) AS total FROM employees)
SELECT department_id, 
       COUNT(*) * 100.0 / (SELECT total FROM total_employees) AS percentage
FROM employees
GROUP BY department_id;

-- 252. Find the median salary per department.
SELECT department_id, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary 
FROM employees
GROUP BY department_id;

-- 253. Find the employee who worked the most hours in a project.
SELECT employee_id, project_id, MAX(hours_worked) AS max_hours 
FROM project_assignments
GROUP BY employee_id, project_id 
ORDER BY max_hours DESC
LIMIT 1;

-- 254. Find the second most expensive product per category.
SELECT category_id, product_id, price 
FROM (
    SELECT category_id, product_id, price,
           ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rn 
    FROM products
) sub
WHERE rn = 2;

-- 255. Find employees with the highest salary in each job title.
WITH max_salary_per_job AS (
    SELECT job_title, MAX(salary) AS max_salary
    FROM employees
    GROUP BY job_title
)
SELECT e.*
FROM employees e
JOIN max_salary_per_job m ON e.job_title = m.job_title AND e.salary = m.max_salary;

-- 256. Calculate the ratio of males to females in each department.
SELECT department_id,
       SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) * 1.0 / 
       NULLIF(SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END), 0) AS male_to_female_ratio 
FROM employees
GROUP BY department_id;

-- 257. Find customers who spent more than average in their country.
WITH avg_spent_per_country AS (
    SELECT c.country, AVG(o.amount) AS avg_amount 
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id 
    GROUP BY c.country
)
SELECT c.customer_id, SUM(o.amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id 
JOIN avg_spent_per_country a ON c.country = a.country
GROUP BY c.customer_id, c.country, a.avg_amount 
HAVING SUM(o.amount) > a.avg_amount;

-- 258. Find employees who have not been assigned to any project in the last year.
SELECT e.*
FROM employees e
LEFT JOIN project_assignments pa ON e.id = pa.employee_id 
    AND pa.assignment_date >= CURRENT_DATE - INTERVAL '1 year' 
WHERE pa.project_id IS NULL;

-- 259. Find the top 3 customers by total order amount in each region.
SELECT region, customer_id, total_amount 
FROM (
    SELECT c.region, o.customer_id, SUM(o.amount) AS total_amount,
           ROW_NUMBER() OVER (PARTITION BY c.region ORDER BY SUM(o.amount) DESC) AS rn
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.region, o.customer_id 
) sub
WHERE rn <= 3;

-- 260. Find employees hired after their managers.
SELECT e.name AS employee_name, m.name AS manager_name, 
       e.hire_date, m.hire_date AS manager_hire_date 
FROM employees e
JOIN employees m ON e.manager_id = m.id
WHERE e.hire_date > m.hire_date;

-- 261. Find customers who ordered all products from a specific category.
WITH category_products AS (
    SELECT product_id 
    FROM products
    WHERE category_id = 1 -- replace with specific category_id
),
customer_products AS (
    SELECT customer_id, product_id 
    FROM sales
    WHERE product_id IN (SELECT product_id FROM category_products)
    GROUP BY customer_id, product_id
)
SELECT customer_id
FROM customer_products 
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (SELECT COUNT(*) FROM category_products);

-- 262. Find employees with the highest number of direct reports.
SELECT manager_id, COUNT(*) AS report_count 
FROM employees
WHERE manager_id IS NOT NULL
GROUP BY manager_id
ORDER BY report_count DESC
LIMIT 1;

-- 263. Calculate the retention rate of customers month-over-month.
WITH monthly_customers AS (
    SELECT customer_id, DATE_TRUNC('month', order_date) AS month
    FROM orders
    GROUP BY customer_id, month
),
retention AS (
    SELECT current.month AS current_month, current.customer_id
    FROM monthly_customers current
    JOIN monthly_customers previous ON current.customer_id = previous.customer_id
        AND current.month = previous.month + INTERVAL '1 month'
)
SELECT current_month, 
       COUNT(DISTINCT customer_id) * 100.0 / (
           SELECT COUNT(DISTINCT customer_id)
           FROM monthly_customers
           WHERE month = current_month - INTERVAL '1 month'
       ) AS retention_rate
FROM retention
GROUP BY current_month
ORDER BY current_month;

-- 264. Find the average time difference between order and delivery.
SELECT AVG(delivery_date - order_date) AS avg_delivery_time 
FROM orders
WHERE delivery_date IS NOT NULL;

-- 265. Find the department with the youngest average employee age.
SELECT department_id, 
       AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))) AS avg_age
FROM employees
GROUP BY department_id 
ORDER BY avg_age
LIMIT 1;

-- 266. Find products that were sold in every quarter of the current year.
WITH quarterly_sales AS (
    SELECT product_id, DATE_TRUNC('quarter', sale_date) AS quarter 
    FROM sales
    WHERE EXTRACT(YEAR FROM sale_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY product_id, quarter 
)
SELECT product_id 
FROM quarterly_sales
GROUP BY product_id
HAVING COUNT(DISTINCT quarter) = 4;

-- 267. Find customers whose orders decreased consecutively for 3 months.
WITH monthly_orders AS (
    SELECT customer_id, 
           DATE_TRUNC('month', order_date) AS month, 
           COUNT(*) AS order_count 
    FROM orders
    GROUP BY customer_id, month
),
orders_with_lag AS (
    SELECT customer_id, month, order_count, 
           LAG(order_count, 1) OVER (PARTITION BY customer_id ORDER BY month) AS prev_1, 
           LAG(order_count, 2) OVER (PARTITION BY customer_id ORDER BY month) AS prev_2
    FROM monthly_orders 
)
SELECT DISTINCT customer_id
FROM orders_with_lag
WHERE order_count < prev_1 AND prev_1 < prev_2;

-- 268. Find the employee(s) with the highest number of late arrivals.
SELECT employee_id, COUNT(*) AS late_count 
FROM attendance
WHERE arrival_time > scheduled_start_time
GROUP BY employee_id 
ORDER BY late_count DESC
LIMIT 1;

-- 269. Find the most common product combinations in orders (pairs).
WITH order_pairs AS (
    SELECT o1.order_id, o1.product_id AS product1, o2.product_id AS product2 
    FROM order_items o1
    JOIN order_items o2 ON o1.order_id = o2.order_id
        AND o1.product_id < o2.product_id 
)
SELECT product1, product2, COUNT(*) AS pair_count
FROM order_pairs
GROUP BY product1, product2
ORDER BY pair_count DESC
LIMIT 10;

-- 270. Find employees who have worked more than 40 hours in a week.
WITH weekly_hours AS (
    SELECT employee_id, 
           DATE_TRUNC('week', work_date) AS week_start, 
           SUM(hours_worked) AS total_hours
    FROM work_logs
    GROUP BY employee_id, week_start
)
SELECT employee_id, week_start, total_hours 
FROM weekly_hours
WHERE total_hours > 40;

-- 271. Find products with an increasing sales trend over the last 3 months.
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    WHERE sale_date >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY product_id, month
),
sales_ranked AS (
    SELECT product_id, month, total_sales,
           LAG(total_sales) OVER (PARTITION BY product_id ORDER BY month) AS prev_month_sales, 
           LAG(total_sales, 2) OVER (PARTITION BY product_id ORDER BY month) AS prev_2_month_sales 
    FROM monthly_sales 
)
SELECT DISTINCT product_id 
FROM sales_ranked
WHERE total_sales > prev_month_sales AND prev_month_sales > prev_2_month_sales;

-- 272. Find departments where average salary is higher than the company average.
WITH company_avg AS (
    SELECT AVG(salary) AS avg_salary 
    FROM employees
)
SELECT department_id, AVG(salary) AS dept_avg 
FROM employees
GROUP BY department_id
HAVING AVG(salary) > (SELECT avg_salary FROM company_avg);

-- 273. Find customers with orders where no product quantity is less than 5.
SELECT DISTINCT customer_id 
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY customer_id, o.order_id 
HAVING MIN(oi.quantity) >= 5;

-- 274. Find employees who have not submitted their timesheets in the last month.
SELECT e.id, e.name 
FROM employees e
LEFT JOIN timesheets t ON e.id = t.employee_id 
    AND t.timesheet_date >= CURRENT_DATE - INTERVAL '1 month'
WHERE t.timesheet_id IS NULL;

-- 275. Find employees whose salaries are within 10% of their department's average salary.
WITH dept_avg AS (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id 
)
SELECT e.*
FROM employees e
JOIN dept_avg d ON e.department_id = d.department_id
WHERE e.salary BETWEEN d.avg_salary * 0.9 AND d.avg_salary * 1.1;

-- 276. Find customers who ordered the most products in each category.
WITH product_totals AS (
    SELECT c.customer_id, p.category_id,
           SUM(s.quantity) AS total_quantity,
           RANK() OVER (PARTITION BY p.category_id ORDER BY SUM(s.quantity) DESC) AS rank
    FROM sales s
    JOIN products p ON s.product_id = p.product_id 
    JOIN customers c ON s.customer_id = c.customer_id
    GROUP BY c.customer_id, p.category_id 
)
SELECT customer_id, category_id, total_quantity 
FROM product_totals
WHERE rank = 1;

-- 277. Find the department with the most projects completed last year.
SELECT department_id, COUNT(*) AS completed_projects
FROM projects
WHERE status = 'Completed' 
  AND completion_date BETWEEN 
      DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year' 
      AND DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 day'
GROUP BY department_id
ORDER BY completed_projects DESC
LIMIT 1;

-- 278. Find customers who have increased their order frequency month-over-month for 3 consecutive months.
WITH monthly_orders AS (
    SELECT customer_id, 
           DATE_TRUNC('month', order_date) AS month, 
           COUNT(*) AS order_count 
    FROM orders
    GROUP BY customer_id, month
),
orders_with_lag AS (
    SELECT customer_id, month, order_count,
           LAG(order_count, 1) OVER (PARTITION BY customer_id ORDER BY month) AS prev_1, 
           LAG(order_count, 2) OVER (PARTITION BY customer_id ORDER BY month) AS prev_2
    FROM monthly_orders
)
SELECT DISTINCT customer_id
FROM orders_with_lag
WHERE order_count > prev_1 AND prev_1 > prev_2;

-- 279. Find employees who have been assigned projects outside their department.
SELECT DISTINCT e.id, e.name 
FROM employees e
JOIN project_assignments pa ON e.id = pa.employee_id
JOIN projects p ON pa.project_id = p.project_id 
WHERE e.department_id != p.department_id;

-- 280. Calculate the average time to close tickets per support agent.
SELECT support_agent_id, 
       AVG(closed_date - opened_date) AS avg_close_time
FROM support_tickets
WHERE closed_date IS NOT NULL
GROUP BY support_agent_id;

-- 281. Find the first and last login date for each user.
SELECT user_id, 
       MIN(login_date) AS first_login, 
       MAX(login_date) AS last_login
FROM user_logins
GROUP BY user_id;

-- 282. Find customers who made purchases only in one month of the year.
WITH customer_months AS (
    SELECT customer_id, DATE_TRUNC('month', order_date) AS month
    FROM orders
    GROUP BY customer_id, month
)
SELECT customer_id
FROM customer_months 
GROUP BY customer_id
HAVING COUNT(*) = 1;

-- 283. Find products with sales revenue above the average revenue per product.
WITH avg_revenue AS (
    SELECT AVG(total_revenue) AS avg_rev
    FROM (
        SELECT product_id, SUM(amount) AS total_revenue
        FROM sales
        GROUP BY product_id 
    ) sub
)
SELECT product_id, SUM(amount) AS total_revenue 
FROM sales
GROUP BY product_id
HAVING SUM(amount) > (SELECT avg_rev FROM avg_revenue);

-- 284. Find departments where more than 50% of employees have a salary above $60,000.
SELECT department_id
FROM employees
GROUP BY department_id
HAVING AVG(CASE WHEN salary > 60000 THEN 1 ELSE 0 END) > 0.5;

-- 285. Find employees who worked on all projects in the company.
WITH total_projects AS (
    SELECT COUNT(DISTINCT project_id) AS project_count 
    FROM projects
),
employee_projects AS (
    SELECT employee_id, COUNT(DISTINCT project_id) AS projects_worked 
    FROM project_assignments
    GROUP BY employee_id 
)
SELECT ep.employee_id 
FROM employee_projects ep
JOIN total_projects tp ON 1=1
WHERE ep.projects_worked = tp.project_count;

-- 286. Find customers who ordered products from all categories.
WITH category_count AS (
    SELECT COUNT(DISTINCT category_id) AS total_categories 
    FROM products
),
customer_categories AS (
    SELECT customer_id, COUNT(DISTINCT p.category_id) AS categories_ordered 
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY customer_id 
)
SELECT customer_id
FROM customer_categories
JOIN category_count ON 1=1
WHERE categories_ordered = total_categories;

-- 287. Find the average tenure of employees by department.
SELECT department_id, 
       AVG(DATE_PART('year', CURRENT_DATE - hire_date)) AS avg_tenure_years 
FROM employees
GROUP BY department_id;

-- 288. Find the number of orders placed on weekends vs weekdays.
SELECT CASE
    WHEN EXTRACT(DOW FROM order_date) IN (0,6) THEN 'Weekend' 
    ELSE 'Weekday'
END AS day_type,
COUNT(*) AS order_count 
FROM orders
GROUP BY day_type;

-- 289. Find the percentage of orders with discounts per month.
SELECT DATE_TRUNC('month', order_date) AS month,
       100.0 * SUM(CASE WHEN discount > 0 THEN 1 ELSE 0 END) / COUNT(*) AS discount_percentage 
FROM orders
GROUP BY month 
ORDER BY month;

-- 290. Find the employees who have never been late to work.
SELECT e.id, e.name
FROM employees e
LEFT JOIN attendance a ON e.id = a.employee_id 
    AND a.arrival_time > a.scheduled_start_time
WHERE a.employee_id IS NULL;

-- 291. Find products with sales only during holiday seasons.
SELECT product_id 
FROM sales s
JOIN holidays h ON s.sale_date = h.holiday_date
GROUP BY product_id
HAVING COUNT(*) = (
    SELECT COUNT(*) 
    FROM sales 
    WHERE product_id = s.product_id
);

-- 292. Find the department with the largest increase in employee count compared to last year.
WITH current_year AS (
    SELECT department_id, COUNT(*) AS emp_count 
    FROM employees
    WHERE hire_date <= CURRENT_DATE 
      AND (termination_date IS NULL OR termination_date >= CURRENT_DATE)
    GROUP BY department_id
),
last_year AS (
    SELECT department_id, COUNT(*) AS emp_count 
    FROM employees
    WHERE hire_date <= CURRENT_DATE - INTERVAL '1 year' 
      AND (termination_date IS NULL OR termination_date >= CURRENT_DATE - INTERVAL '1 year')
    GROUP BY department_id
)
SELECT c.department_id, 
       c.emp_count - COALESCE(l.emp_count, 0) AS increase
FROM current_year c
LEFT JOIN last_year l ON c.department_id = l.department_id
ORDER BY increase DESC
LIMIT 1;

-- 293. Find employees who manage more than 3 projects.
SELECT manager_id, COUNT(DISTINCT project_id) AS project_count
FROM projects
GROUP BY manager_id
HAVING COUNT(DISTINCT project_id) > 3;

-- 294. Find products that have never been returned.
SELECT p.product_id
FROM products p
LEFT JOIN returns r ON p.product_id = r.product_id
WHERE r.return_id IS NULL;

-- 295. Find customers with orders but no shipments.
SELECT DISTINCT o.customer_id
FROM orders o
LEFT JOIN shipments s ON o.order_id = s.order_id
WHERE s.shipment_id IS NULL;

-- 296. Find employees whose salaries increased every year.
WITH salary_diff AS (
    SELECT employee_id, year, salary, 
           LAG(salary) OVER (PARTITION BY employee_id ORDER BY year) AS prev_salary
    FROM salaries
)
SELECT DISTINCT employee_id
FROM salary_diff
WHERE salary > prev_salary OR prev_salary IS NULL 
GROUP BY employee_id
HAVING COUNT(*) = (SELECT COUNT(*) FROM salaries s2 WHERE s2.employee_id = salary_diff.employee_id);

-- 297. Find the total number of unique products sold in the last quarter.
SELECT COUNT(DISTINCT product_id) AS unique_products_sold 
FROM sales
WHERE sale_date >= DATE_TRUNC('quarter', CURRENT_DATE) - INTERVAL '3 months'
  AND sale_date < DATE_TRUNC('quarter', CURRENT_DATE);

-- 298. Find the day with the highest sales in each month.
WITH daily_sales AS (
    SELECT DATE(order_date) AS day, SUM(amount) AS total_sales
    FROM orders 
    GROUP BY day
),
ranked_sales AS (
    SELECT day, total_sales,
           RANK() OVER (PARTITION BY DATE_TRUNC('month', day) ORDER BY total_sales DESC) AS sales_rank
    FROM daily_sales 
)
SELECT day, total_sales 
FROM ranked_sales
WHERE sales_rank = 1;

-- 299. Find the products with the highest sales increase compared to the previous month.
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    GROUP BY product_id, month
),
sales_diff AS (
    SELECT product_id, month, total_sales, 
           LAG(total_sales) OVER (PARTITION BY product_id ORDER BY month) AS prev_month_sales
    FROM monthly_sales
)
SELECT product_id, month, total_sales - prev_month_sales AS increase
FROM sales_diff
WHERE prev_month_sales IS NOT NULL 
ORDER BY increase DESC
LIMIT 1;

-- 300. Find the top 5 customers by total order value in the last year.
SELECT customer_id, SUM(amount) AS total_order_value
FROM orders 
WHERE order_date >= CURRENT_DATE - INTERVAL '1 year' 
GROUP BY customer_id
ORDER BY total_order_value DESC
LIMIT 5;