-- =============================================================================
-- SCMS — triggers.sql
-- Business rules enforced INSIDE the database (final integrity layer):
--   R1 duplicate registration           -> uq_registration_student_section (+ clear message here)
--   R2 section capacity                 -> trg_registration_rules (row lock on section)
--   R3 marks 0..100                     -> ck_examination_marks
--   R4 attendance status                -> ck_attendance_status
--   R5 no overpayment                   -> trg_payment_rules (row lock on fee_bill)
--   Grade calculation                   -> trg_examination_grade (deterministic mapping)
--   Fee bill status                     -> derived from payments, never typed in by users
-- Custom errors use SQLSTATE P0001 with a human-readable message and a HINT code.
-- =============================================================================

set search_path = public;

-- -----------------------------------------------------------------------------
-- Grade mapping (percentage = marks * 100 / max_marks)
--   90-100 A+ (10) | 80-89.99 A (9) | 70-79.99 B+ (8) | 60-69.99 B (7)
--   50-59.99 C (6) | 40-49.99 D (5) | <40 F (0)
-- -----------------------------------------------------------------------------
create or replace function fn_grade_for_percentage(p_pct numeric,
                                                   out grade_letter varchar,
                                                   out grade_point numeric)
language sql immutable
as $$
    select case
             when p_pct >= 90 then 'A+'
             when p_pct >= 80 then 'A'
             when p_pct >= 70 then 'B+'
             when p_pct >= 60 then 'B'
             when p_pct >= 50 then 'C'
             when p_pct >= 40 then 'D'
             else 'F'
           end,
           case
             when p_pct >= 90 then 10
             when p_pct >= 80 then 9
             when p_pct >= 70 then 8
             when p_pct >= 60 then 7
             when p_pct >= 50 then 6
             when p_pct >= 40 then 5
             else 0
           end::numeric(3,1);
$$;

-- Attendance threshold used by reports and UI (Present + Late count as attended).
create or replace function attendance_threshold()
returns numeric language sql immutable as $$ select 75.0::numeric $$;

-- Current semester = latest semester that has already started.
create or replace function current_semester_id()
returns integer language sql stable as $$
    select semester_id
    from semester
    where start_date <= current_date
    order by start_date desc
    limit 1;
$$;

-- -----------------------------------------------------------------------------
-- REGISTRATION: active student, no duplicate, one section per course per
-- semester, and capacity. The section row is locked FOR UPDATE so two
-- concurrent registrations cannot both take the last seat.
-- -----------------------------------------------------------------------------
create or replace function trg_registration_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_capacity        integer;
    v_taken           integer;
    v_label           text;
    v_course_id       integer;
    v_semester_id     integer;
    v_student_status  text;
begin
    -- Dropping a registration never needs a seat.
    if new.status = 'Dropped' then
        return new;
    end if;

    -- Status change Registered <-> Completed in the same section: seat already held.
    if tg_op = 'UPDATE' and old.section_id = new.section_id and old.status <> 'Dropped' then
        return new;
    end if;

    select status into v_student_status from student where student_id = new.student_id;
    if v_student_status is distinct from 'Active' and new.status = 'Registered' then
        raise exception 'Only Active students can be registered (current status: %).',
              coalesce(v_student_status, 'unknown')
              using errcode = 'P0001', hint = 'STUDENT_NOT_ACTIVE';
    end if;

    select s.capacity, c.course_code || ' - Section ' || s.section_code, s.course_id, s.semester_id
      into v_capacity, v_label, v_course_id, v_semester_id
      from section s
      join course c on c.course_id = s.course_id
     where s.section_id = new.section_id
       for update of s;

    if not found then
        return new;  -- fk_registration_section will reject it
    end if;

    if exists (select 1 from registration
                where student_id = new.student_id
                  and section_id = new.section_id
                  and registration_id <> new.registration_id) then
        raise exception 'This student is already registered in %.', v_label
              using errcode = '23505', hint = 'DUPLICATE_REGISTRATION';
    end if;

    if exists (select 1
                 from registration r
                 join section s on s.section_id = r.section_id
                where r.student_id  = new.student_id
                  and s.course_id   = v_course_id
                  and s.semester_id = v_semester_id
                  and r.status     <> 'Dropped'
                  and r.registration_id <> new.registration_id) then
        raise exception 'This student is already registered in another section of this course for the same semester.'
              using errcode = 'P0001', hint = 'DUPLICATE_COURSE';
    end if;

    select count(*) into v_taken
      from registration
     where section_id = new.section_id
       and status <> 'Dropped'
       and registration_id <> new.registration_id;

    if v_taken >= v_capacity then
        raise exception '% is full: % of % seats are taken.', v_label, v_taken, v_capacity
              using errcode = 'P0001', hint = 'SECTION_FULL';
    end if;

    return new;
end;
$$;

drop trigger if exists registration_rules on registration;
create trigger registration_rules
    before insert or update of section_id, status, student_id on registration
    for each row execute function trg_registration_rules();

-- -----------------------------------------------------------------------------
-- ATTENDANCE: only for non-dropped registrations, within the semester,
-- never in the future.
-- -----------------------------------------------------------------------------
create or replace function trg_attendance_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_reg_status text;
    v_start date;
    v_end   date;
begin
    select r.status, sm.start_date, sm.end_date
      into v_reg_status, v_start, v_end
      from registration r
      join section  s  on s.section_id  = r.section_id
      join semester sm on sm.semester_id = s.semester_id
     where r.registration_id = new.registration_id;

    if not found then
        return new;
    end if;

    if v_reg_status = 'Dropped' then
        raise exception 'Attendance cannot be recorded for a dropped registration.'
              using errcode = 'P0001', hint = 'REGISTRATION_DROPPED';
    end if;

    if new.attendance_date > current_date then
        raise exception 'Attendance cannot be recorded for a future date (%).', new.attendance_date
              using errcode = 'P0001', hint = 'FUTURE_DATE';
    end if;

    if new.attendance_date < v_start or new.attendance_date > v_end then
        raise exception 'Attendance date % is outside the semester (% to %).', new.attendance_date, v_start, v_end
              using errcode = 'P0001', hint = 'OUTSIDE_SEMESTER';
    end if;

    return new;
end;
$$;

drop trigger if exists attendance_rules on attendance;
create trigger attendance_rules
    before insert or update on attendance
    for each row execute function trg_attendance_rules();

-- -----------------------------------------------------------------------------
-- EXAMINATION: no exams for dropped registrations.
-- -----------------------------------------------------------------------------
create or replace function trg_examination_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if exists (select 1 from registration
                where registration_id = new.registration_id and status = 'Dropped') then
        raise exception 'Examination records cannot be created for a dropped registration.'
              using errcode = 'P0001', hint = 'REGISTRATION_DROPPED';
    end if;
    return new;
end;
$$;

drop trigger if exists examination_rules on examination;
create trigger examination_rules
    before insert or update of registration_id on examination
    for each row execute function trg_examination_rules();

-- -----------------------------------------------------------------------------
-- GRADE: computed from marks after every insert/update of an examination.
-- SECURITY DEFINER because no client role is allowed to write GRADE directly.
-- -----------------------------------------------------------------------------
create or replace function trg_examination_grade()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_letter varchar;
    v_point  numeric;
begin
    if new.marks is null then
        delete from grade where exam_id = new.exam_id;
        return new;
    end if;

    select g.grade_letter, g.grade_point
      into v_letter, v_point
      from fn_grade_for_percentage(new.marks * 100.0 / new.max_marks) g;

    insert into grade (exam_id, grade_letter, grade_point, graded_on)
    values (new.exam_id, v_letter, v_point, current_timestamp)
    on conflict (exam_id) do update
        set grade_letter = excluded.grade_letter,
            grade_point  = excluded.grade_point,
            graded_on    = excluded.graded_on;

    return new;
end;
$$;

drop trigger if exists examination_grade on examination;
create trigger examination_grade
    after insert or update of marks, max_marks on examination
    for each row execute function trg_examination_grade();

-- -----------------------------------------------------------------------------
-- FEE BILL status is always derived: Unpaid / Partially Paid / Paid.
-- -----------------------------------------------------------------------------
create or replace function fn_bill_status(p_due numeric, p_paid numeric)
returns varchar language sql immutable as $$
    select case
             when p_paid >= p_due then 'Paid'
             when p_paid > 0      then 'Partially Paid'
             else 'Unpaid'
           end;
$$;

create or replace function trg_fee_bill_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_paid numeric := 0;
begin
    if tg_op = 'UPDATE' then
        select coalesce(sum(amount_paid), 0) into v_paid from payment where bill_id = new.bill_id;
        if new.amount_due < v_paid then
            raise exception 'Amount due (₹%) cannot be lower than the amount already paid (₹%).', new.amount_due, v_paid
                  using errcode = 'P0001', hint = 'DUE_BELOW_PAID';
        end if;
        if new.student_id <> old.student_id and v_paid > 0 then
            raise exception 'A bill that already has payments cannot be moved to another student.'
                  using errcode = 'P0001', hint = 'BILL_HAS_PAYMENTS';
        end if;
    end if;

    new.status := fn_bill_status(new.amount_due, v_paid);
    return new;
end;
$$;

drop trigger if exists fee_bill_rules on fee_bill;
create trigger fee_bill_rules
    before insert or update on fee_bill
    for each row execute function trg_fee_bill_rules();

-- -----------------------------------------------------------------------------
-- PAYMENT: reject overpayment. The bill row is locked so concurrent payments
-- are serialised and cannot jointly exceed amount_due.
-- -----------------------------------------------------------------------------
create or replace function trg_payment_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_due  numeric;
    v_paid numeric;
begin
    select amount_due into v_due from fee_bill where bill_id = new.bill_id for update;
    if not found then
        return new;  -- fk_payment_fee_bill will reject it
    end if;

    select coalesce(sum(amount_paid), 0) into v_paid
      from payment
     where bill_id = new.bill_id
       and payment_id <> new.payment_id;

    if v_paid + new.amount_paid > v_due then
        raise exception 'Overpayment rejected: outstanding balance on bill #% is ₹%, but ₹% was entered.',
              new.bill_id, (v_due - v_paid), new.amount_paid
              using errcode = 'P0001', hint = 'OVERPAYMENT';
    end if;

    return new;
end;
$$;

drop trigger if exists payment_rules on payment;
create trigger payment_rules
    before insert or update of amount_paid, bill_id on payment
    for each row execute function trg_payment_rules();

create or replace function trg_payment_refresh_bill()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_bill integer := coalesce(new.bill_id, old.bill_id);
begin
    update fee_bill
       set status = fn_bill_status(amount_due,
                     (select coalesce(sum(amount_paid), 0) from payment where bill_id = v_bill))
     where bill_id = v_bill;
    if tg_op = 'UPDATE' and old.bill_id <> new.bill_id then
        update fee_bill
           set status = fn_bill_status(amount_due,
                         (select coalesce(sum(amount_paid), 0) from payment where bill_id = old.bill_id))
         where bill_id = old.bill_id;
    end if;
    return null;
end;
$$;

drop trigger if exists payment_refresh_bill on payment;
create trigger payment_refresh_bill
    after insert or update or delete on payment
    for each row execute function trg_payment_refresh_bill();

-- =============================================================================
-- TRANSACTIONAL RPCs (SECURITY INVOKER: Row Level Security still applies).
-- A PL/pgSQL function call runs in a single transaction, so either every
-- statement succeeds or none is persisted.
-- =============================================================================

-- Admission: student + guardian in one transaction.
create or replace function admit_student(p_student jsonb, p_guardian jsonb default null)
returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
    v_student_id integer;
begin
    insert into student (programme_id, reg_no, full_name, dob, email, phone, admission_date, status)
    values ((p_student->>'programme_id')::integer,
            upper(trim(p_student->>'reg_no')),
            trim(p_student->>'full_name'),
            (p_student->>'dob')::date,
            lower(trim(p_student->>'email')),
            trim(p_student->>'phone'),
            coalesce((p_student->>'admission_date')::date, current_date),
            coalesce(nullif(p_student->>'status', ''), 'Active'))
    returning student_id into v_student_id;

    if p_guardian is not null and coalesce(trim(p_guardian->>'name'), '') <> '' then
        insert into guardian (student_id, name, relation, phone, email, address)
        values (v_student_id,
                trim(p_guardian->>'name'),
                p_guardian->>'relation',
                trim(p_guardian->>'phone'),
                nullif(lower(trim(p_guardian->>'email')), ''),
                nullif(trim(p_guardian->>'address'), ''));
    end if;

    return v_student_id;
end;
$$;

-- Attendance for a whole section on one date (insert or correct), atomically.
-- p_entries: [{"registration_id": 1, "status": "Present"}, ...]
create or replace function save_attendance(p_section_id integer, p_date date, p_entries jsonb)
returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
    v_count   integer;
    v_invalid integer;
begin
    select count(*) into v_invalid
      from jsonb_array_elements(p_entries) e
      left join registration r
             on r.registration_id = (e->>'registration_id')::integer
            and r.section_id = p_section_id
     where r.registration_id is null;

    if v_invalid > 0 then
        raise exception '% attendance entr(y/ies) do not belong to the selected section.', v_invalid
              using errcode = 'P0001', hint = 'WRONG_SECTION';
    end if;

    insert into attendance (registration_id, attendance_date, status)
    select (e->>'registration_id')::integer, p_date, e->>'status'
      from jsonb_array_elements(p_entries) e
    on conflict (registration_id, attendance_date)
    do update set status = excluded.status;

    get diagnostics v_count = row_count;
    return v_count;
end;
$$;

-- Marks entry / correction; the grade trigger fires inside the same transaction.
create or replace function record_exam_result(p_registration_id integer,
                                              p_exam_type varchar,
                                              p_exam_date date,
                                              p_marks numeric,
                                              p_max_marks numeric default 100)
returns table (exam_id integer, marks numeric, grade_letter varchar, grade_point numeric)
language plpgsql
security invoker
set search_path = public
as $$
#variable_conflict use_column
declare
    v_exam_id integer;
begin
    insert into examination (registration_id, exam_type, exam_date, max_marks, marks)
    values (p_registration_id, p_exam_type, p_exam_date, coalesce(p_max_marks, 100), p_marks)
    on conflict (registration_id, exam_type)
    do update set exam_date = excluded.exam_date,
                  max_marks = excluded.max_marks,
                  marks     = excluded.marks
    returning examination.exam_id into v_exam_id;

    return query
        select e.exam_id, e.marks, g.grade_letter, g.grade_point
          from examination e
          left join grade g on g.exam_id = e.exam_id
         where e.exam_id = v_exam_id;
end;
$$;
