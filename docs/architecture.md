# System Architecture

The **Student & College Management System (SCMS)** is designed as a three-tier database-driven web application developed for an undergraduate Database Management Systems (DBMS) Project-Based Learning (PBL) curriculum.

The system emphasizes **database-centric data integrity**, delegating critical business logic, domain constraints, state validation, and transactional consistency to the relational database engine (MySQL 8.0+ with InnoDB), while utilizing a lightweight Python/Flask backend for REST APIs and a responsive React frontend for user interaction.

---

## 1. Architectural Overview

```mermaid
graph TD
    subgraph Client ["Client Layer (Browser)"]
        UI[React 19 + Vite SPA]
        Router[React Router v7]
        AuthCtx[Auth Context / JWT in LocalStorage]
    end

    subgraph Server ["Backend API Layer (Python / Flask)"]
        Flask[Flask Application :5000]
        CORS[Flask-CORS Middleware]
        AuthBP[Auth Blueprint - bcrypt & PyJWT]
        Blueprints[API Blueprints: Students, Academics, Reg, Fees, Exams, Reports]
        DBDriver[mysql-connector-python Driver]
    end

    subgraph Database ["Database Layer (MySQL 8.0+ InnoDB)"]
        Tables[(15 Relational Tables)]
        Constraints[PK, FK, UNIQUE, CHECK Constraints]
        Triggers[Business Rule Triggers]
        Procedures[Stored Procedures: sp_admit_student, sp_record_exam_result]
        Views[8 Analytical SQL Views]
    end

    UI -->|HTTP / JSON Requests| Flask
    Flask -->|SQL Queries & CALL proc| DBDriver
    DBDriver -->|TCP / Port 3306| Database
    Database -->|Tuples / Results / SQLSTATE Errors| DBDriver
    DBDriver -->|Sanitized JSON Dicts| Flask
    Flask -->|HTTP 200 / 400 / 500 Responses| UI
```

---

## 2. Layer Breakdown

### Tier 1 — Presentation Layer (Frontend)
- **Framework**: React 19 bootstrapped with Vite.
- **Routing**: React Router (`react-router-dom` v7) providing client-side route navigation and component rendering.
- **State & Session Management**: React Context (`AuthContext`) storing active user profile details and signed JWT tokens in browser `localStorage`.
- **Styling**: Vanilla CSS design system (`src/index.css`) utilizing modern CSS custom properties, responsive grid layouts, card surfaces, and accessible UI controls.
- **API Communication**: Asynchronous HTTP helper functions (`src/lib/api.js`) consuming REST endpoints exposed by the Flask server through a Vite development proxy.

### Tier 2 — Application & API Layer (Backend)
- **Framework**: Python 3.10+ with Flask.
- **Architecture**: Modular blueprint routing architecture (`server/routes/`):
  - `auth.py`: Credential verification via bcrypt and HS256 JWT issuance.
  - `students.py`: Student records, profile details, and stored procedure execution (`sp_admit_student`).
  - `academics.py`: Department, programme, faculty, course, semester, and section lookups.
  - `registration.py`: Course section enrollment and drop management.
  - `attendance.py`: Daily attendance rosters and batch recording.
  - `examinations.py`: Marks logging and procedure dispatch (`sp_record_exam_result`).
  - `fees.py`: Semester fee bills, payment transactions, and ledger history.
  - `reports.py`: Direct pass-through queries to relational database views.
  - `dashboard.py`: Aggregate institutional KPI metrics.
- **Database Connector**: `mysql-connector-python` executing parameterized SQL queries to prevent SQL injection vulnerabilities.
- **Data Sanitization**: `server/db.py` handles conversion of Python `Decimal`, `date`, and `datetime` types into JSON-serializable primitives.

### Tier 3 — Persistence & Integrity Layer (Database)
- **Engine**: MySQL 8.0+ using the `InnoDB` storage engine for ACID transaction compliance.
- **Schema**: 15 normalized tables (14 academic domain tables + 1 application user account table).
- **Integrity**:
  - Declarative constraints (`PRIMARY KEY`, `FOREIGN KEY` with `RESTRICT` and `CASCADE`, `UNIQUE`, `NOT NULL`, and `CHECK`).
  - Procedural triggers enforcing multi-table business constraints before and after mutations.
  - Atomic stored procedures coordinating multi-table inserts within explicit database transactions.
  - Analytical views delivering aggregated institutional insights directly from the database engine.

---

## 3. End-to-End Request Lifecycle

### Case Study: Course Section Registration

The registration workflow demonstrates how the three tiers interact and how database triggers enforce business invariants:

```mermaid
sequenceDiagram
    autonumber
    actor User as Student / Academic Admin
    participant React as React UI (Registration.jsx)
    participant Flask as Flask API (/api/registration)
    participant MySQL as MySQL (registration table)
    participant Trigger as trg_registration_before_insert

    User->>React: Selects Student & Course Section
    React->>Flask: POST /api/registration { student_id, section_id }
    Flask->>MySQL: INSERT INTO registration (student_id, section_id)
    MySQL->>Trigger: Fire BEFORE INSERT trigger
    alt Student is Inactive
        Trigger-->>MySQL: SIGNAL SQLSTATE '45000' ('Only Active students can enroll')
        MySQL-->>Flask: mysql.connector.Error 1644
        Flask-->>React: HTTP 400 { error: "Registration Blocked: Only Active students..." }
        React-->>User: Visual Error Alert
    else Duplicate Course in Same Semester
        Trigger-->>MySQL: SIGNAL SQLSTATE '45000' ('Already registered in another section')
        MySQL-->>Flask: mysql.connector.Error 1644
        Flask-->>React: HTTP 400 { error: "Registration Failed: Student is already registered..." }
        React-->>User: Visual Error Alert
    else Section at Full Capacity
        Trigger-->>MySQL: SIGNAL SQLSTATE '45000' ('Section reached maximum capacity')
        MySQL-->>Flask: mysql.connector.Error 1644
        Flask-->>React: HTTP 400 { error: "Registration Blocked: Section capacity reached" }
        React-->>User: Visual Error Alert
    else All Checks Pass
        Trigger-->>MySQL: Allow INSERT
        MySQL-->>Flask: Insert Successful (registration_id generated)
        Flask-->>React: HTTP 201 { registration_id, message: "Enrolled successfully" }
        React-->>User: Success Notification & UI Refresh
    end
```

---

## 4. Reporting Architecture

Instead of fetching large volumes of raw rows and aggregating them in application memory, SCMS pushes computation directly to MySQL through **Analytical SQL Views**:

```
[Raw Tables]
student, section, course, attendance, examination, grade, fee_bill, payment
      │
      ▼ (Aggregations, JOINs, CASE expressions, window functions)
[MySQL Analytical Views]
v_section_occupancy, v_attendance_summary, v_result_analysis, etc.
      │
      ▼ (Clean SELECT queries via /api/reports/<tab>)
[Flask Backend]
server/routes/reports.py
      │
      ▼ (JSON Response)
[React UI]
Tabular Reporting Interface (src/pages/Reports.jsx)
```

This design keeps the API server stateless and lightweight while utilizing the query execution and index optimization capabilities of the MySQL database engine.
