-- ============================================================
-- Student & College Management System (SCMS)
-- Database: scms_db
-- Author: Vardan Desai (25WU0104029) | Woxsen University
-- Triggers for Business Logic Enforcement
-- ============================================================

USE scms_db;

DELIMITER $$

-- ------------------------------------------------------------
-- TRIGGER 1: REGISTRATION VALIDATION (BEFORE INSERT)
-- Rules:
-- 1. Student must exist and be in 'Active' status
-- 2. Prevent duplicate active enrollment for the same course & semester
-- 3. Section capacity must not be exceeded
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_registration_before_insert$$
CREATE TRIGGER trg_registration_before_insert
BEFORE INSERT ON registration
FOR EACH ROW
BEGIN
    DECLARE v_student_status VARCHAR(20);
    DECLARE v_capacity INT;
    DECLARE v_enrolled_count INT;
    DECLARE v_duplicate_count INT;

    -- 1. Check student existence and status
    SELECT status INTO v_student_status
    FROM student
    WHERE student_id = NEW.student_id;

    IF v_student_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration rejected: Student does not exist.';
    ELSEIF v_student_status <> 'Active' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration rejected: Only Active students can register for courses.';
    END IF;

    -- 2. Check for duplicate registration in this course and semester
    SELECT COUNT(*) INTO v_duplicate_count
    FROM registration
    WHERE student_id = NEW.student_id
      AND course_id = NEW.course_id
      AND semester_id = NEW.semester_id
      AND status <> 'Dropped';

    IF v_duplicate_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration rejected: Student is already registered for this course in the selected semester.';
    END IF;

    -- 3. Check section capacity
    SELECT capacity INTO v_capacity
    FROM section
    WHERE section_id = NEW.section_id;

    IF v_capacity IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration rejected: Specified section does not exist.';
    END IF;

    SELECT COUNT(*) INTO v_enrolled_count
    FROM registration
    WHERE section_id = NEW.section_id
      AND status = 'Enrolled';

    IF v_enrolled_count >= v_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration rejected: Section capacity has been reached.';
    END IF;
END$$


-- ------------------------------------------------------------
-- TRIGGER 2: ATTENDANCE VALIDATION (BEFORE INSERT)
-- Rules:
-- 1. Registration must exist and must not be 'Dropped'
-- 2. Future attendance dates are rejected
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_attendance_before_insert$$
CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE v_reg_status VARCHAR(20);

    -- 1. Check registration status
    SELECT status INTO v_reg_status
    FROM registration
    WHERE registration_id = NEW.registration_id;

    IF v_reg_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Attendance rejected: Registration record not found.';
    ELSEIF v_reg_status = 'Dropped' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Attendance rejected: Cannot record attendance for a dropped registration.';
    END IF;

    -- 2. Disallow future dates
    IF NEW.attendance_date > CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Attendance rejected: Attendance date cannot be in the future.';
    END IF;
END$$


-- ------------------------------------------------------------
-- TRIGGER 3: PAYMENT VALIDATION (BEFORE INSERT)
-- Rules:
-- 1. Payment amount must be positive
-- 2. Payment cannot exceed outstanding bill balance
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_payment_before_insert$$
CREATE TRIGGER trg_payment_before_insert
BEFORE INSERT ON payment
FOR EACH ROW
BEGIN
    DECLARE v_bill_amount DECIMAL(10,2);
    DECLARE v_already_paid DECIMAL(10,2);
    DECLARE v_balance DECIMAL(10,2);

    IF NEW.amount_paid <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment rejected: Payment amount must be greater than zero.';
    END IF;

    -- Fetch bill details
    SELECT amount INTO v_bill_amount
    FROM fee_bill
    WHERE bill_id = NEW.bill_id;

    IF v_bill_amount IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment rejected: Associated fee bill not found.';
    END IF;

    -- Calculate total already paid
    SELECT IFNULL(SUM(amount_paid), 0.00) INTO v_already_paid
    FROM payment
    WHERE bill_id = NEW.bill_id;

    SET v_balance = v_bill_amount - v_already_paid;

    IF NEW.amount_paid > v_balance THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment rejected: Payment amount exceeds outstanding balance.';
    END IF;
END$$


-- ------------------------------------------------------------
-- TRIGGER 4: FEE STATUS CALCULATION (AFTER INSERT & DELETE & UPDATE)
-- Rules:
-- Automatically re-evaluate and update fee_bill.status based on
-- sum of payments vs bill amount:
-- - sum >= amount => 'Paid'
-- - sum > 0       => 'Partially Paid'
-- - sum = 0       => 'Unpaid'
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_payment_after_insert$$
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    DECLARE v_bill_amount DECIMAL(10,2);
    DECLARE v_total_paid DECIMAL(10,2);

    SELECT amount INTO v_bill_amount
    FROM fee_bill
    WHERE bill_id = NEW.bill_id;

    SELECT IFNULL(SUM(amount_paid), 0.00) INTO v_total_paid
    FROM payment
    WHERE bill_id = NEW.bill_id;

    IF v_total_paid >= v_bill_amount THEN
        UPDATE fee_bill SET status = 'Paid' WHERE bill_id = NEW.bill_id;
    ELSEIF v_total_paid > 0 THEN
        UPDATE fee_bill SET status = 'Partially Paid' WHERE bill_id = NEW.bill_id;
    ELSE
        UPDATE fee_bill SET status = 'Unpaid' WHERE bill_id = NEW.bill_id;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_payment_after_delete$$
CREATE TRIGGER trg_payment_after_delete
AFTER DELETE ON payment
FOR EACH ROW
BEGIN
    DECLARE v_bill_amount DECIMAL(10,2);
    DECLARE v_total_paid DECIMAL(10,2);

    SELECT amount INTO v_bill_amount
    FROM fee_bill
    WHERE bill_id = OLD.bill_id;

    SELECT IFNULL(SUM(amount_paid), 0.00) INTO v_total_paid
    FROM payment
    WHERE bill_id = OLD.bill_id;

    IF v_total_paid >= v_bill_amount THEN
        UPDATE fee_bill SET status = 'Paid' WHERE bill_id = OLD.bill_id;
    ELSEIF v_total_paid > 0 THEN
        UPDATE fee_bill SET status = 'Partially Paid' WHERE bill_id = OLD.bill_id;
    ELSE
        UPDATE fee_bill SET status = 'Unpaid' WHERE bill_id = OLD.bill_id;
    END IF;
END$$


-- ------------------------------------------------------------
-- TRIGGER 5: AUTOMATIC GRADE GENERATION (AFTER INSERT & AFTER UPDATE)
-- Rules:
-- Automatically calculates percentage and computes:
-- 90+  -> A+ -> 10.0
-- 80+  -> A  -> 9.0
-- 70+  -> B+ -> 8.0
-- 60+  -> B  -> 7.0
-- 50+  -> C  -> 6.0
-- 40+  -> D  -> 5.0
-- <40  -> F  -> 0.0
-- Writes directly into grade table.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_exam_after_insert$$
CREATE TRIGGER trg_exam_after_insert
AFTER INSERT ON examination
FOR EACH ROW
BEGIN
    DECLARE v_percentage DECIMAL(5,2);
    DECLARE v_letter VARCHAR(5);
    DECLARE v_gp DECIMAL(3,1);
    DECLARE v_rem VARCHAR(50);

    SET v_percentage = (NEW.marks_obtained / NEW.max_marks) * 100.00;

    IF v_percentage >= 90.00 THEN
        SET v_letter = 'A+';
        SET v_gp = 10.0;
        SET v_rem = 'Outstanding';
    ELSEIF v_percentage >= 80.00 THEN
        SET v_letter = 'A';
        SET v_gp = 9.0;
        SET v_rem = 'Excellent';
    ELSEIF v_percentage >= 70.00 THEN
        SET v_letter = 'B+';
        SET v_gp = 8.0;
        SET v_rem = 'Very Good';
    ELSEIF v_percentage >= 60.00 THEN
        SET v_letter = 'B';
        SET v_gp = 7.0;
        SET v_rem = 'Good';
    ELSEIF v_percentage >= 50.00 THEN
        SET v_letter = 'C';
        SET v_gp = 6.0;
        SET v_rem = 'Average';
    ELSEIF v_percentage >= 40.00 THEN
        SET v_letter = 'D';
        SET v_gp = 5.0;
        SET v_rem = 'Pass';
    ELSE
        SET v_letter = 'F';
        SET v_gp = 0.0;
        SET v_rem = 'Fail';
    END IF;

    INSERT INTO grade (exam_id, percentage, letter_grade, grade_point, remarks)
    VALUES (NEW.exam_id, v_percentage, v_letter, v_gp, v_rem)
    ON DUPLICATE KEY UPDATE
        percentage = v_percentage,
        letter_grade = v_letter,
        grade_point = v_gp,
        remarks = v_rem,
        calculated_at = CURRENT_TIMESTAMP;
END$$

DROP TRIGGER IF EXISTS trg_exam_after_update$$
CREATE TRIGGER trg_exam_after_update
AFTER UPDATE ON examination
FOR EACH ROW
BEGIN
    DECLARE v_percentage DECIMAL(5,2);
    DECLARE v_letter VARCHAR(5);
    DECLARE v_gp DECIMAL(3,1);
    DECLARE v_rem VARCHAR(50);

    SET v_percentage = (NEW.marks_obtained / NEW.max_marks) * 100.00;

    IF v_percentage >= 90.00 THEN
        SET v_letter = 'A+';
        SET v_gp = 10.0;
        SET v_rem = 'Outstanding';
    ELSEIF v_percentage >= 80.00 THEN
        SET v_letter = 'A';
        SET v_gp = 9.0;
        SET v_rem = 'Excellent';
    ELSEIF v_percentage >= 70.00 THEN
        SET v_letter = 'B+';
        SET v_gp = 8.0;
        SET v_rem = 'Very Good';
    ELSEIF v_percentage >= 60.00 THEN
        SET v_letter = 'B';
        SET v_gp = 7.0;
        SET v_rem = 'Good';
    ELSEIF v_percentage >= 50.00 THEN
        SET v_letter = 'C';
        SET v_gp = 6.0;
        SET v_rem = 'Average';
    ELSEIF v_percentage >= 40.00 THEN
        SET v_letter = 'D';
        SET v_gp = 5.0;
        SET v_rem = 'Pass';
    ELSE
        SET v_letter = 'F';
        SET v_gp = 0.0;
        SET v_rem = 'Fail';
    END IF;

    INSERT INTO grade (exam_id, percentage, letter_grade, grade_point, remarks)
    VALUES (NEW.exam_id, v_percentage, v_letter, v_gp, v_rem)
    ON DUPLICATE KEY UPDATE
        percentage = v_percentage,
        letter_grade = v_letter,
        grade_point = v_gp,
        remarks = v_rem,
        calculated_at = CURRENT_TIMESTAMP;
END$$

DELIMITER ;
