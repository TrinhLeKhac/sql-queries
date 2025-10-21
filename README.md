# SQL Practice Questions Collection

A comprehensive collection of 300 SQL questions organized by difficulty level with a complete PostgreSQL database schema for practice and learning.

## 📁 Project Structure

```
sql/
├── README.md                           # This file
├── requirements.txt                    # Python dependencies
├── create_schema_and_data.sql         # Database schema and sample data
├── sql_questions_v2/
│   ├── easy_1-100.sql                 # Easy questions (1-100)
│   ├── medium_101-200.sql             # Medium questions (101-200)
│   └── hard_201-300.sql               # Hard questions (201-300)
└── sql_questions/                     # Original questions (archived)
    ├── 1-30.sql
    ├── 31-60.sql
    └── ... (10 files total)
```

## 🚀 Quick Start

### Prerequisites
- PostgreSQL 12+ installed
- Python 3.8+ (optional, for data analysis)

### 1. Database Setup

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE sql_practice;

# Connect to the database
\c sql_practice

# Run the schema script
\i create_schema_and_data.sql
```

### 2. Python Environment (Optional)

```bash
# Install dependencies
pip install -r requirements.txt

# Start Jupyter notebook for analysis
jupyter notebook
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

## 🎯 Usage Examples

### Running Individual Questions

```sql
-- Example: Find second highest salary
SELECT MAX(salary) AS second_highest_salary
FROM employees 
WHERE salary < (SELECT MAX(salary) FROM employees);
```

### Testing Multiple Questions

```sql
-- Load question file
\i sql_questions_v2/easy_1-100.sql

-- Execute specific questions by copying from the file
```

### Using Python for Analysis

```python
import psycopg2
import pandas as pd

# Connect to database
conn = psycopg2.connect(
    host="localhost",
    database="sql_practice",
    user="postgres",
    password="your_password"
)

# Run query
df = pd.read_sql("SELECT * FROM employees LIMIT 10", conn)
print(df)
```

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

## 📖 Learning Path

### Beginners (Start Here)
1. Review basic SQL syntax
2. Practice questions 1-50 (basic operations)
3. Learn JOINs with questions 51-100

### Intermediate
1. Master window functions (questions 101-150)
2. Practice CTEs and subqueries (questions 151-200)
3. Focus on date/time operations

### Advanced
1. Recursive queries (questions 201-250)
2. Performance optimization (questions 251-300)
3. Complex analytical functions

## 🛠️ Troubleshooting

### Common Issues

**Connection Error:**
```bash
# Check PostgreSQL service
sudo service postgresql status

# Restart if needed
sudo service postgresql restart
```

**Permission Denied:**
```sql
-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE sql_practice TO your_user;
```

**Missing Data:**
```sql
-- Verify data was loaded
SELECT COUNT(*) FROM employees;
-- Should return ~1000 rows
```

## 📝 Contributing

Feel free to:
- Add new questions
- Improve existing queries
- Report bugs or issues
- Suggest enhancements

## 📄 License

This project is for educational purposes. Feel free to use and modify for learning and teaching SQL.

## 🎓 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [SQL Tutorial](https://www.w3schools.com/sql/)
- [Advanced SQL Techniques](https://mode.com/sql-tutorial/)

---

**Happy Learning! 🚀**