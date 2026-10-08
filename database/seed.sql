-- ============================================================
-- Student & College Management System (SCMS)
-- Database: scms_db
-- Author: Vardan Desai (25WU0104029) | Woxsen University
-- Seed Data: Academic entities, registrations, exams, dues & demo users
-- ============================================================

USE scms_db;

-- ------------------------------------------------------------
-- 1. DEPARTMENTS (5 Academic Departments)
-- ------------------------------------------------------------
INSERT INTO department (department_id, dept_code, dept_name, building, established_year) VALUES
(1, 'CSE', 'Computer Science & Engineering', 'Aryabhata Academic Block', 2014),
(2, 'ECE', 'Electronics & Communication Engineering', 'Ramanujan Tech Wing', 2015),
(3, 'MECH', 'Mechanical Engineering', 'Visvesvaraya Innovation Center', 2014),
(4, 'MGMT', 'School of Business Management', 'Chanakya Management Complex', 2016),
(5, 'DES', 'School of Art & Design', 'Da Vinci Design Studio', 2018)
ON DUPLICATE KEY UPDATE dept_name=VALUES(dept_name);

-- ------------------------------------------------------------
-- 2. PROGRAMMES (6 Degree Programmes)
-- ------------------------------------------------------------
INSERT INTO programme (programme_id, department_id, prog_code, prog_name, degree_type, duration_years, total_semesters) VALUES
(1, 1, 'BTECH-AIML', 'B.Tech Computer Science & Engineering (AI & ML)', 'B.Tech', 4, 8),
(2, 1, 'BTECH-DS', 'B.Tech Computer Science (Data Science)', 'B.Tech', 4, 8),
(3, 2, 'BTECH-ECE', 'B.Tech Electronics & Communication Engineering', 'B.Tech', 4, 8),
(4, 3, 'BTECH-MECH', 'B.Tech Mechanical & Robotics Engineering', 'B.Tech', 4, 8),
(5, 4, 'BBA-FIN', 'Bachelor of Business Administration (Finance & Analytics)', 'BBA', 3, 6),
(6, 5, 'BDES-IND', 'Bachelor of Design (Industrial & Product Design)', 'B.Des', 4, 8)
ON DUPLICATE KEY UPDATE prog_name=VALUES(prog_name);

-- ------------------------------------------------------------
-- 3. FACULTY (12 Faculty Members)
-- ------------------------------------------------------------
INSERT INTO faculty (faculty_id, employee_id, department_id, first_name, last_name, email, phone, designation, joining_date, is_active) VALUES
(1, 'EMP0101', 1, 'Kavitha', 'Reddy', 'kavitha.reddy@woxsen.edu.in', '9876500101', 'Professor', '2016-07-01', TRUE),
(2, 'EMP0102', 1, 'Srinivas', 'Rao', 'srinivas.rao@woxsen.edu.in', '9876500102', 'Associate Professor', '2018-01-15', TRUE),
(3, 'EMP0103', 1, 'Ananya', 'Sharma', 'ananya.sharma@woxsen.edu.in', '9876500103', 'Assistant Professor', '2020-08-10', TRUE),
(4, 'EMP0104', 1, 'Vikram', 'Malhotra', 'vikram.malhotra@woxsen.edu.in', '9876500104', 'Associate Professor', '2019-06-20', TRUE),
(5, 'EMP0201', 2, 'Rajesh', 'Verma', 'rajesh.verma@woxsen.edu.in', '9876500201', 'Professor', '2015-08-01', TRUE),
(6, 'EMP0202', 2, 'Pooja', 'Nair', 'pooja.nair@woxsen.edu.in', '9876500202', 'Assistant Professor', '2021-02-01', TRUE),
(7, 'EMP0301', 3, 'Mahesh', 'Kulkarni', 'mahesh.kulkarni@woxsen.edu.in', '9876500301', 'Professor', '2014-09-15', TRUE),
(8, 'EMP0302', 3, 'Deepak', 'Patel', 'deepak.patel@woxsen.edu.in', '9876500302', 'Assistant Professor', '2022-07-15', TRUE),
(9, 'EMP0401', 4, 'Sunita', 'Menon', 'sunita.menon@woxsen.edu.in', '9876500401', 'Professor', '2017-06-01', TRUE),
(10, 'EMP0402', 4, 'Arun', 'Choudhary', 'arun.choudhary@woxsen.edu.in', '9876500402', 'Associate Professor', '2019-11-10', TRUE),
(11, 'EMP0501', 5, 'Meera', 'Sen', 'meera.sen@woxsen.edu.in', '9876500501', 'Associate Professor', '2018-09-01', TRUE),
(12, 'EMP0502', 5, 'Rohan', 'Iyer', 'rohan.iyer@woxsen.edu.in', '9876500502', 'Assistant Professor', '2023-01-10', TRUE)
ON DUPLICATE KEY UPDATE first_name=VALUES(first_name);

-- ------------------------------------------------------------
-- 4. COURSES (12 Courses)
-- ------------------------------------------------------------
INSERT INTO course (course_id, department_id, course_code, course_name, credits, course_level, description) VALUES
(1, 1, 'CSE201', 'Database Management Systems', 4, 'Undergraduate', 'Relational data modeling, SQL, Normalization, ACID Transactions, Indexing'),
(2, 1, 'CSE202', 'Data Structures & Algorithms', 4, 'Undergraduate', 'Linear & non-linear structures, algorithmic complexity, graph theory'),
(3, 1, 'CSE301', 'Machine Learning Foundations', 4, 'Undergraduate', 'Supervised and unsupervised learning, optimization, model evaluation'),
(4, 1, 'CSE302', 'Artificial Intelligence & Neural Nets', 3, 'Undergraduate', 'Search heuristics, knowledge representation, deep learning architectures'),
(5, 1, 'CSE205', 'Object Oriented Programming with Java', 3, 'Undergraduate', 'OOP design principles, inheritance, concurrency, JDBC'),
(6, 2, 'ECE201', 'Digital System Design & HDL', 4, 'Undergraduate', 'Logic gates, combinational and sequential circuit design using Verilog'),
(7, 2, 'ECE301', 'Microprocessors & Embedded Systems', 3, 'Undergraduate', 'ARM architecture, peripheral interfacing, real-time operating concepts'),
(8, 3, 'MEC201', 'Thermodynamics & Heat Transfer', 4, 'Undergraduate', 'First and second laws, cycles, conduction and convection mechanics'),
(9, 3, 'MEC301', 'Robotics & Automation', 3, 'Undergraduate', 'Kinematics, actuators, industrial sensors, robot path planning'),
(10, 4, 'MGT101', 'Financial Accounting & Management', 3, 'Undergraduate', 'Balance sheets, cash flows, financial ratios, corporate budgeting'),
(11, 4, 'MGT201', 'Marketing Principles & Strategy', 3, 'Undergraduate', 'Consumer behavior, marketing mix, digital advertising metrics'),
(12, 5, 'DES101', 'Design Thinking & Visual Communication', 3, 'Undergraduate', 'Human-centered design, sketching, prototyping and ergonomic analysis')
ON DUPLICATE KEY UPDATE course_name=VALUES(course_name);

-- ------------------------------------------------------------
-- 5. SEMESTERS
-- ------------------------------------------------------------
INSERT INTO semester (semester_id, semester_code, semester_name, academic_year, start_date, end_date, is_active) VALUES
(1, 'FA2025', 'Fall 2025', '2025-2026', '2025-08-01', '2025-12-15', FALSE),
(2, 'SP2026', 'Spring 2026', '2025-2026', '2026-01-05', '2026-05-20', TRUE),
(3, 'FA2026', 'Fall 2026', '2026-2027', '2026-08-03', '2026-12-18', FALSE)
ON DUPLICATE KEY UPDATE semester_name=VALUES(semester_name);

-- ------------------------------------------------------------
-- 6. SECTIONS (Includes 'Rhinos' section for Woxsen PBL)
-- ------------------------------------------------------------
INSERT INTO section (section_id, course_id, semester_id, faculty_id, section_name, capacity, room_no) VALUES
(1, 1, 2, 1, 'Rhinos', 30, 'LH-101'),
(2, 1, 2, 2, 'Tigers', 30, 'LH-102'),
(3, 2, 2, 3, 'Rhinos', 30, 'LH-103'),
(4, 2, 2, 4, 'Falcons', 30, 'LH-104'),
(5, 3, 2, 1, 'Section-A', 25, 'CS-Lab1'),
(6, 4, 2, 3, 'Section-A', 25, 'AI-Lab'),
(7, 6, 2, 5, 'Section-A', 30, 'EC-201'),
(8, 8, 2, 7, 'Section-A', 30, 'ME-301'),
(9, 10, 2, 9, 'Section-A', 35, 'MB-101'),
(10, 12, 2, 11, 'Section-A', 20, 'Studio-A')
ON DUPLICATE KEY UPDATE section_name=VALUES(section_name);

-- ------------------------------------------------------------
-- 7. STUDENTS (25 Fictional Students, including Vardan Desai)
-- ------------------------------------------------------------
INSERT INTO student (student_id, reg_number, programme_id, first_name, last_name, email, phone, dob, gender, admission_date, current_semester, status) VALUES
(1, '25WU0104029', 1, 'Vardan', 'Desai', 'vardan.desai@woxsen.edu.in', '9848011001', '2004-05-14', 'Male', '2024-07-20', 2, 'Active'),
(2, '25WU0104001', 1, 'Aarav', 'Gupta', 'aarav.gupta@woxsen.edu.in', '9848011002', '2004-03-12', 'Male', '2024-07-20', 2, 'Active'),
(3, '25WU0104002', 1, 'Aditi', 'Verma', 'aditi.verma@woxsen.edu.in', '9848011003', '2004-08-25', 'Female', '2024-07-20', 2, 'Active'),
(4, '25WU0104003', 1, 'Aniruddh', 'Rao', 'aniruddh.rao@woxsen.edu.in', '9848011004', '2004-11-09', 'Male', '2024-07-20', 2, 'Active'),
(5, '25WU0104004', 1, 'Divya', 'Nath', 'divya.nath@woxsen.edu.in', '9848011005', '2004-01-30', 'Female', '2024-07-20', 2, 'Active'),
(6, '25WU0104005', 1, 'Ishaan', 'Joshi', 'ishaan.joshi@woxsen.edu.in', '9848011006', '2004-06-18', 'Male', '2024-07-20', 2, 'Active'),
(7, '25WU0104006', 1, 'Kavya', 'Reddy', 'kavya.reddy@woxsen.edu.in', '9848011007', '2004-09-03', 'Female', '2024-07-20', 2, 'Active'),
(8, '25WU0104007', 1, 'Manish', 'Kumar', 'manish.kumar@woxsen.edu.in', '9848011008', '2004-12-14', 'Male', '2024-07-20', 2, 'Active'),
(9, '25WU0104008', 2, 'Neha', 'Bhatia', 'neha.bhatia@woxsen.edu.in', '9848011009', '2004-04-21', 'Female', '2024-07-21', 2, 'Active'),
(10, '25WU0104009', 2, 'Pranav', 'Shah', 'pranav.shah@woxsen.edu.in', '9848011010', '2004-07-11', 'Male', '2024-07-21', 2, 'Active'),
(11, '25WU0104010', 2, 'Priya', 'Sundaram', 'priya.sundaram@woxsen.edu.in', '9848011011', '2004-10-05', 'Female', '2024-07-21', 2, 'Active'),
(12, '25WU0104011', 2, 'Rahul', 'Nair', 'rahul.nair@woxsen.edu.in', '9848011012', '2004-02-17', 'Male', '2024-07-21', 2, 'Active'),
(13, '25WU0104012', 3, 'Rhea', 'Pillai', 'rhea.pillai@woxsen.edu.in', '9848011013', '2004-05-29', 'Female', '2024-07-22', 2, 'Active'),
(14, '25WU0104013', 3, 'Rohit', 'Chopra', 'rohit.chopra@woxsen.edu.in', '9848011014', '2004-08-16', 'Male', '2024-07-22', 2, 'Active'),
(15, '25WU0104014', 3, 'Sai', 'Kiran', 'sai.kiran@woxsen.edu.in', '9848011015', '2004-11-23', 'Male', '2024-07-22', 2, 'Active'),
(16, '25WU0104015', 3, 'Sakshi', 'Agarwal', 'sakshi.agarwal@woxsen.edu.in', '9848011016', '2004-03-08', 'Female', '2024-07-22', 2, 'Active'),
(17, '25WU0104016', 4, 'Siddharth', 'Mehta', 'siddharth.mehta@woxsen.edu.in', '9848011017', '2004-06-25', 'Male', '2024-07-23', 2, 'Active'),
(18, '25WU0104017', 4, 'Sneha', 'Roy', 'sneha.roy@woxsen.edu.in', '9848011018', '2004-09-19', 'Female', '2024-07-23', 2, 'Active'),
(19, '25WU0104018', 4, 'Tanvi', 'Pandey', 'tanvi.pandey@woxsen.edu.in', '9848011019', '2004-12-31', 'Female', '2024-07-23', 2, 'Active'),
(20, '25WU0104019', 4, 'Utkarsh', 'Saxena', 'utkarsh.saxena@woxsen.edu.in', '9848011020', '2004-04-14', 'Male', '2024-07-23', 2, 'Active'),
(21, '25WU0104020', 5, 'Varun', 'Teja', 'varun.teja@woxsen.edu.in', '9848011021', '2004-07-02', 'Male', '2024-07-24', 2, 'Active'),
(22, '25WU0104021', 5, 'Yash', 'Singhania', 'yash.singhania@woxsen.edu.in', '9848011022', '2004-10-18', 'Male', '2024-07-24', 2, 'Active'),
(23, '25WU0104022', 6, 'Zara', 'Khan', 'zara.khan@woxsen.edu.in', '9848011023', '2004-01-12', 'Female', '2024-07-24', 2, 'Active'),
(24, '25WU0104023', 6, 'Ayaan', 'Ali', 'ayaan.ali@woxsen.edu.in', '9848011024', '2004-05-06', 'Male', '2024-07-24', 2, 'Active'),
(25, '25WU0104024', 1, 'Ritvik', 'Sen', 'ritvik.sen@woxsen.edu.in', '9848011025', '2003-08-14', 'Male', '2023-07-20', 4, 'Active')
ON DUPLICATE KEY UPDATE first_name=VALUES(first_name);

-- ------------------------------------------------------------
-- 8. GUARDIANS (Corresponding Guardian Records)
-- ------------------------------------------------------------
INSERT INTO guardian (guardian_id, student_id, guardian_name, relationship, phone, email, address) VALUES
(1, 1, 'Sanjay Desai', 'Father', '9988001001', 'sanjay.desai@gmail.com', 'Plot 45, Jubilee Hills, Hyderabad'),
(2, 2, 'Ramesh Gupta', 'Father', '9988001002', 'ramesh.gupta@gmail.com', 'Flat 302, Gachibowli, Hyderabad'),
(3, 3, 'Sunita Verma', 'Mother', '9988001003', 'sunita.verma@gmail.com', 'B-12, Kondapur, Hyderabad'),
(4, 4, 'Kishore Rao', 'Father', '9988001004', 'kishore.rao@gmail.com', 'H-90, Madhapur, Hyderabad'),
(5, 5, 'Anuradha Nath', 'Mother', '9988001005', 'anuradha.nath@gmail.com', 'Plot 10, Banjara Hills, Hyderabad'),
(6, 6, 'Prakash Joshi', 'Father', '9988001006', 'prakash.joshi@gmail.com', 'Flat 101, Hitec City, Hyderabad'),
(7, 7, 'Venkat Reddy', 'Father', '9988001007', 'venkat.reddy@gmail.com', 'Road 12, Banjara Hills, Hyderabad'),
(8, 8, 'Ajay Kumar', 'Father', '9988001008', 'ajay.kumar@gmail.com', 'Sector 4, Begumpet, Hyderabad'),
(9, 9, 'Mohan Bhatia', 'Father', '9988001009', 'mohan.bhatia@gmail.com', 'Flat 501, Somajiguda, Hyderabad'),
(10, 10, 'Nitin Shah', 'Father', '9988001010', 'nitin.shah@gmail.com', 'C-15, Secunderabad'),
(11, 25, 'Arindam Sen', 'Father', '9988001025', 'arindam.sen@gmail.com', 'Plot 88, Kothaguda, Hyderabad')
ON DUPLICATE KEY UPDATE guardian_name=VALUES(guardian_name);

-- ------------------------------------------------------------
-- 9. REGISTRATIONS (Students enrolled in Course / Semester / Section)
-- ------------------------------------------------------------
INSERT INTO registration (registration_id, student_id, course_id, semester_id, section_id, registration_date, status) VALUES
-- Vardan Desai (ID: 1)
(1, 1, 1, 2, 1, '2026-01-08', 'Enrolled'),
(2, 1, 2, 2, 3, '2026-01-08', 'Enrolled'),
(3, 1, 3, 2, 5, '2026-01-08', 'Enrolled'),
-- Aarav Gupta (ID: 2)
(4, 2, 1, 2, 1, '2026-01-08', 'Enrolled'),
(5, 2, 2, 2, 3, '2026-01-08', 'Enrolled'),
-- Aditi Verma (ID: 3)
(6, 3, 1, 2, 1, '2026-01-08', 'Enrolled'),
(7, 3, 2, 2, 3, '2026-01-08', 'Enrolled'),
-- Aniruddh Rao (ID: 4)
(8, 4, 1, 2, 1, '2026-01-09', 'Enrolled'),
(9, 4, 2, 2, 3, '2026-01-09', 'Enrolled'),
-- Divya Nath (ID: 5)
(10, 5, 1, 2, 1, '2026-01-09', 'Enrolled'),
-- Ishaan Joshi (ID: 6)
(11, 6, 1, 2, 2, '2026-01-09', 'Enrolled'),
-- Kavya Reddy (ID: 7)
(12, 7, 1, 2, 2, '2026-01-10', 'Enrolled'),
-- Manish Kumar (ID: 8)
(13, 8, 1, 2, 2, '2026-01-10', 'Enrolled'),
-- Neha Bhatia (ID: 9)
(14, 9, 2, 2, 4, '2026-01-10', 'Enrolled'),
-- Pranav Shah (ID: 10)
(15, 10, 2, 2, 4, '2026-01-10', 'Enrolled')
ON DUPLICATE KEY UPDATE status=VALUES(status);

-- ------------------------------------------------------------
-- 10. ATTENDANCE RECORDS (Past dates in Spring 2026)
-- ------------------------------------------------------------
INSERT INTO attendance (attendance_id, registration_id, attendance_date, status, remarks) VALUES
-- Vardan Desai in DBMS (Reg ID: 1)
(1, 1, '2026-01-15', 'Present', 'Regular class lecture'),
(2, 1, '2026-01-22', 'Present', 'ER modeling hands-on'),
(3, 1, '2026-01-29', 'Present', 'Normalization lab session'),
(4, 1, '2026-02-05', 'Present', 'SQL Constraints workshop'),
(5, 1, '2026-02-12', 'Absent',  'Medical leave notified'),
(6, 1, '2026-02-19', 'Present', 'Indexing and performance lab'),
-- Aarav Gupta in DBMS (Reg ID: 4)
(7, 4, '2026-01-15', 'Present', 'Regular class lecture'),
(8, 4, '2026-01-22', 'Absent',  'Unexcused absence'),
(9, 4, '2026-01-29', 'Present', 'Normalization lab session'),
(10, 4, '2026-02-05', 'Present', 'SQL Constraints workshop'),
-- Aditi Verma in DBMS (Reg ID: 6)
(11, 6, '2026-01-15', 'Present', 'Regular class lecture'),
(12, 6, '2026-01-22', 'Present', 'ER modeling hands-on'),
(13, 6, '2026-01-29', 'Present', 'Normalization lab session'),
(14, 6, '2026-02-05', 'Present', 'SQL Constraints workshop'),
-- Vardan Desai in DSA (Reg ID: 2)
(15, 2, '2026-01-16', 'Present', 'Trees traversal algorithms'),
(16, 2, '2026-01-23', 'Present', 'Heap data structure'),
(17, 2, '2026-01-30', 'Present', 'Graph algorithms BFS/DFS')
ON DUPLICATE KEY UPDATE status=VALUES(status);

-- ------------------------------------------------------------
-- 11. EXAMINATIONS
-- ------------------------------------------------------------
INSERT INTO examination (exam_id, registration_id, exam_type, exam_date, max_marks, marks_obtained) VALUES
(1, 1, 'Mid-Term', '2026-02-20', 100.00, 92.50), -- Vardan DBMS Mid-Term (A+ -> 10)
(2, 1, 'Quiz',     '2026-02-10', 25.00,  23.00), -- Vardan DBMS Quiz (92% -> A+ -> 10)
(3, 4, 'Mid-Term', '2026-02-20', 100.00, 84.00), -- Aarav DBMS Mid-Term (A -> 9)
(4, 6, 'Mid-Term', '2026-02-20', 100.00, 76.50), -- Aditi DBMS Mid-Term (B+ -> 8)
(5, 8, 'Mid-Term', '2026-02-20', 100.00, 65.00), -- Aniruddh DBMS Mid-Term (B -> 7)
(6, 10, 'Mid-Term', '2026-02-20', 100.00, 54.00),-- Divya DBMS Mid-Term (C -> 6)
(7, 2, 'Mid-Term', '2026-02-22', 100.00, 88.00), -- Vardan DSA Mid-Term (A -> 9)
(8, 5, 'Mid-Term', '2026-02-22', 100.00, 42.00)  -- Aarav DSA Mid-Term (D -> 5)
ON DUPLICATE KEY UPDATE marks_obtained=VALUES(marks_obtained);

-- ------------------------------------------------------------
-- 12. GRADES (Calculated matching trigger specification)
-- ------------------------------------------------------------
INSERT INTO grade (grade_id, exam_id, percentage, letter_grade, grade_point, remarks) VALUES
(1, 1, 92.50, 'A+', 10.0, 'Outstanding'),
(2, 2, 92.00, 'A+', 10.0, 'Outstanding'),
(3, 3, 84.00, 'A',   9.0, 'Excellent'),
(4, 4, 76.50, 'B+',  8.0, 'Very Good'),
(5, 5, 65.00, 'B',   7.0, 'Good'),
(6, 6, 54.00, 'C',   6.0, 'Average'),
(7, 7, 88.00, 'A',   9.0, 'Excellent'),
(8, 8, 42.00, 'D',   5.0, 'Pass')
ON DUPLICATE KEY UPDATE letter_grade=VALUES(letter_grade);

-- ------------------------------------------------------------
-- 13. FEE BILLS
-- ------------------------------------------------------------
INSERT INTO fee_bill (bill_id, bill_number, student_id, semester_id, fee_type, amount, due_date, issue_date, status) VALUES
(1, 'BILL-2026-001', 1, 2, 'Tuition Fee', 150000.00, '2026-02-28', '2026-01-05', 'Paid'),
(2, 'BILL-2026-002', 1, 2, 'Examination Fee', 5000.00, '2026-03-15', '2026-02-01', 'Unpaid'),
(3, 'BILL-2026-003', 2, 2, 'Tuition Fee', 150000.00, '2026-02-28', '2026-01-05', 'Partially Paid'),
(4, 'BILL-2026-004', 3, 2, 'Tuition Fee', 150000.00, '2026-02-28', '2026-01-05', 'Unpaid'),
(5, 'BILL-2026-005', 4, 2, 'Tuition Fee', 150000.00, '2026-02-28', '2026-01-05', 'Paid'),
(6, 'BILL-2026-006', 9, 2, 'Tuition Fee', 140000.00, '2026-02-28', '2026-01-05', 'Partially Paid'),
(7, 'BILL-2026-007', 13, 2, 'Tuition Fee', 135000.00, '2026-02-28', '2026-01-05', 'Paid')
ON DUPLICATE KEY UPDATE status=VALUES(status);

-- ------------------------------------------------------------
-- 14. PAYMENTS
-- ------------------------------------------------------------
INSERT INTO payment (payment_id, receipt_number, bill_id, amount_paid, payment_date, payment_mode, transaction_ref) VALUES
(1, 'REC-2026-001', 1, 150000.00, '2026-01-18', 'Online / UPI', 'UPI/2026/88392101'),
(2, 'REC-2026-002', 3, 100000.00, '2026-01-20', 'Net Banking', 'NEFT/HDFC/992381'),
(3, 'REC-2026-003', 5, 150000.00, '2026-01-25', 'Credit/Debit Card', 'CARD/POS/449102'),
(4, 'REC-2026-004', 6, 70000.00,  '2026-02-02', 'Online / UPI', 'UPI/2026/1129304'),
(5, 'REC-2026-005', 7, 135000.00, '2026-01-30', 'Net Banking', 'NEFT/ICICI/550192')
ON DUPLICATE KEY UPDATE amount_paid=VALUES(amount_paid);

-- ------------------------------------------------------------
-- 15. USER ACCOUNTS (Hashed with bcrypt: admin123, faculty123, student123)
-- ------------------------------------------------------------
INSERT INTO user_account (user_id, username, password_hash, role, reference_id, email, is_active) VALUES
(1, 'admin', '$2b$12$.bJACED4NhdjMNIpSV3.feVHl.jFN08s7gEnW7ve09eJPY2TxEBHW', 'Admin', NULL, 'admin@woxsen.edu.in', TRUE),
(2, 'faculty', '$2b$12$.oulvNmD2XHYDMz1E3YGr.8JHKbsIzdvIG9Ke8FI3wcR6FuFzt4JC', 'Faculty', 1, 'kavitha.reddy@woxsen.edu.in', TRUE),
(3, 'student', '$2b$12$Z0lqnkoMkH97IX6vBQRGxep2XLcUJCjLus9kTei2ARKsEau15iuGC', 'Student', 1, 'vardan.desai@woxsen.edu.in', TRUE),
(4, 'vardan', '$2b$12$Z0lqnkoMkH97IX6vBQRGxep2XLcUJCjLus9kTei2ARKsEau15iuGC', 'Student', 1, 'vardan.direct@woxsen.edu.in', TRUE)
ON DUPLICATE KEY UPDATE username=VALUES(username);
