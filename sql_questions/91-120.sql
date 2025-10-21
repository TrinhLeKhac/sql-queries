-- SQL Questions 91-120

-- 91. Write a query to find the department with the highest average years of experience.
-- Find department with highest average employee experience
SELECT department_id, 
       AVG(EXTRACT(year FROM CURRENT_DATE - hire_date)) AS avg_experience_years
FROM employees
GROUP BY department_id
ORDER BY avg_experience_years DESC 
LIMIT 1;

-- 92. Identify employees who had overlapping project assignments.
-- Find employees with overlapping project assignments
SELECT p1.employee_id, p1.project_id AS project1, p2.project_id AS project2
FROM project_assignments p1
JOIN project_assignments p2 ON p1.employee_id = p2.employee_id AND p1.project_id < p2.project_id
WHERE p1.start_date < p2.end_date AND p1.end_date > p2.start_date;

-- 93. Find customers who made purchases in every month of the current year.
-- Find customers with purchases in all 12 months of current year
WITH months AS (
    SELECT generate_series(1, 12) AS month
),
customer_months AS (
    SELECT customer_id, EXTRACT(MONTH FROM purchase_date) AS month 
    FROM sales
    WHERE EXTRACT(YEAR FROM purchase_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY customer_id, EXTRACT(MONTH FROM purchase_date)
)
SELECT customer_id
FROM customer_months 
GROUP BY customer_id
HAVING COUNT(DISTINCT month) = 12;

-- 94. List employees who earn more than all their subordinates.
-- Find managers earning more than all their direct reports
SELECT e.id, e.name, e.salary 
FROM employees e
WHERE e.salary > ALL (
    SELECT salary
    FROM employees sub
    WHERE sub.manager_id = e.id
);

-- 95. Get the product with the highest sales for each category.
-- Find top selling product per category
WITH category_sales AS (
    SELECT category_id, product_id, SUM(amount) AS total_sales,
           RANK() OVER (PARTITION BY category_id ORDER BY SUM(amount) DESC) AS sales_rank 
    FROM sales
    GROUP BY category_id, product_id 
)
SELECT category_id, product_id, total_sales 
FROM category_sales
WHERE sales_rank = 1;

-- 96. Find customers who haven't ordered in the last 6 months.
-- Find customers with no orders in past 6 months
SELECT customer_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING MAX(o.order_date) < CURRENT_DATE - INTERVAL '6 months'
   OR MAX(o.order_date) IS NULL;

-- 97. Find the maximum salary gap between any two employees within the same department.
-- Calculate maximum salary gap within each department
SELECT department_id, MAX(salary) - MIN(salary) AS salary_gap
FROM employees
GROUP BY department_id;

-- 98. Write a recursive query to compute the total budget under each manager (including subordinates).
-- Calculate total budget under each manager including subordinates
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

-- 99. Write a query to detect gaps in a sequence of invoice numbers.
-- Find missing invoice numbers in sequence
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

-- 100. Calculate the rank of employees by salary within their department but restart rank numbering every 10 employees.
-- Rank employees by salary with rank reset every 10 employees
WITH ranked_employees AS (
    SELECT e.*, 
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn 
    FROM employees e
)
SELECT *, ((rn - 1) / 10) + 1 AS rank_group 
FROM ranked_employees;

-- 101. Find the moving median of daily sales over the last 7 days for each product.
-- Calculate 7-day moving median of daily sales by product
WITH daily_sales AS (
    SELECT product_id, sale_date, SUM(amount) AS total_sales
    FROM sales
    GROUP BY product_id, sale_date
)
SELECT product_id, sale_date, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) 
       OVER (PARTITION BY product_id ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_median 
FROM daily_sales;

-- 102. Find customers who purchased both product A and product B.
-- Find customers who bought both specific products
SELECT customer_id
FROM sales
WHERE product_id IN ('A', 'B') 
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = 2;

-- 103. Write a query to generate a calendar table with all dates for the current year.
-- Generate calendar for current year
SELECT generate_series(
    DATE_TRUNC('year', CURRENT_DATE), 
    DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year' - INTERVAL '1 day', 
    INTERVAL '1 day'
) AS calendar_date;

-- 104. Find employees who have worked in more than 3 different departments.
-- Find employees who worked in multiple departments
SELECT employee_id
FROM employee_department_history 
GROUP BY employee_id
HAVING COUNT(DISTINCT department_id) > 3;

-- 105. Calculate the percentage contribution of each product's sales to the total sales per month.
-- Calculate product sales percentage contribution by month
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS product_sales 
    FROM sales
    GROUP BY product_id, month
),
total_monthly_sales AS (
    SELECT month, SUM(product_sales) AS total_sales 
    FROM monthly_sales
    GROUP BY month
)
SELECT ms.product_id, ms.month, ms.product_sales, 
       (ms.product_sales * 100.0) / tms.total_sales AS pct_contribution
FROM monthly_sales ms
JOIN total_monthly_sales tms ON ms.month = tms.month;

-- 106. Write a query to pivot monthly sales data for each product into columns.
-- Pivot monthly sales data into columns
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

-- 107. Find the 3 most recent orders per customer including order details.
-- Get 3 most recent orders per customer with details
SELECT *
FROM (
    SELECT o.*, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders o
) sub
WHERE rn <= 3;

-- 108. Find employees who have never taken any leave.
-- Find employees with no leave records
SELECT e.*
FROM employees e
LEFT JOIN leaves l ON e.id = l.employee_id 
WHERE l.leave_id IS NULL;

-- 109. List customers who placed orders in January but not in February.
-- Find customers with January orders but no February orders
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

-- 110. Find products that have seen a price increase in the last 6 months.
-- Find products with price increases in past 6 months
WITH price_changes AS (
    SELECT product_id, price, effective_date,
           LAG(price) OVER (PARTITION BY product_id ORDER BY effective_date) AS prev_price
    FROM product_prices
    WHERE effective_date >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT DISTINCT product_id
FROM price_changes 
WHERE price > prev_price;

-- 111. Find the department(s) with the second highest average salary.
-- Find departments with second highest average salary
WITH avg_salaries AS (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id
),
ranked_salaries AS (
    SELECT department_id, avg_salary, 
           DENSE_RANK() OVER (ORDER BY avg_salary DESC) AS rnk
    FROM avg_salaries
)
SELECT department_id, avg_salary 
FROM ranked_salaries 
WHERE rnk = 2;

-- 112. Find employees who joined in the same month and year.
-- Find employees hired in same month and year
SELECT e1.id AS emp1_id, e2.id AS emp2_id, e1.hire_date
FROM employees e1
JOIN employees e2 ON e1.id < e2.id
  AND EXTRACT(MONTH FROM e1.hire_date) = EXTRACT(MONTH FROM e2.hire_date)
  AND EXTRACT(YEAR FROM e1.hire_date) = EXTRACT(YEAR FROM e2.hire_date);

-- 113. Write a recursive query to find all employees and their level of reporting (distance from CEO).
-- Find organizational hierarchy levels from CEO
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

-- 114. Find the second highest salary per department without using window functions.
-- Find second highest salary per department without window functions
SELECT department_id, MAX(salary) AS second_highest_salary
FROM employees e1
WHERE salary < (
    SELECT MAX(salary)
    FROM employees e2
    WHERE e2.department_id = e1.department_id
)
GROUP BY department_id;

-- 115. Calculate the percentage change in sales for each product comparing current month to previous month.
-- Calculate month-over-month sales percentage change by product
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    GROUP BY product_id, month
)
SELECT product_id, month, total_sales,
       (total_sales - LAG(total_sales) OVER (PARTITION BY product_id ORDER BY month)) * 100.0 / 
       LAG(total_sales) OVER (PARTITION BY product_id ORDER BY month) AS pct_change 
FROM monthly_sales;

-- 116. Write a query to identify duplicate rows (all columns) in a table.
-- Identify duplicate rows based on all columns
SELECT *, COUNT(*) OVER (PARTITION BY col1, col2, col3) AS cnt
FROM table_name
WHERE cnt > 1;
-- Note: Replace col1, col2, col3 with actual column names

-- 117. Write a query to unpivot quarterly sales data into rows.
-- Unpivot quarterly sales data from columns to rows
SELECT product_id, 'Q1' AS quarter, Q1_sales AS sales FROM sales_data 
UNION ALL
SELECT product_id, 'Q2', Q2_sales FROM sales_data 
UNION ALL
SELECT product_id, 'Q3', Q3_sales FROM sales_data 
UNION ALL
SELECT product_id, 'Q4', Q4_sales FROM sales_data;

-- 118. Find employees whose salary is above the average salary of their department but below the company-wide average.
-- Find employees above dept average but below company average
SELECT *
FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees WHERE department_id = e.department_id)
  AND salary < (SELECT AVG(salary) FROM employees);

-- 119. Write a query to find customers with the highest purchase amount per year.
-- Find top customer by purchase amount each year
WITH yearly_sales AS (
    SELECT customer_id, 
           EXTRACT(YEAR FROM sale_date) AS year, 
           SUM(amount) AS total_amount 
    FROM sales
    GROUP BY customer_id, year
),
ranked_sales AS (
    SELECT *, 
           RANK() OVER (PARTITION BY year ORDER BY total_amount DESC) AS rnk
    FROM yearly_sales
)
SELECT customer_id, year, total_amount 
FROM ranked_sales
WHERE rnk = 1;

-- 120. Write a query to list all employees who have a salary equal to the average salary of their department.
-- Find employees with salary equal to department average
SELECT e.*
FROM employees e 
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id
) d ON e.department_id = d.department_id AND e.salary = d.avg_salary;