-- ============================================================
-- Student & College Management System (SCMS)
-- Database: scms_db
-- Author: Vardan Desai (25WU0104029) | Woxsen University
-- DBMS PBL Prototype - Core Relational Schema (3NF)
-- ============================================================

CREATE DATABASE IF NOT EXISTS scms_db;
USE scms_db;

-- Disable FK checks during clean setup
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

-- ------------------------------------------------------------
-- 1. DEPARTMENT TABLE
-- ------------------------------------------------------------
CREATE TABLE department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_code VARCHAR(10) NOT NULL UNIQUE,
    dept_name VARCHAR(100) NOT NULL,
    building VARCHAR(50),
    established_year INT CHECK (established_year >= 1900),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 2. PROGRAMME TABLE
-- ------------------------------------------------------------
CREATE TABLE programme (
    programme_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    prog_code VARCHAR(15) NOT NULL UNIQUE,
    prog_name VARCHAR(100) NOT NULL,
    degree_type VARCHAR(20) NOT NULL,
    duration_years INT NOT NULL CHECK (duration_years BETWEEN 1 AND 5),
    total_semesters INT NOT NULL CHECK (total_semesters BETWEEN 2 AND 10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_programme_dept FOREIGN KEY (department_id) 
        REFERENCES department(department_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 3. FACULTY TABLE
-- ------------------------------------------------------------
CREATE TABLE faculty (
    faculty_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(20) NOT NULL UNIQUE,
    department_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    designation VARCHAR(50) NOT NULL,
    joining_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_faculty_dept FOREIGN KEY (department_id) 
        REFERENCES department(department_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 4. COURSE TABLE
-- ------------------------------------------------------------
CREATE TABLE course (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    course_code VARCHAR(15) NOT NULL UNIQUE,
    course_name VARCHAR(120) NOT NULL,
    credits INT NOT NULL CHECK (credits BETWEEN 1 AND 8),
    course_level VARCHAR(30) NOT NULL DEFAULT 'Undergraduate',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_course_dept FOREIGN KEY (department_id) 
        REFERENCES department(department_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 5. SEMESTER TABLE
-- ------------------------------------------------------------
CREATE TABLE semester (
    semester_id INT AUTO_INCREMENT PRIMARY KEY,
    semester_code VARCHAR(20) NOT NULL UNIQUE,
    semester_name VARCHAR(50) NOT NULL,
    academic_year VARCHAR(15) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_sem_dates CHECK (start_date < end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 6. SECTION TABLE
-- ------------------------------------------------------------
CREATE TABLE section (
    section_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT NOT NULL,
    semester_id INT NOT NULL,
    faculty_id INT NULL,
    section_name VARCHAR(30) NOT NULL,
    capacity INT NOT NULL DEFAULT 30 CHECK (capacity > 0),
    room_no VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_section_course_sem UNIQUE (course_id, semester_id, section_name),
    CONSTRAINT fk_section_course FOREIGN KEY (course_id) 
        REFERENCES course(course_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_section_sem FOREIGN KEY (semester_id) 
        REFERENCES semester(semester_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_section_faculty FOREIGN KEY (faculty_id) 
        REFERENCES faculty(faculty_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 7. STUDENT TABLE
-- ------------------------------------------------------------
CREATE TABLE student (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    reg_number VARCHAR(20) NOT NULL UNIQUE,
    programme_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    dob DATE NOT NULL,
    gender VARCHAR(15) NOT NULL,
    admission_date DATE NOT NULL,
    current_semester INT NOT NULL DEFAULT 1 CHECK (current_semester BETWEEN 1 AND 10),
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive', 'Suspended', 'Graduated')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_student_prog FOREIGN KEY (programme_id) 
        REFERENCES programme(programme_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 8. GUARDIAN TABLE
-- ------------------------------------------------------------
CREATE TABLE guardian (
    guardian_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    guardian_name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_guardian_student FOREIGN KEY (student_id) 
        REFERENCES student(student_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 9. REGISTRATION TABLE
-- ------------------------------------------------------------
CREATE TABLE registration (
    registration_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    semester_id INT NOT NULL,
    section_id INT NOT NULL,
    registration_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Enrolled' CHECK (status IN ('Enrolled', 'Dropped', 'Completed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_student_course_semester UNIQUE (student_id, course_id, semester_id),
    CONSTRAINT fk_reg_student FOREIGN KEY (student_id) 
        REFERENCES student(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reg_course FOREIGN KEY (course_id) 
        REFERENCES course(course_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reg_sem FOREIGN KEY (semester_id) 
        REFERENCES semester(semester_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reg_section FOREIGN KEY (section_id) 
        REFERENCES section(section_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 10. ATTENDANCE TABLE
-- ------------------------------------------------------------
CREATE TABLE attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    registration_id INT NOT NULL,
    attendance_date DATE NOT NULL,
    status VARCHAR(15) NOT NULL CHECK (status IN ('Present', 'Absent', 'Excused')),
    remarks VARCHAR(255),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_reg_date UNIQUE (registration_id, attendance_date),
    CONSTRAINT fk_att_reg FOREIGN KEY (registration_id) 
        REFERENCES registration(registration_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 11. EXAMINATION TABLE
-- ------------------------------------------------------------
CREATE TABLE examination (
    exam_id INT AUTO_INCREMENT PRIMARY KEY,
    registration_id INT NOT NULL,
    exam_type VARCHAR(30) NOT NULL CHECK (exam_type IN ('Mid-Term', 'End-Term', 'Quiz', 'Assignment', 'Lab-Exam')),
    exam_date DATE NOT NULL,
    max_marks DECIMAL(5,2) NOT NULL DEFAULT 100.00 CHECK (max_marks > 0),
    marks_obtained DECIMAL(5,2) NOT NULL CHECK (marks_obtained >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_marks_bounds CHECK (marks_obtained <= max_marks),
    CONSTRAINT fk_exam_reg FOREIGN KEY (registration_id) 
        REFERENCES registration(registration_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 12. GRADE TABLE (Populated automatically by trigger)
-- ------------------------------------------------------------
CREATE TABLE grade (
    grade_id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL UNIQUE,
    percentage DECIMAL(5,2) NOT NULL,
    letter_grade VARCHAR(5) NOT NULL,
    grade_point DECIMAL(3,1) NOT NULL,
    remarks VARCHAR(50),
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_grade_exam FOREIGN KEY (exam_id) 
        REFERENCES examination(exam_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 13. FEE_BILL TABLE
-- ------------------------------------------------------------
CREATE TABLE fee_bill (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    bill_number VARCHAR(30) NOT NULL UNIQUE,
    student_id INT NOT NULL,
    semester_id INT NOT NULL,
    fee_type VARCHAR(50) NOT NULL DEFAULT 'Tuition Fee',
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    due_date DATE NOT NULL,
    issue_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Unpaid' CHECK (status IN ('Unpaid', 'Partially Paid', 'Paid')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bill_student FOREIGN KEY (student_id) 
        REFERENCES student(student_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_bill_sem FOREIGN KEY (semester_id) 
        REFERENCES semester(semester_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 14. PAYMENT TABLE
-- ------------------------------------------------------------
CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    receipt_number VARCHAR(30) NOT NULL UNIQUE,
    bill_id INT NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL CHECK (amount_paid > 0),
    payment_date DATE NOT NULL,
    payment_mode VARCHAR(30) NOT NULL,
    transaction_ref VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pay_bill FOREIGN KEY (bill_id) 
        REFERENCES fee_bill(bill_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 15. USER_ACCOUNT TABLE
-- ------------------------------------------------------------
CREATE TABLE user_account (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('Admin', 'Faculty', 'Student')),
    reference_id INT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Indexes for performance on frequently queried foreign keys & filters
CREATE INDEX idx_student_reg ON student(reg_number);
CREATE INDEX idx_student_prog ON student(programme_id);
CREATE INDEX idx_course_code ON course(course_code);
CREATE INDEX idx_reg_lookup ON registration(student_id, semester_id);
CREATE INDEX idx_att_reg ON attendance(registration_id);
CREATE INDEX idx_exam_reg ON examination(registration_id);
CREATE INDEX idx_bill_student ON fee_bill(student_id, status);
CREATE INDEX idx_payment_bill ON payment(bill_id);
