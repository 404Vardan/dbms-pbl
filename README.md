# Student & College Management System (SCMS)
### Database Management Systems Project-Based Learning (DBMS-PBL) Prototype

An enterprise-grade, relational academic administrative ERP prototype engineered on **PostgreSQL (Supabase)** and **React + Vite**. The system guarantees business rule enforcement, referential integrity, and multi-tenant access control strictly within the database layer.

---

## 🏛️ 14 Core Domain Tables & Relationships

The relational architecture spans 14 normalized tables without soft mocks:

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
3. **`faculty`**: Academic staff profiles (`faculty_id`, `dept_id`, `employee_code`, `full_name`, `email`, `designation`)
4. **`course`**: Curriculum courses (`course_id`, `dept_id`, `course_code`, `course_name`, `credits`, `course_type`)
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

---

## 🛡️ Database-Enforced Business Rules

The database serves as the absolute integrity layer:
1. **Section Capacity**: Row-level locking trigger (`trg_registration_rules`) prevents registrations exceeding room capacity.
2. **Duplicate Registration Prevention**: Unique constraints and composite checks block re-enrolment in the same course or section.
3. **Marks Range Validation**: Check constraints enforce `marks BETWEEN 0 AND max_marks`.
4. **Attendance Validation**: Strict enumeration (`Present`, `Absent`, `Late`) within valid semester calendar bounds.
5. **Overpayment Rejection**: Trigger (`trg_payment_rules`) prevents cumulative payments from exceeding `amount_due`.
6. **Deterministic Grade Trigger**: Automatically computes grades (`A+` to `F`) and grade points (0.0 to 10.0) upon examination submission.
7. **Derived Bill Status**: Fee bills transition automatically between `Unpaid`, `Partially Paid`, and `Paid`.

---

## 👥 Role-Based Access Control (RLS)

- **Admin / Registrar**: Full read/write access to institutional structure, admissions, and reports.
- **Faculty**: Access to assigned section rosters, attendance registers, and candidate evaluation.
- **Student**: Read-only access restricted strictly to personal academic history, attendance, and fee statements.
- **Accounts**: Student directory lookup, tuition fee invoice generation, and receipt recording.

### Pre-Seeded Demo Accounts
Password for all demo accounts: `Demo@12345`
- **Registrar (Admin)**: `registrar@scms.edu.in`
- **Faculty (Prof. Priya)**: `priya.raghavan@scms.edu.in`
- **Accounts Officer**: `accounts@scms.edu.in`
- **Student (Meera Nair)**: `meera.nair@students.scms.edu.in`

---

## 🚀 Setup & Local Execution

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/404Vardan/dbms-pbl.git
cd dbms-pbl
npm install
```

### 2. Configure Supabase Database
1. Open your Supabase Dashboard: [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Go to **SQL Editor** and execute the scripts in the following order:
   - `database/schema.sql` (Creates 14 tables, constraints, indexes)
   - `database/triggers.sql` (Enforces business rules and transactional RPCs)
   - `database/security.sql` (Configures Row Level Security & permissions)
   - `database/reports.sql` (Compiles the 6 analytical views & dashboard RPC)
   - `database/seed.sql` (Populates realistic linked Indian university demo data)

### 3. Configure Environment Variables
Copy `.env.example` to `.env`:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 4. Start Development Server
```bash
npm run dev
```

---

## 📊 Analytical SQL Views
The system implements 6 enterprise analytical views accessible under the **Reports** module:
- `v_section_occupancy`: Real-time registration vs. capacity tracking.
- `v_attendance_summary`: Attendance percentage calculation and `<75%` shortage alerting.
- `v_result_analysis`: Aggregate performance, passing percentage, and grade distributions.
- `v_student_academic_history`: Transcripts with Mid-Term and End-Term evaluation.
- `v_fee_dues`: Tuition fee recovery, outstanding balances, and overdue days.
- `v_department_summary`: Department student counts and course capacities.
