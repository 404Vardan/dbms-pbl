-- =============================================================================
-- SCMS — Database Triggers (MySQL 8.0+)
-- File : database/triggers.sql
-- Description : Enforces core business rules inside the MySQL database:
--   1. Section Capacity & Duplicate Course Checks (BEFORE INSERT ON registration)
--   2. Attendance Calendar & Dropped Registration Validation (BEFORE INSERT ON attendance)
--   3. Overpayment Prevention & Balance Enforcement (BEFORE INSERT ON payment)
--   4. Deterministic Examination Grading (AFTER INSERT/UPDATE ON examination)
--   5. Fee Bill Status Synchronization (AFTER INSERT ON payment)
-- =============================================================================

USE scms_db;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. REGISTRATION CAPACITY & DUPLICATE ENROLMENT TRIGGER
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_registration_before_insert$$
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

    -- Check if student is active
    SELECT status INTO v_student_status FROM student WHERE student_id = NEW.student_id;
    IF v_student_status != 'Active' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration Blocked: Only Active students can be enrolled in sections.';
    END IF;

    -- Retrieve section capacity, course, and semester
    SELECT capacity, course_id, semester_id 
    INTO v_capacity, v_course_id, v_semester_id
    FROM section 
    WHERE section_id = NEW.section_id;

    -- Check if student is already enrolled in another section of the same course in this semester
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

    -- Check current occupancy
    SELECT COUNT(*) INTO v_current_taken
    FROM registration
    WHERE section_id = NEW.section_id
      AND status != 'Dropped';

    IF v_current_taken >= v_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration Blocked: This section has reached maximum student capacity.';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- 2. ATTENDANCE VALIDATION TRIGGER
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_attendance_before_insert$$
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

-- -----------------------------------------------------------------------------
-- 3. PAYMENT OVERPAYMENT PREVENTION TRIGGER
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_payment_before_insert$$
CREATE TRIGGER trg_payment_before_insert
BEFORE INSERT ON payment
FOR EACH ROW
BEGIN
    DECLARE v_amount_due DECIMAL(10,2);
    DECLARE v_total_paid DECIMAL(10,2);
    DECLARE v_remaining DECIMAL(10,2);

    SELECT amount_due INTO v_amount_due
    FROM fee_bill
    WHERE bill_id = NEW.bill_id;

    SELECT COALESCE(SUM(amount_paid), 0) INTO v_total_paid
    FROM payment
    WHERE bill_id = NEW.bill_id;

    SET v_remaining = v_amount_due - v_total_paid;

    IF NEW.amount_paid > v_remaining THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment Rejected: Total payment cannot exceed the remaining balance due.';
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- 4. PAYMENT POST-INSERT: SYNCHRONIZE FEE BILL STATUS
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_payment_after_insert$$
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    DECLARE v_amount_due DECIMAL(10,2);
    DECLARE v_total_paid DECIMAL(10,2);

    SELECT amount_due INTO v_amount_due
    FROM fee_bill
    WHERE bill_id = NEW.bill_id;

    SELECT COALESCE(SUM(amount_paid), 0) INTO v_total_paid
    FROM payment
    WHERE bill_id = NEW.bill_id;

    IF v_total_paid >= v_amount_due THEN
        UPDATE fee_bill SET status = 'Paid' WHERE bill_id = NEW.bill_id;
    ELSEIF v_total_paid > 0 THEN
        UPDATE fee_bill SET status = 'Partially Paid' WHERE bill_id = NEW.bill_id;
    ELSE
        UPDATE fee_bill SET status = 'Unpaid' WHERE bill_id = NEW.bill_id;
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- 5. DETERMINISTIC EXAMINATION GRADE TRIGGER (INSERT)
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_examination_after_insert$$
CREATE TRIGGER trg_examination_after_insert
AFTER INSERT ON examination
FOR EACH ROW
BEGIN
    DECLARE v_pct DECIMAL(5,2);
    DECLARE v_letter VARCHAR(2);
    DECLARE v_point DECIMAL(3,1);

    IF NEW.marks IS NOT NULL THEN
        SET v_pct = (NEW.marks * 100.0) / NEW.max_marks;

        IF v_pct >= 90.0 THEN
            SET v_letter = 'A+', v_point = 10.0;
        ELSEIF v_pct >= 80.0 THEN
            SET v_letter = 'A', v_point = 9.0;
        ELSEIF v_pct >= 70.0 THEN
            SET v_letter = 'B+', v_point = 8.0;
        ELSEIF v_pct >= 60.0 THEN
            SET v_letter = 'B', v_point = 7.0;
        ELSEIF v_pct >= 50.0 THEN
            SET v_letter = 'C', v_point = 6.0;
        ELSEIF v_pct >= 40.0 THEN
            SET v_letter = 'D', v_point = 5.0;
        ELSE
            SET v_letter = 'F', v_point = 0.0;
        END IF;

        INSERT INTO grade (exam_id, grade_letter, grade_point, graded_on)
        VALUES (NEW.exam_id, v_letter, v_point, CURRENT_TIMESTAMP)
        ON DUPLICATE KEY UPDATE
            grade_letter = v_letter,
            grade_point = v_point,
            graded_on = CURRENT_TIMESTAMP;
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- 6. DETERMINISTIC EXAMINATION GRADE TRIGGER (UPDATE)
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_examination_after_update$$
CREATE TRIGGER trg_examination_after_update
AFTER UPDATE ON examination
FOR EACH ROW
BEGIN
    DECLARE v_pct DECIMAL(5,2);
    DECLARE v_letter VARCHAR(2);
    DECLARE v_point DECIMAL(3,1);

    IF NEW.marks IS NOT NULL THEN
        SET v_pct = (NEW.marks * 100.0) / NEW.max_marks;

        IF v_pct >= 90.0 THEN
            SET v_letter = 'A+', v_point = 10.0;
        ELSEIF v_pct >= 80.0 THEN
            SET v_letter = 'A', v_point = 9.0;
        ELSEIF v_pct >= 70.0 THEN
            SET v_letter = 'B+', v_point = 8.0;
        ELSEIF v_pct >= 60.0 THEN
            SET v_letter = 'B', v_point = 7.0;
        ELSEIF v_pct >= 50.0 THEN
            SET v_letter = 'C', v_point = 6.0;
        ELSEIF v_pct >= 40.0 THEN
            SET v_letter = 'D', v_point = 5.0;
        ELSE
            SET v_letter = 'F', v_point = 0.0;
        END IF;

        INSERT INTO grade (exam_id, grade_letter, grade_point, graded_on)
        VALUES (NEW.exam_id, v_letter, v_point, CURRENT_TIMESTAMP)
        ON DUPLICATE KEY UPDATE
            grade_letter = v_letter,
            grade_point = v_point,
            graded_on = CURRENT_TIMESTAMP;
    ELSE
        DELETE FROM grade WHERE exam_id = NEW.exam_id;
    END IF;
END$$

DELIMITER ;
