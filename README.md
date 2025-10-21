# SQL Practice Questions Collection

A comprehensive collection of 300 SQL questions organized by difficulty level with a complete PostgreSQL database schema for practice and learning.

## 📁 Project Structure

```
sql/
├── README.md                           # This file
├── requirements.txt                    # Python dependencies
├── .gitignore                          # Git ignore file
├── create_schema_and_data.sql         # Database schema and sample data
├── create_questions_table.sql         # SQL questions table creation
├── insert_medium_questions.sql        # Medium questions data insertion
├── insert_hard_questions.sql          # Hard questions data insertion
├── sql_questions_v2/
│   ├── easy_1-100.sql                 # Easy questions (1-100)
│   ├── medium_101-200.sql             # Medium questions (101-200)
│   └── hard_201-300.sql               # Hard questions (201-300)
└── sql_questions/                     # Original questions (archived)
    ├── 1-30.sql
    ├── 31-60.sql
    ├── 61-90.sql
    ├── 91-120.sql
    ├── 121-150.sql
    ├── 151-180.sql
    ├── 181-210.sql
    ├── 211-240.sql
    ├── 241-270.sql
    └── 271-300.sql
```

## 🚀 Quick Start

### Prerequisites
- PostgreSQL 12+ installed
- Python 3.8+ (optional, for data analysis)

### 1. Database Setup

#### Step 1: Install PostgreSQL

**macOS (using Homebrew):**
```bash
brew install postgresql
brew services start postgresql
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Windows:**
- Download from [PostgreSQL official website](https://www.postgresql.org/download/windows/)
- Run installer and follow setup wizard

#### Step 2: Create Database and User

**Option A: Using Command Line**
```bash
# Connect as postgres superuser
sudo -u postgres psql

# Or on Windows/macOS:
psql -U postgres
```

```sql
-- Create database
CREATE DATABASE sql_practice;

-- Create user (optional but recommended)
CREATE USER sql_learner WITH PASSWORD 'your_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE sql_practice TO sql_learner;

-- Exit
\q
```

**Option B: Using pgAdmin (GUI Interface)**

If you have PostgreSQL installed with pgAdmin:

1. **Open pgAdmin** (usually available in Applications or Start Menu)
2. **Connect to PostgreSQL Server**:
   - Right-click "Servers" → "Create" → "Server"
   - Name: `Local PostgreSQL`
   - Host: `localhost`, Port: `5432`
   - Username: `postgres`, Password: (your postgres password)

3. **Create Database**:
   - Right-click "Databases" → "Create" → "Database"
   - Database name: `sql_practice`
   - Click "Save"

4. **Create User (Optional)**:
   - Right-click "Login/Group Roles" → "Create" → "Login/Group Role"
   - General tab: Name: `sql_learner`
   - Definition tab: Password: `your_password`
   - Privileges tab: Check "Can login?"
   - Click "Save"

5. **Grant Permissions**:
   - Right-click `sql_practice` database → "Properties"
   - Security tab → Add `sql_learner` with all privileges

#### Step 3: Load Schema and Data

**Option A: Using Command Line**
```bash
# Connect to the database
psql -U sql_learner -d sql_practice
# Or: psql -U postgres -d sql_practice

# Run the schema script (this will take 2-3 minutes)
\i create_schema_and_data.sql

# Verify installation
SELECT COUNT(*) FROM employees; -- Should return ~1000
SELECT COUNT(*) FROM sales;     -- Should return ~5000
```

**Option B: Using pgAdmin (GUI Interface)**

1. **Open Query Tool**:
   - In pgAdmin, expand "Servers" → "Local PostgreSQL" → "Databases"
   - Right-click `sql_practice` → "Query Tool"

2. **Load and Execute Script**:
   - Click "Open File" button (folder icon)
   - Navigate to and select `create_schema_and_data.sql`
   - Click "Execute" button (play icon) - this will take 2-3 minutes
   - Wait for "Query returned successfully" message

3. **Verify Installation**:
   ```sql
   SELECT COUNT(*) FROM employees; -- Should return ~1000
   SELECT COUNT(*) FROM sales;     -- Should return ~5000
   ```

#### Step 4: Test Connection

```sql
-- List all tables
\dt

-- Check sample data
SELECT d.department_name, COUNT(e.id) as employee_count
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY employee_count DESC;
```

### 2. Python Environment (Optional)

#### Step 1: Create Virtual Environment

```bash
# Create virtual environment
python -m venv sql_env

# Activate virtual environment
# On macOS/Linux:
source sql_env/bin/activate
# On Windows:
sql_env\Scripts\activate
```

#### Step 2: Install Dependencies

```bash
# Install all required packages
pip install -r requirements.txt

# Verify installation
python -c "import psycopg2, pandas, sqlalchemy; print('All packages installed successfully')"
```

#### Step 3: Test Database Connection

```python
# Create test_connection.py
import psycopg2
import pandas as pd

try:
    conn = psycopg2.connect(
        host="localhost",
        database="sql_practice",
        user="sql_learner",  # or "postgres"
        password="your_password"
    )
    
    df = pd.read_sql("SELECT COUNT(*) as total_employees FROM employees", conn)
    print(f"✅ Connection successful! Total employees: {df.iloc[0]['total_employees']}")
    
    conn.close()
except Exception as e:
    print(f"❌ Connection failed: {e}")
```

#### Step 4: Start Jupyter Notebook

```bash
# Start Jupyter notebook
jupyter notebook

# Or Jupyter Lab (more modern interface)
jupyter lab
```

## 📊 Database Schema

The database includes 25+ tables with realistic sample data:

### Core Tables
- **employees** (1,000 records) - Employee information with salaries, departments, managers
- **departments** (20 records) - Department details with budgets
- **customers** (500 records) - Customer information across regions
- **products** (200 records) - Product catalog with categories
- **sales** (5,000 records) - Sales transactions
- **orders** (3,000 records) - Order history with shipping details

### Supporting Tables
- **projects** & **project_assignments** - Project management data
- **salary_history** & **promotions** - Employee career progression
- **attendance** & **work_logs** - Time tracking
- **leaves** & **dependents** - HR data
- **bookings** & **shifts** - Scheduling data

## 📚 Question Categories

### Easy (1-100)
- Basic SELECT statements
- WHERE clauses and filtering
- GROUP BY and aggregations
- Simple JOINs
- Basic date functions

### Medium (101-200)
- Window functions (ROW_NUMBER, RANK, LAG/LEAD)
- Common Table Expressions (CTEs)
- Advanced JOINs and subqueries
- Date/time calculations
- Conditional aggregations

### Hard (201-300)
- Recursive CTEs
- Complex window functions
- Advanced analytics
- Performance optimization
- Data modeling concepts

## 🔍 Key Features

### Realistic Data
- **100,000+** total records across all tables
- Proper foreign key relationships
- Realistic date ranges and distributions
- Industry-standard naming conventions

### Educational Progression
- Questions build from basic to advanced concepts
- Each difficulty level introduces new SQL features
- Comprehensive coverage of PostgreSQL functions

### Interview Preparation
- Common SQL interview questions
- Real-world scenarios and use cases
- Performance optimization examples

## 🎓 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [SQL Tutorial](https://www.w3schools.com/sql/)
- [Advanced SQL Techniques](https://mode.com/sql-tutorial/)

---

**Happy Learning! 🚀**