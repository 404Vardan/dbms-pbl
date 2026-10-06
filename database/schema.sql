-- =============================================================================
-- SCMS — Student & College Management System
-- Database Engine : MySQL 8.0+
-- File            : database/schema.sql
-- Description     : Creates the database and all 14 core domain tables
--                   plus the user_account table for authentication.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS scms_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE scms_db;

-- Disable foreign key checks during schema creation
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS fee_bill;
DROP TABLE IF EXISTS grade;
DROP TABLE IF EXISTS examination;
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS registration;
DROP TABLE IF EXISTS guardian;
DROP TABLE IF EXISTS student;
DROP TABLE IF EXISTS section;
DROP TABLE IF EXISTS semester;
DROP TABLE IF EXISTS course;
DROP TABLE IF EXISTS faculty;
DROP TABLE IF EXISTS programme;
DROP TABLE IF EXISTS department;
DROP TABLE IF EXISTS user_account;

SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- 1. DEPARTMENT
-- -----------------------------------------------------------------------------
CREATE TABLE department (
    dept_id       INT AUTO_INCREMENT PRIMARY KEY,
    dept_code     VARCHAR(10)  NOT NULL,
    dept_name     VARCHAR(100) NOT NULL,
    office_email  VARCHAR(120) NULL,
    CONSTRAINT uq_department_code  UNIQUE (dept_code),
    CONSTRAINT uq_department_name  UNIQUE (dept_name),
    CONSTRAINT uq_department_email UNIQUE (office_email)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 2. PROGRAMME
-- -----------------------------------------------------------------------------
CREATE TABLE programme (
    programme_id    INT AUTO_INCREMENT PRIMARY KEY,
    dept_id         INT          NOT NULL,
    programme_code  VARCHAR(15)  NOT NULL,
    programme_name  VARCHAR(120) NOT NULL,
    duration_years  TINYINT      NOT NULL,
    status          VARCHAR(10)  NOT NULL DEFAULT 'Active',
    CONSTRAINT fk_programme_department FOREIGN KEY (dept_id) REFERENCES department (dept_id) ON DELETE RESTRICT,
    CONSTRAINT uq_programme_code       UNIQUE (programme_code),
    CONSTRAINT ck_programme_duration   CHECK (duration_years > 0),
    CONSTRAINT ck_programme_status     CHECK (status IN ('Active', 'Inactive'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 3. FACULTY
-- -----------------------------------------------------------------------------
CREATE TABLE faculty (
    faculty_id     INT AUTO_INCREMENT PRIMARY KEY,
    dept_id        INT          NOT NULL,
    employee_code  VARCHAR(15)  NOT NULL,
    full_name      VARCHAR(100) NOT NULL,
    email          VARCHAR(120) NOT NULL,
    designation    VARCHAR(60)  NOT NULL,
    status         VARCHAR(10)  NOT NULL DEFAULT 'Active',
    CONSTRAINT fk_faculty_department FOREIGN KEY (dept_id) REFERENCES department (dept_id) ON DELETE RESTRICT,
    CONSTRAINT uq_faculty_employee_code UNIQUE (employee_code),
    CONSTRAINT uq_faculty_email         UNIQUE (email),
    CONSTRAINT ck_faculty_status        CHECK (status IN ('Active', 'Inactive'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 4. COURSE
-- -----------------------------------------------------------------------------
CREATE TABLE course (
    course_id    INT AUTO_INCREMENT PRIMARY KEY,
    dept_id      INT          NOT NULL,
    course_code  VARCHAR(12)  NOT NULL,
    course_name  VARCHAR(120) NOT NULL,
    credits      TINYINT      NOT NULL,
    course_type  VARCHAR(10)  NOT NULL DEFAULT 'Core',
    status       VARCHAR(10)  NOT NULL DEFAULT 'Active',
    CONSTRAINT fk_course_department FOREIGN KEY (dept_id) REFERENCES department (dept_id) ON DELETE RESTRICT,
    CONSTRAINT uq_course_code       UNIQUE (course_code),
    CONSTRAINT ck_course_credits    CHECK (credits > 0),
    CONSTRAINT ck_course_type       CHECK (course_type IN ('Core', 'Elective', 'Lab', 'Project')),
    CONSTRAINT ck_course_status     CHECK (status IN ('Active', 'Inactive'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 5. SEMESTER
-- -----------------------------------------------------------------------------
CREATE TABLE semester (
    semester_id    INT AUTO_INCREMENT PRIMARY KEY,
    academic_year  VARCHAR(9)  NOT NULL,           -- e.g. '2026-27'
    term           VARCHAR(10) NOT NULL,           -- Odd / Even / Summer
    start_date     DATE        NOT NULL,
    end_date       DATE        NOT NULL,
    CONSTRAINT uq_semester_year_term UNIQUE (academic_year, term),
    CONSTRAINT ck_semester_dates     CHECK (end_date >= start_date),
    CONSTRAINT ck_semester_term      CHECK (term IN ('Odd', 'Even', 'Summer'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 6. SECTION
-- -----------------------------------------------------------------------------
CREATE TABLE section (
    section_id    INT AUTO_INCREMENT PRIMARY KEY,
    course_id     INT         NOT NULL,
    faculty_id    INT         NOT NULL,
    semester_id   INT         NOT NULL,
    section_code  VARCHAR(5)  NOT NULL,
    room_no       VARCHAR(15) NOT NULL,
    capacity      SMALLINT    NOT NULL,
    CONSTRAINT fk_section_course   FOREIGN KEY (course_id)   REFERENCES course (course_id)     ON DELETE RESTRICT,
    CONSTRAINT fk_section_faculty  FOREIGN KEY (faculty_id)  REFERENCES faculty (faculty_id)   ON DELETE RESTRICT,
    CONSTRAINT fk_section_semester FOREIGN KEY (semester_id) REFERENCES semester (semester_id) ON DELETE RESTRICT,
    CONSTRAINT uq_section_course_semester_code UNIQUE (course_id, semester_id, section_code),
    CONSTRAINT ck_section_capacity CHECK (capacity > 0)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 7. STUDENT
-- -----------------------------------------------------------------------------
CREATE TABLE student (
    student_id      INT AUTO_INCREMENT PRIMARY KEY,
    programme_id    INT          NOT NULL,
    reg_no          VARCHAR(20)  NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    dob             DATE         NOT NULL,
    email           VARCHAR(120) NOT NULL,
    phone           VARCHAR(15)  NOT NULL,
    admission_date  DATE         NOT NULL,
    status          VARCHAR(12)  NOT NULL DEFAULT 'Active',
    CONSTRAINT fk_student_programme FOREIGN KEY (programme_id) REFERENCES programme (programme_id) ON DELETE RESTRICT,
    CONSTRAINT uq_student_reg_no    UNIQUE (reg_no),
    CONSTRAINT uq_student_email     UNIQUE (email),
    CONSTRAINT ck_student_dob       CHECK (dob < admission_date),
    CONSTRAINT ck_student_status    CHECK (status IN ('Active', 'Inactive', 'Graduated', 'Withdrawn'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 8. GUARDIAN
-- -----------------------------------------------------------------------------
CREATE TABLE guardian (
    guardian_id  INT AUTO_INCREMENT PRIMARY KEY,
    student_id   INT          NOT NULL,
    name         VARCHAR(100) NOT NULL,
    relation     VARCHAR(20)  NOT NULL,
    phone        VARCHAR(15)  NOT NULL,
    email        VARCHAR(120) NULL,
    address      TEXT         NULL,
    CONSTRAINT fk_guardian_student FOREIGN KEY (student_id) REFERENCES student (student_id) ON DELETE RESTRICT,
    CONSTRAINT uq_guardian_email   UNIQUE (email),
    CONSTRAINT ck_guardian_relation CHECK (relation IN ('Father', 'Mother', 'Guardian', 'Sibling', 'Spouse', 'Other'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 9. REGISTRATION
-- -----------------------------------------------------------------------------
CREATE TABLE registration (
    registration_id  INT AUTO_INCREMENT PRIMARY KEY,
    student_id       INT         NOT NULL,
    section_id       INT         NOT NULL,
    registered_on    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status           VARCHAR(12) NOT NULL DEFAULT 'Registered',
    CONSTRAINT fk_registration_student FOREIGN KEY (student_id) REFERENCES student (student_id) ON DELETE RESTRICT,
    CONSTRAINT fk_registration_section FOREIGN KEY (section_id) REFERENCES section (section_id) ON DELETE RESTRICT,
    CONSTRAINT uq_registration_student_section UNIQUE (student_id, section_id),
    CONSTRAINT ck_registration_status CHECK (status IN ('Registered', 'Dropped', 'Completed'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 10. ATTENDANCE
-- -----------------------------------------------------------------------------
CREATE TABLE attendance (
    attendance_id    INT AUTO_INCREMENT PRIMARY KEY,
    registration_id  INT        NOT NULL,
    attendance_date  DATE       NOT NULL,
    status           VARCHAR(7) NOT NULL,
    CONSTRAINT fk_attendance_registration FOREIGN KEY (registration_id) REFERENCES registration (registration_id) ON DELETE RESTRICT,
    CONSTRAINT uq_attendance_registration_date UNIQUE (registration_id, attendance_date),
    CONSTRAINT ck_attendance_status CHECK (status IN ('Present', 'Absent', 'Late'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 11. EXAMINATION
-- -----------------------------------------------------------------------------
CREATE TABLE examination (
    exam_id          INT AUTO_INCREMENT PRIMARY KEY,
    registration_id  INT           NOT NULL,
    exam_type        VARCHAR(12)   NOT NULL,
    exam_date        DATE          NOT NULL,
    max_marks        DECIMAL(5,2)  NOT NULL DEFAULT 100.00,
    marks            DECIMAL(5,2)  NULL,
    CONSTRAINT fk_examination_registration FOREIGN KEY (registration_id) REFERENCES registration (registration_id) ON DELETE RESTRICT,
    CONSTRAINT uq_examination_registration_type UNIQUE (registration_id, exam_type),
    CONSTRAINT ck_examination_type      CHECK (exam_type IN ('Mid-Term', 'End-Term', 'Internal', 'Practical')),
    CONSTRAINT ck_examination_max_marks CHECK (max_marks > 0 AND max_marks <= 100),
    CONSTRAINT ck_examination_marks     CHECK (marks IS NULL OR (marks >= 0 AND marks <= 100 AND marks <= max_marks))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 12. GRADE
-- -----------------------------------------------------------------------------
CREATE TABLE grade (
    grade_id      INT AUTO_INCREMENT PRIMARY KEY,
    exam_id       INT          NOT NULL,
    grade_letter  VARCHAR(2)   NOT NULL,
    grade_point   DECIMAL(3,1) NOT NULL,
    graded_on     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_grade_examination FOREIGN KEY (exam_id) REFERENCES examination (exam_id) ON DELETE CASCADE,
    CONSTRAINT uq_grade_exam        UNIQUE (exam_id),
    CONSTRAINT ck_grade_letter      CHECK (grade_letter IN ('A+', 'A', 'B+', 'B', 'C', 'D', 'F')),
    CONSTRAINT ck_grade_point       CHECK (grade_point >= 0 AND grade_point <= 10)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 13. FEE_BILL
-- -----------------------------------------------------------------------------
CREATE TABLE fee_bill (
    bill_id      INT AUTO_INCREMENT PRIMARY KEY,
    student_id   INT           NOT NULL,
    semester_id  INT           NOT NULL,
    bill_date    DATE          NOT NULL DEFAULT (CURRENT_DATE),
    amount_due   DECIMAL(10,2) NOT NULL,
    due_date     DATE          NOT NULL,
    status       VARCHAR(15)   NOT NULL DEFAULT 'Unpaid',
    CONSTRAINT fk_fee_bill_student  FOREIGN KEY (student_id)  REFERENCES student (student_id)   ON DELETE RESTRICT,
    CONSTRAINT fk_fee_bill_semester FOREIGN KEY (semester_id) REFERENCES semester (semester_id) ON DELETE RESTRICT,
    CONSTRAINT uq_fee_bill_student_semester UNIQUE (student_id, semester_id),
    CONSTRAINT ck_fee_bill_amount   CHECK (amount_due >= 0),
    CONSTRAINT ck_fee_bill_due_date CHECK (due_date >= bill_date),
    CONSTRAINT ck_fee_bill_status   CHECK (status IN ('Unpaid', 'Partially Paid', 'Paid'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 14. PAYMENT
-- -----------------------------------------------------------------------------
CREATE TABLE payment (
    payment_id    INT AUTO_INCREMENT PRIMARY KEY,
    bill_id       INT           NOT NULL,
    payment_date  DATE          NOT NULL DEFAULT (CURRENT_DATE),
    amount_paid   DECIMAL(10,2) NOT NULL,
    payment_mode  VARCHAR(10)   NOT NULL,
    reference_no  VARCHAR(40)   NULL,
    CONSTRAINT fk_payment_fee_bill FOREIGN KEY (bill_id) REFERENCES fee_bill (bill_id) ON DELETE RESTRICT,
    CONSTRAINT uq_payment_reference UNIQUE (reference_no),
    CONSTRAINT ck_payment_amount    CHECK (amount_paid > 0),
    CONSTRAINT ck_payment_mode      CHECK (payment_mode IN ('Cash', 'UPI', 'Card', 'NEFT', 'Cheque', 'DD'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- AUTHENTICATION TABLE: user_account (Replaces Supabase Auth)
-- -----------------------------------------------------------------------------
CREATE TABLE user_account (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    email         VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(15)  NOT NULL,
    full_name     VARCHAR(100) NOT NULL,
    student_id    INT          NULL UNIQUE,
    faculty_id    INT          NULL UNIQUE,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_student FOREIGN KEY (student_id) REFERENCES student (student_id) ON DELETE SET NULL,
    CONSTRAINT fk_user_faculty FOREIGN KEY (faculty_id) REFERENCES faculty (faculty_id) ON DELETE SET NULL,
    CONSTRAINT ck_user_role CHECK (role IN ('admin', 'faculty', 'student', 'accounts'))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- INDEXES
-- -----------------------------------------------------------------------------
CREATE INDEX ix_programme_dept        ON programme (dept_id);
CREATE INDEX ix_faculty_dept          ON faculty (dept_id);
CREATE INDEX ix_course_dept           ON course (dept_id);
CREATE INDEX ix_section_faculty       ON section (faculty_id);
CREATE INDEX ix_section_semester      ON section (semester_id);
CREATE INDEX ix_student_programme     ON student (programme_id);
CREATE INDEX ix_student_name          ON student (full_name);
CREATE INDEX ix_guardian_student      ON guardian (student_id);
CREATE INDEX ix_registration_section  ON registration (section_id, status);
CREATE INDEX ix_attendance_date       ON attendance (attendance_date);
CREATE INDEX ix_examination_date      ON examination (exam_date);
CREATE INDEX ix_fee_bill_semester     ON fee_bill (semester_id);
CREATE INDEX ix_payment_bill          ON payment (bill_id);
CREATE INDEX ix_payment_date          ON payment (payment_date DESC);
