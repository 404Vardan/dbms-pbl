-- ============================================================
-- Student & College Management System (SCMS)
-- Database: scms_db
-- Author: Vardan Desai (25WU0104029) | Woxsen University
-- SQL Analytical and Reporting Views
-- ============================================================

USE scms_db;

-- ------------------------------------------------------------
-- VIEW 1: v_section_occupancy
-- Tracks section capacities, current active enrollments, and seat availability.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS v_section_occupancy;
CREATE VIEW v_section_occupancy AS
SELECT 
    sec.section_id,
    sec.section_name,
    c.course_code,
    c.course_name,
    sem.semester_name,
    IFNULL(CONCAT(f.first_name, ' ', f.last_name), 'Unassigned') AS faculty_name,
    sec.room_no,
    sec.capacity,
    COUNT(CASE WHEN r.status = 'Enrolled' THEN 1 END) AS enrolled_count,
    (sec.capacity - COUNT(CASE WHEN r.status = 'Enrolled' THEN 1 END)) AS available_seats,
    ROUND((COUNT(CASE WHEN r.status = 'Enrolled' THEN 1 END) / sec.capacity) * 100.0, 1) AS occupancy_pct
FROM section sec
JOIN course c ON sec.course_id = c.course_id
JOIN semester sem ON sec.semester_id = sem.semester_id
LEFT JOIN faculty f ON sec.faculty_id = f.faculty_id
LEFT JOIN registration r ON sec.section_id = r.section_id
GROUP BY 
    sec.section_id, sec.section_name, c.course_code, c.course_name, 
    sem.semester_name, f.first_name, f.last_name, sec.room_no, sec.capacity;


-- ------------------------------------------------------------
-- VIEW 2: v_attendance_summary
-- Aggregates student attendance counts and attendance percentages per course.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS v_attendance_summary;
CREATE VIEW v_attendance_summary AS
SELECT 
    r.registration_id,
    s.student_id,
    s.reg_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.course_code,
    c.course_name,
    sem.semester_name,
    sec.section_name,
    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS present_count,
    SUM(CASE WHEN a.status = 'Absent' THEN 1 ELSE 0 END) AS absent_count,
    SUM(CASE WHEN a.status = 'Excused' THEN 1 ELSE 0 END) AS excused_count,
    ROUND(
        IFNULL(
            (SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) / NULLIF(COUNT(a.attendance_id), 0)) * 100.0,
            0.0
        ), 2
    ) AS attendance_pct
FROM registration r
JOIN student s ON r.student_id = s.student_id
JOIN course c ON r.course_id = c.course_id
JOIN semester sem ON r.semester_id = sem.semester_id
JOIN section sec ON r.section_id = sec.section_id
LEFT JOIN attendance a ON r.registration_id = a.registration_id
WHERE r.status = 'Enrolled'
GROUP BY 
    r.registration_id, s.student_id, s.reg_number, s.first_name, 
    s.last_name, c.course_code, c.course_name, sem.semester_name, sec.section_name;


-- ------------------------------------------------------------
-- VIEW 3: v_exam_details
-- Comprehensive details of examinations with trigger-computed grades.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS v_exam_details;
CREATE VIEW v_exam_details AS
SELECT 
    e.exam_id,
    s.reg_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.course_code,
    c.course_name,
    sem.semester_name,
    e.exam_type,
    e.exam_date,
    e.max_marks,
    e.marks_obtained,
    g.percentage,
    g.letter_grade,
    g.grade_point,
    g.remarks
FROM examination e
JOIN registration r ON e.registration_id = r.registration_id
JOIN student s ON r.student_id = s.student_id
JOIN course c ON r.course_id = c.course_id
JOIN semester sem ON r.semester_id = sem.semester_id
LEFT JOIN grade g ON e.exam_id = g.exam_id;


-- ------------------------------------------------------------
-- VIEW 4: v_result_analysis
-- Statistical summary for examination results across courses.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS v_result_analysis;
CREATE VIEW v_result_analysis AS
SELECT 
    c.course_code,
    c.course_name,
    sem.semester_name,
    e.exam_type,
    COUNT(e.exam_id) AS total_candidates,
    ROUND(AVG(e.marks_obtained), 2) AS avg_marks,
    MAX(e.marks_obtained) AS highest_marks,
    MIN(e.marks_obtained) AS lowest_marks,
    ROUND(
        SUM(CASE WHEN g.percentage >= 40.0 THEN 1 ELSE 0 END) / COUNT(e.exam_id) * 100.0, 
        1
    ) AS pass_pct
FROM examination e
JOIN registration r ON e.registration_id = r.registration_id
JOIN course c ON r.course_id = c.course_id
JOIN semester sem ON r.semester_id = sem.semester_id
LEFT JOIN grade g ON e.exam_id = g.exam_id
GROUP BY c.course_code, c.course_name, sem.semester_name, e.exam_type;


-- ------------------------------------------------------------
-- VIEW 5: v_student_academic_history
-- Full transcript style history for students across all registered courses.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS v_student_academic_history;
CREATE VIEW v_student_academic_history AS
SELECT 
    s.student_id,
    s.reg_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    p.prog_name,
    sem.semester_name,
    c.course_code,
    c.course_name,
    c.credits,
    r.status AS reg_status,
    e.exam_type,
    e.marks_obtained,
    e.max_marks,
    g.letter_grade,
    g.grade_point
FROM student s
JOIN programme p ON s.programme_id = p.programme_id
JOIN registration r ON s.student_id = r.student_id
JOIN course c ON r.course_id = c.course_id
JOIN semester sem ON r.semester_id = sem.semester_id
LEFT JOIN examination e ON r.registration_id = e.registration_id
LEFT JOIN grade g ON e.exam_id = g.exam_id;


-- ------------------------------------------------------------
-- VIEW 6: v_fee_dues
-- Detailed breakdown of individual fee bills and outstanding balances.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS v_fee_dues;
CREATE VIEW v_fee_dues AS
SELECT 
    b.bill_id,
    b.bill_number,
    s.reg_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    sem.semester_name,
    b.fee_type,
    b.amount AS bill_amount,
    IFNULL(SUM(p.amount_paid), 0.00) AS paid_amount,
    (b.amount - IFNULL(SUM(p.amount_paid), 0.00)) AS balance_due,
    b.due_date,
    b.status
FROM fee_bill b
JOIN student s ON b.student_id = s.student_id
JOIN semester sem ON b.semester_id = sem.semester_id
LEFT JOIN payment p ON b.bill_id = p.bill_id
GROUP BY 
    b.bill_id, b.bill_number, s.reg_number, s.first_name, 
    s.last_name, sem.semester_name, b.fee_type, b.amount, b.due_date, b.status;


-- ------------------------------------------------------------
-- VIEW 7: v_student_dues
-- Aggregated financial status per student.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS v_student_dues;
CREATE VIEW v_student_dues AS
SELECT 
    s.student_id,
    s.reg_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    p.prog_name,
    IFNULL(SUM(b.amount), 0.00) AS total_billed,
    IFNULL(SUM(paid.total_paid), 0.00) AS total_paid,
    (IFNULL(SUM(b.amount), 0.00) - IFNULL(SUM(paid.total_paid), 0.00)) AS total_outstanding_due,
    COUNT(CASE WHEN b.status <> 'Paid' THEN 1 END) AS active_bills_count
FROM student s
JOIN programme p ON s.programme_id = p.programme_id
LEFT JOIN fee_bill b ON s.student_id = b.student_id
LEFT JOIN (
    SELECT bill_id, SUM(amount_paid) AS total_paid
    FROM payment
    GROUP BY bill_id
) paid ON b.bill_id = paid.bill_id
GROUP BY s.student_id, s.reg_number, s.first_name, s.last_name, p.prog_name;


-- ------------------------------------------------------------
-- VIEW 8: v_department_summary
-- Academic workload and resource overview per department.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS v_department_summary;
CREATE VIEW v_department_summary AS
SELECT 
    d.department_id,
    d.dept_code,
    d.dept_name,
    COUNT(DISTINCT f.faculty_id) AS total_faculty,
    COUNT(DISTINCT p.programme_id) AS total_programmes,
    COUNT(DISTINCT c.course_id) AS total_courses,
    COUNT(DISTINCT s.student_id) AS total_students
FROM department d
LEFT JOIN faculty f ON d.department_id = f.department_id
LEFT JOIN programme p ON d.department_id = p.department_id
LEFT JOIN course c ON d.department_id = c.department_id
LEFT JOIN student s ON p.programme_id = s.programme_id
GROUP BY d.department_id, d.dept_code, d.dept_name;
