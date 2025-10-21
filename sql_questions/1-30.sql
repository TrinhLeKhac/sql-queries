-- SQL Questions 1-30

-- 1. Find the second highest salary from the Employee table.
-- Find the second highest salary from the employees table
SELECT MAX(salary) AS SecondHighestSalary
FROM employees 
WHERE salary < (SELECT MAX(salary) FROM employees);

-- 2. Find duplicate records in a table.
-- Find duplicate employee names in the employees table
SELECT name, COUNT(*)
FROM employees 
GROUP BY name
HAVING COUNT(*) > 1;

-- 3. Retrieve employees who earn more than their manager.
-- Find employees whose salary is higher than their manager's salary
SELECT e.name AS Employee, e.salary, m.name AS Manager, m.salary AS ManagerSalary 
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.salary > m.salary;

-- 4. Count employees in each department having more than 5 employees.
-- Count departments with more than 5 employees
SELECT department_id, COUNT(*) AS num_employees
FROM employees
GROUP BY department_id 
HAVING COUNT(*) > 5;

-- 5. Find employees who joined in the last 6 months.
-- Retrieve employees hired within the last 6 months
SELECT *
FROM employees
WHERE hire_date > CURRENT_DATE - INTERVAL '6 months';

-- 6. Get departments with no employees.
-- Find departments that have no employees assigned
SELECT d.department_name 
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.id IS NULL;

-- 7. Write a query to find the median salary.
-- Calculate the median salary of all employees
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary
FROM employees;

-- 8. Running total of salaries by department.
-- Calculate running total of salaries within each department
SELECT name, department_id, salary, 
       SUM(salary) OVER (PARTITION BY department_id ORDER BY id) AS running_total 
FROM employees;

-- 9. Find the longest consecutive streak of daily logins for each user.
-- Find the longest consecutive login streak for each user
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

-- 10. Recursive query to find the full reporting chain for each employee.
-- Build organizational hierarchy showing reporting levels
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

-- 11. Write a query to find gaps in a sequence of numbers (missing IDs).
-- Find missing employee IDs in sequence
SELECT (id + 1) AS missing_id 
FROM employees e1
WHERE NOT EXISTS (
    SELECT 1 FROM employees e2 WHERE e2.id = e1.id + 1
)
ORDER BY missing_id;

-- 12. Calculate cumulative distribution (CDF) of salaries.
-- Calculate cumulative distribution of employee salaries
SELECT name, salary,
       CUME_DIST() OVER (ORDER BY salary) AS salary_cdf
FROM employees;

-- 13. Compare two tables and find rows with differences in any column.
-- Compare two tables and identify differences in any column
SELECT *
FROM table1 t1
FULL OUTER JOIN table2 t2 ON t1.id = t2.id
WHERE t1.col1 IS DISTINCT FROM t2.col1 
   OR t1.col2 IS DISTINCT FROM t2.col2 
   OR t1.col3 IS DISTINCT FROM t2.col3;

-- 14. Write a query to rank employees based on salary with ties handled properly.
-- Rank employees by salary handling ties appropriately
SELECT name, salary,
       RANK() OVER (ORDER BY salary DESC) AS salary_rank 
FROM employees;

-- 15. Find customers who have not made any purchase.
-- Find customers with no sales records
SELECT c.customer_id, c.name 
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id 
WHERE s.sale_id IS NULL;

-- 16. Write a query to perform a conditional aggregation (count males and females in each department)
-- Count male and female employees by department
SELECT department_id,
       COUNT(CASE WHEN gender = 'M' THEN 1 END) AS male_count,
       COUNT(CASE WHEN gender = 'F' THEN 1 END) AS female_count
FROM employees
GROUP BY department_id;

-- 17. Write a query to calculate the difference between current row and previous row's salary (lag function).
-- Calculate salary difference from previous employee
SELECT name, salary,
       salary - LAG(salary) OVER (ORDER BY id) AS salary_diff
FROM employees;

-- 18. Identify overlapping date ranges for bookings.
-- Find overlapping booking date ranges
SELECT b1.booking_id, b2.booking_id
FROM bookings b1
JOIN bookings b2 ON b1.booking_id < b2.booking_id 
WHERE b1.start_date <= b2.end_date
  AND b1.end_date >= b2.start_date;

-- 19. Write a query to find employees with salary greater than average salary in the entire company, ordered by salary descending.
-- Find employees earning above company average salary
SELECT name, salary 
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;

-- 20. Aggregate JSON data (if supported) to list all employee names in a department as a JSON array.
-- Aggregate employee names by department as JSON array
SELECT department_id, JSON_AGG(name) AS employee_names
FROM employees
GROUP BY department_id;

-- 21. Find employees who have the same salary as their manager.
-- Find employees with identical salary to their manager
SELECT e.name AS Employee, e.salary, m.name AS Manager
FROM employees e
JOIN employees m ON e.manager_id = m.id 
WHERE e.salary = m.salary;

-- 22. Write a query to get the first and last purchase date for each customer.
-- Get first and last purchase dates per customer
SELECT customer_id,
       MIN(purchase_date) AS first_purchase, 
       MAX(purchase_date) AS last_purchase
FROM sales
GROUP BY customer_id;

-- 23. Find departments with the highest average salary.
-- Find departments with maximum average salary
WITH avg_salaries AS (
    SELECT department_id, AVG(salary) AS avg_salary 
    FROM employees
    GROUP BY department_id
)
SELECT *
FROM avg_salaries
WHERE avg_salary = (SELECT MAX(avg_salary) FROM avg_salaries);

-- 24. Write a query to find the number of employees in each job title.
-- Count employees by job title
SELECT job_title, COUNT(*) AS num_employees
FROM employees 
GROUP BY job_title;

-- 25. Find employees who don't have a department assigned.
-- Find employees without department assignment
SELECT *
FROM employees
WHERE department_id IS NULL;

-- 26. Write a query to find the difference in days between two dates in the same table.
-- Calculate days difference between project start and end dates
SELECT id, (end_date - start_date) AS days_difference
FROM projects;

-- 27. Calculate the moving average of salaries over the last 3 employees ordered by hire date.
-- Calculate 3-employee moving average of salaries by hire date
SELECT name, hire_date, salary,
       AVG(salary) OVER (ORDER BY hire_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_salary 
FROM employees;

-- 28. Find the most recent purchase per customer using window functions.
-- Get most recent purchase for each customer
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY purchase_date DESC) AS rn 
    FROM sales
) sub
WHERE rn = 1;

-- 29. Detect hierarchical depth of each employee in the org chart.
-- Calculate organizational depth for each employee
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

-- 30. Write a query to perform a self-join to find pairs of employees in the same department.
-- Find pairs of employees working in the same department
SELECT e1.name AS Employee1, e2.name AS Employee2, e1.department_id
FROM employees e1
JOIN employees e2 ON e1.department_id = e2.department_id AND e1.id < e2.id;