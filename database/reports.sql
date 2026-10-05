-- =============================================================================
-- SCMS — reports.sql : reusable reporting views + dashboard RPC
-- All views use security_invoker = true so Row Level Security of the caller
-- still applies (a student querying a view only sees their own rows).
-- =============================================================================

set search_path = public;

drop function if exists dashboard_summary();
drop view if exists v_student_sgpa;
drop view if exists v_student_academic_history;
drop view if exists v_result_analysis;
drop view if exists v_exam_details;
drop view if exists v_attendance_summary;
drop view if exists v_student_dues;
drop view if exists v_fee_dues;
drop view if exists v_department_summary;
drop view if exists v_programme_summary;
drop view if exists v_section_occupancy;

-- -----------------------------------------------------------------------------
-- 1. SECTION OCCUPANCY — registered count, capacity, remaining seats
-- -----------------------------------------------------------------------------
create view v_section_occupancy with (security_invoker = true) as
select s.section_id,
       s.semester_id,
       sm.academic_year || ' ' || sm.term                         as semester_label,
       c.course_id,
       c.course_code,
       c.course_name,
       c.credits,
       c.course_type,
       d.dept_code,
       s.section_code,
       s.room_no,
       f.faculty_id,
       f.full_name                                                as faculty_name,
       s.capacity,
       count(r.registration_id) filter (where r.status <> 'Dropped')                       as registered_count,
       s.capacity - count(r.registration_id) filter (where r.status <> 'Dropped')          as remaining_seats,
       round(100.0 * count(r.registration_id) filter (where r.status <> 'Dropped') / s.capacity, 1) as occupancy_pct,
       count(r.registration_id) filter (where r.status <> 'Dropped') >= s.capacity          as is_full
from section s
join course     c  on c.course_id   = s.course_id
join department d  on d.dept_id     = c.dept_id
join faculty    f  on f.faculty_id  = s.faculty_id
join semester   sm on sm.semester_id = s.semester_id
left join registration r on r.section_id = s.section_id
group by s.section_id, sm.semester_id, c.course_id, d.dept_id, f.faculty_id;

-- -----------------------------------------------------------------------------
-- 2. ATTENDANCE SUMMARY — percentage by student and course
--    attended = Present + Late ; shortage when below attendance_threshold() (75%)
-- -----------------------------------------------------------------------------
create view v_attendance_summary with (security_invoker = true) as
select r.registration_id,
       r.student_id,
       st.reg_no,
       st.full_name                         as student_name,
       p.programme_code,
       s.section_id,
       s.semester_id,
       sm.academic_year || ' ' || sm.term   as semester_label,
       c.course_code,
       c.course_name,
       s.section_code,
       s.faculty_id,
       f.full_name                          as faculty_name,
       count(a.attendance_id)                                   as total_classes,
       count(a.attendance_id) filter (where a.status = 'Present') as present_count,
       count(a.attendance_id) filter (where a.status = 'Late')    as late_count,
       count(a.attendance_id) filter (where a.status = 'Absent')  as absent_count,
       round(100.0 * count(a.attendance_id) filter (where a.status in ('Present', 'Late'))
             / nullif(count(a.attendance_id), 0), 1)            as attendance_pct,
       coalesce(100.0 * count(a.attendance_id) filter (where a.status in ('Present', 'Late'))
             / nullif(count(a.attendance_id), 0) < attendance_threshold(), false) as is_shortage
from registration r
join student   st on st.student_id   = r.student_id
join programme p  on p.programme_id  = st.programme_id
join section   s  on s.section_id    = r.section_id
join course    c  on c.course_id     = s.course_id
join faculty   f  on f.faculty_id    = s.faculty_id
join semester  sm on sm.semester_id  = s.semester_id
left join attendance a on a.registration_id = r.registration_id
where r.status <> 'Dropped'
group by r.registration_id, st.student_id, p.programme_id, s.section_id, c.course_id, f.faculty_id, sm.semester_id;

-- -----------------------------------------------------------------------------
-- 3. EXAM DETAILS — one row per examination with its grade
-- -----------------------------------------------------------------------------
create view v_exam_details with (security_invoker = true) as
select e.exam_id,
       e.registration_id,
       e.exam_type,
       e.exam_date,
       e.max_marks,
       e.marks,
       round(e.marks * 100.0 / e.max_marks, 2) as percentage,
       g.grade_letter,
       g.grade_point,
       g.graded_on,
       r.student_id,
       st.reg_no,
       st.full_name                            as student_name,
       s.section_id,
       s.section_code,
       s.semester_id,
       sm.academic_year || ' ' || sm.term      as semester_label,
       c.course_code,
       c.course_name,
       c.credits,
       s.faculty_id,
       f.full_name                             as faculty_name
from examination e
join registration r on r.registration_id = e.registration_id
join student  st on st.student_id  = r.student_id
join section  s  on s.section_id   = r.section_id
join course   c  on c.course_id    = s.course_id
join faculty  f  on f.faculty_id   = s.faculty_id
join semester sm on sm.semester_id = s.semester_id
left join grade g on g.exam_id = e.exam_id;

-- -----------------------------------------------------------------------------
-- 4. RESULT ANALYSIS — per section and exam type
-- -----------------------------------------------------------------------------
create view v_result_analysis with (security_invoker = true) as
select s.section_id,
       s.semester_id,
       sm.academic_year || ' ' || sm.term                  as semester_label,
       c.course_code,
       c.course_name,
       s.section_code,
       s.faculty_id,
       f.full_name                                         as faculty_name,
       e.exam_type,
       min(e.exam_date)                                    as exam_date,
       count(e.exam_id)                                    as candidates,
       count(e.marks)                                      as evaluated,
       round(avg(e.marks * 100.0 / e.max_marks), 2)        as average_pct,
       round(max(e.marks * 100.0 / e.max_marks), 2)        as highest_pct,
       round(min(e.marks * 100.0 / e.max_marks), 2)        as lowest_pct,
       count(g.grade_id) filter (where g.grade_letter <> 'F') as passed,
       count(g.grade_id) filter (where g.grade_letter =  'F') as failed,
       round(100.0 * count(g.grade_id) filter (where g.grade_letter <> 'F')
             / nullif(count(g.grade_id), 0), 1)            as pass_pct,
       count(g.grade_id) filter (where g.grade_letter = 'A+') as grade_a_plus,
       count(g.grade_id) filter (where g.grade_letter = 'A')  as grade_a,
       count(g.grade_id) filter (where g.grade_letter = 'B+') as grade_b_plus,
       count(g.grade_id) filter (where g.grade_letter = 'B')  as grade_b,
       count(g.grade_id) filter (where g.grade_letter = 'C')  as grade_c,
       count(g.grade_id) filter (where g.grade_letter = 'D')  as grade_d,
       count(g.grade_id) filter (where g.grade_letter = 'F')  as grade_f
from examination e
join registration r on r.registration_id = e.registration_id
join section  s  on s.section_id   = r.section_id
join course   c  on c.course_id    = s.course_id
join faculty  f  on f.faculty_id   = s.faculty_id
join semester sm on sm.semester_id = s.semester_id
left join grade g on g.exam_id = e.exam_id
where r.status <> 'Dropped'
group by s.section_id, c.course_id, f.faculty_id, sm.semester_id, e.exam_type;

-- -----------------------------------------------------------------------------
-- 5. STUDENT ACADEMIC HISTORY — one row per registration
--    Final course grade = grade of the End-Term examination.
-- -----------------------------------------------------------------------------
create view v_student_academic_history with (security_invoker = true) as
select r.registration_id,
       r.student_id,
       st.reg_no,
       st.full_name                         as student_name,
       p.programme_code,
       p.programme_name,
       sm.semester_id,
       sm.academic_year || ' ' || sm.term   as semester_label,
       sm.start_date                        as semester_start,
       c.course_code,
       c.course_name,
       c.credits,
       s.section_id,
       s.section_code,
       f.full_name                          as faculty_name,
       r.status                             as registration_status,
       max(e.marks)        filter (where e.exam_type = 'Mid-Term') as mid_term_marks,
       max(e.marks)        filter (where e.exam_type = 'End-Term') as end_term_marks,
       max(g.grade_letter) filter (where e.exam_type = 'End-Term') as final_grade,
       max(g.grade_point)  filter (where e.exam_type = 'End-Term') as final_grade_point,
       (select round(100.0 * count(*) filter (where a.status in ('Present', 'Late')) / nullif(count(*), 0), 1)
          from attendance a
         where a.registration_id = r.registration_id)              as attendance_pct
from registration r
join student   st on st.student_id  = r.student_id
join programme p  on p.programme_id = st.programme_id
join section   s  on s.section_id   = r.section_id
join course    c  on c.course_id    = s.course_id
join faculty   f  on f.faculty_id   = s.faculty_id
join semester  sm on sm.semester_id = s.semester_id
left join examination e on e.registration_id = r.registration_id
left join grade       g on g.exam_id         = e.exam_id
group by r.registration_id, st.student_id, p.programme_id, sm.semester_id, c.course_id, s.section_id, f.faculty_id;

-- SGPA per student per semester (credit-weighted End-Term grade points)
create view v_student_sgpa with (security_invoker = true) as
select student_id,
       reg_no,
       student_name,
       semester_id,
       semester_label,
       semester_start,
       count(*)                                                     as courses,
       sum(credits)                                                 as credits_registered,
       sum(credits) filter (where final_grade is not null and final_grade <> 'F') as credits_earned,
       round(sum(credits * final_grade_point) / nullif(sum(credits) filter (where final_grade_point is not null), 0), 2) as sgpa
from v_student_academic_history
where registration_status <> 'Dropped'
group by student_id, reg_no, student_name, semester_id, semester_label, semester_start;

-- -----------------------------------------------------------------------------
-- 6. FEE DUES — per bill, and aggregated per student
-- -----------------------------------------------------------------------------
create view v_fee_dues with (security_invoker = true) as
select b.bill_id,
       b.student_id,
       st.reg_no,
       st.full_name                                   as student_name,
       st.status                                      as student_status,
       p.programme_code,
       b.semester_id,
       sm.academic_year || ' ' || sm.term             as semester_label,
       b.bill_date,
       b.due_date,
       b.amount_due,
       coalesce(sum(py.amount_paid), 0)               as amount_paid,
       b.amount_due - coalesce(sum(py.amount_paid), 0) as balance,
       b.status,
       count(py.payment_id)                           as payment_count,
       max(py.payment_date)                           as last_payment_date,
       (b.due_date < current_date and b.amount_due - coalesce(sum(py.amount_paid), 0) > 0) as is_overdue,
       case when b.amount_due - coalesce(sum(py.amount_paid), 0) > 0
            then greatest(current_date - b.due_date, 0) else 0 end as days_overdue
from fee_bill b
join student   st on st.student_id  = b.student_id
join programme p  on p.programme_id = st.programme_id
join semester  sm on sm.semester_id = b.semester_id
left join payment py on py.bill_id = b.bill_id
group by b.bill_id, st.student_id, p.programme_id, sm.semester_id;

create view v_student_dues with (security_invoker = true) as
select student_id,
       reg_no,
       student_name,
       student_status,
       programme_code,
       count(*)                                  as bills,
       sum(amount_due)                           as total_billed,
       sum(amount_paid)                          as total_paid,
       sum(balance)                              as outstanding,
       count(*) filter (where is_overdue)        as overdue_bills,
       max(days_overdue)                         as max_days_overdue
from v_fee_dues
group by student_id, reg_no, student_name, student_status, programme_code;

-- -----------------------------------------------------------------------------
-- 7. PROGRAMME / DEPARTMENT SUMMARY
-- -----------------------------------------------------------------------------
create view v_programme_summary with (security_invoker = true) as
select p.programme_id,
       p.programme_code,
       p.programme_name,
       p.duration_years,
       p.status,
       d.dept_id,
       d.dept_code,
       d.dept_name,
       count(s.student_id)                                    as total_students,
       count(s.student_id) filter (where s.status = 'Active')    as active_students,
       count(s.student_id) filter (where s.status = 'Graduated') as graduated_students,
       count(s.student_id) filter (where s.status in ('Withdrawn', 'Inactive')) as inactive_students
from programme p
join department d on d.dept_id = p.dept_id
left join student s on s.programme_id = p.programme_id
group by p.programme_id, d.dept_id;

create view v_department_summary with (security_invoker = true) as
select d.dept_id,
       d.dept_code,
       d.dept_name,
       d.office_email,
       (select count(*) from programme x where x.dept_id = d.dept_id)                          as programmes,
       (select count(*) from programme x where x.dept_id = d.dept_id and x.status = 'Active')  as active_programmes,
       (select count(*) from faculty   x where x.dept_id = d.dept_id and x.status = 'Active')  as faculty_count,
       (select count(*) from course    x where x.dept_id = d.dept_id and x.status = 'Active')  as course_count,
       coalesce(ps.total_students, 0)  as total_students,
       coalesce(ps.active_students, 0) as active_students
from department d
left join (select dept_id,
                  sum(total_students)  as total_students,
                  sum(active_students) as active_students
             from v_programme_summary
            group by dept_id) ps on ps.dept_id = d.dept_id;

-- -----------------------------------------------------------------------------
-- DASHBOARD — every KPI is a live query (RLS-filtered for the caller)
-- -----------------------------------------------------------------------------
create or replace function dashboard_summary()
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
    with cur as (select current_semester_id() as semester_id)
    select jsonb_build_object(
        'current_semester', (select jsonb_build_object('semester_id', sm.semester_id,
                                                       'label', sm.academic_year || ' ' || sm.term,
                                                       'start_date', sm.start_date,
                                                       'end_date', sm.end_date)
                               from semester sm, cur where sm.semester_id = cur.semester_id),
        'total_students',        (select count(*) from student where status = 'Active'),
        'active_programmes',     (select count(*) from programme where status = 'Active'),
        'active_sections',       (select count(*) from section s, cur where s.semester_id = cur.semester_id),
        'current_registrations', (select count(*) from registration r join section s on s.section_id = r.section_id, cur
                                   where s.semester_id = cur.semester_id and r.status = 'Registered'),
        'attendance_shortage',   (select count(*) from v_attendance_summary v, cur
                                   where v.semester_id = cur.semester_id and v.is_shortage),
        'outstanding_fees',      (select coalesce(sum(balance), 0) from v_fee_dues),
        'overdue_bills',         (select count(*) from v_fee_dues where is_overdue),
        'collected_this_month',  (select coalesce(sum(amount_paid), 0) from payment
                                   where payment_date >= date_trunc('month', current_date)),
        'recent_payments', (select coalesce(jsonb_agg(x order by x.payment_date desc, x.payment_id desc), '[]'::jsonb)
                              from (select py.payment_id, py.payment_date, py.amount_paid, py.payment_mode,
                                           py.reference_no, st.full_name as student_name, st.reg_no
                                      from payment py
                                      join fee_bill b on b.bill_id = py.bill_id
                                      join student st on st.student_id = b.student_id
                                     order by py.payment_date desc, py.payment_id desc
                                     limit 6) x),
        'exams', (select coalesce(jsonb_agg(x order by x.exam_date desc), '[]'::jsonb)
                    from (select v.exam_date, v.exam_type, v.course_code, v.course_name, v.section_code,
                                 count(*) as candidates, count(v.marks) as evaluated,
                                 round(avg(v.percentage), 1) as average_pct
                            from v_exam_details v, cur
                           where v.semester_id = cur.semester_id
                           group by v.exam_date, v.exam_type, v.course_code, v.course_name, v.section_code
                           order by v.exam_date desc
                           limit 8) x)
    );
$$;

-- Supabase default privileges grant new objects to anon; take that back.
revoke all on v_section_occupancy, v_attendance_summary, v_exam_details, v_result_analysis,
              v_student_academic_history, v_student_sgpa, v_fee_dues, v_student_dues,
              v_programme_summary, v_department_summary from anon;
grant select on v_section_occupancy, v_attendance_summary, v_exam_details, v_result_analysis,
                v_student_academic_history, v_student_sgpa, v_fee_dues, v_student_dues,
                v_programme_summary, v_department_summary to authenticated;
revoke execute on function dashboard_summary() from anon, public;
grant execute on function dashboard_summary() to authenticated;
