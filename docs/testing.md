# Database Rule Testing Guide

This guide details the manual verification procedures for testing the constraints, triggers, and stored procedures implemented in the **Student & College Management System (SCMS)**.

> **Note on Testing Scope**: The project implements database-level integrity rules and stored procedures verified through direct SQL executions and interactive UI workflows. It does not use an automated end-to-end testing suite.

---

## Pre-Requisites for Testing
Ensure the database has been loaded using the provided seed data (`database/seed.sql`):
```bash
mysql -u root -p scms_db < database/seed.sql
```

---

## Scenario 1: Student Admission Transaction (`sp_admit_student`)

### Objective
Verify that `sp_admit_student` atomically creates a student record along with their linked guardian record in a single transaction.

### Test Execution (SQL CLI)
```sql
CALL sp_admit_student(
    1,                                  -- programme_id: BTECH-CSE
    '25CSE999',                         -- reg_no
    'Rohan K. Varma',                   -- full_name
    '2005-06-15',                       -- dob
    'rohan.varma@students.scms.edu.in', -- email
    '+919876543210',                    -- phone
    '2026-07-01',                       -- admission_date
    'Kishore Varma',                    -- guardian name
    'Father',                           -- relation
    '+919876543211',                    -- guardian phone
    'kishore.varma@example.com',        -- guardian email
    'Flat 402, Green Meadows, Hyderabad',-- guardian address
    @new_student_id
);

SELECT @new_student_id AS admitted_student_id;
```

### Verification Query
```sql
SELECT s.student_id, s.reg_no, s.full_name, g.name AS guardian_name, g.relation
FROM student s
JOIN guardian g ON g.student_id = s.student_id
WHERE s.student_id = @new_student_id;
```

### Expected Result
- Returns a new valid `student_id`.
- The verification query returns 1 row confirming both `student` and `guardian` were inserted atomically.
- If any error occurs (e.g., duplicate email), both operations rollback cleanly with no partial records.

---

## Scenario 2: Section Capacity Barrier (`trg_registration_before_insert`)

### Objective
Verify that the trigger blocks enrollment when a section has reached maximum capacity.

### Seed Context
In `database/seed.sql`, Section `CS203-B` (section_id = 4) has a capacity of **3 seats**, and currently has **3 active registrations** (registration IDs 6, 7, 8).

### Test Execution (SQL CLI)
```sql
-- Attempt to enroll student_id = 5 (Neha Gupta) into full section_id = 4
INSERT INTO registration (student_id, section_id, status)
VALUES (5, 4, 'Registered');
```

### Expected Result
```
ERROR 1644 (45000): Registration Blocked: This section has reached maximum student capacity.
```
The transaction is rejected; no row is added to `registration`.

---

## Scenario 3: Duplicate Course Registration (`trg_registration_before_insert`)

### Objective
Verify that a student cannot be enrolled in two different sections of the same course in the same semester.

### Seed Context
Student `1` (Aarav Mehta) is already enrolled in `CS203` (Database Management Systems) under Section `A` (`section_id = 3`, Semester 3).

### Test Execution (SQL CLI)
```sql
-- Attempt to enroll Aarav Mehta into CS203 Section B (section_id = 4)
INSERT INTO registration (student_id, section_id, status)
VALUES (1, 4, 'Registered');
```

### Expected Result
```
ERROR 1644 (45000): Registration Failed: Student is already registered in another section for this course in the same semester.
```
The registration is blocked by the trigger.

---

## Scenario 4: Attendance Calendar & Date Validity (`trg_attendance_before_insert`)

### Objective
Verify that attendance cannot be recorded for a future date or outside the semester schedule.

### Test Execution (SQL CLI)
```sql
-- Attempt 1: Future attendance date
INSERT INTO attendance (registration_id, attendance_date, status)
VALUES (9, DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY), 'Present');
```

### Expected Result 1
```
ERROR 1644 (45000): Invalid Date: Attendance cannot be recorded for a future date.
```

```sql
-- Attempt 2: Date outside the semester calendar (Semester 3 starts 2026-07-15)
INSERT INTO attendance (registration_id, attendance_date, status)
VALUES (9, '2025-01-10', 'Present');
```

### Expected Result 2
```
ERROR 1644 (45000): Invalid Date: Attendance date falls outside the scheduled semester period.
```

---

## Scenario 5: Deterministic Grade Calculation (`trg_examination_after_insert`)

### Objective
Verify that entering exam marks triggers automatic grade letter and grade point computation.

### Test Execution (SQL CLI)
```sql
-- Insert exam marks of 88.5 / 100 for registration_id = 1
INSERT INTO examination (registration_id, exam_type, exam_date, max_marks, marks)
VALUES (1, 'Mid-Term', '2026-09-15', 100.00, 88.50);

-- Query the automatically populated grade record
SELECT e.exam_id, e.marks, e.max_marks, g.grade_letter, g.grade_point
FROM examination e
JOIN grade g ON g.exam_id = e.exam_id
WHERE e.registration_id = 1 AND e.exam_type = 'Mid-Term';
```

### Expected Result
- `marks`: 88.50
- `percentage`: 88.50% (falls in 80% - 89.99% bracket)
- `grade_letter`: `A`
- `grade_point`: `9.0`
The grade row is populated automatically by `trg_examination_after_insert`.

---

## Scenario 6: Fee Overpayment Prevention (`trg_payment_before_insert`)

### Objective
Verify that a student cannot pay more than their remaining invoice balance.

### Seed Context
Student `Meera Nair` has Fee Bill `4` for ₹92,500.00 with ₹50,000.00 previously paid. Outstanding balance is **₹42,500.00**.

### Test Execution (SQL CLI)
```sql
-- Attempt to submit payment of ₹50,000 (exceeds balance of ₹42,500)
INSERT INTO payment (bill_id, payment_date, amount_paid, payment_mode, reference_no)
VALUES (4, CURRENT_DATE(), 50000.00, 'UPI', 'UPI-OVERPAY-001');
```

### Expected Result
```
ERROR 1644 (45000): Payment Rejected: Total payment cannot exceed the remaining balance due.
```
The trigger blocks the overpayment.

---

## Scenario 7: Fee Status Synchronization (`trg_payment_after_insert`)

### Objective
Verify that submitting the exact remaining balance automatically marks the bill as `Paid`.

### Test Execution (SQL CLI)
```sql
-- Pay exact remaining balance of ₹42,500.00
INSERT INTO payment (bill_id, payment_date, amount_paid, payment_mode, reference_no)
VALUES (4, CURRENT_DATE(), 42500.00, 'UPI', 'UPI-SETTLE-001');

-- Verify bill status
SELECT bill_id, amount_due, status FROM fee_bill WHERE bill_id = 4;
```

### Expected Result
- Total paid: ₹50,000 + ₹42,500 = ₹92,500.
- `fee_bill.status` is automatically updated to `'Paid'`.
