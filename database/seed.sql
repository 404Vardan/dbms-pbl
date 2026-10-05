-- =============================================================================
-- SCMS — seed.sql : realistic linked demo data for all 14 tables + demo users
--
-- Re-runnable: truncates domain tables first.
-- Demo login password: the literal token __DEMO_PASSWORD__ below is replaced
-- by `npm run db:seed` with DEMO_PASSWORD from your local .env (never committed).
-- If you paste this file into the Supabase SQL Editor, replace it manually.
--
-- Built-in scenarios:
--   * CS203-B (2026-27 Odd) is FULL (3/3)        -> capacity rule demo
--   * CS203-A has 1 seat left (5/6)               -> register, then it becomes full
--   * Aarav Mehta is already in CS203-A           -> duplicate registration demo
--   * Meera Nair's 2026-27 Odd bill: ₹92,500 due, ₹50,000 paid -> overpayment demo
--   * Present / Absent / Late attendance, several students below 75%
--   * Paid, Partially Paid and Unpaid (overdue) bills
--   * Upcoming End-Term exams (marks not yet entered)
-- =============================================================================

set search_path = public;

truncate table payment, fee_bill, grade, examination, attendance, registration,
               guardian, user_profile, student, section, semester, course, faculty,
               programme, department
restart identity cascade;

-- -----------------------------------------------------------------------------
-- DEPARTMENT
-- -----------------------------------------------------------------------------
insert into department (dept_id, dept_code, dept_name, office_email) overriding system value values
 (1, 'CSE', 'Computer Science & Engineering',            'cse.office@scms.edu.in'),
 (2, 'ECE', 'Electronics & Communication Engineering',   'ece.office@scms.edu.in'),
 (3, 'ME',  'Mechanical Engineering',                    'mech.office@scms.edu.in'),
 (4, 'SOM', 'School of Management',                      'som.office@scms.edu.in'),
 (5, 'BSH', 'Basic Sciences & Humanities',               'bsh.office@scms.edu.in');

-- -----------------------------------------------------------------------------
-- PROGRAMME
-- -----------------------------------------------------------------------------
insert into programme (programme_id, dept_id, programme_code, programme_name, duration_years, status) overriding system value values
 (1, 1, 'BTECH-CSE',  'B.Tech Computer Science & Engineering',          4, 'Active'),
 (2, 2, 'BTECH-ECE',  'B.Tech Electronics & Communication Engineering', 4, 'Active'),
 (3, 3, 'BTECH-ME',   'B.Tech Mechanical Engineering',                  4, 'Active'),
 (4, 1, 'MTECH-CSE',  'M.Tech Computer Science & Engineering',          2, 'Active'),
 (5, 4, 'MBA',        'Master of Business Administration',              2, 'Active'),
 (6, 2, 'MTECH-VLSI', 'M.Tech VLSI Design',                             2, 'Inactive');

-- -----------------------------------------------------------------------------
-- FACULTY
-- -----------------------------------------------------------------------------
insert into faculty (faculty_id, dept_id, employee_code, full_name, email, designation) overriding system value values
 ( 1, 1, 'F1001', 'Dr. Anil Kumar Sharma',   'anil.sharma@scms.edu.in',        'Professor & Head'),
 ( 2, 1, 'F1002', 'Dr. Priya Raghavan',      'priya.raghavan@scms.edu.in',     'Associate Professor'),
 ( 3, 1, 'F1003', 'Mr. Rohit Verma',         'rohit.verma@scms.edu.in',        'Assistant Professor'),
 ( 4, 1, 'F1004', 'Dr. Sneha Kulkarni',      'sneha.kulkarni@scms.edu.in',     'Assistant Professor'),
 ( 5, 2, 'F2001', 'Dr. Venkatesh Iyer',      'venkatesh.iyer@scms.edu.in',     'Professor & Head'),
 ( 6, 2, 'F2002', 'Dr. Meenakshi Sundaram',  'meenakshi.sundaram@scms.edu.in', 'Associate Professor'),
 ( 7, 3, 'F3001', 'Dr. Harpreet Singh Gill', 'harpreet.gill@scms.edu.in',      'Professor & Head'),
 ( 8, 3, 'F3002', 'Mr. Arjun Nair',          'arjun.nair@scms.edu.in',         'Assistant Professor'),
 ( 9, 4, 'F4001', 'Dr. Kavita Deshpande',    'kavita.deshpande@scms.edu.in',   'Professor & Dean'),
 (10, 4, 'F4002', 'Dr. Sanjay Mehta',        'sanjay.mehta@scms.edu.in',       'Associate Professor'),
 (11, 5, 'F5001', 'Dr. Lakshmi Prasad',      'lakshmi.prasad@scms.edu.in',     'Associate Professor');

-- -----------------------------------------------------------------------------
-- COURSE
-- -----------------------------------------------------------------------------
insert into course (course_id, dept_id, course_code, course_name, credits, course_type) overriding system value values
 ( 1, 1, 'CS201', 'Data Structures and Algorithms',      4, 'Core'),
 ( 2, 1, 'CS203', 'Database Management Systems',         4, 'Core'),
 ( 3, 1, 'CS205', 'Operating Systems',                   4, 'Core'),
 ( 4, 1, 'CS207', 'Database Management Systems Lab',     2, 'Lab'),
 ( 5, 1, 'CS301', 'Computer Networks',                   3, 'Core'),
 ( 6, 1, 'CS511', 'Advanced Machine Learning',           3, 'Elective'),
 ( 7, 2, 'EC201', 'Signals and Systems',                 4, 'Core'),
 ( 8, 2, 'EC203', 'Digital Electronics',                 3, 'Core'),
 ( 9, 3, 'ME201', 'Engineering Thermodynamics',          4, 'Core'),
 (10, 3, 'ME203', 'Engineering Mechanics',               3, 'Core'),
 (11, 4, 'MB501', 'Financial Accounting for Managers',   3, 'Core'),
 (12, 4, 'MB503', 'Marketing Management',                3, 'Core'),
 (13, 5, 'MA201', 'Probability and Statistics',          3, 'Core'),
 (14, 4, 'MB601', 'Strategic Management',                3, 'Core');

-- -----------------------------------------------------------------------------
-- SEMESTER
-- -----------------------------------------------------------------------------
insert into semester (semester_id, academic_year, term, start_date, end_date) overriding system value values
 (1, '2025-26', 'Odd',  '2025-07-21', '2025-11-29'),
 (2, '2025-26', 'Even', '2026-01-05', '2026-05-16'),
 (3, '2026-27', 'Odd',  '2026-07-20', '2026-12-05'),
 (4, '2026-27', 'Even', '2027-01-04', '2027-05-15');

-- -----------------------------------------------------------------------------
-- SECTION
-- -----------------------------------------------------------------------------
insert into section (section_id, course_id, faculty_id, semester_id, section_code, room_no, capacity) overriding system value values
 -- 2025-26 Odd
 ( 1, 13, 11, 1, 'A',  'LH-101',   60),
 ( 2, 11,  9, 1, 'A',  'SOM-201',  60),
 -- 2025-26 Even
 ( 3,  1,  1, 2, 'A',  'CSE-201',  60),
 ( 4,  8,  6, 2, 'A',  'ECE-104',  60),
 ( 5, 10,  8, 2, 'A',  'ME-102',   60),
 ( 6, 12, 10, 2, 'A',  'SOM-202',  60),
 ( 7,  6,  1, 2, 'A',  'CSE-LAB3', 15),
 -- 2026-27 Odd (current)
 ( 8,  2,  2, 3, 'A',  'CSE-301',   6),
 ( 9,  2,  3, 3, 'B',  'CSE-302',   3),
 (10,  3,  4, 3, 'A',  'CSE-303',  60),
 (11,  4,  2, 3, 'L1', 'CSE-LAB2', 30),
 (12,  7,  5, 3, 'A',  'ECE-201',  60),
 (13,  9,  7, 3, 'A',  'ME-101',   60),
 (14, 14,  9, 3, 'A',  'SOM-301',  60),
 (15,  5,  3, 3, 'A',  'CSE-304',  40);

-- -----------------------------------------------------------------------------
-- STUDENT
-- -----------------------------------------------------------------------------
insert into student (student_id, programme_id, reg_no, full_name, dob, email, phone, admission_date, status) overriding system value values
 ( 1, 1, '24BCS001', 'Aarav Mehta',          '2006-03-14', 'aarav.mehta@students.scms.edu.in',       '9876543201', '2024-07-29', 'Active'),
 ( 2, 1, '24BCS002', 'Ananya Iyer',          '2006-07-22', 'ananya.iyer@students.scms.edu.in',       '9876543202', '2024-07-29', 'Active'),
 ( 3, 1, '24BCS003', 'Rohan Deshmukh',       '2005-11-02', 'rohan.deshmukh@students.scms.edu.in',    '9876543203', '2024-07-29', 'Active'),
 ( 4, 1, '24BCS004', 'Meera Nair',           '2006-01-30', 'meera.nair@students.scms.edu.in',        '9876543204', '2024-07-29', 'Active'),
 ( 5, 1, '24BCS005', 'Karthik Reddy',        '2005-09-18', 'karthik.reddy@students.scms.edu.in',     '9876543205', '2024-07-29', 'Active'),
 ( 6, 1, '24BCS006', 'Sneha Patil',          '2006-05-09', 'sneha.patil@students.scms.edu.in',       '9876543206', '2024-07-29', 'Active'),
 ( 7, 1, '24BCS007', 'Vikram Singh Rathore', '2005-12-25', 'vikram.rathore@students.scms.edu.in',    '9876543207', '2024-07-29', 'Active'),
 ( 8, 1, '24BCS008', 'Ishita Banerjee',      '2006-08-11', 'ishita.banerjee@students.scms.edu.in',   '9876543208', '2024-07-29', 'Active'),
 ( 9, 2, '24BEC001', 'Aditya Kulkarni',      '2006-02-17', 'aditya.kulkarni@students.scms.edu.in',   '9876543209', '2024-07-29', 'Active'),
 (10, 2, '24BEC002', 'Pooja Menon',          '2006-04-03', 'pooja.menon@students.scms.edu.in',       '9876543210', '2024-07-29', 'Active'),
 (11, 2, '24BEC003', 'Siddharth Joshi',      '2005-10-27', 'siddharth.joshi@students.scms.edu.in',   '9876543211', '2024-07-29', 'Active'),
 (12, 3, '24BME001', 'Harsh Vardhan Yadav',  '2005-06-21', 'harsh.yadav@students.scms.edu.in',       '9876543212', '2024-07-29', 'Active'),
 (13, 3, '24BME002', 'Neha Gupta',           '2006-09-05', 'neha.gupta@students.scms.edu.in',        '9876543213', '2024-07-29', 'Active'),
 (14, 3, '24BME003', 'Manish Tiwari',        '2005-08-14', 'manish.tiwari@students.scms.edu.in',     '9876543214', '2024-07-29', 'Withdrawn'),
 (15, 5, '25MBA001', 'Riya Kapoor',          '2002-12-01', 'riya.kapoor@students.scms.edu.in',       '9876543215', '2025-07-14', 'Active'),
 (16, 5, '25MBA002', 'Arjun Malhotra',       '2001-03-19', 'arjun.malhotra@students.scms.edu.in',    '9876543216', '2025-07-14', 'Active'),
 (17, 4, '25MCS001', 'Divya Krishnan',       '2002-07-08', 'divya.krishnan@students.scms.edu.in',    '9876543217', '2025-07-14', 'Active');

-- -----------------------------------------------------------------------------
-- GUARDIAN
-- -----------------------------------------------------------------------------
insert into guardian (student_id, name, relation, phone, email, address) values
 ( 1, 'Rajesh Mehta',         'Father',   '9822011001', 'rajesh.mehta@gmail.com',      '14, Shanti Nagar, Pune, Maharashtra 411038'),
 ( 2, 'Lalitha Iyer',         'Mother',   '9822011002', 'lalitha.iyer@gmail.com',      '7, T. Nagar, Chennai, Tamil Nadu 600017'),
 ( 3, 'Suresh Deshmukh',      'Father',   '9822011003', null,                          'Plot 22, Dhantoli, Nagpur, Maharashtra 440012'),
 ( 4, 'Gopalakrishnan Nair',  'Father',   '9822011004', 'gk.nair@yahoo.co.in',         'Kowdiar, Thiruvananthapuram, Kerala 695003'),
 ( 5, 'Srinivas Reddy',       'Father',   '9822011005', 'srinivas.reddy@gmail.com',    'Banjara Hills, Hyderabad, Telangana 500034'),
 ( 6, 'Vandana Patil',        'Mother',   '9822011006', null,                          'Kothrud, Pune, Maharashtra 411029'),
 ( 7, 'Mahendra Singh Rathore','Father',  '9822011007', 'ms.rathore@gmail.com',        'Shastri Nagar, Jodhpur, Rajasthan 342003'),
 ( 8, 'Subhash Banerjee',     'Father',   '9822011008', 'subhash.banerjee@gmail.com',  'Salt Lake Sector II, Kolkata, West Bengal 700091'),
 ( 9, 'Shubhangi Kulkarni',   'Mother',   '9822011009', null,                          'Vishrambag, Sangli, Maharashtra 416415'),
 (10, 'Ravi Menon',           'Father',   '9822011010', 'ravi.menon@gmail.com',        'Panampilly Nagar, Kochi, Kerala 682036'),
 (11, 'Prakash Joshi',        'Father',   '9822011011', null,                          'Navrangpura, Ahmedabad, Gujarat 380009'),
 (12, 'Ramesh Yadav',         'Father',   '9822011012', null,                          'Gomti Nagar, Lucknow, Uttar Pradesh 226010'),
 (13, 'Anita Gupta',          'Mother',   '9822011013', 'anita.gupta@gmail.com',       'Malviya Nagar, Jaipur, Rajasthan 302017'),
 (14, 'Om Prakash Tiwari',    'Father',   '9822011014', null,                          'Civil Lines, Prayagraj, Uttar Pradesh 211001'),
 (15, 'Sunita Kapoor',        'Mother',   '9822011015', 'sunita.kapoor@gmail.com',     'Rajouri Garden, New Delhi 110027'),
 (16, 'Vivek Malhotra',       'Father',   '9822011016', 'vivek.malhotra@gmail.com',    'Sector 17, Chandigarh 160017'),
 (17, 'Krishnan Ramaswamy',   'Father',   '9822011017', null,                          'Anna Nagar, Chennai, Tamil Nadu 600040');

-- -----------------------------------------------------------------------------
-- REGISTRATION  (past semesters = Completed, current = Registered)
-- -----------------------------------------------------------------------------
insert into registration (student_id, section_id, registered_on, status)
select x.student_id, x.section_id, sm.start_date - 5, x.status
from (values
        -- 2025-26 Odd
        (1, 1, 'Completed'), (2, 1, 'Completed'), (3, 1, 'Completed'), (4, 1, 'Completed'),
        (5, 1, 'Completed'), (6, 1, 'Completed'), (7, 1, 'Completed'), (8, 1, 'Completed'),
        (9, 1, 'Completed'), (10, 1, 'Completed'), (11, 1, 'Completed'), (12, 1, 'Completed'),
        (13, 1, 'Completed'), (14, 1, 'Completed'), (15, 2, 'Completed'), (16, 2, 'Completed'),
        -- 2025-26 Even
        (1, 3, 'Completed'), (2, 3, 'Completed'), (3, 3, 'Completed'), (4, 3, 'Completed'),
        (5, 3, 'Completed'), (6, 3, 'Completed'), (7, 3, 'Completed'), (8, 3, 'Completed'),
        (9, 4, 'Completed'), (10, 4, 'Completed'), (11, 4, 'Completed'),
        (12, 5, 'Completed'), (13, 5, 'Completed'), (14, 5, 'Completed'),
        (15, 6, 'Completed'), (16, 6, 'Completed'), (17, 7, 'Completed'),
        -- 2026-27 Odd (current)
        (1, 8, 'Registered'), (2, 8, 'Registered'), (3, 8, 'Registered'), (4, 8, 'Registered'), (5, 8, 'Registered'),
        (6, 9, 'Registered'), (7, 9, 'Registered'), (8, 9, 'Registered'),
        (1, 10, 'Registered'), (2, 10, 'Registered'), (3, 10, 'Registered'), (4, 10, 'Registered'),
        (5, 10, 'Registered'), (6, 10, 'Registered'), (7, 10, 'Registered'), (8, 10, 'Registered'),
        (1, 11, 'Registered'), (2, 11, 'Registered'), (3, 11, 'Registered'), (4, 11, 'Registered'),
        (5, 11, 'Registered'), (6, 11, 'Registered'), (7, 11, 'Registered'), (8, 11, 'Registered'),
        (9, 12, 'Registered'), (10, 12, 'Registered'), (11, 12, 'Registered'),
        (12, 13, 'Registered'), (13, 13, 'Registered'),
        (15, 14, 'Registered'), (16, 14, 'Registered')
     ) as x(student_id, section_id, status)
join section  s  on s.section_id   = x.section_id
join semester sm on sm.semester_id = s.semester_id
order by sm.start_date, x.section_id, x.student_id;

-- -----------------------------------------------------------------------------
-- ATTENDANCE — weekly classes, deterministic pattern (no randomness).
-- Students 3, 11, 13 (and Meera in CS205) are engineered below 75 %.
-- -----------------------------------------------------------------------------
insert into attendance (registration_id, attendance_date, status)
select r.registration_id,
       d.class_date,
       case
         when (r.student_id in (3, 11, 13) and sm.semester_id = 3) or (r.student_id = 4 and s.section_id = 10) then
              case when h < 7 then 'Absent' when h < 9 then 'Late' else 'Present' end
         else case when h < 2 then 'Absent' when h = 2 then 'Late' else 'Present' end
       end
from registration r
join section  s  on s.section_id   = r.section_id
join semester sm on sm.semester_id = s.semester_id
cross join lateral (
    select (sm.start_date + 1 + (s.section_id % 5) + 7 * k)::date as class_date, k
      from generate_series(0, 11) as k
) d
cross join lateral (select (r.registration_id * 37 + d.k * 11 + r.student_id * 7) % 20 as h) hh
where d.class_date <= least(sm.end_date, current_date - 1)
  and r.status <> 'Dropped';

-- -----------------------------------------------------------------------------
-- EXAMINATION (GRADE rows are generated automatically by trigger)
--  Past semesters: Mid-Term + End-Term evaluated.
--  Current semester: Mid-Term evaluated, End-Term scheduled (marks NULL).
-- -----------------------------------------------------------------------------
insert into examination (registration_id, exam_type, exam_date, max_marks, marks)
select r.registration_id,
       t.exam_type,
       case t.exam_type
         when 'Mid-Term' then sm.start_date + 56 + (s.section_id % 4)
         else                 sm.end_date   - 12 + (s.section_id % 5)
       end,
       100,
       case
         when sm.semester_id = 3 and t.exam_type = 'End-Term' then null
         when r.student_id = 3 then greatest(38 + ((r.student_id * 53 + s.course_id * 29 + t.n * 17) % 60) - 22, 18)
         else 38 + ((r.student_id * 53 + s.course_id * 29 + t.n * 17) % 60)
       end
from registration r
join section  s  on s.section_id   = r.section_id
join semester sm on sm.semester_id = s.semester_id
cross join (values ('Mid-Term', 1), ('End-Term', 2)) as t(exam_type, n)
where r.status <> 'Dropped';

-- -----------------------------------------------------------------------------
-- FEE_BILL — per programme semester fee
-- -----------------------------------------------------------------------------
insert into fee_bill (student_id, semester_id, bill_date, amount_due, due_date)
select st.student_id,
       sm.semester_id,
       sm.start_date - 10,
       case p.programme_code
         when 'BTECH-CSE' then 92500
         when 'BTECH-ECE' then 87500
         when 'BTECH-ME'  then 82500
         when 'MTECH-CSE' then 75000
         when 'MBA'       then 115000
       end,
       sm.start_date + 25
from student st
join programme p on p.programme_id = st.programme_id
cross join semester sm
where sm.semester_id in (1, 2, 3)
  and not (st.student_id = 14 and sm.semester_id = 3);   -- withdrawn student is not billed

-- -----------------------------------------------------------------------------
-- PAYMENT
-- -----------------------------------------------------------------------------
-- Past semesters fully paid (even student_ids paid in two instalments) except
-- Manish Tiwari (withdrawn) who left a balance in 2025-26 Even.
insert into payment (bill_id, payment_date, amount_paid, payment_mode, reference_no)
select b.bill_id,
       b.bill_date + 3 + (b.student_id % 12) + (i.n - 1) * 20,
       case
         when b.student_id = 14 and b.semester_id = 2 then 40000
         when b.student_id % 2 = 0 and i.n = 1 then round(b.amount_due * 0.6)
         when b.student_id % 2 = 0 and i.n = 2 then b.amount_due - round(b.amount_due * 0.6)
         else b.amount_due
       end,
       (array['UPI', 'NEFT', 'Card', 'DD'])[1 + (b.student_id + i.n) % 4],
       'SCMS' || to_char(b.bill_date, 'YYMM') || lpad(b.student_id::text, 3, '0') || i.n
from fee_bill b
cross join (values (1), (2)) as i(n)
where b.semester_id in (1, 2)
  and (i.n = 1 or (b.student_id % 2 = 0 and not (b.student_id = 14 and b.semester_id = 2)));

-- Current semester: a mix of paid, partially paid and unpaid.
insert into payment (bill_id, payment_date, amount_paid, payment_mode, reference_no)
select b.bill_id, x.paid_on::date, x.amount, x.mode, x.ref
from (values
        ( 1, '2026-07-15', 92500,  'UPI',    'UPI26071500142'),
        ( 2, '2026-07-18', 92500,  'NEFT',   'NEFT2607180088'),
        ( 3, '2026-07-22', 40000,  'UPI',    'UPI26072200311'),
        ( 4, '2026-07-24', 50000,  'Card',   'CRD26072400457'),
        ( 5, '2026-07-16', 92500,  'NEFT',   'NEFT2607160091'),
        ( 6, '2026-07-20', 50000,  'UPI',    'UPI26072000210'),
        ( 6, '2026-08-11', 42500,  'UPI',    'UPI26081100577'),
        ( 7, '2026-08-02', 60000,  'DD',     'DD-SBI-448812'),
        ( 9, '2026-07-19', 87500,  'NEFT',   'NEFT2607190133'),
        (10, '2026-07-28', 45000,  'Cash',   'CASH-RCPT-2026-0412'),
        (12, '2026-07-21', 82500,  'Cheque', 'CHQ-HDFC-102334'),
        (15, '2026-07-17', 115000, 'NEFT',   'NEFT2607170102'),
        (16, '2026-08-05', 75000,  'UPI',    'UPI26080500719'),
        (17, '2026-07-23', 75000,  'Card',   'CRD26072300388')
     ) as x(student_id, paid_on, amount, mode, ref)
join fee_bill b on b.student_id = x.student_id and b.semester_id = 3;

-- -----------------------------------------------------------------------------
-- DEMO AUTH USERS (Supabase Auth) + USER_PROFILE role mapping
-- -----------------------------------------------------------------------------
create or replace function pg_temp.scms_demo_user(p_email text, p_password text, p_role text,
                                                  p_full_name text, p_student_id integer, p_faculty_id integer)
returns void
language plpgsql
as $$
declare
    v_id uuid;
begin
    select id into v_id from auth.users where email = p_email;

    if v_id is null then
        v_id := gen_random_uuid();
        insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                                raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                                confirmation_token, recovery_token, email_change_token_new, email_change,
                                email_change_token_current, reauthentication_token)
        values ('00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated', p_email,
                extensions.crypt(p_password, extensions.gen_salt('bf')), now(),
                '{"provider":"email","providers":["email"]}'::jsonb,
                jsonb_build_object('full_name', p_full_name), now(), now(),
                '', '', '', '', '', '');

        insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
        values (gen_random_uuid(), v_id, v_id::text,
                jsonb_build_object('sub', v_id::text, 'email', p_email, 'email_verified', true),
                'email', now(), now(), now());
    else
        update auth.users
           set encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf')),
               email_confirmed_at = coalesce(email_confirmed_at, now()),
               updated_at = now()
         where id = v_id;
    end if;

    insert into user_profile (user_id, role, full_name, student_id, faculty_id)
    values (v_id, p_role, p_full_name, p_student_id, p_faculty_id)
    on conflict (user_id) do update
        set role = excluded.role, full_name = excluded.full_name,
            student_id = excluded.student_id, faculty_id = excluded.faculty_id;
end;
$$;

do $$
declare
    v_pw text := '__DEMO_PASSWORD__';
begin
    if v_pw = '__DEMO_' || 'PASSWORD__' or length(v_pw) < 8 then
        raise exception 'Set a demo password (min 8 chars): run "npm run db:seed" with DEMO_PASSWORD in .env, or replace the placeholder in seed.sql.';
    end if;

    perform pg_temp.scms_demo_user('registrar@scms.edu.in',            v_pw, 'admin',    'Dr. Ramesh Iyengar', null, null);
    perform pg_temp.scms_demo_user('priya.raghavan@scms.edu.in',       v_pw, 'faculty',  'Dr. Priya Raghavan', null, 2);
    perform pg_temp.scms_demo_user('rohit.verma@scms.edu.in',          v_pw, 'faculty',  'Mr. Rohit Verma',    null, 3);
    perform pg_temp.scms_demo_user('sneha.kulkarni@scms.edu.in',       v_pw, 'faculty',  'Dr. Sneha Kulkarni', null, 4);
    perform pg_temp.scms_demo_user('accounts@scms.edu.in',             v_pw, 'accounts', 'Mr. Suresh Babu',    null, null);
    perform pg_temp.scms_demo_user('meera.nair@students.scms.edu.in',  v_pw, 'student',  'Meera Nair',         4,    null);
    perform pg_temp.scms_demo_user('aarav.mehta@students.scms.edu.in', v_pw, 'student',  'Aarav Mehta',        1,    null);
end $$;

-- -----------------------------------------------------------------------------
-- Keep identity sequences ahead of explicitly seeded keys.
-- -----------------------------------------------------------------------------
select setval(pg_get_serial_sequence('department', 'dept_id'),     (select max(dept_id)      from department));
select setval(pg_get_serial_sequence('programme',  'programme_id'),(select max(programme_id) from programme));
select setval(pg_get_serial_sequence('faculty',    'faculty_id'),  (select max(faculty_id)   from faculty));
select setval(pg_get_serial_sequence('course',     'course_id'),   (select max(course_id)    from course));
select setval(pg_get_serial_sequence('semester',   'semester_id'), (select max(semester_id)  from semester));
select setval(pg_get_serial_sequence('section',    'section_id'),  (select max(section_id)   from section));
select setval(pg_get_serial_sequence('student',    'student_id'),  (select max(student_id)   from student));

-- -----------------------------------------------------------------------------
-- INTEGRITY SELF-CHECK: each deliberate violation must be rejected by the DB.
-- Every attempt runs in its own sub-transaction and is rolled back.
-- -----------------------------------------------------------------------------
do $$
declare
    v_meera_bill integer;
    v_exam integer;
    v_reg integer;
begin
    -- 1. Duplicate registration (Aarav Mehta already in CS203-A)
    begin
        insert into registration (student_id, section_id) values (1, 8);
        raise exception 'CHECK FAILED: duplicate registration was accepted';
    exception when unique_violation then
        raise notice 'OK  duplicate registration rejected: %', sqlerrm;
    end;

    -- 2. Full section (CS203-B is 3/3)
    begin
        insert into registration (student_id, section_id) values (17, 9);
        raise exception 'CHECK FAILED: registration into a full section was accepted';
    exception when raise_exception then
        if sqlerrm like 'CHECK FAILED%' then raise; end if;
        raise notice 'OK  full section rejected: %', sqlerrm;
    end;

    -- 3. Invalid marks (105)
    select exam_id into v_exam from examination order by exam_id limit 1;
    begin
        update examination set marks = 105 where exam_id = v_exam;
        raise exception 'CHECK FAILED: marks 105 were accepted';
    exception when check_violation then
        raise notice 'OK  invalid marks rejected: %', sqlerrm;
    end;

    -- 4. Overpayment (Meera: ₹42,500 outstanding, try ₹50,000)
    select bill_id into v_meera_bill from fee_bill where student_id = 4 and semester_id = 3;
    begin
        insert into payment (bill_id, payment_date, amount_paid, payment_mode) values (v_meera_bill, current_date, 50000, 'UPI');
        raise exception 'CHECK FAILED: overpayment was accepted';
    exception when raise_exception then
        if sqlerrm like 'CHECK FAILED%' then raise; end if;
        raise notice 'OK  overpayment rejected: %', sqlerrm;
    end;

    -- 5. Invalid attendance status
    select registration_id into v_reg from registration where status = 'Registered' order by registration_id limit 1;
    begin
        insert into attendance (registration_id, attendance_date, status) values (v_reg, current_date - 1, 'Leave');
        raise exception 'CHECK FAILED: attendance status Leave was accepted';
    exception when check_violation then
        raise notice 'OK  invalid attendance status rejected: %', sqlerrm;
    end;

    -- 6. Orphan record (non-existent student)
    begin
        insert into guardian (student_id, name, relation, phone) values (99999, 'Nobody', 'Father', '9000000000');
        raise exception 'CHECK FAILED: orphan guardian was accepted';
    exception when foreign_key_violation then
        raise notice 'OK  orphan record rejected: %', sqlerrm;
    end;
end $$;

-- Summary of what was seeded
select 'department' as table_name, count(*) as rows from department union all
select 'programme',    count(*) from programme    union all
select 'faculty',      count(*) from faculty      union all
select 'course',       count(*) from course       union all
select 'semester',     count(*) from semester     union all
select 'section',      count(*) from section      union all
select 'student',      count(*) from student      union all
select 'guardian',     count(*) from guardian     union all
select 'registration', count(*) from registration union all
select 'attendance',   count(*) from attendance   union all
select 'examination',  count(*) from examination  union all
select 'grade',        count(*) from grade        union all
select 'fee_bill',     count(*) from fee_bill     union all
select 'payment',      count(*) from payment      union all
select 'user_profile', count(*) from user_profile;
