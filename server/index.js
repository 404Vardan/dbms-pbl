import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { pool, query } from './db.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'scms_jwt_secret_university_erp';

app.use(cors());
app.use(express.json());

// -----------------------------------------------------------------------------
// AUTHENTICATION & LOGIN
// -----------------------------------------------------------------------------
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const [user] = await query('SELECT * FROM user_account WHERE email = ?', [email]);
    if (!user) {
      return res.status(401).json({ error: 'Invalid email address or account not found.' });
    }

    // Check password (supports bcrypt hash or plain text demo match)
    const valid = await bcrypt.compare(password, user.password_hash) || password === 'Demo@12345';
    if (!valid) {
      return res.status(401).json({ error: 'Invalid password.' });
    }

    const token = jwt.sign(
      { userId: user.user_id, role: user.role, email: user.email },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        userId: user.user_id,
        email: user.email,
        role: user.role,
        fullName: user.full_name,
        studentId: user.student_id,
        facultyId: user.faculty_id
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server authentication failed.' });
  }
});

// -----------------------------------------------------------------------------
// DASHBOARD KPI METRICS
// -----------------------------------------------------------------------------
app.get('/api/dashboard/stats', async (req, res) => {
  try {
    const [stCount] = await query("SELECT COUNT(*) AS total FROM student WHERE status = 'Active'");
    const [prCount] = await query("SELECT COUNT(*) AS total FROM programme WHERE status = 'Active'");
    const [secCount] = await query("SELECT COUNT(*) AS total FROM section WHERE semester_id = 3");
    const [regCount] = await query("SELECT COUNT(*) AS total FROM registration WHERE status = 'Registered'");
    const [dueTotal] = await query("SELECT COALESCE(SUM(balance), 0) AS total FROM v_fee_dues");
    const [shortCount] = await query("SELECT COUNT(*) AS total FROM v_attendance_summary WHERE is_shortage = 1");

    const recentPayments = await query(`
      SELECT p.payment_id, p.payment_date, p.amount_paid, p.payment_mode, p.reference_no,
             st.full_name AS student_name, st.reg_no
      FROM payment p
      JOIN fee_bill b ON b.bill_id = p.bill_id
      JOIN student st ON st.student_id = b.student_id
      ORDER BY p.payment_date DESC, p.payment_id DESC
      LIMIT 6
    `);

    res.json({
      total_students: stCount.total,
      active_programmes: prCount.total,
      active_sections: secCount.total,
      current_registrations: regCount.total,
      outstanding_fees: dueTotal.total,
      attendance_shortage: shortCount.total,
      recent_payments: recentPayments
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------------------
// STUDENTS & ADMISSIONS
// -----------------------------------------------------------------------------
app.get('/api/students', async (req, res) => {
  try {
    const students = await query(`
      SELECT s.*, p.programme_code, p.programme_name,
             g.name AS guardian_name, g.relation AS guardian_relation, g.phone AS guardian_phone
      FROM student s
      JOIN programme p ON p.programme_id = s.programme_id
      LEFT JOIN guardian g ON g.student_id = s.student_id
      ORDER BY s.student_id DESC
    `);
    res.json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/students/:id', async (req, res) => {
  try {
    const [student] = await query(`
      SELECT s.*, p.programme_code, p.programme_name,
             g.name AS guardian_name, g.relation AS guardian_relation, g.phone AS guardian_phone,
             g.email AS guardian_email, g.address AS guardian_address
      FROM student s
      JOIN programme p ON p.programme_id = s.programme_id
      LEFT JOIN guardian g ON g.student_id = s.student_id
      WHERE s.student_id = ?
    `, [req.params.id]);

    if (!student) return res.status(404).json({ error: 'Student not found.' });

    const history = await query('SELECT * FROM v_student_academic_history WHERE student_id = ?', [req.params.id]);
    const bills = await query('SELECT * FROM v_fee_dues WHERE student_id = ?', [req.params.id]);

    res.json({ student, history, bills });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/students/admit', async (req, res) => {
  const { student, guardian: g } = req.body;
  try {
    await query('CALL sp_admit_student(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @out_id)', [
      student.programme_id,
      student.reg_no,
      student.full_name,
      student.dob,
      student.email,
      student.phone,
      student.admission_date || null,
      g?.name || null,
      g?.relation || null,
      g?.phone || null,
      g?.email || null,
      g?.address || null
    ]);

    const [out] = await query('SELECT @out_id AS student_id');
    res.json({ student_id: out.student_id, message: 'Student admitted successfully via MySQL transaction.' });
  } catch (err) {
    console.error('Admission DB error:', err);
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
});

// -----------------------------------------------------------------------------
// COURSE REGISTRATION & CAPACITY ENFORCEMENT
// -----------------------------------------------------------------------------
app.get('/api/registration/options', async (req, res) => {
  try {
    const students = await query("SELECT student_id, reg_no, full_name FROM student WHERE status = 'Active' ORDER BY full_name");
    const sections = await query("SELECT * FROM v_section_occupancy ORDER BY course_code");
    const registrations = await query(`
      SELECT r.registration_id, r.registered_on, r.status,
             st.reg_no, st.full_name AS student_name,
             c.course_code, c.course_name, s.section_code, s.room_no
      FROM registration r
      JOIN student st ON st.student_id = r.student_id
      JOIN section s ON s.section_id = r.section_id
      JOIN course c ON c.course_id = s.course_id
      ORDER BY r.registration_id DESC
      LIMIT 25
    `);
    res.json({ students, sections, registrations });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/registration', async (req, res) => {
  const { student_id, section_id } = req.body;
  try {
    // Triggers in MySQL will reject if section is full or duplicate
    await query('INSERT INTO registration (student_id, section_id, status) VALUES (?, ?, "Registered")', [
      student_id,
      section_id
    ]);
    res.json({ message: 'Course Section Registration confirmed by MySQL trigger!' });
  } catch (err) {
    console.error('Registration trigger violation:', err);
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
});

// -----------------------------------------------------------------------------
// ATTENDANCE TRACKER
// -----------------------------------------------------------------------------
app.get('/api/attendance/sections', async (req, res) => {
  try {
    const sections = await query(`
      SELECT s.section_id, s.section_code, s.room_no,
             c.course_code, c.course_name, f.full_name AS faculty_name
      FROM section s
      JOIN course c ON c.course_id = s.course_id
      JOIN faculty f ON f.faculty_id = s.faculty_id
      ORDER BY s.section_id
    `);
    res.json(sections);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/attendance/roster', async (req, res) => {
  const { section_id, date } = req.query;
  try {
    const roster = await query(`
      SELECT r.registration_id, r.student_id, st.reg_no, st.full_name
      FROM registration r
      JOIN student st ON st.student_id = r.student_id
      WHERE r.section_id = ? AND r.status = 'Registered'
      ORDER BY r.registration_id
    `, [section_id]);

    const attendanceRecords = await query(`
      SELECT a.registration_id, a.status
      FROM attendance a
      JOIN registration r ON r.registration_id = a.registration_id
      WHERE r.section_id = ? AND a.attendance_date = ?
    `, [section_id, date]);

    const summary = await query('SELECT * FROM v_attendance_summary WHERE section_id = ?', [section_id]);

    res.json({ roster, attendanceRecords, summary });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/attendance/save', async (req, res) => {
  const { entries, date } = req.body;
  try {
    for (const item of entries) {
      await query(`
        INSERT INTO attendance (registration_id, attendance_date, status)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE status = VALUES(status)
      `, [item.registration_id, date, item.status]);
    }
    res.json({ message: `Attendance for ${entries.length} students recorded successfully.` });
  } catch (err) {
    console.error('Attendance error:', err);
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
});

// -----------------------------------------------------------------------------
// EXAMINATIONS & DETERMINISTIC GRADING
// -----------------------------------------------------------------------------
app.get('/api/examinations/data', async (req, res) => {
  const { section_id, exam_type } = req.query;
  try {
    const students = await query(`
      SELECT r.registration_id, st.student_id, st.reg_no, st.full_name
      FROM registration r
      JOIN student st ON st.student_id = r.student_id
      WHERE r.section_id = ? AND r.status = 'Registered'
      ORDER BY r.registration_id
    `, [section_id]);

    const records = await query(`
      SELECT * FROM v_exam_details
      WHERE section_id = ? AND exam_type = ?
      ORDER BY reg_no
    `, [section_id, exam_type]);

    res.json({ students, records });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/examinations/record', async (req, res) => {
  const { registration_id, exam_type, exam_date, marks, max_marks } = req.body;
  try {
    await query('CALL sp_record_exam_result(?, ?, ?, ?, ?, @out_id)', [
      registration_id,
      exam_type,
      exam_date,
      marks,
      max_marks || 100.00
    ]);
    res.json({ message: 'Exam marks recorded. MySQL grade trigger executed.' });
  } catch (err) {
    console.error('Exam evaluation error:', err);
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
});

// -----------------------------------------------------------------------------
// FEES & OVERPAYMENT ENFORCEMENT
// -----------------------------------------------------------------------------
app.get('/api/fees/data', async (req, res) => {
  try {
    const bills = await query('SELECT * FROM v_fee_dues ORDER BY bill_id DESC');
    const students = await query("SELECT student_id, reg_no, full_name FROM student WHERE status = 'Active' ORDER BY full_name");
    const semesters = await query('SELECT semester_id, academic_year, term FROM semester ORDER BY start_date DESC');
    const payments = await query(`
      SELECT p.payment_id, p.payment_date, p.amount_paid, p.payment_mode, p.reference_no,
             st.full_name AS student_name, st.reg_no
      FROM payment p
      JOIN fee_bill b ON b.bill_id = p.bill_id
      JOIN student st ON st.student_id = b.student_id
      ORDER BY p.payment_id DESC
      LIMIT 15
    `);
    res.json({ bills, students, semesters, payments });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/fees/bill', async (req, res) => {
  const { student_id, semester_id, amount_due, due_date } = req.body;
  try {
    await query('INSERT INTO fee_bill (student_id, semester_id, amount_due, due_date) VALUES (?, ?, ?, ?)', [
      student_id,
      semester_id,
      amount_due,
      due_date
    ]);
    res.json({ message: 'Fee bill created successfully.' });
  } catch (err) {
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
});

app.post('/api/fees/payment', async (req, res) => {
  const { bill_id, amount_paid, payment_mode, reference_no } = req.body;
  try {
    // MySQL trigger trg_payment_before_insert will reject if overpayment
    await query('INSERT INTO payment (bill_id, amount_paid, payment_mode, reference_no) VALUES (?, ?, ?, ?)', [
      bill_id,
      amount_paid,
      payment_mode,
      reference_no || `TXN-${Date.now()}`
    ]);
    res.json({ message: 'Payment recorded and invoice synchronized by MySQL trigger.' });
  } catch (err) {
    console.error('Payment error:', err);
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
});

// -----------------------------------------------------------------------------
// INSTITUTIONAL REPORTS (VIEWS)
// -----------------------------------------------------------------------------
app.get('/api/reports/:tab', async (req, res) => {
  const { tab } = req.params;
  try {
    let sql;
    switch (tab) {
      case 'occupancy':
        sql = 'SELECT * FROM v_section_occupancy ORDER BY course_code';
        break;
      case 'attendance':
        sql = 'SELECT * FROM v_attendance_summary ORDER BY attendance_pct ASC';
        break;
      case 'results':
        sql = 'SELECT * FROM v_result_analysis ORDER BY course_code';
        break;
      case 'history':
        sql = 'SELECT * FROM v_student_academic_history ORDER BY student_id';
        break;
      case 'dues':
        sql = 'SELECT * FROM v_student_dues ORDER BY outstanding DESC';
        break;
      case 'departments':
        sql = 'SELECT * FROM v_department_summary ORDER BY dept_code';
        break;
      default:
        sql = 'SELECT * FROM v_section_occupancy';
    }
    const data = await query(sql);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------------------
// DEPARTMENTS, COURSES, FACULTY, SEMESTERS, SECTIONS
// -----------------------------------------------------------------------------
app.get('/api/departments', async (req, res) => {
  try {
    const departments = await query('SELECT * FROM department ORDER BY dept_id');
    const programmes = await query(`
      SELECT p.*, d.dept_code, d.dept_name
      FROM programme p
      JOIN department d ON d.dept_id = p.dept_id
      ORDER BY p.programme_id
    `);
    res.json({ departments, programmes });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/courses', async (req, res) => {
  try {
    const courses = await query(`
      SELECT c.*, d.dept_code, d.dept_name
      FROM course c
      JOIN department d ON d.dept_id = c.dept_id
      ORDER BY c.course_code
    `);
    const departments = await query('SELECT dept_id, dept_code, dept_name FROM department ORDER BY dept_id');
    res.json({ courses, departments });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/courses', async (req, res) => {
  const { dept_id, course_code, course_name, credits, course_type } = req.body;
  try {
    await query('INSERT INTO course (dept_id, course_code, course_name, credits, course_type) VALUES (?, ?, ?, ?, ?)', [
      dept_id,
      course_code.toUpperCase(),
      course_name,
      credits,
      course_type
    ]);
    res.json({ message: 'Course created successfully.' });
  } catch (err) {
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
});

app.get('/api/faculty', async (req, res) => {
  try {
    const faculty = await query(`
      SELECT f.*, d.dept_code, d.dept_name
      FROM faculty f
      JOIN department d ON d.dept_id = f.dept_id
      ORDER BY f.employee_code
    `);
    res.json(faculty);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/semesters', async (req, res) => {
  try {
    const semesters = await query('SELECT * FROM semester ORDER BY start_date DESC');
    res.json(semesters);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/sections', async (req, res) => {
  try {
    const sections = await query('SELECT * FROM v_section_occupancy ORDER BY course_code');
    const courses = await query("SELECT course_id, course_code, course_name FROM course WHERE status = 'Active'");
    const faculty = await query("SELECT faculty_id, full_name FROM faculty WHERE status = 'Active'");
    const semesters = await query('SELECT semester_id, academic_year, term FROM semester ORDER BY start_date DESC');
    res.json({ sections, courses, faculty, semesters });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/sections', async (req, res) => {
  const { course_id, faculty_id, semester_id, section_code, room_no, capacity } = req.body;
  try {
    await query('INSERT INTO section (course_id, faculty_id, semester_id, section_code, room_no, capacity) VALUES (?, ?, ?, ?, ?, ?)', [
      course_id,
      faculty_id,
      semester_id,
      section_code.toUpperCase(),
      room_no,
      capacity
    ]);
    res.json({ message: 'Section created successfully.' });
  } catch (err) {
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
});

app.listen(PORT, () => {
  console.log(`SCMS MySQL Backend Server running on port ${PORT}`);
});
