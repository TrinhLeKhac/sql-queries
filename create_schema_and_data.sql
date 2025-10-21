-- PostgreSQL Schema and Data Generation Script
-- Creates tables and sample data for 300 SQL questions

-- Drop existing tables if they exist
DROP TABLE IF EXISTS sql_questions CASCADE;
DROP TABLE IF EXISTS attendance CASCADE;
DROP TABLE IF EXISTS user_logins CASCADE;
DROP TABLE IF EXISTS work_logs CASCADE;
DROP TABLE IF EXISTS shifts CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS leaves CASCADE;
DROP TABLE IF EXISTS bonuses CASCADE;
DROP TABLE IF EXISTS promotions CASCADE;
DROP TABLE IF EXISTS salary_history CASCADE;
DROP TABLE IF EXISTS project_assignments CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS dependents CASCADE;
DROP TABLE IF EXISTS employee_department_history CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS invoices CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS timesheets CASCADE;
DROP TABLE IF EXISTS product_reviews CASCADE;
DROP TABLE IF EXISTS product_prices CASCADE;
DROP TABLE IF EXISTS returns CASCADE;
DROP TABLE IF EXISTS shipments CASCADE;
DROP TABLE IF EXISTS weather_data CASCADE;
DROP TABLE IF EXISTS holidays CASCADE;

-- Create tables
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    creation_date DATE DEFAULT CURRENT_DATE - INTERVAL '5 years' + (RANDOM() * INTERVAL '5 years'),
    budget DECIMAL(12,2) DEFAULT 100000 + (RANDOM() * 900000)
);

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    department_id INTEGER REFERENCES departments(department_id),
    manager_id INTEGER REFERENCES employees(id),
    hire_date DATE DEFAULT CURRENT_DATE - INTERVAL '10 years' + (RANDOM() * INTERVAL '10 years'),
    job_title VARCHAR(100),
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    birth_date DATE DEFAULT CURRENT_DATE - INTERVAL '65 years' + (RANDOM() * INTERVAL '40 years'),
    termination_date DATE
);

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category_id INTEGER REFERENCES categories(category_id),
    price DECIMAL(10,2) DEFAULT 10 + (RANDOM() * 990),
    launch_date DATE DEFAULT CURRENT_DATE - INTERVAL '3 years' + (RANDOM() * INTERVAL '3 years'),
    discontinued BOOLEAN DEFAULT FALSE
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(50) DEFAULT (ARRAY['USA', 'Canada', 'UK', 'Germany', 'France', 'Japan', 'Australia'])[FLOOR(RANDOM() * 7) + 1],
    region VARCHAR(50),
    segment VARCHAR(50) DEFAULT (ARRAY['Enterprise', 'SMB', 'Consumer'])[FLOOR(RANDOM() * 3) + 1],
    registration_date DATE DEFAULT CURRENT_DATE - INTERVAL '5 years' + (RANDOM() * INTERVAL '5 years')
);

CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    product_id INTEGER REFERENCES products(product_id),
    employee_id INTEGER REFERENCES employees(id),
    sale_date DATE DEFAULT CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    amount DECIMAL(10,2) DEFAULT 50 + (RANDOM() * 950),
    quantity INTEGER DEFAULT 1 + FLOOR(RANDOM() * 10),
    category_id INTEGER,
    purchase_date DATE,
    sales_rep_id INTEGER
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    product_id INTEGER REFERENCES products(product_id),
    order_date DATE DEFAULT CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    amount DECIMAL(10,2) DEFAULT 25 + (RANDOM() * 475),
    delivery_date DATE,
    shipping_date DATE,
    discount_amount DECIMAL(8,2) DEFAULT 0,
    discount_used BOOLEAN DEFAULT (RANDOM() > 0.7),
    payment_method VARCHAR(50) DEFAULT (ARRAY['Credit Card', 'Debit Card', 'Cash', 'Bank Transfer'])[FLOOR(RANDOM() * 4) + 1],
    shipping_method VARCHAR(50) DEFAULT (ARRAY['Standard', 'Express', 'Overnight'])[FLOOR(RANDOM() * 3) + 1],
    order_value DECIMAL(10,2),
    category_id INTEGER,
    order_channel VARCHAR(50) DEFAULT (ARRAY['Online', 'In-Store'])[FLOOR(RANDOM() * 2) + 1]
);

CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER DEFAULT 1 + FLOOR(RANDOM() * 5)
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(200) NOT NULL,
    department_id INTEGER REFERENCES departments(department_id),
    manager_id INTEGER REFERENCES employees(id),
    start_date DATE DEFAULT CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    end_date DATE,
    budget DECIMAL(12,2) DEFAULT 50000 + (RANDOM() * 450000),
    status VARCHAR(50) DEFAULT (ARRAY['Active', 'Completed', 'On Hold'])[FLOOR(RANDOM() * 3) + 1],
    completion_date DATE
);

CREATE TABLE project_assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    project_id INTEGER REFERENCES projects(project_id),
    start_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    end_date DATE,
    hours_worked DECIMAL(8,2) DEFAULT 40 + (RANDOM() * 120),
    assignment_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    assignment_start_date DATE,
    assignment_end_date DATE
);

CREATE TABLE salary_history (
    history_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    change_date DATE DEFAULT CURRENT_DATE - INTERVAL '3 years' + (RANDOM() * INTERVAL '3 years'),
    raise_date DATE,
    salary_before DECIMAL(10,2)
);

CREATE TABLE promotions (
    promotion_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    old_title VARCHAR(100),
    new_title VARCHAR(100),
    promotion_date DATE DEFAULT CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2)
);

CREATE TABLE bonuses (
    bonus_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    bonus_amount DECIMAL(10,2) DEFAULT 1000 + (RANDOM() * 9000),
    bonus_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
);

CREATE TABLE leaves (
    leave_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    leave_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    leave_type VARCHAR(50) DEFAULT (ARRAY['Vacation', 'Sick', 'Personal'])[FLOOR(RANDOM() * 3) + 1],
    days INTEGER DEFAULT 1 + FLOOR(RANDOM() * 10)
);

CREATE TABLE dependents (
    dependent_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    dependent_name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50) DEFAULT (ARRAY['Spouse', 'Child', 'Parent'])[FLOOR(RANDOM() * 3) + 1],
    birth_date DATE DEFAULT CURRENT_DATE - INTERVAL '50 years' + (RANDOM() * INTERVAL '40 years')
);

CREATE TABLE employee_department_history (
    history_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    department_id INTEGER REFERENCES departments(department_id),
    start_date DATE DEFAULT CURRENT_DATE - INTERVAL '5 years' + (RANDOM() * INTERVAL '5 years'),
    end_date DATE,
    change_date DATE DEFAULT CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years')
);

CREATE TABLE attendance (
    attendance_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    attendance_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    arrival_time TIME DEFAULT '08:00:00'::TIME + (RANDOM() * INTERVAL '2 hours'),
    scheduled_start_time TIME DEFAULT '09:00:00'
);

CREATE TABLE work_logs (
    log_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    work_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    hours_worked DECIMAL(4,2) DEFAULT 6 + (RANDOM() * 4)
);

CREATE TABLE shifts (
    shift_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    start_time TIMESTAMP DEFAULT CURRENT_DATE - INTERVAL '30 days' + (RANDOM() * INTERVAL '30 days'),
    end_time TIMESTAMP,
    shift_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days' + (RANDOM() * INTERVAL '30 days')
);

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    start_date DATE DEFAULT CURRENT_DATE + (RANDOM() * INTERVAL '90 days'),
    end_date DATE,
    room_type VARCHAR(50) DEFAULT (ARRAY['Standard', 'Deluxe', 'Suite'])[FLOOR(RANDOM() * 3) + 1],
    total_amount DECIMAL(10,2) DEFAULT 100 + (RANDOM() * 900)
);

CREATE TABLE timesheets (
    timesheet_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    timesheet_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 month' + (RANDOM() * INTERVAL '1 month'),
    hours_worked DECIMAL(4,2) DEFAULT 6 + (RANDOM() * 4),
    status VARCHAR(20) DEFAULT (ARRAY['Submitted', 'Approved', 'Pending'])[FLOOR(RANDOM() * 3) + 1]
);

CREATE TABLE product_reviews (
    review_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(product_id),
    customer_id INTEGER REFERENCES customers(customer_id),
    rating INTEGER CHECK (rating BETWEEN 1 AND 5) DEFAULT 1 + FLOOR(RANDOM() * 5),
    review_text TEXT,
    review_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
);

CREATE TABLE returns (
    return_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    return_date DATE DEFAULT CURRENT_DATE - INTERVAL '6 months' + (RANDOM() * INTERVAL '6 months'),
    reason VARCHAR(200),
    refund_amount DECIMAL(10,2) DEFAULT 50 + (RANDOM() * 450)
);

CREATE TABLE shipments (
    shipment_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    shipping_method VARCHAR(50) DEFAULT (ARRAY['Standard', 'Express', 'Overnight'])[FLOOR(RANDOM() * 3) + 1],
    shipped_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    delivery_date DATE,
    tracking_number VARCHAR(50)
);

CREATE TABLE support_tickets (
    ticket_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    support_agent_id INTEGER REFERENCES employees(id),
    opened_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    closed_date DATE,
    status VARCHAR(20) DEFAULT (ARRAY['Open', 'Closed', 'In Progress'])[FLOOR(RANDOM() * 3) + 1],
    priority VARCHAR(10) DEFAULT (ARRAY['Low', 'Medium', 'High'])[FLOOR(RANDOM() * 3) + 1]
);

CREATE TABLE weather_data (
    weather_id SERIAL PRIMARY KEY,
    weather_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    temperature DECIMAL(5,2) DEFAULT -10 + (RANDOM() * 50),
    humidity DECIMAL(5,2) DEFAULT 30 + (RANDOM() * 70),
    location VARCHAR(100) DEFAULT (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston'])[FLOOR(RANDOM() * 4) + 1]
);

CREATE TABLE holidays (
    holiday_id SERIAL PRIMARY KEY,
    holiday_date DATE NOT NULL,
    holiday_name VARCHAR(100) NOT NULL,
    country VARCHAR(50) DEFAULT 'USA'
);

CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) DEFAULT (ARRAY['North', 'South', 'East', 'West'])[FLOOR(RANDOM() * 4) + 1]
);

CREATE TABLE deliveries (
    delivery_id SERIAL PRIMARY KEY,
    supplier_id INTEGER REFERENCES suppliers(supplier_id),
    delivery_region VARCHAR(50) DEFAULT (ARRAY['North', 'South', 'East', 'West'])[FLOOR(RANDOM() * 4) + 1],
    delivery_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
);

CREATE TABLE job_openings (
    job_id SERIAL PRIMARY KEY,
    department_id INTEGER REFERENCES departments(department_id),
    job_title VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT (ARRAY['Open', 'Closed', 'Filled'])[FLOOR(RANDOM() * 3) + 1],
    posted_date DATE DEFAULT CURRENT_DATE - INTERVAL '6 months' + (RANDOM() * INTERVAL '6 months')
);

CREATE TABLE sales_deals (
    deal_id SERIAL PRIMARY KEY,
    sales_rep_id INTEGER REFERENCES employees(id),
    deal_close_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    deal_amount DECIMAL(12,2) DEFAULT 1000 + (RANDOM() * 99000)
);

CREATE TABLE salaries (
    salary_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE) - FLOOR(RANDOM() * 5),
    salary DECIMAL(10,2) DEFAULT 30000 + (RANDOM() * 120000)
);

CREATE TABLE user_logins (
    login_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES customers(customer_id),
    login_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
);

CREATE TABLE invoices (
    invoice_id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) NOT NULL,
    customer_id INTEGER REFERENCES customers(customer_id),
    amount DECIMAL(10,2) DEFAULT 100 + (RANDOM() * 900),
    invoice_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    due_date DATE,
    status VARCHAR(20) DEFAULT (ARRAY['Paid', 'Pending', 'Overdue'])[FLOOR(RANDOM() * 3) + 1]
);

CREATE TABLE product_prices (
    price_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(product_id),
    price DECIMAL(10,2) NOT NULL,
    effective_date DATE DEFAULT CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years')
);

-- Insert sample data
INSERT INTO departments (department_name, creation_date, budget)
SELECT 
    (ARRAY['Engineering', 'Sales', 'Marketing', 'HR', 'Finance', 'Operations', 'IT', 'Legal', 'R&D', 'Customer Service'])[i],
    CURRENT_DATE - INTERVAL '5 years' + (RANDOM() * INTERVAL '5 years'),
    100000 + (RANDOM() * 900000)
FROM generate_series(1, 10) i;

INSERT INTO employees (name, salary, department_id, job_title, gender, hire_date, birth_date)
SELECT 
    'Employee_' || i,
    30000 + (RANDOM() * 120000),
    1 + FLOOR(RANDOM() * 10),
    (ARRAY['Manager', 'Developer', 'Analyst', 'Specialist', 'Coordinator', 'Director', 'VP', 'Intern', 'Senior Manager', 'Lead'])[FLOOR(RANDOM() * 10) + 1],
    (ARRAY['M', 'F'])[FLOOR(RANDOM() * 2) + 1],
    CURRENT_DATE - INTERVAL '10 years' + (RANDOM() * INTERVAL '10 years'),
    CURRENT_DATE - INTERVAL '65 years' + (RANDOM() * INTERVAL '40 years')
FROM generate_series(1, 1000) i;

INSERT INTO categories (category_name)
SELECT (ARRAY['Electronics', 'Clothing', 'Books', 'Home & Garden', 'Sports', 'Automotive', 'Health', 'Beauty', 'Toys', 'Food'])[i]
FROM generate_series(1, 10) i;

INSERT INTO products (product_name, category_id, price, launch_date)
SELECT 
    'Product_' || i,
    1 + FLOOR(RANDOM() * 10),
    10 + (RANDOM() * 990),
    CURRENT_DATE - INTERVAL '3 years' + (RANDOM() * INTERVAL '3 years')
FROM generate_series(1, 500) i;

INSERT INTO customers (name, country, region, segment, registration_date)
SELECT 
    'Customer_' || i,
    (ARRAY['USA', 'Canada', 'UK', 'Germany', 'France', 'Japan', 'Australia'])[FLOOR(RANDOM() * 7) + 1],
    (ARRAY['North', 'South', 'East', 'West', 'Central'])[FLOOR(RANDOM() * 5) + 1],
    (ARRAY['Enterprise', 'SMB', 'Consumer'])[FLOOR(RANDOM() * 3) + 1],
    CURRENT_DATE - INTERVAL '5 years' + (RANDOM() * INTERVAL '5 years')
FROM generate_series(1, 800) i;

INSERT INTO sales (customer_id, product_id, employee_id, sale_date, amount, quantity, category_id, purchase_date)
SELECT 
    1 + FLOOR(RANDOM() * 800),
    1 + FLOOR(RANDOM() * 500),
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    50 + (RANDOM() * 950),
    1 + FLOOR(RANDOM() * 10),
    1 + FLOOR(RANDOM() * 10),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years')
FROM generate_series(1, 5000) i;

INSERT INTO orders (customer_id, product_id, order_date, amount, category_id, order_value)
SELECT 
    1 + FLOOR(RANDOM() * 800),
    1 + FLOOR(RANDOM() * 500),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    25 + (RANDOM() * 475),
    1 + FLOOR(RANDOM() * 10),
    25 + (RANDOM() * 475)
FROM generate_series(1, 3000) i;

INSERT INTO projects (project_name, department_id, manager_id, start_date, end_date, status)
SELECT 
    'Project_' || i,
    1 + FLOOR(RANDOM() * 10),
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    CASE WHEN RANDOM() > 0.3 THEN CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '2 years') END,
    (ARRAY['Active', 'Completed', 'On Hold'])[FLOOR(RANDOM() * 3) + 1]
FROM generate_series(1, 200) i;

INSERT INTO project_assignments (employee_id, project_id, start_date, end_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    1 + FLOOR(RANDOM() * 200),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    CASE WHEN RANDOM() > 0.4 THEN CURRENT_DATE - INTERVAL '6 months' + (RANDOM() * INTERVAL '1 year') END
FROM generate_series(1, 1500) i;

INSERT INTO salary_history (employee_id, old_salary, new_salary, change_date, raise_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    30000 + (RANDOM() * 100000),
    35000 + (RANDOM() * 120000),
    CURRENT_DATE - INTERVAL '3 years' + (RANDOM() * INTERVAL '3 years'),
    CURRENT_DATE - INTERVAL '3 years' + (RANDOM() * INTERVAL '3 years')
FROM generate_series(1, 2000) i;

INSERT INTO promotions (employee_id, old_title, new_title, promotion_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    (ARRAY['Analyst', 'Specialist', 'Coordinator'])[FLOOR(RANDOM() * 3) + 1],
    (ARRAY['Senior Analyst', 'Manager', 'Director'])[FLOOR(RANDOM() * 3) + 1],
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years')
FROM generate_series(1, 500) i;

INSERT INTO leaves (employee_id, leave_date, leave_type, days)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    (ARRAY['Vacation', 'Sick', 'Personal'])[FLOOR(RANDOM() * 3) + 1],
    1 + FLOOR(RANDOM() * 10)
FROM generate_series(1, 3000) i;

INSERT INTO attendance (employee_id, attendance_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
FROM generate_series(1, 50000) i;

INSERT INTO user_logins (user_id, login_date)
SELECT 
    1 + FLOOR(RANDOM() * 800),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
FROM generate_series(1, 10000) i;

INSERT INTO invoices (invoice_number, customer_id, amount, invoice_date, due_date)
SELECT 
    'INV-' || LPAD(i::TEXT, 6, '0'),
    1 + FLOOR(RANDOM() * 800),
    100 + (RANDOM() * 900),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year') + INTERVAL '30 days'
FROM generate_series(1, 2000) i;

INSERT INTO product_prices (product_id, price, effective_date)
SELECT 
    1 + FLOOR(RANDOM() * 500),
    10 + (RANDOM() * 990),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years')
FROM generate_series(1, 1000) i;

INSERT INTO timesheets (employee_id, timesheet_date, hours_worked)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '1 month' + (RANDOM() * INTERVAL '1 month'),
    6 + (RANDOM() * 4)
FROM generate_series(1, 5000) i;

INSERT INTO product_reviews (product_id, customer_id, rating, review_date)
SELECT 
    1 + FLOOR(RANDOM() * 500),
    1 + FLOOR(RANDOM() * 800),
    1 + FLOOR(RANDOM() * 5),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
FROM generate_series(1, 3000) i;

INSERT INTO returns (order_id, product_id, return_date, refund_amount)
SELECT 
    1 + FLOOR(RANDOM() * 3000),
    1 + FLOOR(RANDOM() * 500),
    CURRENT_DATE - INTERVAL '6 months' + (RANDOM() * INTERVAL '6 months'),
    50 + (RANDOM() * 450)
FROM generate_series(1, 500) i;

INSERT INTO shipments (order_id, shipped_date, delivery_date, tracking_number)
SELECT 
    i,
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year') + INTERVAL '3 days',
    'TRK' || LPAD(i::TEXT, 10, '0')
FROM generate_series(1, 2500) i;

INSERT INTO support_tickets (customer_id, support_agent_id, opened_date, closed_date)
SELECT 
    1 + FLOOR(RANDOM() * 800),
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    CASE WHEN RANDOM() > 0.3 THEN CURRENT_DATE - INTERVAL '6 months' + (RANDOM() * INTERVAL '6 months') END
FROM generate_series(1, 1000) i;

INSERT INTO weather_data (weather_date, temperature, humidity, location)
SELECT 
    CURRENT_DATE - INTERVAL '1 year' + (i * INTERVAL '1 day'),
    -10 + (RANDOM() * 50),
    30 + (RANDOM() * 70),
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston'])[FLOOR(RANDOM() * 4) + 1]
FROM generate_series(0, 365) i;

INSERT INTO holidays (holiday_date, holiday_name)
VALUES 
    ('2024-01-01', 'New Year Day'),
    ('2024-07-04', 'Independence Day'),
    ('2024-12-25', 'Christmas Day'),
    ('2024-11-28', 'Thanksgiving'),
    ('2024-05-27', 'Memorial Day');

INSERT INTO suppliers (supplier_name, region)
SELECT 
    'Supplier_' || i,
    (ARRAY['North', 'South', 'East', 'West'])[FLOOR(RANDOM() * 4) + 1]
FROM generate_series(1, 50) i;

INSERT INTO deliveries (supplier_id, delivery_region, delivery_date)
SELECT 
    1 + FLOOR(RANDOM() * 50),
    (ARRAY['North', 'South', 'East', 'West'])[FLOOR(RANDOM() * 4) + 1],
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
FROM generate_series(1, 500) i;

INSERT INTO job_openings (department_id, job_title, status)
SELECT 
    1 + FLOOR(RANDOM() * 10),
    (ARRAY['Software Engineer', 'Data Analyst', 'Project Manager', 'Sales Rep'])[FLOOR(RANDOM() * 4) + 1],
    (ARRAY['Open', 'Closed', 'Filled'])[FLOOR(RANDOM() * 3) + 1]
FROM generate_series(1, 100) i;

INSERT INTO sales_deals (sales_rep_id, deal_close_date, deal_amount)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    1000 + (RANDOM() * 99000)
FROM generate_series(1, 2000) i;

INSERT INTO salaries (employee_id, year, salary)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    2020 + FLOOR(RANDOM() * 5),
    30000 + (RANDOM() * 120000)
FROM generate_series(1, 5000) i;

INSERT INTO dependents (employee_id, dependent_name, relationship)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    'Dependent_' || i,
    (ARRAY['Spouse', 'Child', 'Parent'])[FLOOR(RANDOM() * 3) + 1]
FROM generate_series(1, 2000) i;

INSERT INTO bonuses (employee_id, bonus_amount, bonus_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    1000 + (RANDOM() * 9000),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
FROM generate_series(1, 1000) i;

INSERT INTO work_logs (employee_id, work_date, hours_worked)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    6 + (RANDOM() * 4)
FROM generate_series(1, 20000) i;

INSERT INTO bookings (customer_id, start_date, end_date)
SELECT 
    1 + FLOOR(RANDOM() * 800),
    CURRENT_DATE + (RANDOM() * INTERVAL '90 days'),
    CURRENT_DATE + (RANDOM() * INTERVAL '90 days') + INTERVAL '3 days'
FROM generate_series(1, 1000) i;

INSERT INTO order_items (order_id, product_id, quantity)
SELECT 
    1 + FLOOR(RANDOM() * 3000),
    1 + FLOOR(RANDOM() * 500),
    1 + FLOOR(RANDOM() * 5)
FROM generate_series(1, 8000) i;

INSERT INTO employee_department_history (employee_id, department_id, start_date, end_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    1 + FLOOR(RANDOM() * 10),
    CURRENT_DATE - INTERVAL '5 years' + (RANDOM() * INTERVAL '5 years'),
    CASE WHEN RANDOM() > 0.7 THEN CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '2 years') END
FROM generate_series(1, 1500) i;

-- Update manager relationships (avoid circular references)
UPDATE employees SET manager_id = 
    CASE 
        WHEN id <= 100 THEN NULL  -- Top 100 are managers
        ELSE 1 + FLOOR(RANDOM() * 100)
    END
WHERE id > 100;

-- Update calculated fields
UPDATE orders SET 
    delivery_date = order_date + INTERVAL '3 days' + (RANDOM() * INTERVAL '7 days'),
    shipping_date = order_date + INTERVAL '1 day' + (RANDOM() * INTERVAL '3 days'),
    discount_amount = CASE WHEN discount_used THEN amount * 0.1 * RANDOM() ELSE 0 END;

UPDATE bookings SET 
    end_date = start_date + INTERVAL '1 day' + (RANDOM() * INTERVAL '14 days');

UPDATE shifts SET 
    end_time = start_time + INTERVAL '8 hours' + (RANDOM() * INTERVAL '4 hours');

UPDATE projects SET 
    completion_date = CASE WHEN status = 'Completed' THEN end_date ELSE NULL END;

UPDATE sales SET 
    sales_rep_id = employee_id;

-- Create indexes for better performance
CREATE INDEX idx_employees_department ON employees(department_id);
CREATE INDEX idx_employees_manager ON employees(manager_id);
CREATE INDEX idx_employees_salary ON employees(salary);
CREATE INDEX idx_employees_hire_date ON employees(hire_date);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_product ON sales(product_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_employee ON sales(employee_id);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_projects_department ON projects(department_id);
CREATE INDEX idx_project_assignments_employee ON project_assignments(employee_id);
CREATE INDEX idx_project_assignments_project ON project_assignments(project_id);
CREATE INDEX idx_salary_history_employee ON salary_history(employee_id);
CREATE INDEX idx_attendance_employee ON attendance(employee_id);
CREATE INDEX idx_attendance_date ON attendance(attendance_date);
CREATE INDEX idx_user_logins_user ON user_logins(user_id);
CREATE INDEX idx_user_logins_date ON user_logins(login_date);

-- Add some statistics
ANALYZE;,
    booking_amount DECIMAL(10,2) DEFAULT 100 + (RANDOM() * 900)
);

CREATE TABLE user_logins (
    login_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    login_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
);

CREATE TABLE invoices (
    invoice_id SERIAL PRIMARY KEY,
    invoice_number INTEGER UNIQUE,
    customer_id INTEGER REFERENCES customers(customer_id),
    invoice_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    amount DECIMAL(10,2) DEFAULT 100 + (RANDOM() * 900)
);

CREATE TABLE support_tickets (
    ticket_id SERIAL PRIMARY KEY,
    support_agent_id INTEGER REFERENCES employees(id),
    opened_date DATE DEFAULT CURRENT_DATE - INTERVAL '6 months' + (RANDOM() * INTERVAL '6 months'),
    closed_date DATE,
    status VARCHAR(50) DEFAULT (ARRAY['Open', 'Closed', 'In Progress'])[FLOOR(RANDOM() * 3) + 1]
);

CREATE TABLE timesheets (
    timesheet_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    timesheet_date DATE DEFAULT CURRENT_DATE - INTERVAL '3 months' + (RANDOM() * INTERVAL '3 months'),
    hours DECIMAL(4,2) DEFAULT 6 + (RANDOM() * 4)
);

CREATE TABLE product_reviews (
    review_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(product_id),
    customer_id INTEGER REFERENCES customers(customer_id),
    rating INTEGER DEFAULT 1 + FLOOR(RANDOM() * 5),
    review_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
);

CREATE TABLE product_prices (
    price_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(product_id),
    price DECIMAL(10,2) DEFAULT 10 + (RANDOM() * 90),
    effective_date DATE DEFAULT CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years')
);

CREATE TABLE returns (
    return_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    return_date DATE DEFAULT CURRENT_DATE - INTERVAL '6 months' + (RANDOM() * INTERVAL '6 months'),
    reason VARCHAR(200)
);

CREATE TABLE shipments (
    shipment_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    shipping_method VARCHAR(50) DEFAULT (ARRAY['Standard', 'Express', 'Overnight'])[FLOOR(RANDOM() * 3) + 1],
    delivery_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
);

CREATE TABLE weather_data (
    weather_id SERIAL PRIMARY KEY,
    weather_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    temperature DECIMAL(5,2) DEFAULT -10 + (RANDOM() * 50),
    location VARCHAR(100) DEFAULT (ARRAY['New York', 'London', 'Tokyo', 'Sydney'])[FLOOR(RANDOM() * 4) + 1]
);

CREATE TABLE holidays (
    holiday_id SERIAL PRIMARY KEY,
    holiday_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '2 years'),
    holiday_name VARCHAR(100) DEFAULT (ARRAY['Christmas', 'New Year', 'Independence Day', 'Thanksgiving'])[FLOOR(RANDOM() * 4) + 1]
);

-- Insert sample data
INSERT INTO departments (department_name, budget) 
SELECT 
    (ARRAY['Engineering', 'Sales', 'Marketing', 'HR', 'Finance', 'Operations', 'IT', 'Legal', 'R&D', 'Customer Service'])[FLOOR(RANDOM() * 10) + 1],
    50000 + (RANDOM() * 500000)
FROM generate_series(1, 20);

INSERT INTO employees (name, salary, department_id, job_title, gender, birth_date, hire_date)
SELECT 
    'Employee_' || i,
    30000 + (RANDOM() * 120000),
    1 + FLOOR(RANDOM() * 20),
    (ARRAY['Manager', 'Developer', 'Analyst', 'Specialist', 'Coordinator', 'Director', 'VP', 'Tester', 'Designer', 'Consultant'])[FLOOR(RANDOM() * 10) + 1],
    (ARRAY['M', 'F'])[FLOOR(RANDOM() * 2) + 1],
    CURRENT_DATE - INTERVAL '65 years' + (RANDOM() * INTERVAL '40 years'),
    CURRENT_DATE - INTERVAL '10 years' + (RANDOM() * INTERVAL '10 years')
FROM generate_series(1, 1000) i;

-- Update manager_id for employees (avoid circular references)
UPDATE employees SET manager_id = CASE 
    WHEN id <= 20 THEN NULL  -- Top 20 are managers
    ELSE 1 + FLOOR(RANDOM() * 20)  -- Others report to top 20
END;

INSERT INTO categories (category_name)
VALUES ('Electronics'), ('Clothing'), ('Books'), ('Home & Garden'), ('Sports'), 
       ('Automotive'), ('Health'), ('Beauty'), ('Toys'), ('Food');

INSERT INTO products (product_name, category_id, price, launch_date)
SELECT 
    'Product_' || i,
    1 + FLOOR(RANDOM() * 10),
    10 + (RANDOM() * 990),
    CURRENT_DATE - INTERVAL '5 years' + (RANDOM() * INTERVAL '5 years')
FROM generate_series(1, 500) i;

INSERT INTO customers (name, country, region, segment, registration_date)
SELECT 
    'Customer_' || i,
    (ARRAY['USA', 'Canada', 'UK', 'Germany', 'France', 'Japan', 'Australia', 'Brazil', 'India', 'China'])[FLOOR(RANDOM() * 10) + 1],
    (ARRAY['North', 'South', 'East', 'West', 'Central'])[FLOOR(RANDOM() * 5) + 1],
    (ARRAY['Enterprise', 'SMB', 'Consumer'])[FLOOR(RANDOM() * 3) + 1],
    CURRENT_DATE - INTERVAL '5 years' + (RANDOM() * INTERVAL '5 years')
FROM generate_series(1, 800) i;

INSERT INTO sales (customer_id, product_id, employee_id, sale_date, amount, quantity, category_id, purchase_date, sales_rep_id)
SELECT 
    1 + FLOOR(RANDOM() * 800),
    1 + FLOOR(RANDOM() * 500),
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    25 + (RANDOM() * 975),
    1 + FLOOR(RANDOM() * 10),
    1 + FLOOR(RANDOM() * 10),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    1 + FLOOR(RANDOM() * 100)
FROM generate_series(1, 5000) i;

INSERT INTO orders (customer_id, product_id, order_date, amount, delivery_date, shipping_date, discount_amount, order_value, category_id)
SELECT 
    1 + FLOOR(RANDOM() * 800),
    1 + FLOOR(RANDOM() * 500),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    25 + (RANDOM() * 975),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years') + INTERVAL '1 week',
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years') + INTERVAL '2 days',
    RANDOM() * 50,
    25 + (RANDOM() * 975),
    1 + FLOOR(RANDOM() * 10)
FROM generate_series(1, 3000) i;

INSERT INTO order_items (order_id, product_id, quantity)
SELECT 
    1 + FLOOR(RANDOM() * 3000),
    1 + FLOOR(RANDOM() * 500),
    1 + FLOOR(RANDOM() * 5)
FROM generate_series(1, 8000) i;

INSERT INTO projects (project_name, department_id, manager_id, start_date, end_date, budget, status, completion_date)
SELECT 
    'Project_' || i,
    1 + FLOOR(RANDOM() * 20),
    1 + FLOOR(RANDOM() * 20),
    CURRENT_DATE - INTERVAL '3 years' + (RANDOM() * INTERVAL '3 years'),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '2 years'),
    10000 + (RANDOM() * 490000),
    (ARRAY['Active', 'Completed', 'On Hold', 'Cancelled'])[FLOOR(RANDOM() * 4) + 1],
    CASE WHEN RANDOM() > 0.5 THEN CURRENT_DATE - INTERVAL '6 months' + (RANDOM() * INTERVAL '1 year') ELSE NULL END
FROM generate_series(1, 200) i;

INSERT INTO project_assignments (employee_id, project_id, start_date, end_date, hours_worked, assignment_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    1 + FLOOR(RANDOM() * 200),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    CASE WHEN RANDOM() > 0.3 THEN CURRENT_DATE - INTERVAL '6 months' + (RANDOM() * INTERVAL '1 year') ELSE NULL END,
    20 + (RANDOM() * 160),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years')
FROM generate_series(1, 2000) i;

-- Generate additional sample data for other tables
INSERT INTO salary_history (employee_id, old_salary, new_salary, change_date, raise_date, salary_before)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    30000 + (RANDOM() * 80000),
    35000 + (RANDOM() * 100000),
    CURRENT_DATE - INTERVAL '3 years' + (RANDOM() * INTERVAL '3 years'),
    CURRENT_DATE - INTERVAL '3 years' + (RANDOM() * INTERVAL '3 years'),
    30000 + (RANDOM() * 80000)
FROM generate_series(1, 800) i;

INSERT INTO promotions (employee_id, old_title, new_title, promotion_date, old_salary, new_salary)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    'Junior ' || (ARRAY['Developer', 'Analyst', 'Specialist'])[FLOOR(RANDOM() * 3) + 1],
    'Senior ' || (ARRAY['Developer', 'Analyst', 'Specialist'])[FLOOR(RANDOM() * 3) + 1],
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    40000 + (RANDOM() * 40000),
    50000 + (RANDOM() * 60000)
FROM generate_series(1, 300) i;

INSERT INTO bonuses (employee_id, bonus_amount, bonus_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    500 + (RANDOM() * 9500),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
FROM generate_series(1, 600) i;

INSERT INTO leaves (employee_id, leave_date, leave_type, days)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year'),
    (ARRAY['Vacation', 'Sick', 'Personal', 'Maternity', 'Paternity'])[FLOOR(RANDOM() * 5) + 1],
    1 + FLOOR(RANDOM() * 15)
FROM generate_series(1, 1500) i;

INSERT INTO dependents (employee_id, dependent_name, relationship, birth_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    'Dependent_' || i,
    (ARRAY['Spouse', 'Child', 'Parent'])[FLOOR(RANDOM() * 3) + 1],
    CURRENT_DATE - INTERVAL '60 years' + (RANDOM() * INTERVAL '50 years')
FROM generate_series(1, 800) i;

INSERT INTO employee_department_history (employee_id, department_id, start_date, end_date, change_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    1 + FLOOR(RANDOM() * 20),
    CURRENT_DATE - INTERVAL '5 years' + (RANDOM() * INTERVAL '4 years'),
    CASE WHEN RANDOM() > 0.7 THEN CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year') ELSE NULL END,
    CURRENT_DATE - INTERVAL '3 years' + (RANDOM() * INTERVAL '3 years')
FROM generate_series(1, 1200) i;

INSERT INTO attendance (employee_id, attendance_date, arrival_time, scheduled_start_time)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '1 year' + (i * INTERVAL '1 day'),
    '08:00:00'::TIME + (RANDOM() * INTERVAL '2 hours'),
    '09:00:00'::TIME
FROM generate_series(1, 300) i;

INSERT INTO user_logins (user_id, login_date)
SELECT 
    1 + FLOOR(RANDOM() * 1000),
    CURRENT_DATE - INTERVAL '1 year' + (RANDOM() * INTERVAL '1 year')
FROM generate_series(1, 10000) i;

INSERT INTO invoices (invoice_number, customer_id, invoice_date, amount)
SELECT 
    1000 + i + CASE WHEN RANDOM() > 0.95 THEN FLOOR(RANDOM() * 10) + 5 ELSE 0 END, -- Introduce some gaps
    1 + FLOOR(RANDOM() * 800),
    CURRENT_DATE - INTERVAL '2 years' + (RANDOM() * INTERVAL '2 years'),
    100 + (RANDOM() * 9900)
FROM generate_series(1, 2000) i;

-- Create indexes for better performance
CREATE INDEX idx_employees_dept ON employees(department_id);
CREATE INDEX idx_employees_manager ON employees(manager_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_product ON sales(product_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);

-- Update some calculated fields
UPDATE orders SET delivery_date = order_date + INTERVAL '3 days' + (RANDOM() * INTERVAL '10 days') WHERE delivery_date IS NULL;
UPDATE orders SET shipping_date = order_date + INTERVAL '1 day' + (RANDOM() * INTERVAL '3 days') WHERE shipping_date IS NULL;
UPDATE projects SET end_date = start_date + INTERVAL '6 months' + (RANDOM() * INTERVAL '18 months') WHERE end_date IS NULL;
UPDATE shifts SET end_time = start_time + INTERVAL '8 hours' WHERE end_time IS NULL;
UPDATE bookings SET end_date = start_date + INTERVAL '1 day' + (RANDOM() * INTERVAL '14 days') WHERE end_date IS NULL;

-- Update some foreign key references
UPDATE sales SET category_id = p.category_id FROM products p WHERE sales.product_id = p.product_id;
UPDATE sales SET purchase_date = sale_date WHERE purchase_date IS NULL;
UPDATE orders SET category_id = p.category_id FROM products p WHERE orders.product_id = p.product_id;

ANALYZE;