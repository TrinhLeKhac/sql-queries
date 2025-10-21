-- HARD SQL Questions (101-150)
-- Recursive CTEs, Complex Window Functions, Advanced Analytics, Performance Optimization

-- 101. Recursive query to find the full reporting chain for each employee.
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

-- 102. Find the longest consecutive streak of daily logins for each user.
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

-- 103. Write a query to find gaps in a sequence of numbers (missing IDs).
SELECT (id + 1) AS missing_id 
FROM employees e1
WHERE NOT EXISTS (
    SELECT 1 FROM employees e2 WHERE e2.id = e1.id + 1
)
AND id < (SELECT MAX(id) FROM employees)
ORDER BY missing_id;

-- 104. Compare two tables and find rows with differences in any column.
SELECT COALESCE(t1.id, t2.id) as id, 'DIFFERENT' as status
FROM table1 t1
FULL OUTER JOIN table2 t2 ON t1.id = t2.id
WHERE t1.col1 IS DISTINCT FROM t2.col1 
   OR t1.col2 IS DISTINCT FROM t2.col2 
   OR t1.col3 IS DISTINCT FROM t2.col3
   OR t1.id IS NULL 
   OR t2.id IS NULL;

-- 105. Identify overlapping date ranges for bookings.
SELECT b1.booking_id, b2.booking_id, 
       GREATEST(b1.start_date, b2.start_date) AS overlap_start,
       LEAST(b1.end_date, b2.end_date) AS overlap_end
FROM bookings b1
JOIN bookings b2 ON b1.booking_id < b2.booking_id 
WHERE b1.start_date <= b2.end_date
  AND b1.end_date >= b2.start_date;

-- 106. Aggregate JSON data to list all employee names in a department as a JSON array.
SELECT department_id, JSON_AGG(name ORDER BY name) AS employee_names
FROM employees
GROUP BY department_id;

-- 107. Detect hierarchical depth of each employee in the org chart.
WITH RECURSIVE employee_depth AS (
    SELECT id, name, manager_id, 1 AS depth 
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.id, e.name, e.manager_id, ed.depth + 1 
    FROM employees e
    JOIN employee_depth ed ON e.manager_id = ed.id
)
SELECT id, name, depth, 
       CASE WHEN depth = 1 THEN 'CEO'
            WHEN depth = 2 THEN 'VP'
            WHEN depth = 3 THEN 'Director'
            ELSE 'Staff' END AS level_name
FROM employee_depth;

-- 108. Write a query to detect circular references in employee-manager hierarchy (cycles).
WITH RECURSIVE mgr_path (id, manager_id, path, cycle) AS (
    SELECT id, manager_id, ARRAY[id], false
    FROM employees
    WHERE manager_id IS NOT NULL 
    UNION ALL
    SELECT e.id, e.manager_id, path || e.id, e.id = ANY(path)
    FROM employees e
    JOIN mgr_path mp ON e.manager_id = mp.id 
    WHERE NOT mp.cycle AND NOT e.id = ANY(path)
)
SELECT DISTINCT id, path
FROM mgr_path 
WHERE cycle;

-- 109. Write a query to get the running total of sales per customer, ordered by sale date.
SELECT customer_id, sale_date, amount, 
       SUM(amount) OVER (PARTITION BY customer_id ORDER BY sale_date 
                        ROWS UNBOUNDED PRECEDING) AS running_total,
       AVG(amount) OVER (PARTITION BY customer_id ORDER BY sale_date 
                        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3
FROM sales;

-- 110. Find the department-wise salary percentile (e.g., 90th percentile) using window functions.
SELECT department_id, 
       PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) AS p25,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) AS p75,
       PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY salary) AS p90
FROM employees
GROUP BY department_id;

-- 111. Find employees whose salary is a prime number.
WITH RECURSIVE numbers(n) AS (
    SELECT 2
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < (SELECT MAX(salary) FROM employees)
),
primes AS (
    SELECT n FROM numbers n1
    WHERE NOT EXISTS (
        SELECT 1 FROM numbers n2 
        WHERE n2.n > 1 AND n2.n < n1.n AND n1.n % n2.n = 0
    )
)
SELECT e.*, 'PRIME_SALARY' as note
FROM employees e
WHERE salary IN (SELECT n FROM primes);

-- 112. Find employees who have worked for multiple departments over time.
SELECT employee_id, 
       COUNT(DISTINCT department_id) as dept_count,
       STRING_AGG(DISTINCT department_name, ', ') as departments
FROM employee_department_history edh
JOIN departments d ON edh.department_id = d.department_id
GROUP BY employee_id
HAVING COUNT(DISTINCT edh.department_id) > 1;

-- 113. Use window function to find the difference between current row's sales and previous row's sales partitioned by product.
SELECT product_id, sale_date, amount,
       amount - LAG(amount) OVER (PARTITION BY product_id ORDER BY sale_date) AS sales_diff,
       (amount - LAG(amount) OVER (PARTITION BY product_id ORDER BY sale_date)) * 100.0 / 
       NULLIF(LAG(amount) OVER (PARTITION BY product_id ORDER BY sale_date), 0) AS pct_change
FROM sales;

-- 114. Write a query to find all employees who are at the lowest level in the hierarchy (no subordinates).
SELECT e.*, 'LEAF_NODE' as position_type
FROM employees e 
WHERE NOT EXISTS (
    SELECT 1 FROM employees sub WHERE sub.manager_id = e.id
)
AND e.manager_id IS NOT NULL;

-- 115. Write a query to create a running count of how many employees joined in each year.
SELECT join_year, 
       COUNT(*) AS yearly_hires, 
       SUM(COUNT(*)) OVER (ORDER BY join_year) AS running_total_hires,
       COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS pct_of_total
FROM (
    SELECT EXTRACT(YEAR FROM hire_date) AS join_year
    FROM employees 
) sub
GROUP BY join_year 
ORDER BY join_year;

-- 116. Find employees who have never made a sale.
SELECT e.id, e.name, e.department_id, 'NO_SALES' as performance_flag
FROM employees e
LEFT JOIN sales s ON e.id = s.employee_id 
WHERE s.sale_id IS NULL
AND e.job_title LIKE '%Sales%';

-- 117. Write a query to identify "gaps and islands" in attendance records (consecutive dates present).
WITH attendance_groups AS (
    SELECT employee_id, attendance_date,
           attendance_date - INTERVAL (ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY attendance_date)) DAY AS grp 
    FROM attendance
),
islands AS (
    SELECT employee_id, 
           MIN(attendance_date) AS start_date, 
           MAX(attendance_date) AS end_date, 
           COUNT(*) AS consecutive_days,
           MAX(attendance_date) - MIN(attendance_date) + 1 AS total_days
    FROM attendance_groups 
    GROUP BY employee_id, grp
)
SELECT employee_id, start_date, end_date, consecutive_days,
       CASE WHEN consecutive_days = total_days THEN 'PERFECT_ATTENDANCE'
            ELSE 'HAS_GAPS' END AS attendance_quality
FROM islands
WHERE consecutive_days >= 5
ORDER BY employee_id, start_date;

-- 118. Write a recursive query to list all descendants of a manager in an organizational hierarchy.
WITH RECURSIVE descendants AS (
    SELECT id, name, manager_id, 0 as level, CAST(name AS TEXT) as path
    FROM employees
    WHERE id = 100 -- starting manager id
    UNION ALL
    SELECT e.id, e.name, e.manager_id, d.level + 1, d.path || ' -> ' || e.name
    FROM employees e
    INNER JOIN descendants d ON e.manager_id = d.id
)
SELECT id, name, level, path,
       CASE WHEN level = 0 THEN 'MANAGER'
            WHEN level = 1 THEN 'DIRECT_REPORT'
            ELSE 'INDIRECT_REPORT' END as relationship
FROM descendants
ORDER BY level, name;

-- 119. Calculate a 3-month moving average of monthly sales per product.
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    GROUP BY product_id, month
)
SELECT product_id, month, total_sales, 
       AVG(total_sales) OVER (PARTITION BY product_id ORDER BY month 
                             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3m,
       STDDEV(total_sales) OVER (PARTITION BY product_id ORDER BY month 
                                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_stddev_3m
FROM monthly_sales
ORDER BY product_id, month;

-- 120. Write a query to find employees who have the same hire date as their managers.
SELECT e.name AS employee_name, m.name AS manager_name, e.hire_date,
       'SAME_HIRE_DATE' as anomaly_type
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.hire_date = m.hire_date;

-- 121. Write a query to find products with increasing sales over the last 3 months.
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY DATE_TRUNC('month', sale_date) DESC) AS rn
    FROM sales
    WHERE sale_date >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY product_id, month
),
trend_analysis AS (
    SELECT product_id,
           COUNT(*) as months_with_data,
           MIN(CASE WHEN rn = 3 THEN total_sales END) as month1_sales,
           MIN(CASE WHEN rn = 2 THEN total_sales END) as month2_sales,
           MIN(CASE WHEN rn = 1 THEN total_sales END) as month3_sales
    FROM monthly_sales
    GROUP BY product_id
    HAVING COUNT(*) = 3
)
SELECT product_id, month1_sales, month2_sales, month3_sales,
       'INCREASING_TREND' as trend_type
FROM trend_analysis
WHERE month1_sales < month2_sales AND month2_sales < month3_sales;

-- 122. Write a query to get the nth highest salary per department.
WITH ranked_salaries AS (
    SELECT department_id, salary, name,
           DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank
    FROM employees
)
SELECT department_id, name, salary, salary_rank
FROM ranked_salaries
WHERE salary_rank = 2 -- Replace with N
ORDER BY department_id;

-- 123. Find employees who have managed more than 3 projects simultaneously.
WITH project_overlaps AS (
    SELECT pa1.employee_id, pa1.project_id, pa1.start_date, pa1.end_date,
           COUNT(*) OVER (PARTITION BY pa1.employee_id 
                         ORDER BY pa1.start_date 
                         RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as concurrent_projects
    FROM project_assignments pa1
    JOIN project_assignments pa2 ON pa1.employee_id = pa2.employee_id
    WHERE pa1.start_date <= pa2.end_date AND pa1.end_date >= pa2.start_date
)
SELECT employee_id, MAX(concurrent_projects) as max_concurrent_projects
FROM project_overlaps
GROUP BY employee_id
HAVING MAX(concurrent_projects) > 3;

-- 124. Write a query to calculate the difference in days between each employee's hire date and their manager's hire date.
SELECT e.name AS employee, m.name AS manager, 
       e.hire_date, m.hire_date,
       (e.hire_date - m.hire_date) AS days_difference,
       CASE WHEN e.hire_date < m.hire_date THEN 'HIRED_BEFORE_MANAGER'
            WHEN e.hire_date > m.hire_date THEN 'HIRED_AFTER_MANAGER'
            ELSE 'SAME_HIRE_DATE' END AS hire_relationship
FROM employees e
JOIN employees m ON e.manager_id = m.id;

-- 125. Write a query to find the department with the highest average years of experience.
WITH experience_calc AS (
    SELECT department_id, 
           AVG(EXTRACT(year FROM AGE(CURRENT_DATE, hire_date))) AS avg_experience_years,
           COUNT(*) as employee_count,
           MIN(EXTRACT(year FROM AGE(CURRENT_DATE, hire_date))) as min_exp,
           MAX(EXTRACT(year FROM AGE(CURRENT_DATE, hire_date))) as max_exp
    FROM employees
    GROUP BY department_id
)
SELECT department_id, avg_experience_years, employee_count, min_exp, max_exp,
       RANK() OVER (ORDER BY avg_experience_years DESC) as experience_rank
FROM experience_calc
ORDER BY avg_experience_years DESC;

-- 126. Identify employees who had overlapping project assignments with potential conflicts.
SELECT pa1.employee_id, 
       pa1.project_id AS project1, 
       pa2.project_id AS project2,
       GREATEST(pa1.start_date, pa2.start_date) AS overlap_start,
       LEAST(pa1.end_date, pa2.end_date) AS overlap_end,
       LEAST(pa1.end_date, pa2.end_date) - GREATEST(pa1.start_date, pa2.start_date) AS overlap_days
FROM project_assignments pa1
JOIN project_assignments pa2 ON pa1.employee_id = pa2.employee_id AND pa1.project_id < pa2.project_id
WHERE pa1.start_date <= pa2.end_date AND pa1.end_date >= pa2.start_date
ORDER BY pa1.employee_id, overlap_days DESC;

-- 127. Find customers who made purchases in every month of the current year.
WITH year_months AS (
    SELECT generate_series(1, 12) AS month_num
),
customer_months AS (
    SELECT customer_id, EXTRACT(MONTH FROM purchase_date) AS month_num 
    FROM sales
    WHERE EXTRACT(YEAR FROM purchase_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY customer_id, EXTRACT(MONTH FROM purchase_date)
)
SELECT cm.customer_id, COUNT(*) as months_purchased,
       STRING_AGG(cm.month_num::text, ',' ORDER BY cm.month_num) as purchase_months
FROM customer_months cm
GROUP BY cm.customer_id
HAVING COUNT(*) = 12;

-- 128. List employees who earn more than all their subordinates combined.
WITH subordinate_totals AS (
    SELECT manager_id, 
           COUNT(*) as subordinate_count,
           SUM(salary) as total_subordinate_salary,
           AVG(salary) as avg_subordinate_salary
    FROM employees 
    WHERE manager_id IS NOT NULL
    GROUP BY manager_id
)
SELECT e.id, e.name, e.salary, 
       st.subordinate_count, st.total_subordinate_salary,
       'EARNS_MORE_THAN_ALL_SUBS' as salary_status
FROM employees e
JOIN subordinate_totals st ON e.id = st.manager_id
WHERE e.salary > st.total_subordinate_salary;

-- 129. Get the product with the highest sales for each category with seasonal analysis.
WITH category_sales AS (
    SELECT p.category_id, s.product_id, 
           EXTRACT(QUARTER FROM s.sale_date) as quarter,
           SUM(s.amount) AS total_sales,
           RANK() OVER (PARTITION BY p.category_id, EXTRACT(QUARTER FROM s.sale_date) 
                       ORDER BY SUM(s.amount) DESC) AS sales_rank 
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY p.category_id, s.product_id, EXTRACT(QUARTER FROM s.sale_date)
)
SELECT category_id, product_id, quarter, total_sales
FROM category_sales
WHERE sales_rank = 1
ORDER BY category_id, quarter;

-- 130. Find customers who haven't ordered in the last 6 months but were active before.
WITH customer_activity AS (
    SELECT customer_id,
           MAX(order_date) as last_order_date,
           MIN(order_date) as first_order_date,
           COUNT(*) as total_orders,
           COUNT(CASE WHEN order_date >= CURRENT_DATE - INTERVAL '6 months' THEN 1 END) as recent_orders
    FROM orders
    GROUP BY customer_id
)
SELECT customer_id, last_order_date, first_order_date, total_orders,
       CURRENT_DATE - last_order_date as days_since_last_order,
       'CHURNED_CUSTOMER' as status
FROM customer_activity
WHERE recent_orders = 0 
  AND last_order_date < CURRENT_DATE - INTERVAL '6 months'
  AND total_orders >= 3;

-- 131. Write a recursive query to compute the total budget under each manager (including subordinates).
WITH RECURSIVE manager_budget AS (
    SELECT e.id, e.name, e.manager_id, d.budget, 0 as level
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    WHERE e.manager_id IS NULL
    UNION ALL
    SELECT e.id, e.name, e.manager_id, d.budget, mb.level + 1
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN manager_budget mb ON e.manager_id = mb.id
)
SELECT id, name, level, 
       SUM(budget) OVER (PARTITION BY id) as direct_budget,
       SUM(budget) OVER (ORDER BY level, id ROWS UNBOUNDED PRECEDING) as cumulative_budget
FROM manager_budget
ORDER BY level, id;

-- 132. Write a query to detect gaps in a sequence of invoice numbers.
WITH invoice_sequence AS (
    SELECT invoice_number, 
           invoice_number - LAG(invoice_number) OVER (ORDER BY invoice_number) AS gap
    FROM invoices
    ORDER BY invoice_number
),
missing_ranges AS (
    SELECT LAG(invoice_number) OVER (ORDER BY invoice_number) + 1 AS gap_start,
           invoice_number - 1 AS gap_end,
           invoice_number - LAG(invoice_number) OVER (ORDER BY invoice_number) - 1 AS missing_count
    FROM invoice_sequence
    WHERE gap > 1
)
SELECT gap_start, gap_end, missing_count,
       generate_series(gap_start, gap_end) AS missing_invoice_number
FROM missing_ranges;

-- 133. Calculate the rank of employees by salary within their department but restart rank numbering every 10 employees.
WITH ranked_employees AS (
    SELECT e.*, 
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_rank,
           NTILE(CEILING(COUNT(*) OVER (PARTITION BY department_id) / 10.0)) 
           OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_tier
    FROM employees e
)
SELECT *, 
       ((dept_rank - 1) % 10) + 1 AS tier_rank,
       CASE WHEN salary_tier = 1 THEN 'TOP_TIER'
            WHEN salary_tier <= 3 THEN 'MID_TIER'
            ELSE 'LOWER_TIER' END AS performance_tier
FROM ranked_employees
ORDER BY department_id, dept_rank;

-- 134. Find the moving median of daily sales over the last 7 days for each product.
WITH daily_sales AS (
    SELECT product_id, sale_date, SUM(amount) AS daily_total
    FROM sales
    GROUP BY product_id, sale_date
)
SELECT product_id, sale_date, daily_total,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY daily_total) 
       OVER (PARTITION BY product_id ORDER BY sale_date 
             ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_median_7d,
       AVG(daily_total) OVER (PARTITION BY product_id ORDER BY sale_date 
                             ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d
FROM daily_sales
ORDER BY product_id, sale_date;

-- 135. Write a query to generate a calendar table with all dates for the current year including business day flags.
WITH calendar AS (
    SELECT generate_series(
        DATE_TRUNC('year', CURRENT_DATE), 
        DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year' - INTERVAL '1 day', 
        INTERVAL '1 day'
    ) AS calendar_date
)
SELECT calendar_date,
       EXTRACT(DOW FROM calendar_date) AS day_of_week,
       TO_CHAR(calendar_date, 'Day') AS day_name,
       EXTRACT(WEEK FROM calendar_date) AS week_number,
       EXTRACT(MONTH FROM calendar_date) AS month_number,
       EXTRACT(QUARTER FROM calendar_date) AS quarter,
       CASE WHEN EXTRACT(DOW FROM calendar_date) IN (0,6) THEN false ELSE true END AS is_business_day,
       CASE WHEN EXTRACT(DOW FROM calendar_date) = 1 THEN true ELSE false END AS is_monday
FROM calendar
ORDER BY calendar_date;

-- 136. Find employees who have worked in more than 3 different departments with transition analysis.
WITH dept_transitions AS (
    SELECT employee_id, department_id, start_date, end_date,
           LAG(department_id) OVER (PARTITION BY employee_id ORDER BY start_date) AS prev_dept,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY start_date) AS transition_seq
    FROM employee_department_history
),
transition_summary AS (
    SELECT employee_id, 
           COUNT(DISTINCT department_id) AS dept_count,
           COUNT(*) AS total_transitions,
           STRING_AGG(department_id::text, ' -> ' ORDER BY start_date) AS dept_path,
           MAX(start_date) - MIN(start_date) AS career_span
    FROM dept_transitions
    GROUP BY employee_id
)
SELECT employee_id, dept_count, total_transitions, dept_path, career_span,
       CASE WHEN dept_count > 5 THEN 'HIGH_MOBILITY'
            WHEN dept_count > 3 THEN 'MODERATE_MOBILITY'
            ELSE 'LOW_MOBILITY' END AS mobility_type
FROM transition_summary
WHERE dept_count > 3
ORDER BY dept_count DESC, career_span DESC;

-- 137. Calculate the percentage contribution of each product's sales to the total sales per month with trend analysis.
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
),
contribution_analysis AS (
    SELECT ms.product_id, ms.month, ms.product_sales, 
           tms.total_sales,
           (ms.product_sales * 100.0) / tms.total_sales AS pct_contribution,
           LAG((ms.product_sales * 100.0) / tms.total_sales) 
           OVER (PARTITION BY ms.product_id ORDER BY ms.month) AS prev_pct_contribution
    FROM monthly_sales ms
    JOIN total_monthly_sales tms ON ms.month = tms.month
)
SELECT product_id, month, product_sales, pct_contribution,
       pct_contribution - prev_pct_contribution AS contribution_change,
       CASE WHEN pct_contribution - prev_pct_contribution > 1 THEN 'GROWING_SHARE'
            WHEN pct_contribution - prev_pct_contribution < -1 THEN 'DECLINING_SHARE'
            ELSE 'STABLE_SHARE' END AS trend_status
FROM contribution_analysis
WHERE prev_pct_contribution IS NOT NULL
ORDER BY product_id, month;

-- 138. Write a query to pivot monthly sales data for each product into columns with YoY comparison.
WITH monthly_sales AS (
    SELECT product_id,
           EXTRACT(YEAR FROM sale_date) AS year,
           EXTRACT(MONTH FROM sale_date) AS month,
           SUM(amount) AS monthly_total
    FROM sales
    GROUP BY product_id, EXTRACT(YEAR FROM sale_date), EXTRACT(MONTH FROM sale_date)
)
SELECT product_id, year,
       SUM(CASE WHEN month = 1 THEN monthly_total END) AS Jan,
       SUM(CASE WHEN month = 2 THEN monthly_total END) AS Feb,
       SUM(CASE WHEN month = 3 THEN monthly_total END) AS Mar,
       SUM(CASE WHEN month = 4 THEN monthly_total END) AS Apr,
       SUM(CASE WHEN month = 5 THEN monthly_total END) AS May,
       SUM(CASE WHEN month = 6 THEN monthly_total END) AS Jun,
       SUM(CASE WHEN month = 7 THEN monthly_total END) AS Jul,
       SUM(CASE WHEN month = 8 THEN monthly_total END) AS Aug,
       SUM(CASE WHEN month = 9 THEN monthly_total END) AS Sep,
       SUM(CASE WHEN month = 10 THEN monthly_total END) AS Oct,
       SUM(CASE WHEN month = 11 THEN monthly_total END) AS Nov,
       SUM(CASE WHEN month = 12 THEN monthly_total END) AS Dec,
       SUM(monthly_total) AS yearly_total
FROM monthly_sales
GROUP BY product_id, year
ORDER BY product_id, year;

-- 139. Find the 3 most recent orders per customer including order details with customer lifetime value.
WITH customer_metrics AS (
    SELECT customer_id,
           COUNT(*) AS total_orders,
           SUM(amount) AS lifetime_value,
           AVG(amount) AS avg_order_value,
           MAX(order_date) AS last_order_date,
           MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY customer_id
),
recent_orders AS (
    SELECT o.*, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders o
)
SELECT ro.customer_id, ro.order_id, ro.order_date, ro.amount, ro.rn,
       cm.total_orders, cm.lifetime_value, cm.avg_order_value,
       CASE WHEN cm.lifetime_value > 10000 THEN 'VIP'
            WHEN cm.lifetime_value > 5000 THEN 'HIGH_VALUE'
            WHEN cm.lifetime_value > 1000 THEN 'MEDIUM_VALUE'
            ELSE 'LOW_VALUE' END AS customer_tier
FROM recent_orders ro
JOIN customer_metrics cm ON ro.customer_id = cm.customer_id
WHERE ro.rn <= 3
ORDER BY cm.lifetime_value DESC, ro.customer_id, ro.rn;

-- 140. Write a recursive query to list all ancestors (managers) of a given employee with organizational distance.
WITH RECURSIVE ancestors AS (
    SELECT id, name, manager_id, 0 AS distance, 
           CAST(name AS TEXT) AS management_chain
    FROM employees
    WHERE id = 123 -- given employee id
    UNION ALL
    SELECT e.id, e.name, e.manager_id, a.distance + 1,
           e.name || ' <- ' || a.management_chain
    FROM employees e
    JOIN ancestors a ON e.id = a.manager_id
)
SELECT id, name, distance, management_chain,
       CASE WHEN distance = 0 THEN 'SELF'
            WHEN distance = 1 THEN 'DIRECT_MANAGER'
            WHEN distance = 2 THEN 'SKIP_LEVEL_MANAGER'
            ELSE 'SENIOR_LEADERSHIP' END AS relationship_type
FROM ancestors
ORDER BY distance;

-- 141. Find the second highest salary per department without using window functions.
SELECT e1.department_id, 
       MAX(e1.salary) AS second_highest_salary,
       COUNT(DISTINCT e2.salary) AS higher_salary_count
FROM employees e1
JOIN employees e2 ON e1.department_id = e2.department_id AND e1.salary <= e2.salary
WHERE e1.salary < (
    SELECT MAX(salary)
    FROM employees e3
    WHERE e3.department_id = e1.department_id
)
GROUP BY e1.department_id, e1.salary
HAVING COUNT(DISTINCT e2.salary) = 2;

-- 142. Write a query to identify duplicate rows (all columns) in a table with data quality metrics.
WITH duplicate_analysis AS (
    SELECT *, 
           COUNT(*) OVER (PARTITION BY col1, col2, col3) AS duplicate_count,
           ROW_NUMBER() OVER (PARTITION BY col1, col2, col3 ORDER BY created_date) AS duplicate_rank
    FROM table_name
),
data_quality_summary AS (
    SELECT COUNT(*) AS total_rows,
           COUNT(DISTINCT (col1, col2, col3)) AS unique_combinations,
           COUNT(*) - COUNT(DISTINCT (col1, col2, col3)) AS duplicate_rows,
           (COUNT(*) - COUNT(DISTINCT (col1, col2, col3))) * 100.0 / COUNT(*) AS duplicate_percentage
    FROM table_name
)
SELECT da.*, dqs.duplicate_percentage,
       CASE WHEN da.duplicate_count > 1 AND da.duplicate_rank = 1 THEN 'KEEP'
            WHEN da.duplicate_count > 1 THEN 'REMOVE'
            ELSE 'UNIQUE' END AS action_required
FROM duplicate_analysis da
CROSS JOIN data_quality_summary dqs
WHERE da.duplicate_count > 1
ORDER BY da.duplicate_count DESC, da.col1, da.duplicate_rank;

-- 143. Write a query to unpivot quarterly sales data into rows with variance analysis.
WITH unpivoted_sales AS (
    SELECT product_id, 'Q1' AS quarter, Q1_sales AS sales FROM sales_data 
    UNION ALL
    SELECT product_id, 'Q2', Q2_sales FROM sales_data 
    UNION ALL
    SELECT product_id, 'Q3', Q3_sales FROM sales_data 
    UNION ALL
    SELECT product_id, 'Q4', Q4_sales FROM sales_data
),
quarterly_analysis AS (
    SELECT product_id, quarter, sales,
           AVG(sales) OVER (PARTITION BY product_id) AS avg_quarterly_sales,
           STDDEV(sales) OVER (PARTITION BY product_id) AS sales_stddev,
           (sales - AVG(sales) OVER (PARTITION BY product_id)) / 
           NULLIF(STDDEV(sales) OVER (PARTITION BY product_id), 0) AS z_score
    FROM unpivoted_sales
    WHERE sales IS NOT NULL
)
SELECT product_id, quarter, sales, avg_quarterly_sales, sales_stddev, z_score,
       CASE WHEN ABS(z_score) > 2 THEN 'OUTLIER'
            WHEN ABS(z_score) > 1 THEN 'UNUSUAL'
            ELSE 'NORMAL' END AS variance_category
FROM quarterly_analysis
ORDER BY product_id, quarter;

-- 144. Write a query to find customers with the highest purchase amount per year with cohort analysis.
WITH yearly_customer_sales AS (
    SELECT customer_id, 
           EXTRACT(YEAR FROM sale_date) AS year,
           EXTRACT(YEAR FROM MIN(sale_date) OVER (PARTITION BY customer_id)) AS cohort_year,
           SUM(amount) AS yearly_amount,
           COUNT(*) AS yearly_orders
    FROM sales
    GROUP BY customer_id, EXTRACT(YEAR FROM sale_date)
),
yearly_rankings AS (
    SELECT *, 
           RANK() OVER (PARTITION BY year ORDER BY yearly_amount DESC) AS yearly_rank,
           year - cohort_year AS years_since_first_purchase
    FROM yearly_customer_sales
),
cohort_performance AS (
    SELECT cohort_year, years_since_first_purchase,
           COUNT(*) AS active_customers,
           AVG(yearly_amount) AS avg_yearly_spend,
           SUM(yearly_amount) AS total_cohort_spend
    FROM yearly_rankings
    GROUP BY cohort_year, years_since_first_purchase
)
SELECT yr.customer_id, yr.year, yr.yearly_amount, yr.yearly_rank, 
       yr.cohort_year, yr.years_since_first_purchase,
       cp.avg_yearly_spend AS cohort_avg_spend,
       yr.yearly_amount / cp.avg_yearly_spend AS performance_vs_cohort
FROM yearly_rankings yr
JOIN cohort_performance cp ON yr.cohort_year = cp.cohort_year 
                           AND yr.years_since_first_purchase = cp.years_since_first_purchase
WHERE yr.yearly_rank = 1
ORDER BY yr.year DESC, yr.yearly_amount DESC;

-- 145. Write a query to list all employees who have a salary equal to the average salary of their department.
WITH dept_salary_stats AS (
    SELECT department_id, 
           AVG(salary) AS avg_salary,
           STDDEV(salary) AS salary_stddev,
           COUNT(*) AS dept_size
    FROM employees
    GROUP BY department_id
)
SELECT e.*, dss.avg_salary, dss.salary_stddev, dss.dept_size,
       ABS(e.salary - dss.avg_salary) AS salary_deviation,
       'EXACTLY_AVERAGE' AS salary_position
FROM employees e 
JOIN dept_salary_stats dss ON e.department_id = dss.department_id 
WHERE ABS(e.salary - dss.avg_salary) < 0.01; -- Account for floating point precision

-- 146. Write a recursive query to find all employees and their level of reporting with span of control analysis.
WITH RECURSIVE hierarchy AS (
    SELECT id, name, manager_id, 1 AS level, 
           CAST(name AS TEXT) AS reporting_path
    FROM employees
    WHERE manager_id IS NULL -- CEO level 
    UNION ALL
    SELECT e.id, e.name, e.manager_id, h.level + 1,
           h.reporting_path || ' -> ' || e.name
    FROM employees e
    JOIN hierarchy h ON e.manager_id = h.id
),
span_of_control AS (
    SELECT manager_id, COUNT(*) AS direct_reports
    FROM employees 
    WHERE manager_id IS NOT NULL
    GROUP BY manager_id
)
SELECT h.*, 
       COALESCE(soc.direct_reports, 0) AS direct_reports,
       CASE WHEN COALESCE(soc.direct_reports, 0) = 0 THEN 'INDIVIDUAL_CONTRIBUTOR'
            WHEN soc.direct_reports <= 3 THEN 'SMALL_TEAM_LEAD'
            WHEN soc.direct_reports <= 7 THEN 'MANAGER'
            ELSE 'SENIOR_MANAGER' END AS management_level
FROM hierarchy h
LEFT JOIN span_of_control soc ON h.id = soc.manager_id
ORDER BY h.level, h.name;

-- 147. Write a query to find consecutive days where sales were above a threshold with streak analysis.
WITH daily_sales AS (
    SELECT sale_date, SUM(amount) AS daily_total
    FROM sales
    GROUP BY sale_date
),
flagged_sales AS (
    SELECT sale_date, daily_total,
           CASE WHEN daily_total > 10000 THEN 1 ELSE 0 END AS above_threshold,
           LAG(CASE WHEN daily_total > 10000 THEN 1 ELSE 0 END) 
           OVER (ORDER BY sale_date) AS prev_above_threshold
    FROM daily_sales
),
streak_groups AS (
    SELECT sale_date, daily_total, above_threshold,
           SUM(CASE WHEN above_threshold = 1 AND 
                        (prev_above_threshold = 0 OR prev_above_threshold IS NULL) 
                   THEN 1 ELSE 0 END) 
           OVER (ORDER BY sale_date) AS streak_group
    FROM flagged_sales
    WHERE above_threshold = 1
),
streak_analysis AS (
    SELECT streak_group,
           MIN(sale_date) AS streak_start, 
           MAX(sale_date) AS streak_end, 
           COUNT(*) AS streak_length,
           SUM(daily_total) AS streak_total_sales,
           AVG(daily_total) AS streak_avg_daily_sales
    FROM streak_groups
    GROUP BY streak_group
)
SELECT *, 
       RANK() OVER (ORDER BY streak_length DESC) AS streak_rank,
       CASE WHEN streak_length >= 7 THEN 'EXCELLENT_STREAK'
            WHEN streak_length >= 3 THEN 'GOOD_STREAK'
            ELSE 'SHORT_STREAK' END AS streak_quality
FROM streak_analysis
ORDER BY streak_length DESC, streak_total_sales DESC;

-- 148. Write a recursive query to calculate factorial of a number with mathematical series analysis.
WITH RECURSIVE factorial_series(n, factorial_value, running_sum) AS (
    SELECT 1, 1, 1
    UNION ALL
    SELECT n + 1, factorial_value * (n + 1), running_sum + (factorial_value * (n + 1))
    FROM factorial_series
    WHERE n < 10
),
mathematical_analysis AS (
    SELECT n, factorial_value, running_sum,
           factorial_value::FLOAT / LAG(factorial_value) OVER (ORDER BY n) AS growth_ratio,
           LOG(factorial_value) AS log_factorial,
           factorial_value % 10 AS last_digit
    FROM factorial_series
)
SELECT n, factorial_value, running_sum, growth_ratio, log_factorial, last_digit,
       CASE WHEN n <= 3 THEN 'SMALL'
            WHEN n <= 6 THEN 'MEDIUM' 
            ELSE 'LARGE' END AS factorial_category
FROM mathematical_analysis
ORDER BY n;

-- 149. Write a query to calculate the cumulative percentage of total sales per product with Pareto analysis.
WITH product_sales AS (
    SELECT product_id, SUM(amount) AS total_sales
    FROM sales
    GROUP BY product_id
),
ranked_products AS (
    SELECT product_id, total_sales,
           SUM(total_sales) OVER () AS grand_total,
           ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank,
           COUNT(*) OVER () AS total_products
    FROM product_sales
),
cumulative_analysis AS (
    SELECT product_id, total_sales, sales_rank, total_products,
           total_sales * 100.0 / grand_total AS pct_of_total_sales,
           SUM(total_sales) OVER (ORDER BY total_sales DESC) * 100.0 / grand_total AS cumulative_pct_sales,
           sales_rank * 100.0 / total_products AS pct_of_products
    FROM ranked_products
)
SELECT product_id, total_sales, sales_rank, 
       pct_of_total_sales, cumulative_pct_sales, pct_of_products,
       CASE WHEN cumulative_pct_sales <= 80 THEN 'A_ITEMS_80_PERCENT'
            WHEN cumulative_pct_sales <= 95 THEN 'B_ITEMS_15_PERCENT'
            ELSE 'C_ITEMS_5_PERCENT' END AS pareto_category,
       CASE WHEN pct_of_products <= 20 AND cumulative_pct_sales >= 80 THEN 'PARETO_PRINCIPLE_CONFIRMED'
            ELSE 'REVIEW_DISTRIBUTION' END AS pareto_analysis
FROM cumulative_analysis
ORDER BY sales_rank;

-- 150. Write a query to get employees who reported directly or indirectly to a given manager with organizational network analysis.
WITH RECURSIVE reporting_network AS (
    SELECT id, name, manager_id, 0 AS reporting_distance, 
           CAST(id AS TEXT) AS reporting_chain,
           1 AS network_size
    FROM employees
    WHERE id = 101 -- replace with specific manager's id
    UNION ALL
    SELECT e.id, e.name, e.manager_id, rn.reporting_distance + 1,
           rn.reporting_chain || ' -> ' || e.id,
           rn.network_size + 1
    FROM employees e
    INNER JOIN reporting_network rn ON e.manager_id = rn.id
),
network_analysis AS (
    SELECT reporting_distance, 
           COUNT(*) AS employees_at_level,
           STRING_AGG(name, ', ') AS employees_names,
           AVG(network_size) AS avg_network_size_at_level
    FROM reporting_network
    WHERE reporting_distance > 0
    GROUP BY reporting_distance
)
SELECT rn.id, rn.name, rn.reporting_distance, rn.reporting_chain,
       na.employees_at_level, na.avg_network_size_at_level,
       CASE WHEN rn.reporting_distance = 1 THEN 'DIRECT_REPORT'
            WHEN rn.reporting_distance = 2 THEN 'SKIP_LEVEL'
            WHEN rn.reporting_distance <= 4 THEN 'EXTENDED_TEAM'
            ELSE 'DISTANT_REPORT' END AS relationship_type,
       SUM(na.employees_at_level) OVER (ORDER BY rn.reporting_distance) AS cumulative_team_size
FROM reporting_network rn
LEFT JOIN network_analysis na ON rn.reporting_distance = na.reporting_distance
ORDER BY rn.reporting_distance, rn.name;