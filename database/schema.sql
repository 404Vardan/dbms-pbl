-- =============================================================================
-- SCMS — Student & College Management System
-- schema.sql : 14 domain tables + 1 auth-support table (user_profile)
-- Target     : Supabase PostgreSQL 15+
-- Order      : schema.sql -> triggers.sql -> security.sql -> reports.sql -> seed.sql
--
-- Constraint names are explicit on purpose: the frontend maps them to
-- human-readable messages (src/lib/errors.js).
-- =============================================================================

set search_path = public;

-- -----------------------------------------------------------------------------
-- 1. DEPARTMENT
-- -----------------------------------------------------------------------------
create table if not exists department (
    dept_id       integer generated always as identity primary key,
    dept_code     varchar(10)  not null,
    dept_name     varchar(100) not null,
    office_email  varchar(120),
    constraint uq_department_code  unique (dept_code),
    constraint uq_department_name  unique (dept_name),
    constraint uq_department_email unique (office_email),
    constraint ck_department_email check (office_email is null or office_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

-- -----------------------------------------------------------------------------
-- 2. PROGRAMME
-- -----------------------------------------------------------------------------
create table if not exists programme (
    programme_id    integer generated always as identity primary key,
    dept_id         integer      not null,
    programme_code  varchar(15)  not null,
    programme_name  varchar(120) not null,
    duration_years  smallint     not null,
    status          varchar(10)  not null default 'Active',
    constraint fk_programme_department foreign key (dept_id) references department (dept_id) on delete restrict,
    constraint uq_programme_code       unique (programme_code),
    constraint ck_programme_duration   check (duration_years > 0),
    constraint ck_programme_status     check (status in ('Active', 'Inactive'))
);

-- -----------------------------------------------------------------------------
-- 3. FACULTY
-- -----------------------------------------------------------------------------
create table if not exists faculty (
    faculty_id     integer generated always as identity primary key,
    dept_id        integer      not null,
    employee_code  varchar(15)  not null,
    full_name      varchar(100) not null,
    email          varchar(120) not null,
    designation    varchar(60)  not null,
    status         varchar(10)  not null default 'Active',
    constraint fk_faculty_department foreign key (dept_id) references department (dept_id) on delete restrict,
    constraint uq_faculty_employee_code unique (employee_code),
    constraint uq_faculty_email         unique (email),
    constraint ck_faculty_email         check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    constraint ck_faculty_status        check (status in ('Active', 'Inactive'))
);

-- -----------------------------------------------------------------------------
-- 4. COURSE
-- -----------------------------------------------------------------------------
create table if not exists course (
    course_id    integer generated always as identity primary key,
    dept_id      integer      not null,
    course_code  varchar(12)  not null,
    course_name  varchar(120) not null,
    credits      smallint     not null,
    course_type  varchar(10)  not null default 'Core',
    status       varchar(10)  not null default 'Active',
    constraint fk_course_department foreign key (dept_id) references department (dept_id) on delete restrict,
    constraint uq_course_code       unique (course_code),
    constraint ck_course_credits    check (credits > 0),
    constraint ck_course_type       check (course_type in ('Core', 'Elective', 'Lab', 'Project')),
    constraint ck_course_status     check (status in ('Active', 'Inactive'))
);

-- -----------------------------------------------------------------------------
-- 6. SEMESTER  (created before SECTION because SECTION references it)
-- -----------------------------------------------------------------------------
create table if not exists semester (
    semester_id    integer generated always as identity primary key,
    academic_year  varchar(9)  not null,           -- e.g. '2026-27'
    term           varchar(10) not null,           -- Odd / Even / Summer
    start_date     date        not null,
    end_date       date        not null,
    constraint uq_semester_year_term unique (academic_year, term),
    constraint ck_semester_dates     check (end_date >= start_date),
    constraint ck_semester_term      check (term in ('Odd', 'Even', 'Summer')),
    constraint ck_semester_year      check (academic_year ~ '^[0-9]{4}-[0-9]{2}$')
);

-- -----------------------------------------------------------------------------
-- 5. SECTION
-- -----------------------------------------------------------------------------
create table if not exists section (
    section_id    integer generated always as identity primary key,
    course_id     integer     not null,
    faculty_id    integer     not null,
    semester_id   integer     not null,
    section_code  varchar(5)  not null,
    room_no       varchar(15) not null,
    capacity      smallint    not null,
    constraint fk_section_course   foreign key (course_id)   references course (course_id)     on delete restrict,
    constraint fk_section_faculty  foreign key (faculty_id)  references faculty (faculty_id)   on delete restrict,
    constraint fk_section_semester foreign key (semester_id) references semester (semester_id) on delete restrict,
    constraint uq_section_course_semester_code unique (course_id, semester_id, section_code),
    constraint ck_section_capacity check (capacity > 0)
);

-- -----------------------------------------------------------------------------
-- 7. STUDENT
-- -----------------------------------------------------------------------------
create table if not exists student (
    student_id      integer generated always as identity primary key,
    programme_id    integer      not null,
    reg_no          varchar(20)  not null,
    full_name       varchar(100) not null,
    dob             date         not null,
    email           varchar(120) not null,
    phone           varchar(15)  not null,
    admission_date  date         not null,
    status          varchar(12)  not null default 'Active',
    constraint fk_student_programme foreign key (programme_id) references programme (programme_id) on delete restrict,
    constraint uq_student_reg_no    unique (reg_no),
    constraint uq_student_email     unique (email),
    constraint ck_student_email     check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    constraint ck_student_phone     check (phone ~ '^\+?[0-9]{10,13}$'),
    constraint ck_student_dob       check (dob < admission_date),
    constraint ck_student_status    check (status in ('Active', 'Inactive', 'Graduated', 'Withdrawn'))
);

-- -----------------------------------------------------------------------------
-- 8. GUARDIAN
-- -----------------------------------------------------------------------------
create table if not exists guardian (
    guardian_id  integer generated always as identity primary key,
    student_id   integer      not null,
    name         varchar(100) not null,
    relation     varchar(20)  not null,
    phone        varchar(15)  not null,
    email        varchar(120),
    address      text,
    constraint fk_guardian_student foreign key (student_id) references student (student_id) on delete restrict,
    constraint uq_guardian_email   unique (email),
    constraint ck_guardian_email   check (email is null or email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    constraint ck_guardian_phone   check (phone ~ '^\+?[0-9]{10,13}$'),
    constraint ck_guardian_relation check (relation in ('Father', 'Mother', 'Guardian', 'Sibling', 'Spouse', 'Other'))
);

-- -----------------------------------------------------------------------------
-- 9. REGISTRATION
-- -----------------------------------------------------------------------------
create table if not exists registration (
    registration_id  integer generated always as identity primary key,
    student_id       integer     not null,
    section_id       integer     not null,
    registered_on    timestamptz not null default current_timestamp,
    status           varchar(12) not null default 'Registered',
    constraint fk_registration_student foreign key (student_id) references student (student_id) on delete restrict,
    constraint fk_registration_section foreign key (section_id) references section (section_id) on delete restrict,
    constraint uq_registration_student_section unique (student_id, section_id),
    constraint ck_registration_status check (status in ('Registered', 'Dropped', 'Completed'))
);

-- -----------------------------------------------------------------------------
-- 10. ATTENDANCE
-- -----------------------------------------------------------------------------
create table if not exists attendance (
    attendance_id    integer generated always as identity primary key,
    registration_id  integer     not null,
    attendance_date  date        not null,
    status           varchar(7)  not null,
    constraint fk_attendance_registration foreign key (registration_id) references registration (registration_id) on delete restrict,
    constraint uq_attendance_registration_date unique (registration_id, attendance_date),
    constraint ck_attendance_status check (status in ('Present', 'Absent', 'Late'))
);

-- -----------------------------------------------------------------------------
-- 11. EXAMINATION
-- marks is nullable: a scheduled exam has no marks until evaluated.
-- -----------------------------------------------------------------------------
create table if not exists examination (
    exam_id          integer generated always as identity primary key,
    registration_id  integer      not null,
    exam_type        varchar(12)  not null,
    exam_date        date         not null,
    max_marks        numeric(5,2) not null default 100,
    marks            numeric(5,2),
    constraint fk_examination_registration foreign key (registration_id) references registration (registration_id) on delete restrict,
    constraint uq_examination_registration_type unique (registration_id, exam_type),
    constraint ck_examination_type      check (exam_type in ('Mid-Term', 'End-Term', 'Internal', 'Practical')),
    constraint ck_examination_max_marks check (max_marks > 0 and max_marks <= 100),
    constraint ck_examination_marks     check (marks between 0 and 100),
    constraint ck_examination_marks_max check (marks <= max_marks)
);

-- -----------------------------------------------------------------------------
-- 12. GRADE  (one grade per examination; maintained by trigger, see triggers.sql)
-- -----------------------------------------------------------------------------
create table if not exists grade (
    grade_id      integer generated always as identity primary key,
    exam_id       integer      not null,
    grade_letter  varchar(2)   not null,
    grade_point   numeric(3,1) not null,
    graded_on     timestamptz  not null default current_timestamp,
    constraint fk_grade_examination foreign key (exam_id) references examination (exam_id) on delete cascade,
    constraint uq_grade_exam        unique (exam_id),
    constraint ck_grade_letter      check (grade_letter in ('A+', 'A', 'B+', 'B', 'C', 'D', 'F')),
    constraint ck_grade_point       check (grade_point >= 0 and grade_point <= 10)
);

-- -----------------------------------------------------------------------------
-- 13. FEE_BILL  (status is derived from payments by trigger)
-- -----------------------------------------------------------------------------
create table if not exists fee_bill (
    bill_id      integer generated always as identity primary key,
    student_id   integer       not null,
    semester_id  integer       not null,
    bill_date    date          not null default current_date,
    amount_due   numeric(10,2) not null,
    due_date     date          not null,
    status       varchar(15)   not null default 'Unpaid',
    constraint fk_fee_bill_student  foreign key (student_id)  references student (student_id)   on delete restrict,
    constraint fk_fee_bill_semester foreign key (semester_id) references semester (semester_id) on delete restrict,
    constraint uq_fee_bill_student_semester unique (student_id, semester_id),
    constraint ck_fee_bill_amount   check (amount_due >= 0),
    constraint ck_fee_bill_due_date check (due_date >= bill_date),
    constraint ck_fee_bill_status   check (status in ('Unpaid', 'Partially Paid', 'Paid'))
);

-- -----------------------------------------------------------------------------
-- 14. PAYMENT
-- -----------------------------------------------------------------------------
create table if not exists payment (
    payment_id    integer generated always as identity primary key,
    bill_id       integer       not null,
    payment_date  date          not null default current_date,
    amount_paid   numeric(10,2) not null,
    payment_mode  varchar(10)   not null,
    reference_no  varchar(40),
    constraint fk_payment_fee_bill foreign key (bill_id) references fee_bill (bill_id) on delete restrict,
    constraint uq_payment_reference unique (reference_no),
    constraint ck_payment_amount    check (amount_paid > 0),
    constraint ck_payment_mode      check (payment_mode in ('Cash', 'UPI', 'Card', 'NEFT', 'Cheque', 'DD'))
);

-- -----------------------------------------------------------------------------
-- AUTH SUPPORT (not a domain table): maps a Supabase Auth user to a role and,
-- for students/faculty, to their domain record. Clients can never write here.
-- -----------------------------------------------------------------------------
create table if not exists user_profile (
    user_id     uuid primary key references auth.users (id) on delete cascade,
    role        varchar(10)  not null,
    full_name   varchar(100) not null,
    student_id  integer,
    faculty_id  integer,
    created_at  timestamptz  not null default now(),
    constraint fk_user_profile_student foreign key (student_id) references student (student_id) on delete set null,
    constraint fk_user_profile_faculty foreign key (faculty_id) references faculty (faculty_id) on delete set null,
    constraint uq_user_profile_student unique (student_id),
    constraint uq_user_profile_faculty unique (faculty_id),
    constraint ck_user_profile_role check (role in ('admin', 'faculty', 'student', 'accounts')),
    constraint ck_user_profile_link check (
        (role = 'student' and student_id is not null and faculty_id is null) or
        (role = 'faculty' and faculty_id is not null and student_id is null) or
        (role in ('admin', 'accounts') and student_id is null and faculty_id is null)
    )
);

-- -----------------------------------------------------------------------------
-- INDEXES on foreign keys / frequent filters (PK/UNIQUE already indexed)
-- -----------------------------------------------------------------------------
create index if not exists ix_programme_dept        on programme (dept_id);
create index if not exists ix_faculty_dept          on faculty (dept_id);
create index if not exists ix_course_dept           on course (dept_id);
create index if not exists ix_section_faculty       on section (faculty_id);
create index if not exists ix_section_semester      on section (semester_id);
create index if not exists ix_student_programme     on student (programme_id);
create index if not exists ix_student_name          on student (lower(full_name));
create index if not exists ix_guardian_student      on guardian (student_id);
create index if not exists ix_registration_section  on registration (section_id, status);
create index if not exists ix_attendance_date       on attendance (attendance_date);
create index if not exists ix_examination_date      on examination (exam_date);
create index if not exists ix_fee_bill_semester     on fee_bill (semester_id);
create index if not exists ix_payment_bill          on payment (bill_id);
create index if not exists ix_payment_date          on payment (payment_date desc);
