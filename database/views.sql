-- =============================================================================
-- SCMS — Analytical Views (MySQL 8.0+)
-- File : database/views.sql
-- Description : 6 Institutional SQL Analytical Views
-- =============================================================================

USE scms_db;

-- -----------------------------------------------------------------------------
-- 1. SECTION OCCUPANCY VIEW
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_section_occupancy;
CREATE VIEW v_section_occupancy AS
SELECT 
    s.section_id,
    s.semester_id,
    CONCAT(sm.academic_year, ' ', sm.term) AS semester_label,
    c.course_id,
    c.course_code,
    c.course_name,
    c.credits,
    c.course_type,
    d.dept_code,
    s.section_code,
    s.room_no,
    f.faculty_id,
    f.full_name AS faculty_name,
    s.capacity,
    COUNT(CASE WHEN r.status != 'Dropped' THEN r.registration_id END) AS registered_count,
    s.capacity - COUNT(CASE WHEN r.status != 'Dropped' THEN r.registration_id END) AS remaining_seats,
    ROUND(100.0 * COUNT(CASE WHEN r.status != 'Dropped' THEN r.registration_id END) / s.capacity, 1) AS occupancy_pct,
    CASE WHEN COUNT(CASE WHEN r.status != 'Dropped' THEN r.registration_id END) >= s.capacity THEN 1 ELSE 0 END AS is_full
FROM section s
JOIN course c ON c.course_id = s.course_id
JOIN department d ON d.dept_id = c.dept_id
JOIN faculty f ON f.faculty_id = s.faculty_id
JOIN semester sm ON sm.semester_id = s.semester_id
LEFT JOIN registration r ON r.section_id = s.section_id
GROUP BY s.section_id, sm.semester_id, c.course_id, d.dept_id, f.faculty_id;

-- -----------------------------------------------------------------------------
-- 2. ATTENDANCE SUMMARY VIEW (Shortage Alert < 75%)
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_attendance_summary;
CREATE VIEW v_attendance_summary AS
SELECT 
    r.registration_id,
    r.student_id,
    st.reg_no,
    st.full_name AS student_name,
    p.programme_code,
    s.section_id,
    s.semester_id,
    CONCAT(sm.academic_year, ' ', sm.term) AS semester_label,
    c.course_code,
    c.course_name,
    s.section_code,
    s.faculty_id,
    f.full_name AS faculty_name,
    COUNT(a.attendance_id) AS total_classes,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS present_count,
    SUM(CASE WHEN a.status = 'Late' THEN 1 ELSE 0 END) AS late_count,
    SUM(CASE WHEN a.status = 'Absent' THEN 1 ELSE 0 END) AS absent_count,
    ROUND(100.0 * SUM(CASE WHEN a.status IN ('Present', 'Late') THEN 1 ELSE 0 END) / NULLIF(COUNT(a.attendance_id), 0), 1) AS attendance_pct,
    CASE 
        WHEN (100.0 * SUM(CASE WHEN a.status IN ('Present', 'Late') THEN 1 ELSE 0 END) / NULLIF(COUNT(a.attendance_id), 0)) < 75.0 
        THEN 1 ELSE 0 
    END AS is_shortage
FROM registration r
JOIN student st ON st.student_id = r.student_id
JOIN programme p ON p.programme_id = st.programme_id
JOIN section s ON s.section_id = r.section_id
JOIN course c ON c.course_id = s.course_id
JOIN faculty f ON f.faculty_id = s.faculty_id
JOIN semester sm ON sm.semester_id = s.semester_id
LEFT JOIN attendance a ON a.registration_id = r.registration_id
WHERE r.status != 'Dropped'
GROUP BY r.registration_id, st.student_id, p.programme_id, s.section_id, c.course_id, f.faculty_id, sm.semester_id;

-- -----------------------------------------------------------------------------
-- 3. EXAM DETAILS VIEW
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_exam_details;
CREATE VIEW v_exam_details AS
SELECT 
    e.exam_id,
    e.registration_id,
    e.exam_type,
    e.exam_date,
    e.max_marks,
    e.marks,
    ROUND(e.marks * 100.0 / e.max_marks, 2) AS percentage,
    g.grade_letter,
    g.grade_point,
    g.graded_on,
    r.student_id,
    st.reg_no,
    st.full_name AS student_name,
    s.section_id,
    s.section_code,
    s.semester_id,
    CONCAT(sm.academic_year, ' ', sm.term) AS semester_label,
    c.course_code,
    c.course_name,
    c.credits,
    s.faculty_id,
    f.full_name AS faculty_name
FROM examination e
JOIN registration r ON r.registration_id = e.registration_id
JOIN student st ON st.student_id = r.student_id
JOIN section s ON s.section_id = r.section_id
JOIN course c ON c.course_id = s.course_id
JOIN faculty f ON f.faculty_id = s.faculty_id
JOIN semester sm ON sm.semester_id = s.semester_id
LEFT JOIN grade g ON g.exam_id = e.exam_id;

-- -----------------------------------------------------------------------------
-- 4. RESULT ANALYSIS VIEW
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_result_analysis;
CREATE VIEW v_result_analysis AS
SELECT 
    s.section_id,
    s.semester_id,
    CONCAT(sm.academic_year, ' ', sm.term) AS semester_label,
    c.course_code,
    c.course_name,
    s.section_code,
    s.faculty_id,
    f.full_name AS faculty_name,
    e.exam_type,
    MIN(e.exam_date) AS exam_date,
    COUNT(e.exam_id) AS candidates,
    COUNT(e.marks) AS evaluated,
    ROUND(AVG(e.marks * 100.0 / e.max_marks), 2) AS average_pct,
    ROUND(MAX(e.marks * 100.0 / e.max_marks), 2) AS highest_pct,
    ROUND(MIN(e.marks * 100.0 / e.max_marks), 2) AS lowest_pct,
    SUM(CASE WHEN g.grade_letter != 'F' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN g.grade_letter = 'F' THEN 1 ELSE 0 END) AS failed,
    ROUND(100.0 * SUM(CASE WHEN g.grade_letter != 'F' THEN 1 ELSE 0 END) / NULLIF(COUNT(g.grade_id), 0), 1) AS pass_pct
FROM examination e
JOIN registration r ON r.registration_id = e.registration_id
JOIN section s ON s.section_id = r.section_id
JOIN course c ON c.course_id = s.course_id
JOIN faculty f ON f.faculty_id = s.faculty_id
JOIN semester sm ON sm.semester_id = s.semester_id
LEFT JOIN grade g ON g.exam_id = e.exam_id
WHERE r.status != 'Dropped'
GROUP BY s.section_id, c.course_id, f.faculty_id, sm.semester_id, e.exam_type;

-- -----------------------------------------------------------------------------
-- 5. STUDENT ACADEMIC HISTORY VIEW
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_student_academic_history;
CREATE VIEW v_student_academic_history AS
SELECT 
    r.registration_id,
    r.student_id,
    st.reg_no,
    st.full_name AS student_name,
    p.programme_code,
    p.programme_name,
    sm.semester_id,
    CONCAT(sm.academic_year, ' ', sm.term) AS semester_label,
    sm.start_date AS semester_start,
    c.course_code,
    c.course_name,
    c.credits,
    s.section_id,
    s.section_code,
    f.full_name AS faculty_name,
    r.status AS registration_status,
    MAX(CASE WHEN e.exam_type = 'Mid-Term' THEN e.marks END) AS mid_term_marks,
    MAX(CASE WHEN e.exam_type = 'End-Term' THEN e.marks END) AS end_term_marks,
    MAX(CASE WHEN e.exam_type = 'End-Term' THEN g.grade_letter END) AS final_grade,
    MAX(CASE WHEN e.exam_type = 'End-Term' THEN g.grade_point END) AS final_grade_point,
    ROUND(100.0 * (
        SELECT COUNT(*) FROM attendance a 
        WHERE a.registration_id = r.registration_id AND a.status IN ('Present', 'Late')
    ) / NULLIF((SELECT COUNT(*) FROM attendance a WHERE a.registration_id = r.registration_id), 0), 1) AS attendance_pct
FROM registration r
JOIN student st ON st.student_id = r.student_id
JOIN programme p ON p.programme_id = st.programme_id
JOIN section s ON s.section_id = r.section_id
JOIN course c ON c.course_id = s.course_id
JOIN faculty f ON f.faculty_id = s.faculty_id
JOIN semester sm ON sm.semester_id = s.semester_id
LEFT JOIN examination e ON e.registration_id = r.registration_id
LEFT JOIN grade g ON g.exam_id = e.exam_id
GROUP BY r.registration_id, st.student_id, p.programme_id, sm.semester_id, c.course_id, s.section_id, f.faculty_id;

-- -----------------------------------------------------------------------------
-- 6. FEE DUES & RECOVERY VIEWS
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_fee_dues;
CREATE VIEW v_fee_dues AS
SELECT 
    b.bill_id,
    b.student_id,
    st.reg_no,
    st.full_name AS student_name,
    st.status AS student_status,
    p.programme_code,
    b.semester_id,
    CONCAT(sm.academic_year, ' ', sm.term) AS semester_label,
    b.bill_date,
    b.due_date,
    b.amount_due,
    COALESCE(SUM(py.amount_paid), 0) AS amount_paid,
    b.amount_due - COALESCE(SUM(py.amount_paid), 0) AS balance,
    b.status,
    COUNT(py.payment_id) AS payment_count,
    MAX(py.payment_date) AS last_payment_date,
    CASE WHEN b.due_date < CURRENT_DATE() AND (b.amount_due - COALESCE(SUM(py.amount_paid), 0)) > 0 THEN 1 ELSE 0 END AS is_overdue,
    CASE WHEN (b.amount_due - COALESCE(SUM(py.amount_paid), 0)) > 0 THEN GREATEST(DATEDIFF(CURRENT_DATE(), b.due_date), 0) ELSE 0 END AS days_overdue
FROM fee_bill b
JOIN student st ON st.student_id = b.student_id
JOIN programme p ON p.programme_id = st.programme_id
JOIN semester sm ON sm.semester_id = b.semester_id
LEFT JOIN payment py ON py.bill_id = b.bill_id
GROUP BY b.bill_id, st.student_id, p.programme_id, sm.semester_id;

DROP VIEW IF EXISTS v_student_dues;
CREATE VIEW v_student_dues AS
SELECT 
    student_id,
    reg_no,
    student_name,
    student_status,
    programme_code,
    COUNT(*) AS bills,
    SUM(amount_due) AS total_billed,
    SUM(amount_paid) AS total_paid,
    SUM(balance) AS outstanding,
    SUM(CASE WHEN is_overdue = 1 THEN 1 ELSE 0 END) AS overdue_bills,
    MAX(days_overdue) AS max_days_overdue
FROM v_fee_dues
GROUP BY student_id, reg_no, student_name, student_status, programme_code;

-- -----------------------------------------------------------------------------
-- 7. DEPARTMENT SUMMARY VIEW
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_department_summary;
CREATE VIEW v_department_summary AS
SELECT 
    d.dept_id,
    d.dept_code,
    d.dept_name,
    d.office_email,
    (SELECT COUNT(*) FROM programme pr WHERE pr.dept_id = d.dept_id) AS programmes,
    (SELECT COUNT(*) FROM programme pr WHERE pr.dept_id = d.dept_id AND pr.status = 'Active') AS active_programmes,
    (SELECT COUNT(*) FROM faculty f WHERE f.dept_id = d.dept_id AND f.status = 'Active') AS faculty_count,
    (SELECT COUNT(*) FROM course c WHERE c.dept_id = d.dept_id AND c.status = 'Active') AS course_count,
    (SELECT COUNT(*) FROM student st JOIN programme pr ON pr.programme_id = st.programme_id WHERE pr.dept_id = d.dept_id) AS total_students,
    (SELECT COUNT(*) FROM student st JOIN programme pr ON pr.programme_id = st.programme_id WHERE pr.dept_id = d.dept_id AND st.status = 'Active') AS active_students
FROM department d;
