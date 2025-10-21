-- SQL Questions 271-300

-- 271. Find the total revenue generated per sales representative.
-- Calculate total revenue by sales rep
SELECT sales_rep_id, SUM(amount) AS total_revenue 
FROM sales
GROUP BY sales_rep_id;

-- 272. Find customers with no orders in the last year.
-- Find inactive customers
SELECT customer_id
FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '1 year'
);

-- 273. Find products with an increasing sales trend over the last 3 months.
-- Find products with consistent sales growth
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

-- 274. Find departments where average salary is higher than the company average.
-- Find above-average salary departments
WITH company_avg AS (
    SELECT AVG(salary) AS avg_salary 
    FROM employees
)
SELECT department_id, AVG(salary) AS dept_avg 
FROM employees
GROUP BY department_id
HAVING AVG(salary) > (SELECT avg_salary FROM company_avg);

-- 275. Find customers with orders where no product quantity is less than 5.
-- Find customers with consistently large quantity orders
SELECT DISTINCT customer_id 
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY customer_id, o.order_id 
HAVING MIN(oi.quantity) >= 5;

-- 276. Find products ordered only by customers from one country.
-- Find country-specific products
SELECT product_id 
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
GROUP BY product_id
HAVING COUNT(DISTINCT c.country) = 1;

-- 277. Find employees who have not submitted their timesheets in the last month.
-- Find employees missing recent timesheets
SELECT e.id, e.name 
FROM employees e
LEFT JOIN timesheets t ON e.id = t.employee_id 
    AND t.timesheet_date >= CURRENT_DATE - INTERVAL '1 month'
WHERE t.timesheet_id IS NULL;

-- 278. Find the total discount given in each month.
-- Calculate monthly discount totals
SELECT DATE_TRUNC('month', order_date) AS month, 
       SUM(discount_amount) AS total_discount 
FROM orders
GROUP BY month 
ORDER BY month;

-- 279. Find customers who have placed orders but never paid by credit card.
-- Find customers who never used credit card payment
SELECT DISTINCT customer_id
FROM orders
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM orders 
    WHERE payment_method = 'Credit Card'
);

-- 280. Find employees whose salaries are within 10% of their department's average salary.
-- Find employees near department salary average
WITH dept_avg AS (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id 
)
SELECT e.*
FROM employees e
JOIN dept_avg d ON e.department_id = d.department_id
WHERE e.salary BETWEEN d.avg_salary * 0.9 AND d.avg_salary * 1.1;

-- 281. Find customers who ordered the most products in each category.
-- Find top customer per product category
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

-- 282. Find the top 5 longest projects.
-- Find projects with longest duration
SELECT project_id, start_date, end_date, 
       end_date - start_date AS duration
FROM projects
ORDER BY duration DESC
LIMIT 5;

-- 283. Find employees who have not taken any leave in the last 6 months.
-- Find employees with no recent leave
SELECT e.id, e.name 
FROM employees e
LEFT JOIN leaves l ON e.id = l.employee_id 
    AND l.leave_date >= CURRENT_DATE - INTERVAL '6 months'
WHERE l.leave_id IS NULL;

-- 284. Find the department with the most projects completed last year.
-- Find most productive department by completed projects
SELECT department_id, COUNT(*) AS completed_projects
FROM projects
WHERE status = 'Completed' 
  AND completion_date BETWEEN 
      DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year' 
      AND DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 day'
GROUP BY department_id
ORDER BY completed_projects DESC
LIMIT 1;

-- 285. Find customers who have increased their order frequency month-over-month for 3 consecutive months.
-- Find customers with consistent order growth
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

-- 286. Find employees who have been assigned projects outside their department.
-- Find employees on cross-departmental projects
SELECT DISTINCT e.id, e.name 
FROM employees e
JOIN project_assignments pa ON e.id = pa.employee_id
JOIN projects p ON pa.project_id = p.project_id 
WHERE e.department_id != p.department_id;

-- 287. Calculate the average time to close tickets per support agent.
-- Calculate average ticket resolution time by agent
SELECT support_agent_id, 
       AVG(closed_date - opened_date) AS avg_close_time
FROM support_tickets
WHERE closed_date IS NOT NULL
GROUP BY support_agent_id;

-- 288. Find the first and last login date for each user.
-- Get user login date range
SELECT user_id, 
       MIN(login_date) AS first_login, 
       MAX(login_date) AS last_login
FROM user_logins
GROUP BY user_id;

-- 289. Find customers who made purchases only in one month of the year.
-- Find customers with single-month purchase activity
WITH customer_months AS (
    SELECT customer_id, DATE_TRUNC('month', order_date) AS month
    FROM orders
    GROUP BY customer_id, month
)
SELECT customer_id
FROM customer_months 
GROUP BY customer_id
HAVING COUNT(*) = 1;

-- 290. Find products with sales revenue above the average revenue per product.
-- Find above-average revenue products
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

-- 291. Find departments where more than 50% of employees have a salary above $60,000.
-- Find high-salary departments
SELECT department_id
FROM employees
GROUP BY department_id
HAVING AVG(CASE WHEN salary > 60000 THEN 1 ELSE 0 END) > 0.5;

-- 292. Find employees who worked on all projects in the company.
-- Find employees assigned to every project
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

-- 293. Find customers who ordered products from all categories.
-- Find customers with purchases across all categories
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

-- 294. Find the average tenure of employees by department.
-- Calculate average employee tenure by department
SELECT department_id, 
       AVG(DATE_PART('year', CURRENT_DATE - hire_date)) AS avg_tenure_years 
FROM employees
GROUP BY department_id;

-- 295. Find the number of orders placed on weekends vs weekdays.
-- Compare weekend vs weekday order patterns
SELECT CASE
    WHEN EXTRACT(DOW FROM order_date) IN (0,6) THEN 'Weekend' 
    ELSE 'Weekday'
END AS day_type,
COUNT(*) AS order_count 
FROM orders
GROUP BY day_type;

-- 296. Find the percentage of orders with discounts per month.
-- Calculate monthly discount usage rate
SELECT DATE_TRUNC('month', order_date) AS month,
       100.0 * SUM(CASE WHEN discount > 0 THEN 1 ELSE 0 END) / COUNT(*) AS discount_percentage 
FROM orders
GROUP BY month 
ORDER BY month;

-- 297. Find the employees who have never been late to work.
-- Find punctual employees
SELECT e.id, e.name
FROM employees e
LEFT JOIN attendance a ON e.id = a.employee_id 
    AND a.arrival_time > a.scheduled_start_time
WHERE a.employee_id IS NULL;

-- 298. Find products with sales only during holiday seasons.
-- Find seasonal products sold only during holidays
SELECT product_id 
FROM sales s
JOIN holidays h ON s.sale_date = h.holiday_date
GROUP BY product_id
HAVING COUNT(*) = (
    SELECT COUNT(*) 
    FROM sales 
    WHERE product_id = s.product_id
);

-- 299. Find the department with the largest increase in employee count compared to last year.
-- Find fastest growing department
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

-- 300. Find the average order value per customer segment.
-- Calculate average order value by customer segment
SELECT segment, AVG(o.amount) AS avg_order_value 
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY segment;