-- =============================================================================
-- SCMS — security.sql : role helpers, Row Level Security, grants
--
-- Roles live in user_profile (no client write access), so a user can never
-- promote themselves. Helper functions are SECURITY DEFINER so that policies
-- can look up role / ownership without recursive RLS evaluation.
--
--   admin    : full academic dataset (read/write), all reports
--   faculty  : reference data; own sections' roster, attendance, exams, grades
--   student  : own profile, registrations, attendance, exams, grades, bills, payments (read-only)
--   accounts : students (read), fee bills + payments (read/write)
--   anon     : nothing
-- =============================================================================

set search_path = public;

-- -----------------------------------------------------------------------------
-- Helper functions
-- -----------------------------------------------------------------------------
create or replace function app_role()
returns text language sql stable security definer set search_path = public as $$
    select role from user_profile where user_id = auth.uid();
$$;

create or replace function app_student_id()
returns integer language sql stable security definer set search_path = public as $$
    select student_id from user_profile where user_id = auth.uid();
$$;

create or replace function app_faculty_id()
returns integer language sql stable security definer set search_path = public as $$
    select faculty_id from user_profile where user_id = auth.uid();
$$;

create or replace function has_role(variadic p_roles text[])
returns boolean language sql stable security definer set search_path = public as $$
    select coalesce((select role from user_profile where user_id = auth.uid()) = any (p_roles), false);
$$;

-- Faculty teaches the section?
create or replace function teaches_section(p_section_id integer)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1 from section
                    where section_id = p_section_id
                      and faculty_id = app_faculty_id());
$$;

-- Faculty teaches the section of this registration?
create or replace function teaches_registration(p_registration_id integer)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1
                     from registration r
                     join section s on s.section_id = r.section_id
                    where r.registration_id = p_registration_id
                      and s.faculty_id = app_faculty_id());
$$;

-- Registration belongs to the logged-in student?
create or replace function owns_registration(p_registration_id integer)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1 from registration
                    where registration_id = p_registration_id
                      and student_id = app_student_id());
$$;

create or replace function owns_exam(p_exam_id integer)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1
                     from examination e
                     join registration r on r.registration_id = e.registration_id
                    where e.exam_id = p_exam_id
                      and r.student_id = app_student_id());
$$;

create or replace function teaches_exam(p_exam_id integer)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1
                     from examination e
                     join registration r on r.registration_id = e.registration_id
                     join section s      on s.section_id      = r.section_id
                    where e.exam_id = p_exam_id
                      and s.faculty_id = app_faculty_id());
$$;

-- Faculty has this student in any of their sections?
create or replace function teaches_student(p_student_id integer)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1
                     from registration r
                     join section s on s.section_id = r.section_id
                    where r.student_id = p_student_id
                      and s.faculty_id = app_faculty_id());
$$;

create or replace function owns_bill(p_bill_id integer)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1 from fee_bill
                    where bill_id = p_bill_id
                      and student_id = app_student_id());
$$;

-- -----------------------------------------------------------------------------
-- Grants: anon gets nothing; authenticated gets table privileges that are then
-- narrowed row-by-row by RLS.
-- -----------------------------------------------------------------------------
revoke all on all tables    in schema public from anon;
revoke all on all sequences in schema public from anon;
revoke execute on all functions in schema public from anon, public;

grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
grant execute on all functions in schema public to authenticated;

-- GRADE is written only by trigger; USER_PROFILE only by administrators via SQL.
revoke insert, update, delete on grade        from authenticated;
revoke insert, update, delete on user_profile from authenticated;
-- PAYMENT is an immutable ledger from the client's perspective.
revoke update, delete on payment from authenticated;

-- -----------------------------------------------------------------------------
-- Enable RLS on every exposed table
-- -----------------------------------------------------------------------------
alter table department   enable row level security;
alter table programme    enable row level security;
alter table faculty      enable row level security;
alter table course       enable row level security;
alter table semester     enable row level security;
alter table section      enable row level security;
alter table student      enable row level security;
alter table guardian     enable row level security;
alter table registration enable row level security;
alter table attendance   enable row level security;
alter table examination  enable row level security;
alter table grade        enable row level security;
alter table fee_bill     enable row level security;
alter table payment      enable row level security;
alter table user_profile enable row level security;

-- Drop existing policies so this file is re-runnable.
do $$
declare p record;
begin
    for p in select policyname, tablename from pg_policies where schemaname = 'public' loop
        execute format('drop policy if exists %I on public.%I', p.policyname, p.tablename);
    end loop;
end $$;

-- -----------------------------------------------------------------------------
-- Reference data: readable by any signed-in role, managed by admin.
-- -----------------------------------------------------------------------------
create policy department_read  on department for select to authenticated using (app_role() is not null);
create policy department_write on department for all    to authenticated using (has_role('admin')) with check (has_role('admin'));

create policy programme_read   on programme  for select to authenticated using (app_role() is not null);
create policy programme_write  on programme  for all    to authenticated using (has_role('admin')) with check (has_role('admin'));

create policy faculty_read     on faculty    for select to authenticated using (app_role() is not null);
create policy faculty_write    on faculty    for all    to authenticated using (has_role('admin')) with check (has_role('admin'));

create policy course_read      on course     for select to authenticated using (app_role() is not null);
create policy course_write     on course     for all    to authenticated using (has_role('admin')) with check (has_role('admin'));

create policy semester_read    on semester   for select to authenticated using (app_role() is not null);
create policy semester_write   on semester   for all    to authenticated using (has_role('admin')) with check (has_role('admin'));

create policy section_read     on section    for select to authenticated using (app_role() is not null);
create policy section_write    on section    for all    to authenticated using (has_role('admin')) with check (has_role('admin'));

-- -----------------------------------------------------------------------------
-- STUDENT
-- -----------------------------------------------------------------------------
create policy student_read on student for select to authenticated using (
    has_role('admin', 'accounts')
    or student_id = app_student_id()
    or (has_role('faculty') and teaches_student(student_id))
);
create policy student_insert on student for insert to authenticated with check (has_role('admin'));
create policy student_update on student for update to authenticated using (has_role('admin')) with check (has_role('admin'));

-- -----------------------------------------------------------------------------
-- GUARDIAN
-- -----------------------------------------------------------------------------
create policy guardian_read on guardian for select to authenticated using (
    has_role('admin') or student_id = app_student_id()
);
create policy guardian_write on guardian for all to authenticated
    using (has_role('admin')) with check (has_role('admin'));

-- -----------------------------------------------------------------------------
-- REGISTRATION (admin manages; faculty sees own rosters; student sees own)
-- -----------------------------------------------------------------------------
create policy registration_read on registration for select to authenticated using (
    has_role('admin')
    or student_id = app_student_id()
    or (has_role('faculty') and teaches_section(section_id))
);
create policy registration_insert on registration for insert to authenticated with check (has_role('admin'));
create policy registration_update on registration for update to authenticated using (has_role('admin')) with check (has_role('admin'));
create policy registration_delete on registration for delete to authenticated using (has_role('admin'));

-- -----------------------------------------------------------------------------
-- ATTENDANCE
-- -----------------------------------------------------------------------------
create policy attendance_read on attendance for select to authenticated using (
    has_role('admin')
    or owns_registration(registration_id)
    or (has_role('faculty') and teaches_registration(registration_id))
);
create policy attendance_insert on attendance for insert to authenticated with check (
    has_role('admin') or (has_role('faculty') and teaches_registration(registration_id))
);
create policy attendance_update on attendance for update to authenticated
    using      (has_role('admin') or (has_role('faculty') and teaches_registration(registration_id)))
    with check (has_role('admin') or (has_role('faculty') and teaches_registration(registration_id)));
create policy attendance_delete on attendance for delete to authenticated using (
    has_role('admin') or (has_role('faculty') and teaches_registration(registration_id))
);

-- -----------------------------------------------------------------------------
-- EXAMINATION
-- -----------------------------------------------------------------------------
create policy examination_read on examination for select to authenticated using (
    has_role('admin')
    or owns_registration(registration_id)
    or (has_role('faculty') and teaches_registration(registration_id))
);
create policy examination_insert on examination for insert to authenticated with check (
    has_role('admin') or (has_role('faculty') and teaches_registration(registration_id))
);
create policy examination_update on examination for update to authenticated
    using      (has_role('admin') or (has_role('faculty') and teaches_registration(registration_id)))
    with check (has_role('admin') or (has_role('faculty') and teaches_registration(registration_id)));

-- -----------------------------------------------------------------------------
-- GRADE (read-only for every client role)
-- -----------------------------------------------------------------------------
create policy grade_read on grade for select to authenticated using (
    has_role('admin')
    or owns_exam(exam_id)
    or (has_role('faculty') and teaches_exam(exam_id))
);

-- -----------------------------------------------------------------------------
-- FEE_BILL / PAYMENT (accounts + admin manage; student reads own)
-- -----------------------------------------------------------------------------
create policy fee_bill_read on fee_bill for select to authenticated using (
    has_role('admin', 'accounts') or student_id = app_student_id()
);
create policy fee_bill_insert on fee_bill for insert to authenticated with check (has_role('admin', 'accounts'));
create policy fee_bill_update on fee_bill for update to authenticated
    using (has_role('admin', 'accounts')) with check (has_role('admin', 'accounts'));
create policy fee_bill_delete on fee_bill for delete to authenticated using (has_role('admin', 'accounts'));

create policy payment_read on payment for select to authenticated using (
    has_role('admin', 'accounts') or owns_bill(bill_id)
);
create policy payment_insert on payment for insert to authenticated with check (has_role('admin', 'accounts'));

-- -----------------------------------------------------------------------------
-- USER_PROFILE (own row; admin sees all)
-- -----------------------------------------------------------------------------
create policy user_profile_read on user_profile for select to authenticated using (
    user_id = auth.uid() or has_role('admin')
);
