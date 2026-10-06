# Student & College Management System (SCMS)
### Database Management Systems Project-Based Learning (DBMS-PBL) Prototype

An enterprise-grade, relational academic administrative ERP prototype engineered on **MySQL 8.0+**, **Node.js/Express**, and **React + Vite**. The system guarantees business rule enforcement, referential integrity, and multi-user access control strictly within the relational database layer.

---

## 🏛️ 14 Core Domain Tables & Relational Schema

The conceptual and relational design covers 14 normalized tables without soft mocks:

```
[ department ]
     ├──< [ programme ] ──< [ student ] ──< [ guardian ]
     ├──< [ faculty ]                       ├──< [ registration ] ──< [ attendance ]
     └──< [ course ] ──< [ section ] ───────┤                     └──< [ examination ] ──< [ grade ]
                              │             └──< [ fee_bill ] ──< [ payment ]
                         [ semester ] ──────────────┘
```

1. **`department`**: Academic faculties (`dept_id`, `dept_code`, `dept_name`, `office_email`)
2. **`programme`**: Degree programs (`programme_id`, `dept_id`, `programme_code`, `programme_name`, `duration_years`, `status`)
3. **`faculty`**: Academic staff profiles (`faculty_id`, `dept_id`, `employee_code`, `full_name`, `email`, `designation`, `status`)
4. **`course`**: Curriculum courses (`course_id`, `dept_id`, `course_code`, `course_name`, `credits`, `course_type`, `status`)
5. **`semester`**: Academic calendar terms (`semester_id`, `academic_year`, `term`, `start_date`, `end_date`)
6. **`section`**: Allocated lecture/lab cohorts (`section_id`, `course_id`, `faculty_id`, `semester_id`, `section_code`, `room_no`, `capacity`)
7. **`student`**: Admitted candidates (`student_id`, `programme_id`, `reg_no`, `full_name`, `dob`, `email`, `phone`, `admission_date`, `status`)
8. **`guardian`**: Linked parent contacts (`guardian_id`, `student_id`, `name`, `relation`, `phone`, `email`, `address`)
9. **`registration`**: Course enrolments (`registration_id`, `student_id`, `section_id`, `registered_on`, `status`)
10. **`attendance`**: Daily class sessions (`attendance_id`, `registration_id`, `attendance_date`, `status`)
11. **`examination`**: Evaluated assessments (`exam_id`, `registration_id`, `exam_type`, `exam_date`, `max_marks`, `marks`)
12. **`grade`**: Automated grading records (`grade_id`, `exam_id`, `grade_letter`, `grade_point`, `graded_on`)
13. **`fee_bill`**: Semester tuition invoices (`bill_id`, `student_id`, `semester_id`, `bill_date`, `amount_due`, `due_date`, `status`)
14. **`payment`**: Transaction ledger (`payment_id`, `bill_id`, `payment_date`, `amount_paid`, `payment_mode`, `reference_no`)

Additionally, authentication is managed via the **`user_account`** table (`user_id`, `email`, `password_hash`, `role`, `full_name`, `student_id`, `faculty_id`).

---

## 🛡️ MySQL Database Triggers & Integrity Rules

All critical business rules are enforced inside MySQL via triggers:
1. **Section Capacity Barrier (`trg_registration_before_insert`)**:
   Rejects student registration if the section occupancy has reached its room capacity limit (`capacity`).
2. **Duplicate Registration Prevention (`trg_registration_before_insert`)**:
   Unique constraints and trigger checks prevent a student from registering twice in the same section or enrolling in multiple sections of the same course within a semester.
3. **Attendance Validation (`trg_attendance_before_insert`)**:
   Restricts statuses to `Present`, `Absent`, or `Late`; rejects attendance for dropped registrations and dates outside the scheduled semester.
4. **Overpayment Rejection (`trg_payment_before_insert`)**:
   Prevents any payment where `amount_paid` exceeds the remaining balance (`amount_due - total_paid`).
5. **Fee Bill Status Synchronization (`trg_payment_after_insert`)**:
   Automatically updates the invoice status (`Unpaid` → `Partially Paid` → `Paid`) upon payment insertion.
6. **Deterministic Grade Trigger (`trg_examination_after_insert` & `trg_examination_after_update`)**:
   Automatically computes grades (`A+` to `F`) and grade points (`10.0` to `0.0`) based on marks:
   - 90–100 = `A+` (10.0) | 80–89.99 = `A` (9.0) | 70–79.99 = `B+` (8.0) | 60–69.99 = `B` (7.0)
   - 50–59.99 = `C` (6.0) | 40–49.99 = `D` (5.0) | < 40 = `F` (0.0)

---

## ⚙️ Stored Procedures & Multi-Step Transactions

Located in `database/procedures.sql`:
- **`sp_admit_student`**: Atomically inserts the student profile and guardian contact in a single transaction with automatic rollback on failure.
- **`sp_record_exam_result`**: Handles atomic exam score insertion or updates, automatically triggering grade derivation.

---

## 📊 Analytical MySQL Views

Located in `database/views.sql`:
- **`v_section_occupancy`**: Tracks registered count, capacity, remaining seats, and full flags.
- **`v_attendance_summary`**: Computes total sessions, attended sessions, percentage, and flags attendance shortage (< 75%).
- **`v_result_analysis`**: Calculates average, highest, lowest scores, and pass percentages per section.
- **`v_student_academic_history`**: Aggregates Mid-Term and End-Term evaluation and course credits.
- **`v_fee_dues`** & **`v_student_dues`**: Invoicing statements, payments received, balances, and overdue days.
- **`v_department_summary`**: Aggregate student counts and curriculum capacities per department.

---

## 👥 Demo User Accounts

All pre-seeded demo accounts use the password: `Demo@12345`
- **Registrar (Admin)**: `registrar@scms.edu.in`
- **Faculty (Prof. Priya)**: `priya.raghavan@scms.edu.in`
- **Accounts Officer**: `accounts@scms.edu.in`
- **Student (Meera Nair)**: `meera.nair@students.scms.edu.in`

---

## 🚀 Setup & Execution Guide

### 1. Database Setup (MySQL CLI or MySQL Workbench)
Run the SQL scripts in this exact order:
```sql
SOURCE database/schema.sql;
SOURCE database/triggers.sql;
SOURCE database/procedures.sql;
SOURCE database/views.sql;
SOURCE database/seed.sql;
```

Or via command line:
```bash
mysql -u root -p < database/schema.sql
mysql -u root -p < database/triggers.sql
mysql -u root -p < database/procedures.sql
mysql -u root -p < database/views.sql
mysql -u root -p < database/seed.sql
```

### 2. Configure Environment (`.env`)
Copy `.env.example` to `.env` and fill in your MySQL credentials:
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=scms_db
PORT=5000
JWT_SECRET=scms_jwt_secret_university_erp_2026
```

### 3. Install & Start Application
```bash
npm install
npm run start
```
- Express API server runs on `http://localhost:5000`
- React Vite frontend opens on `http://localhost:5173`
