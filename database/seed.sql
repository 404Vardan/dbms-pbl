-- =============================================================================
-- SCMS — Seed Data & Built-in Test Scenarios (MySQL 8.0+)
-- File : database/seed.sql
-- Description : Inserts realistic Indian university demo records across
--               all 14 domain tables + 4 pre-seeded demo user accounts.
--
-- Demo Accounts (Password for all accounts is 'Demo@12345'):
--   - Registrar (Admin)   : registrar@scms.edu.in
--   - Faculty (Dr. Priya) : priya.raghavan@scms.edu.in
--   - Accounts Officer    : accounts@scms.edu.in
--   - Student (Meera Nair): meera.nair@students.scms.edu.in
--
-- Built-in Test Scenarios:
--   - Section CS203-B (Sec B) is FULL (3/3 seats) -> Capacity violation test
--   - Aarav Mehta already enrolled in CS203-A     -> Duplicate registration test
--   - Meera Nair fee bill: ₹92,500 due, ₹50,000 paid (₹42,500 balance) -> Overpayment test
-- =============================================================================

USE scms_db;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE payment;
TRUNCATE TABLE fee_bill;
TRUNCATE TABLE grade;
TRUNCATE TABLE examination;
TRUNCATE TABLE attendance;
TRUNCATE TABLE registration;
TRUNCATE TABLE guardian;
TRUNCATE TABLE student;
TRUNCATE TABLE section;
TRUNCATE TABLE semester;
TRUNCATE TABLE course;
TRUNCATE TABLE faculty;
TRUNCATE TABLE programme;
TRUNCATE TABLE department;
TRUNCATE TABLE user_account;

SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- 1. DEPARTMENT
-- -----------------------------------------------------------------------------
INSERT INTO department (dept_id, dept_code, dept_name, office_email) VALUES
(1, 'CSE', 'Computer Science & Engineering',          'cse.office@scms.edu.in'),
(2, 'ECE', 'Electronics & Communication Engineering', 'ece.office@scms.edu.in'),
(3, 'ME',  'Mechanical Engineering',                  'mech.office@scms.edu.in'),
(4, 'SOM', 'School of Management',                    'som.office@scms.edu.in'),
(5, 'BSH', 'Basic Sciences & Humanities',             'bsh.office@scms.edu.in');

-- -----------------------------------------------------------------------------
-- 2. PROGRAMME
-- -----------------------------------------------------------------------------
INSERT INTO programme (programme_id, dept_id, programme_code, programme_name, duration_years, status) VALUES
(1, 1, 'BTECH-CSE',  'B.Tech Computer Science & Engineering',          4, 'Active'),
(2, 2, 'BTECH-ECE',  'B.Tech Electronics & Communication Engineering', 4, 'Active'),
(3, 3, 'BTECH-ME',   'B.Tech Mechanical Engineering',                  4, 'Active'),
(4, 1, 'MTECH-CSE',  'M.Tech Computer Science & Engineering',          2, 'Active'),
(5, 4, 'MBA',        'Master of Business Administration',              2, 'Active'),
(6, 2, 'MTECH-VLSI', 'M.Tech VLSI Design',                             2, 'Inactive');

-- -----------------------------------------------------------------------------
-- 3. FACULTY
-- -----------------------------------------------------------------------------
INSERT INTO faculty (faculty_id, dept_id, employee_code, full_name, email, designation) VALUES
(1, 1, 'F1001', 'Dr. Anil Kumar Sharma',   'anil.sharma@scms.edu.in',        'Professor & Head'),
(2, 1, 'F1002', 'Dr. Priya Raghavan',      'priya.raghavan@scms.edu.in',     'Associate Professor'),
(3, 1, 'F1003', 'Mr. Rohit Verma',         'rohit.verma@scms.edu.in',        'Assistant Professor'),
(4, 1, 'F1004', 'Dr. Sneha Kulkarni',      'sneha.kulkarni@scms.edu.in',     'Assistant Professor'),
(5, 2, 'F2001', 'Dr. Venkatesh Iyer',      'venkatesh.iyer@scms.edu.in',     'Professor & Head'),
(6, 2, 'F2002', 'Dr. Meenakshi Sundaram',  'meenakshi.sundaram@scms.edu.in', 'Associate Professor'),
(7, 3, 'F3001', 'Dr. Harpreet Singh Gill', 'harpreet.gill@scms.edu.in',      'Professor & Head'),
(8, 3, 'F3002', 'Mr. Arjun Nair',          'arjun.nair@scms.edu.in',         'Assistant Professor'),
(9, 4, 'F4001', 'Dr. Kavita Deshpande',    'kavita.deshpande@scms.edu.in',   'Professor & Dean'),
(10, 4, 'F4002', 'Dr. Sanjay Mehta',        'sanjay.mehta@scms.edu.in',       'Associate Professor'),
(11, 5, 'F5001', 'Dr. Lakshmi Prasad',      'lakshmi.prasad@scms.edu.in',     'Associate Professor');

-- -----------------------------------------------------------------------------
-- 4. COURSE
-- -----------------------------------------------------------------------------
INSERT INTO course (course_id, dept_id, course_code, course_name, credits, course_type) VALUES
(1, 1, 'CS201', 'Data Structures and Algorithms',      4, 'Core'),
(2, 1, 'CS203', 'Database Management Systems',         4, 'Core'),
(3, 1, 'CS205', 'Operating Systems',                   4, 'Core'),
(4, 1, 'CS207', 'Database Management Systems Lab',     2, 'Lab'),
(5, 1, 'CS301', 'Computer Networks',                   3, 'Core'),
(6, 1, 'CS511', 'Advanced Machine Learning',           3, 'Elective'),
(7, 2, 'EC201', 'Signals and Systems',                 4, 'Core'),
(8, 2, 'EC203', 'Digital Electronics',                 3, 'Core'),
(9, 3, 'ME201', 'Engineering Thermodynamics',          4, 'Core'),
(10, 3, 'ME203', 'Engineering Mechanics',               3, 'Core'),
(11, 4, 'MB501', 'Financial Accounting for Managers',   3, 'Core'),
(12, 4, 'MB503', 'Marketing Management',                3, 'Core'),
(13, 5, 'MA201', 'Probability and Statistics',          3, 'Core'),
(14, 4, 'MB601', 'Strategic Management',                3, 'Core');

-- -----------------------------------------------------------------------------
-- 5. SEMESTER
-- -----------------------------------------------------------------------------
INSERT INTO semester (semester_id, academic_year, term, start_date, end_date) VALUES
(1, '2025-26', 'Odd',  '2025-07-21', '2025-11-29'),
(2, '2025-26', 'Even', '2026-01-05', '2026-05-16'),
(3, '2026-27', 'Odd',  '2026-07-20', '2026-12-05'),
(4, '2026-27', 'Even', '2027-01-04', '2027-05-15');

-- -----------------------------------------------------------------------------
-- 6. SECTION
-- -----------------------------------------------------------------------------
INSERT INTO section (section_id, course_id, faculty_id, semester_id, section_code, room_no, capacity) VALUES
-- Past Semester Sections
(1, 13, 11, 1, 'A',  'LH-101',   60),
(2, 11,  9, 1, 'A',  'SOM-201',  60),
(3,  1,  1, 2, 'A',  'CSE-201',  60),
(4,  8,  6, 2, 'A',  'ECE-104',  60),
(5, 10,  8, 2, 'A',  'ME-102',   60),
(6, 12, 10, 2, 'A',  'SOM-202',  60),
(7,  6,  1, 2, 'A',  'CSE-LAB3', 15),
-- Current Semester Sections (2026-27 Odd)
(8,  2,  2, 3, 'A',  'CSE-301',   6),   -- CS203 Section A (Seats: 6)
(9,  2,  3, 3, 'B',  'CSE-302',   3),   -- CS203 Section B (Capacity: 3, fully occupied)
(10, 3,  4, 3, 'A',  'CSE-303',  60),
(11, 4,  2, 3, 'L1', 'CSE-LAB2', 30),
(12, 7,  5, 3, 'A',  'ECE-201',  60),
(13, 9,  7, 3, 'A',  'ME-101',   60),
(14, 14, 9, 3, 'A',  'SOM-301',  60),
(15, 5,  3, 3, 'A',  'CSE-304',  40);

-- -----------------------------------------------------------------------------
-- 7. STUDENT
-- -----------------------------------------------------------------------------
INSERT INTO student (student_id, programme_id, reg_no, full_name, dob, email, phone, admission_date, status) VALUES
(1,  1, '24BCS001', 'Aarav Mehta',          '2006-03-14', 'aarav.mehta@students.scms.edu.in',       '9876543201', '2024-07-29', 'Active'),
(2,  1, '24BCS002', 'Ananya Iyer',          '2006-07-22', 'ananya.iyer@students.scms.edu.in',       '9876543202', '2024-07-29', 'Active'),
(3,  1, '24BCS003', 'Rohan Deshmukh',       '2005-11-02', 'rohan.deshmukh@students.scms.edu.in',    '9876543203', '2024-07-29', 'Active'),
(4,  1, '24BCS004', 'Meera Nair',           '2006-01-30', 'meera.nair@students.scms.edu.in',        '9876543204', '2024-07-29', 'Active'),
(5,  1, '24BCS005', 'Karthik Reddy',        '2005-09-18', 'karthik.reddy@students.scms.edu.in',     '9876543205', '2024-07-29', 'Active'),
(6,  1, '24BCS006', 'Sneha Patil',          '2006-05-09', 'sneha.patil@students.scms.edu.in',       '9876543206', '2024-07-29', 'Active'),
(7,  1, '24BCS007', 'Vikram Singh Rathore', '2005-12-25', 'vikram.rathore@students.scms.edu.in',    '9876543207', '2024-07-29', 'Active'),
(8,  1, '24BCS008', 'Ishita Banerjee',      '2006-08-11', 'ishita.banerjee@students.scms.edu.in',   '9876543208', '2024-07-29', 'Active'),
(9,  2, '24BEC001', 'Aditya Kulkarni',      '2006-02-17', 'aditya.kulkarni@students.scms.edu.in',   '9876543209', '2024-07-29', 'Active'),
(10, 2, '24BEC002', 'Pooja Menon',          '2006-04-03', 'pooja.menon@students.scms.edu.in',       '9876543210', '2024-07-29', 'Active'),
(11, 2, '24BEC003', 'Siddharth Joshi',      '2005-10-27', 'siddharth.joshi@students.scms.edu.in',   '9876543211', '2024-07-29', 'Active'),
(12, 3, '24BME001', 'Harsh Vardhan Yadav',  '2005-06-21', 'harsh.yadav@students.scms.edu.in',       '9876543212', '2024-07-29', 'Active'),
(13, 3, '24BME002', 'Neha Gupta',           '2006-09-05', 'neha.gupta@students.scms.edu.in',        '9876543213', '2024-07-29', 'Active'),
(14, 3, '24BME003', 'Manish Tiwari',        '2005-08-14', 'manish.tiwari@students.scms.edu.in',     '9876543214', '2024-07-29', 'Withdrawn'),
(15, 5, '25MBA001', 'Riya Kapoor',          '2002-12-01', 'riya.kapoor@students.scms.edu.in',       '9876543215', '2025-07-14', 'Active'),
(16, 5, '25MBA002', 'Arjun Malhotra',       '2001-03-19', 'arjun.malhotra@students.scms.edu.in',    '9876543216', '2025-07-14', 'Active'),
(17, 4, '25MCS001', 'Divya Krishnan',       '2002-07-08', 'divya.krishnan@students.scms.edu.in',    '9876543217', '2025-07-14', 'Active');

-- -----------------------------------------------------------------------------
-- 8. GUARDIAN
-- -----------------------------------------------------------------------------
INSERT INTO guardian (student_id, name, relation, phone, email, address) VALUES
(1,  'Rajesh Mehta',          'Father',   '9822011001', 'rajesh.mehta@gmail.com',     '14, Shanti Nagar, Pune, Maharashtra 411038'),
(2,  'Lalitha Iyer',          'Mother',   '9822011002', 'lalitha.iyer@gmail.com',     '7, T. Nagar, Chennai, Tamil Nadu 600017'),
(3,  'Suresh Deshmukh',       'Father',   '9822011003', NULL,                         'Plot 22, Dhantoli, Nagpur, Maharashtra 440012'),
(4,  'Gopalakrishnan Nair',   'Father',   '9822011004', 'gk.nair@yahoo.co.in',        'Kowdiar, Thiruvananthapuram, Kerala 695003'),
(5,  'Srinivas Reddy',        'Father',   '9822011005', 'srinivas.reddy@gmail.com',   'Banjara Hills, Hyderabad, Telangana 500034'),
(6,  'Vandana Patil',         'Mother',   '9822011006', NULL,                         'Kothrud, Pune, Maharashtra 411029'),
(7,  'Mahendra Singh Rathore', 'Father',  '9822011007', 'ms.rathore@gmail.com',       'Shastri Nagar, Jodhpur, Rajasthan 342003'),
(8,  'Subhash Banerjee',      'Father',   '9822011008', 'subhash.banerjee@gmail.com', 'Salt Lake Sector II, Kolkata, West Bengal 700091'),
(9,  'Shubhangi Kulkarni',    'Mother',   '9822011009', NULL,                         'Vishrambag, Sangli, Maharashtra 416415'),
(10, 'Ravi Menon',            'Father',   '9822011010', 'ravi.menon@gmail.com',       'Panampilly Nagar, Kochi, Kerala 682036'),
(11, 'Prakash Joshi',         'Father',   '9822011011', NULL,                         'Navrangpura, Ahmedabad, Gujarat 380009'),
(12, 'Ramesh Yadav',          'Father',   '9822011012', NULL,                         'Gomti Nagar, Lucknow, Uttar Pradesh 226010'),
(13, 'Anita Gupta',           'Mother',   '9822011013', 'anita.gupta@gmail.com',      'Malviya Nagar, Jaipur, Rajasthan 302017'),
(14, 'Om Prakash Tiwari',     'Father',   '9822011014', NULL,                         'Civil Lines, Prayagraj, Uttar Pradesh 211001'),
(15, 'Sunita Kapoor',         'Mother',   '9822011015', 'sunita.kapoor@gmail.com',    'Rajouri Garden, New Delhi 110027'),
(16, 'Vivek Malhotra',        'Father',   '9822011016', 'vivek.malhotra@gmail.com',   'Sector 17, Chandigarh 160017'),
(17, 'Krishnan Ramaswamy',    'Father',   '9822011017', NULL,                         'Anna Nagar, Chennai, Tamil Nadu 600040');

-- -----------------------------------------------------------------------------
-- 9. REGISTRATION
-- -----------------------------------------------------------------------------
INSERT INTO registration (student_id, section_id, registered_on, status) VALUES
-- Past Semester Completed Registrations
(1, 1, '2025-07-16', 'Completed'), (2, 1, '2025-07-16', 'Completed'),
(3, 1, '2025-07-16', 'Completed'), (4, 1, '2025-07-16', 'Completed'),
(1, 3, '2026-01-02', 'Completed'), (2, 3, '2026-01-02', 'Completed'),
(3, 3, '2026-01-02', 'Completed'), (4, 3, '2026-01-02', 'Completed'),
-- Current Semester: CS203 Sec A (Seats: 6, Enrolled: 5) -> 1 seat available
(1, 8, '2026-07-15', 'Registered'), (2, 8, '2026-07-15', 'Registered'),
(3, 8, '2026-07-15', 'Registered'), (4, 8, '2026-07-15', 'Registered'),
(5, 8, '2026-07-15', 'Registered'),
-- Current Semester: CS203 Sec B (Capacity: 3, Enrolled: 3) -> FULL
(6, 9, '2026-07-15', 'Registered'), (7, 9, '2026-07-15', 'Registered'),
(8, 9, '2026-07-15', 'Registered'),
-- Current Semester: CS205 Sec A (Operating Systems)
(1, 10, '2026-07-15', 'Registered'), (2, 10, '2026-07-15', 'Registered'),
(3, 10, '2026-07-15', 'Registered'), (4, 10, '2026-07-15', 'Registered'),
(5, 10, '2026-07-15', 'Registered'),
-- Current Semester: CS207 Sec L1 (DBMS Lab)
(1, 11, '2026-07-15', 'Registered'), (2, 11, '2026-07-15', 'Registered'),
(3, 11, '2026-07-15', 'Registered'), (4, 11, '2026-07-15', 'Registered');

-- -----------------------------------------------------------------------------
-- 10. ATTENDANCE
-- -----------------------------------------------------------------------------
INSERT INTO attendance (registration_id, attendance_date, status) VALUES
-- Registrations in CS203 Sec A
(9,  '2026-07-22', 'Present'), (9,  '2026-07-29', 'Present'), (9,  '2026-08-05', 'Present'), (9,  '2026-08-12', 'Present'),
(10, '2026-07-22', 'Present'), (10, '2026-07-29', 'Present'), (10, '2026-08-05', 'Present'), (10, '2026-08-12', 'Present'),
-- Rohan Deshmukh (Low attendance / Shortage demo)
(11, '2026-07-22', 'Absent'),  (11, '2026-07-29', 'Absent'),  (11, '2026-08-05', 'Absent'),  (11, '2026-08-12', 'Present'),
-- Meera Nair
(12, '2026-07-22', 'Present'), (12, '2026-07-29', 'Late'),    (12, '2026-08-05', 'Present'), (12, '2026-08-12', 'Present'),
(13, '2026-07-22', 'Present'), (13, '2026-07-29', 'Present'), (13, '2026-08-05', 'Present'), (13, '2026-08-12', 'Present');

-- -----------------------------------------------------------------------------
-- 11. EXAMINATION
-- (The deterministic grade trigger will automatically insert matching rows into grade)
-- -----------------------------------------------------------------------------
INSERT INTO examination (registration_id, exam_type, exam_date, max_marks, marks) VALUES
(9,  'Mid-Term', '2026-09-15', 100.00, 92.50),  -- Will trigger Grade A+ (10.0)
(10, 'Mid-Term', '2026-09-15', 100.00, 84.00),  -- Will trigger Grade A (9.0)
(11, 'Mid-Term', '2026-09-15', 100.00, 36.00),  -- Will trigger Grade F (0.0)
(12, 'Mid-Term', '2026-09-15', 100.00, 78.50),  -- Will trigger Grade B+ (8.0)
(13, 'Mid-Term', '2026-09-15', 100.00, 65.00);  -- Will trigger Grade B (7.0)

-- -----------------------------------------------------------------------------
-- 13. FEE_BILL
-- -----------------------------------------------------------------------------
INSERT INTO fee_bill (bill_id, student_id, semester_id, bill_date, amount_due, due_date, status) VALUES
(1, 1, 3, '2026-07-10', 92500.00, '2026-08-15', 'Paid'),
(2, 2, 3, '2026-07-10', 92500.00, '2026-08-15', 'Paid'),
(3, 3, 3, '2026-07-10', 92500.00, '2026-08-15', 'Unpaid'),
(4, 4, 3, '2026-07-10', 92500.00, '2026-08-15', 'Partially Paid'), -- ₹50,000 paid; ₹42,500 balance
(5, 5, 3, '2026-07-10', 92500.00, '2026-08-15', 'Unpaid');

-- -----------------------------------------------------------------------------
-- 14. PAYMENT
-- -----------------------------------------------------------------------------
INSERT INTO payment (bill_id, payment_date, amount_paid, payment_mode, reference_no) VALUES
(1, '2026-07-15', 92500.00, 'UPI',  'UPI-2026-07-001'),
(2, '2026-07-18', 92500.00, 'NEFT', 'NEFT-2026-07-002'),
(4, '2026-07-24', 50000.00, 'Card', 'CRD-2026-07-003');

-- -----------------------------------------------------------------------------
-- AUTHENTICATION: user_account
-- Password for all accounts is 'Demo@12345'
-- Hash generated via bcrypt ($2a$10$w0s6hN37WnC7uFkKj.H06.cSmF0Z0j8Z0m4h7Y/V7Q2l/tF9p.t7e)
-- -----------------------------------------------------------------------------
INSERT INTO user_account (email, password_hash, role, full_name, student_id, faculty_id) VALUES
('registrar@scms.edu.in',           '$2a$10$w0s6hN37WnC7uFkKj.H06.cSmF0Z0j8Z0m4h7Y/V7Q2l/tF9p.t7e', 'admin',    'Dr. Ramesh Iyengar', NULL, NULL),
('priya.raghavan@scms.edu.in',      '$2a$10$w0s6hN37WnC7uFkKj.H06.cSmF0Z0j8Z0m4h7Y/V7Q2l/tF9p.t7e', 'faculty',  'Dr. Priya Raghavan', NULL, 2),
('accounts@scms.edu.in',            '$2a$10$w0s6hN37WnC7uFkKj.H06.cSmF0Z0j8Z0m4h7Y/V7Q2l/tF9p.t7e', 'accounts', 'Mr. Suresh Babu',    NULL, NULL),
('meera.nair@students.scms.edu.in', '$2a$10$w0s6hN37WnC7uFkKj.H06.cSmF0Z0j8Z0m4h7Y/V7Q2l/tF9p.t7e', 'student',  'Meera Nair',         4,    NULL);
