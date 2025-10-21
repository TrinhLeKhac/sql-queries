-- Medium SQL Questions 101-200
-- Window functions, CTEs, advanced JOINs, and subqueries

-- 101. Running total of salaries by department.
SELECT name, department_id, salary, 
       SUM(salary) OVER (PARTITION BY department_id ORDER BY id) AS running_total 
FROM employees;

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

-- 103. Calculate cumulative distribution (CDF) of salaries.
SELECT name, salary,
       CUME_DIST() OVER (ORDER BY salary) AS salary_cdf
FROM employees;

-- 104. Write a query to calculate the difference between current row and previous row's salary (lag function).
SELECT name, salary,
       salary - LAG(salary) OVER (ORDER BY id) AS salary_diff
FROM employees;

-- 105. Identify overlapping date ranges for bookings.
SELECT b1.booking_id, b2.booking_id
FROM bookings b1
JOIN bookings b2 ON b1.booking_id < b2.booking_id 
WHERE b1.start_date <= b2.end_date
  AND b1.end_date >= b2.start_date;

-- 106. Write a query to find employees with salary greater than average salary in the entire company, ordered by salary descending.
SELECT name, salary 
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;

-- 107. Aggregate JSON data (if supported) to list all employee names in a department as a JSON array.
SELECT department_id, JSON_AGG(name) AS employee_names
FROM employees
GROUP BY department_id;

-- 108. Find departments with the highest average salary.
WITH avg_salaries AS (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id
)
SELECT *
FROM avg_salaries
WHERE avg_salary = (SELECT MAX(avg_salary) FROM avg_salaries);

-- 109. Calculate the moving average of salaries over the last 3 employees ordered by hire date.
SELECT name, hire_date, salary,
       AVG(salary) OVER (ORDER BY hire_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_salary 
FROM employees;

-- 110. Find the most recent purchase per customer using window functions.
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY purchase_date DESC) AS rn 
    FROM sales
) sub
WHERE rn = 1;

-- 111. Write a query to pivot rows into columns dynamically (if dynamic pivot is not supported, simulate it for fixed values).
SELECT department_id,
       SUM(CASE WHEN job_title = 'Manager' THEN 1 ELSE 0 END) AS Managers,
       SUM(CASE WHEN job_title = 'Developer' THEN 1 ELSE 0 END) AS Developers,
       SUM(CASE WHEN job_title = 'Tester' THEN 1 ELSE 0 END) AS Testers 
FROM employees
GROUP BY department_id;

-- 112. Find customers who made purchases in every category available.
SELECT customer_id
FROM sales s
GROUP BY customer_id
HAVING COUNT(DISTINCT category_id) = (SELECT COUNT(DISTINCT category_id) FROM sales);

-- 113. Identify employees who haven't received a salary raise in more than a year.
SELECT e.name
FROM employees e
JOIN salary_history sh ON e.id = sh.employee_id
GROUP BY e.id, e.name
HAVING MAX(sh.raise_date) < CURRENT_DATE - INTERVAL '1 year';

-- 114. Write a query to rank salespeople by monthly sales, resetting the rank every month.
SELECT salesperson_id, sale_month, total_sales, 
       RANK() OVER (PARTITION BY sale_month ORDER BY total_sales DESC) AS monthly_rank
FROM (
    SELECT salesperson_id, 
           DATE_TRUNC('month', sale_date) AS sale_month, 
           SUM(amount) AS total_sales
    FROM sales
    GROUP BY salesperson_id, sale_month 
) AS monthly_sales;

-- 115. Calculate the percentage change in sales compared to the previous month for each product.
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

-- 116. Find employees who earn more than the average salary across the company but less than the highest salary in their department.
SELECT *
FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees)
  AND salary < (SELECT MAX(salary) FROM employees WHERE department_id = e.department_id);

-- 117. Retrieve the last 5 orders for each customer.
SELECT *
FROM (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders o
) sub
WHERE rn <= 5;

-- 118. Find employees with no salary changes in the last 2 years.
SELECT e.*
FROM employees e
LEFT JOIN salary_history sh ON e.id = sh.employee_id 
    AND sh.change_date >= CURRENT_DATE - INTERVAL '2 years' 
WHERE sh.employee_id IS NULL;

-- 119. Write a query to get the running total of sales per customer, ordered by sale date.
SELECT customer_id, sale_date, amount, 
       SUM(amount) OVER (PARTITION BY customer_id ORDER BY sale_date) AS running_total
FROM sales;

-- 120. Find the department-wise salary percentile (e.g., 90th percentile) using window functions.
SELECT department_id, salary, 
       PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY salary) OVER (PARTITION BY department_id) AS pct_90_salary 
FROM employees;

-- 121. Find employees who have worked for multiple departments over time.
SELECT employee_id
FROM employee_department_history 
GROUP BY employee_id
HAVING COUNT(DISTINCT department_id) > 1;

-- 122. Use window function to find the difference between current row's sales and previous row's sales partitioned by product.
SELECT product_id, sale_date, amount,
       amount - LAG(amount) OVER (PARTITION BY product_id ORDER BY sale_date) AS sales_diff 
FROM sales;

-- 123. Write a query to find all employees who are at the lowest level in the hierarchy (no subordinates).
SELECT *
FROM employees e 
WHERE NOT EXISTS (
    SELECT 1 FROM employees sub WHERE sub.manager_id = e.id
);

-- 124. Find average order value per month and product category.
SELECT DATE_TRUNC('month', order_date) AS order_month, 
       category_id, 
       AVG(order_value) AS avg_order_value 
FROM orders
GROUP BY order_month, category_id;

-- 125. Write a query to create a running count of how many employees joined in each year.
SELECT join_year, COUNT(*) AS yearly_hires, 
       SUM(COUNT(*)) OVER (ORDER BY join_year) AS running_total_hires
FROM (
    SELECT EXTRACT(YEAR FROM hire_date) AS join_year
    FROM employees 
) sub
GROUP BY join_year 
ORDER BY join_year;

-- 126. Write a query to find the second most recent order date per customer.
SELECT customer_id, order_date 
FROM (
    SELECT customer_id, order_date, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders
) sub
WHERE rn = 2;

-- 127. Get employees with salary in the top 10% in their department.
SELECT *
FROM (
    SELECT e.*, 
           NTILE(10) OVER (PARTITION BY department_id ORDER BY salary DESC) AS decile 
    FROM employees e
) sub
WHERE decile = 1;

-- 128. Write a recursive query to calculate factorial of a number (e.g., 5).
WITH RECURSIVE factorial(n, fact) AS (
    SELECT 1, 1 
    UNION ALL
    SELECT n + 1, fact * (n + 1) 
    FROM factorial
    WHERE n < 5
)
SELECT fact FROM factorial WHERE n = 5;

-- 129. Write a query to calculate the cumulative percentage of total sales per product.
SELECT product_id, sale_amount,
       SUM(sale_amount) OVER (ORDER BY sale_amount DESC) * 100.0 / 
       SUM(sale_amount) OVER () AS cumulative_pct 
FROM sales;

-- 130. Find the average number of orders per customer and standard deviation.
SELECT AVG(order_count) AS avg_orders,
       STDDEV(order_count) AS stddev_orders 
FROM (
    SELECT customer_id, COUNT(*) AS order_count 
    FROM orders
    GROUP BY customer_id
) sub;

-- 131. Write a query to find consecutive days where sales were above a threshold.
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

-- 132. Write a query to concatenate employee names in each department (string aggregation).
SELECT department_id, STRING_AGG(name, ', ') AS employee_names
FROM employees
GROUP BY department_id;

-- 133. Find employees whose salary is above the average salary of their department but below the company-wide average.
SELECT *
FROM employees e 
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
    WHERE department_id = e.department_id
)
AND salary < (SELECT AVG(salary) FROM employees);

-- 134. List the customers who purchased all products in a specific category.
SELECT customer_id
FROM sales
WHERE product_id IN (SELECT product_id FROM products WHERE category_id = 10)
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (
    SELECT COUNT(DISTINCT product_id) 
    FROM products 
    WHERE category_id = 10
);

-- 135. Retrieve the Nth highest salary from the employees table.
SELECT DISTINCT salary
FROM employees 
ORDER BY salary DESC
LIMIT 1 OFFSET 2; -- N-1 for Nth highest

-- 136. Find employees with no corresponding entries in the salary_history table.
SELECT e.*
FROM employees e
LEFT JOIN salary_history sh ON e.id = sh.employee_id
WHERE sh.employee_id IS NULL;

-- 137. Show the department with the highest number of employees and the count.
SELECT department_id, COUNT(*) AS employee_count 
FROM employees
GROUP BY department_id 
ORDER BY employee_count DESC 
LIMIT 1;

-- 138. Calculate the median salary by department using window functions.
SELECT DISTINCT department_id, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) OVER (PARTITION BY department_id) AS median_salary 
FROM employees;

-- 139. Write a query to find the first purchase date and last purchase date for each customer, including customers who never purchased anything.
SELECT c.customer_id,
       MIN(s.purchase_date) AS first_purchase,
       MAX(s.purchase_date) AS last_purchase 
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id 
GROUP BY c.customer_id;

-- 140. Find the percentage difference between each month's total sales and the previous month's total sales.
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

-- 141. Write a query to find employees who have the longest tenure within their department.
WITH tenure AS (
    SELECT *, 
           RANK() OVER (PARTITION BY department_id ORDER BY hire_date ASC) AS tenure_rank 
    FROM employees
)
SELECT *
FROM tenure
WHERE tenure_rank = 1;

-- 142. Generate a report that shows sales and sales growth percentage compared to the same month last year.
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

-- 143. Write a query to identify overlapping shifts for employees.
SELECT s1.employee_id, s1.shift_id AS shift1, s2.shift_id AS shift2
FROM shifts s1
JOIN shifts s2 ON s1.employee_id = s2.employee_id AND s1.shift_id < s2.shift_id
WHERE s1.start_time < s2.end_time AND s1.end_time > s2.start_time;

-- 144. Calculate the total revenue for each customer, and rank them from highest to lowest spender.
SELECT customer_id, SUM(amount) AS total_revenue,
       RANK() OVER (ORDER BY SUM(amount) DESC) AS revenue_rank 
FROM sales
GROUP BY customer_id;

-- 145. Write a query to find the employee(s) who have never received a promotion.
SELECT e.*
FROM employees e
LEFT JOIN promotions p ON e.id = p.employee_id 
WHERE p.employee_id IS NULL;

-- 146. Write a query to find the top 3 products with the highest total sales amount each month.
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

-- 147. Find the customers who placed orders only in the last 30 days.
SELECT DISTINCT customer_id 
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
  AND customer_id NOT IN (
      SELECT DISTINCT customer_id 
      FROM orders
      WHERE order_date < CURRENT_DATE - INTERVAL '30 days'
  );

-- 148. Find products that have never been ordered.
SELECT p.product_id, p.product_name 
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id 
WHERE o.order_id IS NULL;

-- 149. Find employees whose salary is above their department's average but below the overall average salary.
SELECT *
FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees WHERE department_id = e.department_id)
  AND salary < (SELECT AVG(salary) FROM employees);

-- 150. Calculate the total sales amount and number of orders per customer in the last year.
SELECT customer_id, COUNT(*) AS total_orders, SUM(amount) AS total_sales
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY customer_id;

-- 151. List the top 5 highest-paid employees per department.
SELECT *
FROM (
    SELECT e.*,
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees e
) sub
WHERE rn <= 5;

-- 152. Write a query to identify "gaps and islands" in attendance records (consecutive dates present).
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

-- 153. Calculate a 3-month moving average of monthly sales per product.
WITH monthly_sales AS (
    SELECT product_id, 
           DATE_TRUNC('month', sale_date) AS month, 
           SUM(amount) AS total_sales 
    FROM sales
    GROUP BY product_id, month
)
SELECT product_id, month, total_sales, 
       AVG(total_sales) OVER (PARTITION BY product_id ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
FROM monthly_sales;

-- 154. Write a query to find employees who have the same hire date as their managers.
SELECT e.name AS employee_name, m.name AS manager_name, e.hire_date
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.hire_date = m.hire_date;

-- 155. Write a query to find products with increasing sales over the last 3 months.
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

-- 156. Write a query to get the nth highest salary per department.
SELECT department_id, salary
FROM (
    SELECT department_id, salary, 
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn 
    FROM employees
) sub
WHERE rn = 2; -- Replace with N

-- 157. Find employees who have managed more than 3 projects.
SELECT manager_id, COUNT(DISTINCT project_id) AS project_count
FROM projects
GROUP BY manager_id
HAVING COUNT(DISTINCT project_id) > 3;

-- 158. Write a query to calculate the difference in days between each employee's hire date and their manager's hire date.
SELECT e.name AS employee, m.name AS manager, 
       (e.hire_date - m.hire_date) AS days_difference 
FROM employees e
JOIN employees m ON e.manager_id = m.id;

-- 159. Write a query to find the department with the highest average years of experience.
SELECT department_id, 
       AVG(EXTRACT(year FROM CURRENT_DATE - hire_date)) AS avg_experience_years
FROM employees
GROUP BY department_id
ORDER BY avg_experience_years DESC 
LIMIT 1;

-- 160. Identify employees who had overlapping project assignments.
SELECT p1.employee_id, p1.project_id AS project1, p2.project_id AS project2
FROM project_assignments p1
JOIN project_assignments p2 ON p1.employee_id = p2.employee_id AND p1.project_id < p2.project_id
WHERE p1.start_date < p2.end_date AND p1.end_date > p2.start_date;

-- 161. Find customers who made purchases in every month of the current year.
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

-- 162. List employees who earn more than all their subordinates.
SELECT e.id, e.name, e.salary 
FROM employees e
WHERE e.salary > ALL (
    SELECT salary
    FROM employees sub
    WHERE sub.manager_id = e.id
);

-- 163. Get the product with the highest sales for each category.
WITH category_sales AS (
    SELECT category_id, product_id, SUM(amount) AS total_sales,
           RANK() OVER (PARTITION BY category_id ORDER BY SUM(amount) DESC) AS sales_rank 
    FROM sales
    GROUP BY category_id, product_id 
)
SELECT category_id, product_id, total_sales 
FROM category_sales
WHERE sales_rank = 1;

-- 164. Find customers who haven't ordered in the last 6 months.
SELECT customer_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING MAX(o.order_date) < CURRENT_DATE - INTERVAL '6 months'
   OR MAX(o.order_date) IS NULL;

-- 165. Find the maximum salary gap between any two employees within the same department.
SELECT department_id, MAX(salary) - MIN(salary) AS salary_gap
FROM employees
GROUP BY department_id;

-- 166. Calculate the rank of employees by salary within their department but restart rank numbering every 10 employees.
WITH ranked_employees AS (
    SELECT e.*, 
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn 
    FROM employees e
)
SELECT *, ((rn - 1) / 10) + 1 AS rank_group 
FROM ranked_employees;

-- 167. Find the moving median of daily sales over the last 7 days for each product.
WITH daily_sales AS (
    SELECT product_id, sale_date, SUM(amount) AS total_sales
    FROM sales
    GROUP BY product_id, sale_date
)
SELECT product_id, sale_date, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) 
       OVER (PARTITION BY product_id ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_median 
FROM daily_sales;

-- 168. Find customers who purchased both product A and product B.
SELECT customer_id
FROM sales
WHERE product_id IN ('A', 'B') 
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = 2;

-- 169. Write a query to generate a calendar table with all dates for the current year.
SELECT generate_series(
    DATE_TRUNC('year', CURRENT_DATE), 
    DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year' - INTERVAL '1 day', 
    INTERVAL '1 day'
) AS calendar_date;

-- 170. Find employees who have worked in more than 3 different departments.
SELECT employee_id
FROM employee_department_history 
GROUP BY employee_id
HAVING COUNT(DISTINCT department_id) > 3;

-- 171. Calculate the percentage contribution of each product's sales to the total sales per month.
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

-- 172. Write a query to pivot monthly sales data for each product into columns.
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

-- 173. Find the 3 most recent orders per customer including order details.
SELECT *
FROM (
    SELECT o.*, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders o
) sub
WHERE rn <= 3;

-- 174. Find employees who have never taken any leave.
SELECT e.*
FROM employees e
LEFT JOIN leaves l ON e.id = l.employee_id 
WHERE l.leave_id IS NULL;

-- 175. List customers who placed orders in January but not in February.
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

-- 176. Find products that have seen a price increase in the last 6 months.
WITH price_changes AS (
    SELECT product_id, price, effective_date,
           LAG(price) OVER (PARTITION BY product_id ORDER BY effective_date) AS prev_price
    FROM product_prices
    WHERE effective_date >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT DISTINCT product_id
FROM price_changes 
WHERE price > prev_price;

-- 177. Find the department(s) with the second highest average salary.
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

-- 178. Find employees who joined in the same month and year.
SELECT e1.id AS emp1_id, e2.id AS emp2_id, e1.hire_date
FROM employees e1
JOIN employees e2 ON e1.id < e2.id
  AND EXTRACT(MONTH FROM e1.hire_date) = EXTRACT(MONTH FROM e2.hire_date)
  AND EXTRACT(YEAR FROM e1.hire_date) = EXTRACT(YEAR FROM e2.hire_date);

-- 179. Find the second highest salary per department without using window functions.
SELECT department_id, MAX(salary) AS second_highest_salary
FROM employees e1
WHERE salary < (
    SELECT MAX(salary)
    FROM employees e2
    WHERE e2.department_id = e1.department_id
)
GROUP BY department_id;

-- 180. Calculate the percentage change in sales for each product comparing current month to previous month.
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

-- 181. Write a query to unpivot quarterly sales data into rows.
SELECT product_id, 'Q1' AS quarter, Q1_sales AS sales FROM sales_data 
UNION ALL
SELECT product_id, 'Q2', Q2_sales FROM sales_data 
UNION ALL
SELECT product_id, 'Q3', Q3_sales FROM sales_data 
UNION ALL
SELECT product_id, 'Q4', Q4_sales FROM sales_data;

-- 182. Write a query to find customers with the highest purchase amount per year.
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

-- 183. Write a query to list all employees who have a salary equal to the average salary of their department.
SELECT e.*
FROM employees e 
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id
) d ON e.department_id = d.department_id AND e.salary = d.avg_salary;

-- 184. Find the highest salary by department and the employee(s) who earn it.
WITH dept_max AS (
    SELECT department_id, MAX(salary) AS max_salary 
    FROM employees
    GROUP BY department_id
)
SELECT e.*
FROM employees e
JOIN dept_max d ON e.department_id = d.department_id AND e.salary = d.max_salary;

-- 185. Find employees whose salary is within 10% of the highest salary in their department.
WITH dept_max AS (
    SELECT department_id, MAX(salary) AS max_salary 
    FROM employees
    GROUP BY department_id
)
SELECT e.*
FROM employees e
JOIN dept_max d ON e.department_id = d.department_id
WHERE e.salary >= 0.9 * d.max_salary;

-- 186. Find the running total of sales by date.
SELECT sale_date, 
       SUM(amount) OVER (ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total 
FROM sales
ORDER BY sale_date;

-- 187. Get the last 3 orders placed by each customer.
SELECT *
FROM (
    SELECT o.*, 
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn 
    FROM orders o
) sub
WHERE rn <= 3;

-- 188. Find employees who have worked on all projects.
SELECT employee_id 
FROM project_assignments
GROUP BY employee_id
HAVING COUNT(DISTINCT project_id) = (SELECT COUNT(*) FROM projects);

-- 189. Find customers who placed orders only in the last 6 months.
SELECT customer_id
FROM orders
GROUP BY customer_id
HAVING MIN(order_date) >= CURRENT_DATE - INTERVAL '6 months';

-- 190. Get the total number of orders per day, including days with zero orders.
WITH dates AS (
    SELECT generate_series(MIN(order_date), MAX(order_date), INTERVAL '1 day') AS day 
    FROM orders
)
SELECT d.day, COUNT(o.order_id) AS order_count
FROM dates d
LEFT JOIN orders o ON d.day = o.order_date 
GROUP BY d.day
ORDER BY d.day;

-- 191. Write a query to find gaps in employee IDs.
WITH numbered AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
    FROM employees
)
SELECT rn + 1 AS missing_id 
FROM numbered
WHERE id != rn;

-- 192. Find employees with the highest number of dependents.
SELECT employee_id, COUNT(*) AS dependent_count
FROM dependents 
GROUP BY employee_id
ORDER BY dependent_count DESC 
LIMIT 1;

-- 193. Find customers with the longest gap between two consecutive orders.
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

-- 194. Find customers who ordered all products in a category.
SELECT customer_id
FROM sales
WHERE product_id IN (SELECT product_id FROM products WHERE category_id = 1)
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (SELECT COUNT(*) FROM products WHERE category_id = 1);

-- 195. List products with sales above the average sales amount.
WITH avg_sales AS (
    SELECT AVG(amount) AS avg_amount 
    FROM sales
)
SELECT product_id, SUM(amount) AS total_sales 
FROM sales
GROUP BY product_id
HAVING SUM(amount) > (SELECT avg_amount FROM avg_sales);

-- 196. Find employees whose salaries are between the 25th and 75th percentile.
WITH percentiles AS (
    SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) AS p25,
           PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) AS p75
    FROM employees
)
SELECT e.*
FROM employees e, percentiles p
WHERE e.salary BETWEEN p.p25 AND p.p75;

-- 197. Find products with sales only in the current month.
SELECT product_id 
FROM sales
GROUP BY product_id 
HAVING MAX(sale_date) >= DATE_TRUNC('month', CURRENT_DATE) 
   AND MIN(sale_date) >= DATE_TRUNC('month', CURRENT_DATE);

-- 198. Find employees with consecutive workdays.
WITH attendance AS (
    SELECT employee_id, work_date, 
           work_date - INTERVAL (ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY work_date)) DAY AS grp 
    FROM work_log
)
SELECT employee_id, COUNT(*) AS consecutive_days
FROM attendance
GROUP BY employee_id, grp 
HAVING COUNT(*) > 1;

-- 199. Find employees who have worked on more than 5 projects.
SELECT employee_id, COUNT(DISTINCT project_id) AS project_count
FROM project_assignments
GROUP BY employee_id
HAVING COUNT(DISTINCT project_id) > 5;

-- 200. Find the average gap (in days) between orders per customer.
WITH ordered_orders AS (
    SELECT customer_id, order_date,
           LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date
    FROM orders
),
gaps AS (
    SELECT customer_id, order_date - prev_order_date AS gap
    FROM ordered_orders
    WHERE prev_order_date IS NOT NULL 
)
SELECT customer_id, AVG(gap) AS avg_gap_days 
FROM gaps
GROUP BY customer_id;