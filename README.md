# Student & College Management System (SCMS)

A relational, database-centric academic management prototype built with Python, Streamlit, and MySQL for university administration workflows.

![Python](https://img.shields.io/badge/Python-3.11%2B-blue?logo=python&logoColor=white)
![Streamlit](https://img.shields.io/badge/Streamlit-1.30%2B-red?logo=streamlit&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-orange?logo=mysql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Overview

The **Student & College Management System (SCMS)** is an academic management application designed to demonstrate the role of a relational database management system (DBMS) in running institutional operations. Rather than treating the database as passive storage, SCMS uses MySQL 8.0+ as the core engine for operational validation, referential integrity, transaction management, and analytical reporting.

The project was developed as a Database Management Systems Project-Based Learning (PBL) implementation at Woxsen University. It pairs a relational schema normalized to Third Normal Form (3NF) with a Python-based Streamlit interface, ensuring that business constraints are enforced by the database engine through triggers, stored procedures, and views.

---

## Problem Statement

Educational institutions handle deeply interdependent records across academic departments, degree programs, faculty appointments, course catalogs, section enrollments, session attendances, evaluation components, and tuition invoicing.

When institutional software delegates validation solely to application code, several structural challenges arise:
- Concurrent operations can bypass application checks, causing over-enrollment beyond classroom seating capacity.
- Accidental duplicate registrations and orphaned records degrade relational consistency.
- Financial dues and fee receipts easily fall out of synchronization.
- Complex academic transcripts and attendance aggregates require repeated, expensive manual calculations.

A relational DBMS provides the constraints, transactional locks (ACID), procedural execution, and event-driven triggers required to solve these challenges at the data tier.

---

## Objectives

- **Database-Centric Architecture:** Model academic administration directly inside MySQL using structured schemas, constraints, and referential rules.
- **Relational Normalization:** Design tables conforming to 3NF to eliminate redundant data attributes and prevent insert, update, and delete anomalies.
- **Automated Domain Rules:** Enforce critical constraints—such as section capacity ceilings, duplicate enrollment checks, and attendance date validity—via database triggers using `SIGNAL SQLSTATE '45000'`.
- **Atomic Transactional Operations:** Execute coordinated multi-table records (e.g., student admission with emergency guardian assignment) through transactional stored procedures with automatic rollback on exception.
- **Declarative Reporting via Views:** Deliver real-time analytical reporting for seat occupancy, attendance compliance, exam performance, and outstanding balances entirely through SQL views.
- **Simple, Usable Interface:** Provide an intuitive Streamlit interface to demonstrate relational queries, data entry, and trigger-fired rejections without multi-tier architectural overhead.

---

## Key Features

- **Academic Lifecycle Management:** Covers the progression from student admission and section allocation to attendance logging, examination scoring, and term fee clearance.
- **Database Trigger Enforcement:** Prevents invalid enrollments, blocks attendance on dropped registrations, guards against future dates, rejects overpayments, and automatically computes percentage grades.
- **Transactional Stored Procedures:** Encapsulates multi-table operations (`sp_admit_student`) inside explicit transactions that commit only when all foreign keys and constraints succeed.
- **Analytical Reporting Views:** Pre-compiled SQL views compute occupancy rates, attendance percentages, and fee balances on demand directly inside the database engine.
- **Role-Based Demonstration Access:** Authenticates Admin, Faculty, and Student personas using salted bcrypt password hashes stored in `user_account`.

---

## System Modules

| Module | Description |
| :--- | :--- |
| **Login** | Authenticates users against `user_account` with bcrypt hash verification and role assignment. |
| **Dashboard** | Displays live institutional KPIs (active students, faculty, courses, semester, financial dues) queried directly from MySQL. |
| **Students** | Manages student profiles, search filters, and admits new students atomically via `sp_admit_student`. |
| **Departments** | Catalogs academic departments and verifies foreign key deletion constraints. |
| **Programmes** | Manages degree curricula, duration years, and departmental affiliations. |
| **Faculty** | Maintains instructor directories, employee designations, and departmental appointments. |
| **Courses** | Maintains the institutional course syllabus, credit distributions, and academic levels. |
| **Semesters** | Configures academic calendar terms, dates, and toggles the currently active semester. |
| **Sections** | Defines classroom cohorts, seating capacities, and room allocations. |
| **Registration** | Enrolls students into course sections; actively enforced by enrollment triggers. |
| **Attendance** | Logs daily session attendance status (Present, Absent, Excused) with date validation. |
| **Examinations** | Records evaluation marks; triggers automatic letter grade and grade point calculation. |
| **Fees** | Issues fee invoices, logs payments, prevents overpayment, and tracks real-time settlement status. |
| **Reports** | Presents academic transcripts, attendance compliance, exam analytics, and financial ledgers via SQL views. |

---

## System Architecture

SCMS uses a streamlined three-tier architecture:

```
┌────────────────────────────────────────────────────────┐
│               Streamlit Presentation UI                │
│    (Dashboard, Forms, Metric Cards, Filtering, Tabs)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│               Python Application Layer                 │
│      (mysql-connector-python, bcrypt, python-dotenv)   │
│         Utils Layer: utils/db.py, utils/auth.py        │
└───────────────────────────┬────────────────────────────┘
                            │ Parameterized SQL Queries & CALLs
                            ▼
┌────────────────────────────────────────────────────────┐
│               MySQL 8.0+ Relational Engine             │
│  ├── 15 Relational Tables (InnoDB, PKs, FKs, CHECK)   │
│  ├── 5 Active Business Triggers (SIGNAL SQLSTATE 45000)│
│  ├── 2 Stored Procedures (Transactions & Rollbacks)    │
│  └── 8 SQL Analytical Views                            │
└────────────────────────────────────────────────────────┘
```

The application layer contains no business calculation or grading logic; it formats parameters and forwards statements to MySQL. All business constraints, triggers, and aggregations execute within the database.

---

## Database Design

The relational schema is implemented in InnoDB with `utf8mb4` encoding. It adheres to Third Normal Form (3NF):
- **1NF:** Every column contains atomic values; repeating groups and delimited arrays are avoided.
- **2NF:** All non-key attributes are fully dependent on the primary key, eliminating partial dependencies.
- **3NF:** Non-key attributes are directly dependent on the primary key, removing transitive dependencies (e.g., student records reference `programme_id`, avoiding duplication of department data).

Referential integrity is maintained with foreign keys. Parent deletions that would orphan critical operational data use `ON DELETE RESTRICT`, while tightly coupled child entities (such as guardian contacts belonging to a student) utilize `ON DELETE CASCADE`.

---

## Core Entities

The schema consists of 15 relational tables:

| Entity | Purpose |
| :--- | :--- |
| **`department`** | Academic divisions responsible for programs, faculty, and courses. |
| **`programme`** | Degree programs (B.Tech, BBA, B.Des) offered by departments. |
| **`faculty`** | Academic instructors and their departmental appointments. |
| **`course`** | Course catalog detailing subject codes, names, and academic credit units. |
| **`semester`** | Academic terms with verified start/end dates and active term flags. |
| **`section`** | Class cohorts associated with a course, semester, instructor, room, and capacity. |
| **`student`** | Enrolled student profiles, registration numbers, and academic statuses. |
| **`guardian`** | Emergency and parental contact records linked to individual students. |
| **`registration`** | Student course registrations linked to a specific semester and section. |
| **`attendance`** | Session attendance logs recording Present, Absent, or Excused status. |
| **`examination`** | Assessment evaluations recording assessment type, max marks, and marks obtained. |
| **`grade`** | Trigger-computed percentage, letter grade, and grade point records. |
| **`fee_bill`** | Fee invoices issued to students with billing amounts and due dates. |
| **`payment`** | Financial receipts recorded against specific fee bills. |
| **`user_account`** | User login accounts with bcrypt password hashes and assigned roles. |

---

## Relationships

- **Department $\rightarrow$ Programme / Faculty / Course:** One-to-Many relationships. A department oversees multiple programs, employs multiple faculty members, and administers multiple courses.
- **Programme $\rightarrow$ Student:** One-to-Many. Each student belongs to an academic degree program.
- **Student $\rightarrow$ Guardian:** One-to-Many with cascading delete. Guardian contacts are tied directly to student identity.
- **Course / Semester / Section $\rightarrow$ Registration:** Many-to-One. Registrations map a student to a specific course, semester, and section.
- **Registration $\rightarrow$ Attendance:** One-to-Many. Daily class session attendance is recorded against valid, active registrations.
- **Registration $\rightarrow$ Examination $\rightarrow$ Grade:** One-to-Many from registration to assessments; One-to-One between examination and grade.
- **Student $\rightarrow$ Fee Bill $\rightarrow$ Payment:** One-to-Many from student to bills; One-to-Many from bill to payment receipts.
- **User Account $\rightarrow$ Student / Faculty:** Optional foreign reference mapping credentials to academic records.

---

## DBMS Concepts Demonstrated

- **Primary & Foreign Keys:** Unambiguous row identification across all 15 tables with enforced relational integrity.
- **Constraints:** `CHECK` constraints (e.g., `start_date < end_date`, `marks_obtained <= max_marks`, `capacity > 0`), `UNIQUE` indexes, and `NOT NULL` constraints.
- **Indexing:** B-Tree indexes on frequently filtered foreign keys and lookup attributes (`reg_number`, `course_code`, `status`).
- **Data Normalization:** Systematic 3NF implementation eliminating update, insertion, and deletion anomalies.
- **CRUD Operations:** Parameterized queries handling insertions, updates, and conditional deletions safely.
- **Joins & Subqueries:** Multi-table `INNER JOIN` and `LEFT JOIN` structures combining records across up to five tables.
- **Aggregations:** Standard aggregate functions (`COUNT`, `SUM`, `AVG`, `MAX`, `MIN`) with `GROUP BY` and `HAVING` clauses.
- **Triggers:** Automated before-action validations and after-action updates.
- **Stored Procedures:** Server-side logic execution and ACID transactions.
- **Transaction Control:** Explicit `START TRANSACTION`, `COMMIT`, and `ROLLBACK` via SQL exception handlers.

---

## Database Automation

The system uses 5 database triggers to enforce institutional business rules:

1. **Registration Validation (`trg_registration_before_insert`)**
   - Verifies the student exists and has an `Active` academic status.
   - Prevents duplicate registrations for the same course in the same semester.
   - Queries current section enrollment and raises an error if capacity is reached.

2. **Attendance Validation (`trg_attendance_before_insert`)**
   - Verifies registration existence and blocks attendance for registrations marked `Dropped`.
   - Rejects future attendance dates (`attendance_date > CURRENT_DATE()`).

3. **Payment Validation (`trg_payment_before_insert`)**
   - Verifies that payment amounts are greater than zero.
   - Computes outstanding bill balances and rejects payments exceeding the remaining balance.

4. **Fee Status Recalculation (`trg_payment_after_insert` & `trg_payment_after_delete`)**
   - Re-evaluates total payments on the bill after payment insertions or deletions.
   - Automatically updates the bill status to `Paid`, `Partially Paid`, or `Unpaid`.

5. **Automated Grading Engine (`trg_exam_after_insert` & `trg_exam_after_update`)**
   - Calculates percentage from raw marks: `(marks_obtained / max_marks) * 100`.
   - Computes letter grade and grade point, then updates the `grade` table automatically.

---

## Grading Logic

Grades are evaluated by the database trigger using the following standard university scale:

| Percentage Range | Letter Grade | Grade Point | Evaluation |
| :--- | :--- | :--- | :--- |
| **90.00% – 100.00%** | **A+** | **10.0** | Outstanding |
| **80.00% – 89.99%** | **A** | **9.0** | Excellent |
| **70.00% – 79.99%** | **B+** | **8.0** | Very Good |
| **60.00% – 69.99%** | **B** | **7.0** | Good |
| **50.00% – 59.99%** | **C** | **6.0** | Average |
| **40.00% – 49.99%** | **D** | **5.0** | Pass |
| **Below 40.00%** | **F** | **0.0** | Fail |

---

## Database Views

The database includes 8 analytical views to support operational reporting:

| View Name | Purpose |
| :--- | :--- |
| **`v_section_occupancy`** | Displays section capacities, active enrollments, seats remaining, and occupancy percentages. |
| **`v_attendance_summary`** | Aggregates session totals, present counts, and attendance compliance percentages per course. |
| **`v_exam_details`** | Combines student details, course information, exam types, raw marks, and trigger-generated grades. |
| **`v_result_analysis`** | Generates statistical summaries (candidates, average, highest, lowest, pass rate) per course and exam type. |
| **`v_student_academic_history`** | Compiles complete transcript history across courses, credits, and assessments for each student. |
| **`v_fee_dues`** | Details individual invoices, total bill amounts, amounts paid, outstanding balances, and statuses. |
| **`v_student_dues`** | Summarizes financial standing per student, aggregating total billed against total collected. |
| **`v_department_summary`** | Provides workload overviews per department, totaling faculty, programs, courses, and students. |

---

## Stored Procedures

| Procedure | Purpose | Parameters & Mechanism |
| :--- | :--- | :--- |
| **`sp_admit_student`** | Atomically admits a student and creates an associated guardian record. | Accepts student and guardian parameters; executes inside `START TRANSACTION` with `DECLARE EXIT HANDLER FOR SQLEXCEPTION` and `ROLLBACK` on failure. Returns new student ID and status message. |
| **`sp_record_exam_result`** | Records evaluation marks within a transaction and returns the trigger-computed grade. | Accepts registration ID, exam type, date, max marks, and marks obtained. Triggers automatic grade computation and returns generated letter grade, grade point, and percentage via `OUT` parameters. |

---

## Authentication & Security

- **Bcrypt Password Hashing:** Passwords are never stored in plaintext; verification uses salted `bcrypt.checkpw()`.
- **Session State Management:** User authentication state and role assignments are tracked through Streamlit session state.
- **Parameterized SQL Execution:** All user inputs are passed via parameterized tuples to prevent SQL injection vulnerabilities.
- **Environment Isolation:** Database host, port, user credentials, and database names are loaded from `.env` via `python-dotenv`.
- **Database-Level Error Masking:** Database trigger `SIGNAL` exceptions are caught cleanly and presented as readable messages without exposing tracebacks.

---

## Technology Stack

| Technology | Purpose |
| :--- | :--- |
| **Python 3.11+** | Application runtime and backend programming language. |
| **Streamlit** | User interface framework for forms, tables, and metric displays. |
| **MySQL Server 8.0+** | Relational database engine, storage, constraints, triggers, and views. |
| **mysql-connector-python** | Official database driver supporting parameterized execution and stored procedures. |
| **bcrypt** | Password hashing library for salted cryptographic authentication. |
| **python-dotenv** | Environment configuration management for database credentials. |

---

## Project Structure

```
SCMS/
├── app.py                     # Main application entry point & authentication portal
├── database/
│   ├── schema.sql             # 15 Relational tables with constraints and indexes
│   ├── seed.sql               # Sample seed data for testing
│   ├── triggers.sql           # 5 Business logic triggers
│   ├── procedures.sql         # Stored procedures (sp_admit_student, sp_record_exam_result)
│   └── views.sql              # 8 Analytical reporting views
├── pages/
│   ├── dashboard.py           # Live database metrics & occupancy widgets
│   ├── students.py            # Student registry & sp_admit_student admission form
│   ├── departments.py         # Department catalog & integrity checks
│   ├── programmes.py          # Degree programs catalog
│   ├── faculty.py             # Faculty directory & appointments
│   ├── courses.py             # Course catalog & syllabus descriptions
│   ├── semesters.py           # Academic terms & active semester controls
│   ├── sections.py            # Section cohorts & v_section_occupancy view
│   ├── registration.py        # Course enrollment form & trigger test lab
│   ├── attendance.py          # Attendance logging & validation lab
│   ├── examinations.py        # Assessment grading & automatic grade lab
│   ├── fees.py                # Invoicing, payments, & overpayment check lab
│   └── reports.py             # Tabbed analytical viewer powered by SQL views
├── utils/
│   ├── db.py                  # Database connection, queries, procedures, & error handling
│   ├── auth.py                # Password hashing, user verification, & session state
│   └── helpers.py             # Header templates, metric cards, & status badges
├── .env.example               # Template for environment variables
├── .gitignore                 # Standard exclusions (environment files, bytecode)
├── requirements.txt           # Minimal Python dependency list
├── LICENSE                    # MIT License
└── README.md                  # Comprehensive repository documentation
```

---

## Installation

### 1. Prerequisites
Ensure you have **Python 3.11+** and **MySQL Server 8.0+** installed on your system.

### 2. Clone the Repository
```bash
git clone https://github.com/404Vardan/DBMS-PBL.git
cd DBMS-PBL
```

### 3. Create a Virtual Environment
```bash
python -m venv venv

# Windows
venv\Scripts\activate

# Linux / macOS
source venv/bin/activate
```

### 4. Install Dependencies
```bash
pip install -r requirements.txt
```

### 5. Configure Environment Variables
Copy `.env.example` to create `.env` and set your local MySQL connection parameters:
```bash
cp .env.example .env
```

Edit `.env`:
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=scms_db
```

### 6. Initialize Database Objects
Log in to MySQL and initialize the database by running the scripts in this exact order:

```bash
# 1. Create schema and relational tables
mysql -u root -p < database/schema.sql

# 2. Populate sample data
mysql -u root -p scms_db < database/seed.sql

# 3. Create business triggers
mysql -u root -p scms_db < database/triggers.sql

# 4. Create stored procedures
mysql -u root -p scms_db < database/procedures.sql

# 5. Create analytical views
mysql -u root -p scms_db < database/views.sql
```

*(On Windows PowerShell, run via cmd: `cmd /c "mysql -u root -p scms_db < database\schema.sql"`).*

### 7. Run the Application
```bash
streamlit run app.py
```
Open your browser and navigate to `http://localhost:8501`.

---

## Environment Variables

| Variable | Description | Default |
| :--- | :--- | :--- |
| `DB_HOST` | Host address of MySQL server | `localhost` |
| `DB_PORT` | Port number of MySQL server | `3306` |
| `DB_USER` | MySQL database username | `root` |
| `DB_PASSWORD` | MySQL password for the specified user | *(empty)* |
| `DB_NAME` | Database schema name | `scms_db` |

---

## Demo Credentials

The database seed script includes three test accounts pre-hashed with bcrypt:

| Role | Username | Password | Scope |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `admin123` | Full access to all academic, billing, and system operations |
| **Faculty** | `faculty` | `faculty123` | Grading, attendance management, course rosters |
| **Student** | `student` | `student123` | Student academic records, transcripts, fee invoices |

---

## Testing / Validation

The prototype includes test scenarios designed to verify database logic:

1. **Authentication:** Validates bcrypt credentials against `user_account`; rejects invalid passwords.
2. **Atomic Student Admission:** Admits a new student and creates a guardian record in a single transaction using `sp_admit_student`.
3. **Student Profile Lookup:** Confirms retrieval of personal and guardian records.
4. **Course Registration:** Enrolls an active student into a valid section and semester.
5. **Duplicate Registration Rejection:** Re-attempting enrollment in the same course and semester triggers `trg_registration_before_insert`.
6. **Section Capacity Rejection:** Registering beyond a section's seating capacity triggers the capacity ceiling check.
7. **Attendance Entry:** Logs session attendance for an enrolled student.
8. **Invalid Attendance Rejection:** Attempting to record attendance for a future date or a dropped registration triggers `trg_attendance_before_insert`.
9. **Exam Marks Submission:** Submits assessment marks through `sp_record_exam_result`.
10. **Automatic Grade Calculation:** Confirms that `trg_exam_after_insert` writes the correct letter grade and grade point to the `grade` table.
11. **Grade Recalculation:** Updates existing examination marks and verifies that `trg_exam_after_update` recalculates the grade.
12. **Fee Invoice Generation:** Creates a new fee invoice with an initial `Unpaid` status.
13. **Fee Payment Recording:** Submits a payment against an active invoice.
14. **Fee Status Update:** Confirms that `trg_payment_after_insert` transitions bill status to `Partially Paid` or `Paid`.
15. **Overpayment Rejection:** Attempting to pay more than the outstanding balance triggers `trg_payment_before_insert`.
16. **Analytical Views:** Verifies data rendering across all 8 SQL views in the Reports module.
17. **Session Termination:** Confirms clean session state clearing upon logout.

---

## Academic Relevance

SCMS demonstrates core relational database concepts within a practical application:
- Normalization up to 3NF ensures schema efficiency and prevents data anomalies.
- Triggers and stored procedures move critical business logic into the DBMS layer, ensuring data integrity regardless of external client implementations.
- SQL views illustrate how complex aggregations and multi-table joins can be abstracted into reusable, high-performance virtual tables.
- Transaction control (ACID) demonstrates how multi-step operations are kept atomic with rollback protection.

---

## Limitations

- **Academic Prototype:** Designed for local evaluation and DBMS viva demonstrations; not hardened for production deployments.
- **Single Currency:** Financial figures are formatted in Indian Rupee (INR / ₹) without multi-currency support.
- **Simulated Payment Processing:** Records transaction references without integration to external payment gateways.

---

## Future Scope

- **Audit Trails:** Implement shadow tables to log database updates, deletions, and user modifications via triggers.
- **Cumulative Performance Tracking:** Develop stored functions to calculate semester GPA and cumulative CGPA across transcripts.
- **Attendance Alerts:** Automated views identifying students falling below the mandatory 75% attendance threshold.
- **Role-Level Permissioning:** Fine-grained page access control directly aligned with database privileges.

---

## Author

**Vardan Desai**  
Roll No: `25WU0104029`  
B.Tech CSE – AIML (Section Rhinos)  
School of Technology, Woxsen University  

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
