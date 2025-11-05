-- Recursive CTEs, complex analytics, advanced optimization, and expert-level queries

-- 1. Recursive query to find the full reporting chain for each employee.
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

-- 2. Compare two tables and find rows with differences in any column.
SELECT *
FROM table1 t1
FULL OUTER JOIN table2 t2 ON t1.id = t2.id
WHERE t1.col1 IS DISTINCT FROM t2.col1 
   OR t1.col2 IS DISTINCT FROM t2.col2 
   OR t1.col3 IS DISTINCT FROM t2.col3;

-- 3. Find employees whose salary is a prime number.
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

-- 4. Detect hierarchical depth of each employee in the org chart.
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

-- 5. Write a query to detect circular references in employee-manager hierarchy (cycles).
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

-- 6. Write a query to get employees who reported directly or indirectly to a given manager (hierarchy traversal).
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

-- 7. Write a recursive query to list all ancestors (managers) of a given employee.
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

-- 8. Write a recursive query to list all descendants of a manager in an organizational hierarchy.
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

-- 9. Write a recursive query to find all employees and their level of reporting (distance from CEO).
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

-- 10. Write a query to identify duplicate rows (all columns) in a table.
SELECT *, COUNT(*) OVER (PARTITION BY col1, col2, col3) AS cnt
FROM table_name
WHERE cnt > 1;
-- Note: Replace col1, col2, col3 with actual column names

-- 11. Write a recursive query to compute the total budget under each manager (including subordinates).
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

-- 12. Write a recursive query to get all descendants of a manager.
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

-- 13. Calculate the retention rate of customers month-over-month.
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

-- 14. Find products that were sold in every quarter of the current year.
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

-- 15. Find products with an increasing sales trend over the last 3 months.
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

-- 16. Find customers who have increased their order frequency month-over-month for 3 consecutive months.
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

-- 17. Find customers who ordered products from all categories.
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

-- 18. Find the department with the largest increase in employee count compared to last year.
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

-- 19. Find employees whose salaries increased every year.
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