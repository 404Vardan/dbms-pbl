# Database Rules: Triggers, Stored Procedures & Views

A primary objective of this DBMS PBL project is demonstrating that **critical institutional rules belong inside the database engine**, rather than relying solely on client-side or application-tier checks that could be bypassed.

This document details the triggers, stored procedures, and analytical views defined in MySQL 8.0+.

---

## 1. Database Triggers

The database implements 6 trigger definitions enforcing validation invariants and automated data propagation.

### Summary Table

| Trigger Name | Event | Target Table | Business Rule Enforced |
|---|---|---|---|
| `trg_registration_before_insert` | `BEFORE INSERT` | `registration` | Enforces student active status, prevents duplicate course enrollments in the same term, and halts enrollment if section capacity is exhausted. |
| `trg_attendance_before_insert` | `BEFORE INSERT` | `attendance` | Rejects attendance for dropped registrations, prevents future dates, and enforces semester date boundaries. |
| `trg_payment_before_insert` | `BEFORE INSERT` | `payment` | Prevents overpayment exceeding the remaining balance on a fee bill. |
| `trg_payment_after_insert` | `AFTER INSERT` | `payment` | Automatically updates fee bill status to `Paid`, `Partially Paid`, or `Unpaid`. |
| `trg_examination_after_insert` | `AFTER INSERT` | `examination` | Automatically computes percentage, assigns grade letter (`A+` to `F`), and awards grade point (`10.0` to `0.0`). |
| `trg_examination_after_update` | `AFTER UPDATE` | `examination` | Recomputes or removes grades when examination marks are updated or cleared. |

---

### Detailed Trigger Specifications

#### 1. `trg_registration_before_insert`
- **File**: `database/triggers.sql`
- **Mechanism**:
  1. Queries the `student` table to verify `status = 'Active'`. If inactive, raises `SQLSTATE '45000'`.
  2. Identifies the `course_id` and `semester_id` of the target section.
  3. Queries existing non-dropped registrations for the student to ensure they are not already enrolled in another section of the same course in that semester.
  4. Counts current active registrations in the target section and compares against `capacity`. If `registered >= capacity`, raises `SQLSTATE '45000'`.

```sql
DELIMITER $$
CREATE TRIGGER trg_registration_before_insert
BEFORE INSERT ON registration
FOR EACH ROW
BEGIN
    DECLARE v_capacity INT;
    DECLARE v_current_taken INT;
    DECLARE v_course_id INT;
    DECLARE v_semester_id INT;
    DECLARE v_student_status VARCHAR(15);
    DECLARE v_duplicate_in_course INT;

    SELECT status INTO v_student_status FROM student WHERE student_id = NEW.student_id;
    IF v_student_status != 'Active' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration Blocked: Only Active students can be enrolled in sections.';
    END IF;

    SELECT capacity, course_id, semester_id 
    INTO v_capacity, v_course_id, v_semester_id
    FROM section 
    WHERE section_id = NEW.section_id;

    SELECT COUNT(*) INTO v_duplicate_in_course
    FROM registration r
    JOIN section s ON s.section_id = r.section_id
    WHERE r.student_id = NEW.student_id
      AND s.course_id = v_course_id
      AND s.semester_id = v_semester_id
      AND r.status != 'Dropped';

    IF v_duplicate_in_course > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration Failed: Student is already registered in another section for this course in the same semester.';
    END IF;

    SELECT COUNT(*) INTO v_current_taken
    FROM registration
    WHERE section_id = NEW.section_id
      AND status != 'Dropped';

    IF v_current_taken >= v_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration Blocked: This section has reached maximum student capacity.';
    END IF;
END$$
DELIMITER ;
```

---

#### 2. `trg_attendance_before_insert`
- **File**: `database/triggers.sql`
- **Mechanism**:
  1. Verifies that the registration status is not `'Dropped'`.
  2. Ensures `NEW.attendance_date <= CURRENT_DATE()`. Future dates are blocked.
  3. Verifies that `attendance_date` falls between the semester's `start_date` and `end_date`.

```sql
DELIMITER $$
CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE v_reg_status VARCHAR(15);
    DECLARE v_sem_start DATE;
    DECLARE v_sem_end DATE;

    SELECT r.status, sm.start_date, sm.end_date
    INTO v_reg_status, v_sem_start, v_sem_end
    FROM registration r
    JOIN section s ON s.section_id = r.section_id
    JOIN semester sm ON sm.semester_id = s.semester_id
    WHERE r.registration_id = NEW.registration_id;

    IF v_reg_status = 'Dropped' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Attendance Rejected: Cannot mark attendance for a dropped registration.';
    END IF;

    IF NEW.attendance_date > CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Date: Attendance cannot be recorded for a future date.';
    END IF;

    IF NEW.attendance_date < v_sem_start OR NEW.attendance_date > v_sem_end THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Date: Attendance date falls outside the scheduled semester period.';
    END IF;
END$$
DELIMITER ;
```

---

#### 3. `trg_payment_before_insert` & `trg_payment_after_insert`
- **File**: `database/triggers.sql`
- **Mechanism**:
  - `BEFORE INSERT`: Computes the remaining balance (`amount_due - SUM(amount_paid)`). If `NEW.amount_paid > remaining_balance`, aborts with an overpayment error.
  - `AFTER INSERT`: Evaluates cumulative payments against `amount_due` and synchronizes `fee_bill.status` (`Paid`, `Partially Paid`, or `Unpaid`).

```sql
DELIMITER $$
CREATE TRIGGER trg_payment_before_insert
BEFORE INSERT ON payment
FOR EACH ROW
BEGIN
    DECLARE v_amount_due DECIMAL(10,2);
    DECLARE v_total_paid DECIMAL(10,2);
    DECLARE v_remaining DECIMAL(10,2);

    SELECT amount_due INTO v_amount_due FROM fee_bill WHERE bill_id = NEW.bill_id;
    SELECT COALESCE(SUM(amount_paid), 0) INTO v_total_paid FROM payment WHERE bill_id = NEW.bill_id;
    SET v_remaining = v_amount_due - v_total_paid;

    IF NEW.amount_paid > v_remaining THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment Rejected: Total payment cannot exceed the remaining balance due.';
    END IF;
END$$

CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    DECLARE v_amount_due DECIMAL(10,2);
    DECLARE v_total_paid DECIMAL(10,2);

    SELECT amount_due INTO v_amount_due FROM fee_bill WHERE bill_id = NEW.bill_id;
    SELECT COALESCE(SUM(amount_paid), 0) INTO v_total_paid FROM payment WHERE bill_id = NEW.bill_id;

    IF v_total_paid >= v_amount_due THEN
        UPDATE fee_bill SET status = 'Paid' WHERE bill_id = NEW.bill_id;
    ELSEIF v_total_paid > 0 THEN
        UPDATE fee_bill SET status = 'Partially Paid' WHERE bill_id = NEW.bill_id;
    ELSE
        UPDATE fee_bill SET status = 'Unpaid' WHERE bill_id = NEW.bill_id;
    END IF;
END$$
DELIMITER ;
```

---

#### 4. `trg_examination_after_insert` & `trg_examination_after_update`
- **File**: `database/triggers.sql`
- **Mechanism**:
  - Automatically calculates percentage score: `pct = (marks * 100.0) / max_marks`.
  - Determines letter grade and 10-point scale:
    - `pct >= 90.0` -> `A+` (10.0)
    - `pct >= 80.0` -> `A`  (9.0)
    - `pct >= 70.0` -> `B+` (8.0)
    - `pct >= 60.0` -> `B`  (7.0)
    - `pct >= 50.0` -> `C`  (6.0)
    - `pct >= 40.0` -> `D`  (5.0)
    - `pct < 40.0`  -> `F`  (0.0)
  - Upserts into `grade` table (`ON DUPLICATE KEY UPDATE`).

---

## 2. Stored Procedures

Located in `database/procedures.sql`. Both procedures wrap multi-statement workflows within explicit transactions and employ `DECLARE EXIT HANDLER FOR SQLEXCEPTION` with `ROLLBACK; RESIGNAL;` for safety.

### 1. `sp_admit_student`
Atomically provisions a student record and associated guardian record inside an ACID transaction.

- **Parameters**:
  - `IN p_programme_id INT`
  - `IN p_reg_no VARCHAR(20)`
  - `IN p_full_name VARCHAR(100)`
  - `IN p_dob DATE`
  - `IN p_email VARCHAR(120)`
  - `IN p_phone VARCHAR(15)`
  - `IN p_admission_date DATE`
  - `IN p_guardian_name VARCHAR(100)`
  - `IN p_guardian_relation VARCHAR(20)`
  - `IN p_guardian_phone VARCHAR(15)`
  - `IN p_guardian_email VARCHAR(120)`
  - `IN p_guardian_address TEXT`
  - `OUT p_student_id INT`

```sql
DELIMITER $$
CREATE PROCEDURE sp_admit_student(
    IN p_programme_id INT,
    IN p_reg_no VARCHAR(20),
    IN p_full_name VARCHAR(100),
    IN p_dob DATE,
    IN p_email VARCHAR(120),
    IN p_phone VARCHAR(15),
    IN p_admission_date DATE,
    IN p_guardian_name VARCHAR(100),
    IN p_guardian_relation VARCHAR(20),
    IN p_guardian_phone VARCHAR(15),
    IN p_guardian_email VARCHAR(120),
    IN p_guardian_address TEXT,
    OUT p_student_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO student (programme_id, reg_no, full_name, dob, email, phone, admission_date, status)
    VALUES (p_programme_id, UPPER(TRIM(p_reg_no)), TRIM(p_full_name), p_dob, LOWER(TRIM(p_email)), TRIM(p_phone), COALESCE(p_admission_date, CURRENT_DATE()), 'Active');

    SET p_student_id = LAST_INSERT_ID();

    IF p_guardian_name IS NOT NULL AND TRIM(p_guardian_name) != '' THEN
        INSERT INTO guardian (student_id, name, relation, phone, email, address)
        VALUES (p_student_id, TRIM(p_guardian_name), p_guardian_relation, TRIM(p_guardian_phone), NULLIF(TRIM(p_guardian_email), ''), NULLIF(TRIM(p_guardian_address), ''));
    END IF;

    COMMIT;
END$$
DELIMITER ;
```

---

### 2. `sp_record_exam_result`
Atomically records examination marks, allowing inserts or updates through `ON DUPLICATE KEY UPDATE` and returning the generated `exam_id`.

- **Parameters**:
  - `IN p_registration_id INT`
  - `IN p_exam_type VARCHAR(12)`
  - `IN p_exam_date DATE`
  - `IN p_marks DECIMAL(5,2)`
  - `IN p_max_marks DECIMAL(5,2)`
  - `OUT p_exam_id INT`

---

## 3. Analytical SQL Views

Located in `database/views.sql`. Pre-computes complex analytical metrics at the database level.

### 1. `v_section_occupancy`
Calculates active student enrollment, available capacity, and full flag per section:
- Columns: `section_id`, `semester_label`, `course_code`, `course_name`, `credits`, `faculty_name`, `capacity`, `registered_count`, `remaining_seats`, `occupancy_pct`, `is_full`.

### 2. `v_attendance_summary`
Aggregates attendance counts and identifies students with attendance below 75%:
- Columns: `registration_id`, `reg_no`, `student_name`, `course_code`, `faculty_name`, `total_classes`, `present_count`, `late_count`, `absent_count`, `attendance_pct`, `is_shortage`.

### 3. `v_exam_details`
Combines registration, course, faculty, exam, and grade calculations:
- Columns: `exam_id`, `reg_no`, `student_name`, `course_code`, `faculty_name`, `exam_type`, `marks`, `max_marks`, `percentage`, `grade_letter`, `grade_point`.

### 4. `v_result_analysis`
Section-level assessment statistics:
- Columns: `section_id`, `course_code`, `faculty_name`, `exam_type`, `candidates`, `evaluated`, `average_pct`, `highest_pct`, `lowest_pct`, `passed`, `failed`, `pass_pct`.

### 5. `v_student_academic_history`
Full longitudinal academic transcript for every student:
- Columns: `student_id`, `reg_no`, `student_name`, `course_code`, `credits`, `semester_label`, `mid_term_marks`, `end_term_marks`, `final_grade`, `final_grade_point`, `attendance_pct`.

### 6. `v_fee_dues`
Detailed semester billing and balance ledger:
- Columns: `bill_id`, `student_id`, `reg_no`, `student_name`, `amount_due`, `amount_paid`, `balance`, `status`, `due_date`, `is_overdue`, `days_overdue`.

### 7. `v_student_dues`
Student-level fee consolidation across multiple semesters:
- Columns: `student_id`, `reg_no`, `student_name`, `total_billed`, `total_paid`, `outstanding`, `overdue_bills`, `max_days_overdue`.

### 8. `v_department_summary`
Institutional roll-up across academic units:
- Columns: `dept_id`, `dept_code`, `dept_name`, `programmes`, `active_programmes`, `faculty_count`, `course_count`, `total_students`, `active_students`.
