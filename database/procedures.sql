-- ============================================================
-- Student & College Management System (SCMS)
-- Database: scms_db
-- Author: Vardan Desai (25WU0104029) | Woxsen University
-- Stored Procedures for Transactional Operations
-- ============================================================

USE scms_db;

DELIMITER $$

-- ------------------------------------------------------------
-- PROCEDURE 1: sp_admit_student
-- Atomically admits a student and registers guardian details.
-- Demonstrates: Transactions (ACID), Exception Handling, Rollback
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_admit_student$$
CREATE PROCEDURE sp_admit_student(
    IN  p_reg_number       VARCHAR(20),
    IN  p_programme_id     INT,
    IN  p_first_name       VARCHAR(50),
    IN  p_last_name        VARCHAR(50),
    IN  p_email            VARCHAR(100),
    IN  p_phone            VARCHAR(20),
    IN  p_dob              DATE,
    IN  p_gender           VARCHAR(15),
    IN  p_admission_date   DATE,
    IN  p_current_semester INT,
    IN  p_guardian_name    VARCHAR(100),
    IN  p_guardian_rel     VARCHAR(50),
    IN  p_guardian_phone   VARCHAR(20),
    IN  p_guardian_email   VARCHAR(100),
    IN  p_guardian_address VARCHAR(255),
    OUT p_student_id       INT,
    OUT p_status_message   VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_new_student_id INT DEFAULT NULL;
    DECLARE v_prog_exists INT DEFAULT 0;

    -- Exception Handler: Rollback transaction on any SQLEXCEPTION
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_student_id = NULL;
        SET p_status_message = 'ERROR: Student admission failed. Transaction rolled back.';
    END;

    -- Validate Programme
    SELECT COUNT(*) INTO v_prog_exists
    FROM programme
    WHERE programme_id = p_programme_id;

    IF v_prog_exists = 0 THEN
        SET p_student_id = NULL;
        SET p_status_message = 'ERROR: Specified Programme ID does not exist.';
        LEAVE proc_label;
    END IF;

    -- Start Transaction
    START TRANSACTION;

    -- 1. Insert Student Record
    INSERT INTO student (
        reg_number, programme_id, first_name, last_name, email,
        phone, dob, gender, admission_date, current_semester, status
    ) VALUES (
        p_reg_number, p_programme_id, p_first_name, p_last_name, p_email,
        p_phone, p_dob, p_gender, p_admission_date, p_current_semester, 'Active'
    );

    SET v_new_student_id = LAST_INSERT_ID();

    -- 2. Insert Guardian Details if name provided
    IF p_guardian_name IS NOT NULL AND TRIM(p_guardian_name) <> '' THEN
        INSERT INTO guardian (
            student_id, guardian_name, relationship, phone, email, address
        ) VALUES (
            v_new_student_id, p_guardian_name, p_guardian_rel,
            p_guardian_phone, p_guardian_email, p_guardian_address
        );
    END IF;

    -- Commit on Success
    COMMIT;

    SET p_student_id = v_new_student_id;
    SET p_status_message = 'SUCCESS: Student admitted successfully with guardian record.';
END$$


-- ------------------------------------------------------------
-- PROCEDURE 2: sp_record_exam_result
-- Records examination marks and triggers automatic grade computation.
-- Demonstrates: Trigger invocation from procedure and returning computed grade.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_record_exam_result$$
CREATE PROCEDURE sp_record_exam_result(
    IN  p_registration_id   INT,
    IN  p_exam_type         VARCHAR(30),
    IN  p_exam_date         DATE,
    IN  p_max_marks         DECIMAL(5,2),
    IN  p_marks_obtained    DECIMAL(5,2),
    OUT p_exam_id           INT,
    OUT p_letter_grade      VARCHAR(5),
    OUT p_grade_point       DECIMAL(3,1),
    OUT p_percentage        DECIMAL(5,2),
    OUT p_status_message    VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_new_exam_id INT DEFAULT NULL;
    DECLARE v_reg_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_exam_id = NULL;
        SET p_letter_grade = NULL;
        SET p_grade_point = NULL;
        SET p_percentage = NULL;
        SET p_status_message = 'ERROR: Failed to record examination marks. Transaction rolled back.';
    END;

    -- Validate Registration
    SELECT status INTO v_reg_status
    FROM registration
    WHERE registration_id = p_registration_id;

    IF v_reg_status IS NULL THEN
        SET p_status_message = 'ERROR: Registration ID does not exist.';
        LEAVE proc_label;
    ELSEIF v_reg_status = 'Dropped' THEN
        SET p_status_message = 'ERROR: Cannot enter exam marks for dropped registration.';
        LEAVE proc_label;
    END IF;

    IF p_marks_obtained > p_max_marks THEN
        SET p_status_message = 'ERROR: Marks obtained cannot exceed maximum marks.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    -- Insert into examination (will trigger trg_exam_after_insert)
    INSERT INTO examination (
        registration_id, exam_type, exam_date, max_marks, marks_obtained
    ) VALUES (
        p_registration_id, p_exam_type, p_exam_date, p_max_marks, p_marks_obtained
    );

    SET v_new_exam_id = LAST_INSERT_ID();

    COMMIT;

    -- Read the trigger-generated grade
    SELECT letter_grade, grade_point, percentage
    INTO p_letter_grade, p_grade_point, p_percentage
    FROM grade
    WHERE exam_id = v_new_exam_id;

    SET p_exam_id = v_new_exam_id;
    SET p_status_message = 'SUCCESS: Exam result recorded and grade generated automatically by database trigger.';
END$$

DELIMITER ;
