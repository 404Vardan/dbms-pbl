# Student & College Management System

## Overview
The Student & College Management System (SCMS) is a database application developed as a Database Management Systems (DBMS) Project-Based Learning (PBL) project. It is designed to manage common academic and administrative operations in a college or university environment, including:
- Students and admissions
- Departments and degree programmes
- Courses and curriculum records
- Faculty members
- Academic semesters and cohorts (sections)
- Course registration
- Daily attendance tracking
- Examinations and marks entry
- Grade calculation
- Fee billing and payment collection
- Analytical reports

The application demonstrates how a relational database schema, database-level business rules, stored procedures, and SQL views can support a full-stack web application.

---

## Features
- **Student Records & Admissions**: Manage student profiles, contact details, and enrollments. Supports atomic creation of student and guardian details.
- **Guardian Information**: Linked guardian contact and relationship records.
- **Department & Programme Management**: Structure of academic departments and degree programmes with defined durations.
- **Course & Faculty Records**: Course catalogs with credit ratings and course types, along with faculty directory assignments.
- **Semester & Section Management**: Academic calendar tracking and section allocations with assigned lecture halls and seat capacities.
- **Course Registration**: Student enrollment into course sections with capacity checks.
- **Section Capacity Validation**: Prevents adding students to sections that have reached maximum capacity.
- **Duplicate Registration Prevention**: Blocks students from enrolling in multiple sections of the same course in the same semester.
- **Attendance Recording & Shortage Alerts**: Daily attendance logging (`Present`, `Absent`, `Late`) and calculation of attendance percentages, highlighting shortage (< 75%).
- **Examination & Marks Recording**: Recording marks for mid-term, end-term, internal, and practical exams.
- **Automatic Grade Calculation**: Database-driven assignment of letter grades (`A+` to `F`) and grade points (`10.0` to `0.0`) based on marks.
- **Fee Bill Generation**: Generation of semester tuition invoices with due dates.
- **Payment Recording**: Logging tuition fee payments across modes (`Cash`, `UPI`, `Card`, `NEFT`, `Cheque`, `DD`).
- **Overpayment Validation**: Rejects payments exceeding the remaining fee balance.
- **Analytical SQL Reports**: Pre-built relational reports summarizing section occupancy, attendance shortage, results analysis, student academic history, fee dues, and departmental statistics.
- **User Authentication**: Login system supporting role-based access for Admin, Faculty, Accounts, and Student users.

---

## Technology Stack

### Frontend
- **React 19**
- **Vite**
- **React Router** (client-side routing)
- **Vanilla CSS** (design system and layout)

### Backend
- **Python 3**
- **Flask** (REST API)
- **Flask-CORS** (cross-origin resource sharing)

### Database
- **MySQL 8.0+** (`InnoDB` storage engine)

### Database Connectivity
- **mysql-connector-python** (official MySQL driver for Python)

### Authentication
- **bcrypt** (password hashing verification)
- **PyJWT** (JSON Web Token generation and validation)

---

## Database Design

The database contains 15 relational tables (14 domain tables and 1 user account table):

1. **`department`**: Academic departments (`dept_id`, `dept_code`, `dept_name`, `office_email`)
2. **`programme`**: Degree curriculums under departments (`programme_id`, `dept_id`, `programme_code`, `programme_name`, `duration_years`, `status`)
3. **`faculty`**: Academic staff profiles (`faculty_id`, `dept_id`, `employee_code`, `full_name`, `email`, `designation`, `status`)
4. **`course`**: Subjects offered (`course_id`, `dept_id`, `course_code`, `course_name`, `credits`, `course_type`, `status`)
5. **`semester`**: Academic calendar terms (`semester_id`, `academic_year`, `term`, `start_date`, `end_date`)
6. **`section`**: Classroom and lab cohorts (`section_id`, `course_id`, `faculty_id`, `semester_id`, `section_code`, `room_no`, `capacity`)
7. **`student`**: Student personal and academic records (`student_id`, `programme_id`, `reg_no`, `full_name`, `dob`, `email`, `phone`, `admission_date`, `status`)
8. **`guardian`**: Parent/guardian contact records (`guardian_id`, `student_id`, `name`, `relation`, `phone`, `email`, `address`)
9. **`registration`**: Course enrollment records (`registration_id`, `student_id`, `section_id`, `registered_on`, `status`)
10. **`attendance`**: Class meeting attendance entries (`attendance_id`, `registration_id`, `attendance_date`, `status`)
11. **`examination`**: Evaluated assessments (`exam_id`, `registration_id`, `exam_type`, `exam_date`, `max_marks`, `marks`)
12. **`grade`**: Derived evaluation grades (`grade_id`, `exam_id`, `grade_letter`, `grade_point`, `graded_on`)
13. **`fee_bill`**: Semester tuition bills (`bill_id`, `student_id`, `semester_id`, `bill_date`, `amount_due`, `due_date`, `status`)
14. **`payment`**: Payment transaction ledger (`payment_id`, `bill_id`, `payment_date`, `amount_paid`, `payment_mode`, `reference_no`)
15. **`user_account`**: Application login credentials and role assignments (`user_id`, `email`, `password_hash`, `role`, `full_name`, `student_id`, `faculty_id`)

Primary keys, foreign keys, unique constraints, check constraints, database triggers, stored procedures, and views are defined across these entities.

---

## Database Features

### Constraints
- **Primary Keys (PK)**: Auto-increment integer identifiers on all primary entities.
- **Foreign Keys (FK)**: Relational links with `ON DELETE RESTRICT` (and `CASCADE` on grades) enforcing referential integrity across the academic hierarchy.
- **UNIQUE Constraints**: Enforced on registration numbers, email addresses, employee codes, course codes, department codes, semester terms, and section combinations.
- **NOT NULL Constraints**: Mandatory constraints on critical personal and academic data fields.
- **CHECK Constraints**: Validate positive credit hours, valid status values, birth date prior to admission date, exam score limits, and semester date boundaries.

### Triggers
Located in `database/triggers.sql`:
- **`trg_registration_before_insert`**:
  - Rejects registration if a section is already at maximum capacity.
  - Prevents duplicate registration in different sections of the same course during the same semester.
  - Ensures only students with `Active` status can register.
- **`trg_attendance_before_insert`**:
  - Rejects attendance logging for dropped course registrations.
  - Prevents attendance recording with future dates.
  - Verifies that the attendance date falls within the semester's start and end dates.
- **`trg_payment_before_insert`**:
  - Prevents payments where `amount_paid` exceeds the outstanding balance on the bill.
- **`trg_payment_after_insert`**:
  - Automatically updates the bill status (`Paid`, `Partially Paid`, or `Unpaid`) when a payment is inserted.
- **`trg_examination_after_insert` & `trg_examination_after_update`**:
  - Automatically computes the grade letter (`A+` to `F`) and grade point (`10.0` to `0.0`) based on percentage marks:
    - ≥ 90%: `A+` (10.0)
    - ≥ 80%: `A` (9.0)
    - ≥ 70%: `B+` (8.0)
    - ≥ 60%: `B` (7.0)
    - ≥ 50%: `C` (6.0)
    - ≥ 40%: `D` (5.0)
    - < 40%: `F` (0.0)

### Stored Procedures
Located in `database/procedures.sql`:
- **`sp_admit_student`**: Performs atomic student admission by inserting the student record and guardian record inside a single database transaction with automatic rollback if an error occurs.
- **`sp_record_exam_result`**: Atomically inserts or updates examination marks for a student registration inside a transaction, which fires the grading trigger.

### Views
Located in `database/views.sql`:
- **`v_section_occupancy`**: Computes total registered students, remaining seats, occupancy percentage, and full flags per section.
- **`v_attendance_summary`**: Calculates total classes, present, late, absent counts, attendance percentage, and identifies attendance shortage (< 75%).
- **`v_exam_details`**: Displays student marks, percentages, and grade letters alongside course and faculty details.
- **`v_result_analysis`**: Evaluates section-level academic performance including average, highest, lowest marks, and pass percentage.
- **`v_student_academic_history`**: Displays a student's full course record, midterm marks, endterm marks, final grade, and attendance percentage.
- **`v_fee_dues`**: Details tuition fee bills, amount paid, remaining balance, and overdue status.
- **`v_student_dues`**: Aggregates total billed, paid, and outstanding balances grouped by student.
- **`v_department_summary`**: Aggregates programmes, faculty, courses, and active students across departments.

---

## Application Modules
- **Dashboard**: High-level metrics for active students, programmes, sections, course enrollments, attendance shortage alerts, pending fee dues, and recent fee receipts.
- **Students**: Student directory with search, detailed profile pages, academic history, fee breakdown, and new student admission form.
- **Departments**: Listing of academic departments and degree programmes.
- **Courses**: Course catalog with course codes, names, credits, and course types, with course creation.
- **Faculty**: Directory of teaching faculty with designations, employee codes, and departments.
- **Semesters**: Academic calendar terms with start and end dates.
- **Sections**: Course section allocations with designated faculty, classroom rooms, and capacities.
- **Registration**: Enrolling active students into course sections with real-time capacity and duplicate checks.
- **Attendance**: Daily attendance roster by course section, status marking (`Present`, `Absent`, `Late`), and attendance summary.
- **Examinations**: Exam score entry and update interface by course section with instant grade calculation.
- **Fees**: Tuition fee billing, student payment receipts, balance tracking, and overpayment prevention.
- **Reports**: Tabbed interface displaying the 8 MySQL analytical views.

---

## Project Structure

```
dbms-pbl/
├── database/
│   ├── schema.sql           # Database schema (15 tables, constraints, indexes)
│   ├── triggers.sql         # Business rule triggers (capacity, attendance, grading, fees)
│   ├── procedures.sql       # Transactional stored procedures (admit student, record marks)
│   ├── views.sql            # 8 analytical SQL views
│   └── seed.sql             # Sample data for testing
├── server/
│   ├── app.py               # Flask application entry point with CORS and route blueprints
│   ├── db.py                # MySQL connection helper and JSON sanitization
│   ├── requirements.txt     # Python backend dependencies
│   └── routes/
│       ├── academics.py     # Routes for departments, courses, faculty, semesters, sections
│       ├── attendance.py    # Routes for section attendance rosters and save
│       ├── auth.py          # Route for user login and JWT generation
│       ├── dashboard.py     # Route for live metrics
│       ├── examinations.py  # Routes for exam marks and stored procedure call
│       ├── fees.py          # Routes for fee bills, payment ledger, and receipts
│       ├── registration.py  # Routes for section enrollments
│       ├── reports.py       # Routes querying the SQL views
│       └── students.py      # Routes for student CRUD and admission procedure
├── src/
│   ├── components/
│   │   └── Layout.jsx       # Navigation sidebar and header layout
│   ├── context/
│   │   └── AuthContext.jsx  # Authentication state provider
│   ├── lib/
│   │   ├── api.js           # API request helpers
│   │   └── errors.js        # Database error message formatting
│   ├── pages/
│   │   ├── Attendance.jsx
│   │   ├── Courses.jsx
│   │   ├── Dashboard.jsx
│   │   ├── Departments.jsx
│   │   ├── Examinations.jsx
│   │   ├── Faculty.jsx
│   │   ├── Fees.jsx
│   │   ├── Login.jsx
│   │   ├── Registration.jsx
│   │   ├── Reports.jsx
│   │   ├── Sections.jsx
│   │   ├── Semesters.jsx
│   │   ├── StudentDetails.jsx
│   │   └── Students.jsx
│   ├── App.jsx              # Main routing and ProtectedRoute definition
│   ├── index.css            # Stylesheet
│   └── main.jsx             # React DOM entry point
├── .env.example             # Example environment variables template
├── .gitignore
├── index.html
├── package.json             # Frontend dependencies and run scripts
├── README.md
└── vite.config.js           # Vite configuration with /api backend proxy
```

---

## Setup

### Prerequisites
- Node.js (v18 or higher) and npm
- Python (v3.10 or higher) and pip
- MySQL Server (v8.0 or higher) running locally on port 3306

### 1. Clone Repository
```bash
git clone https://github.com/404Vardan/dbms-pbl.git
cd dbms-pbl
```

### 2. Set Up the MySQL Database
Execute the SQL files in order using the MySQL CLI or MySQL Workbench:

```bash
mysql -u root -p < database/schema.sql
mysql -u root -p < database/triggers.sql
mysql -u root -p < database/procedures.sql
mysql -u root -p < database/views.sql
mysql -u root -p < database/seed.sql
```

*(Or in MySQL Workbench / CLI: run `SOURCE database/schema.sql;`, `SOURCE database/triggers.sql;`, `SOURCE database/procedures.sql;`, `SOURCE database/views.sql;`, and `SOURCE database/seed.sql;` in that sequence).*

### 3. Configure Environment Variables
Create a `.env` file in the project root (using `.env.example` as reference):

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=scms_db

PORT=5000
JWT_SECRET=scms_jwt_secret_university_erp_2026
```

### 4. Install Python Dependencies
```bash
pip install -r server/requirements.txt
```

### 5. Install Frontend Dependencies
```bash
npm install
```

### 6. Start the Application
To run both backend and frontend concurrently:
```bash
npm start
```

Or run them in separate terminals:
- **Terminal 1 (Flask API)**:
  ```bash
  python server/app.py
  ```
- **Terminal 2 (React Frontend)**:
  ```bash
  npm run dev
  ```

Open [http://localhost:5173](http://localhost:5173) in your browser.

---

## Demo Login

The following user accounts are pre-seeded in `database/seed.sql`:

| Role | Email | Password | Description |
| :--- | :--- | :--- | :--- |
| **Admin** | `registrar@scms.edu.in` | `Demo@12345` | Full administrative access |
| **Faculty** | `priya.raghavan@scms.edu.in` | `Demo@12345` | Faculty member view |
| **Accounts** | `accounts@scms.edu.in` | `Demo@12345` | Fee management and receipts |
| **Student** | `meera.nair@students.scms.edu.in` | `Demo@12345` | Student profile view |

---

## Testing

The application demonstrates and tests the following database rules and constraints:
- **Duplicate Registration**: Attempting to enroll a student into another section of the same course in the same semester triggers an error (`SQLSTATE 45000`).
- **Section Capacity**: Registering a student into a section that is already at full capacity is blocked by the trigger.
- **Invalid Attendance**: Submitting an attendance entry with a future date or outside the semester schedule is rejected.
- **Automatic Grade Derivation**: Entering exam marks (e.g., 92.5 / 100) automatically inserts or updates a record in the `grade` table with `A+` and `10.0`.
- **Fee Overpayment Prevention**: Attempting to pay an amount greater than the remaining balance on an invoice is blocked with an error.
- **Student Admission**: Executing `sp_admit_student` atomically inserts both student and guardian records within a single transaction.

---

## Limitations
- **Academic PBL Scope**: The project is designed as an educational demonstration of relational database concepts, not as a commercial production ERP.
- **Local Database Dependency**: Requires a locally configured MySQL instance with the appropriate credentials.
- **Demonstration Authentication**: Role-based routing is handled on the client and token level for demonstration purposes.

---

## Future Scope
- **Granular Server-Side Authorization**: Enforcing strict role permissions middleware across all API routes.
- **Cloud Database Hosting**: Hosting MySQL on a managed cloud service.
- **Additional Analytical Reports**: Exporting reports to PDF and CSV formats.
- **Notification System**: Automated email or SMS alerts for attendance shortages and fee due dates.

---

## Conclusion
The Student & College Management System demonstrates how a relational database management system (MySQL) can model, constrain, and query complex institutional data. By combining database-level integrity constraints, business triggers, stored procedures, and analytical views with a Python/Flask API and a React frontend, the project provides a practical implementation of core DBMS concepts in an academic context.
