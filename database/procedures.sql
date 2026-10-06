-- =============================================================================
-- SCMS — Stored Procedures (MySQL 8.0+)
-- File : database/procedures.sql
-- Description : Transactional stored procedures for multi-table atomic operations
-- =============================================================================

USE scms_db;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. ADMIT STUDENT (Atomic student + guardian creation)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_admit_student$$
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

-- -----------------------------------------------------------------------------
-- 2. RECORD EXAM RESULT (Atomic marks insertion or update)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_record_exam_result$$
CREATE PROCEDURE sp_record_exam_result(
    IN p_registration_id INT,
    IN p_exam_type VARCHAR(12),
    IN p_exam_date DATE,
    IN p_marks DECIMAL(5,2),
    IN p_max_marks DECIMAL(5,2),
    OUT p_exam_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO examination (registration_id, exam_type, exam_date, max_marks, marks)
    VALUES (p_registration_id, p_exam_type, p_exam_date, COALESCE(p_max_marks, 100.00), p_marks)
    ON DUPLICATE KEY UPDATE
        exam_date = VALUES(exam_date),
        max_marks = VALUES(max_marks),
        marks = VALUES(marks);

    SELECT exam_id INTO p_exam_id
    FROM examination
    WHERE registration_id = p_registration_id AND exam_type = p_exam_type;

    COMMIT;
END$$

DELIMITER ;
