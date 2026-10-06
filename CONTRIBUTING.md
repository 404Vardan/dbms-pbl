# Contributing to SCMS

Thank you for your interest in contributing to the **Student & College Management System (SCMS)**! This project was developed as a university Database Management Systems (DBMS) Project-Based Learning (PBL) project.

Contributions that improve documentation, fix bugs, optimize SQL queries, or enhance usability while respecting the existing database schema are welcome.

---

## Getting Started

### 1. Fork and Clone the Repository
Fork the repository on GitHub, then clone your fork locally:
```bash
git clone https://github.com/<your-username>/dbms-pbl.git
cd dbms-pbl
```

### 2. Set Up the Environment
Follow the instructions in [docs/setup.md](docs/setup.md) to set up:
- MySQL 8.0+ database and run the migration scripts in sequence.
- Python virtual environment and backend dependencies (`pip install -r server/requirements.txt`).
- Node.js frontend dependencies (`npm install`).

### 3. Create a Feature Branch
Create a new branch for your work:
```bash
git checkout -b fix/issue-description
# or
git checkout -b docs/documentation-enhancement
```

---

## Development Guidelines

1. **Database Integrity**:
   - Do not break existing foreign key relationships, triggers, or stored procedures.
   - Any database modifications must be reflected across all relevant files in `database/` (`schema.sql`, `triggers.sql`, `procedures.sql`, `views.sql`, `seed.sql`) and documented.
2. **Code Style**:
   - Write clean, commented code following standard Python (PEP 8) and modern React conventions.
   - Keep SQL statements parameterized using `%s` placeholders in the backend; never concatenate user input into queries.
3. **Verification**:
   - Run the frontend build to ensure there are no build errors:
     ```bash
     npm run build
     ```
   - Verify that your changes do not introduce linting regressions:
     ```bash
     npm run lint
     ```
   - Test relevant database rules manually using the scenarios in [docs/testing.md](docs/testing.md).

---

## Submitting Changes

1. Commit your changes with clear, descriptive commit messages:
   ```bash
   git commit -m "docs: clarify section capacity trigger behavior"
   ```
2. Push the branch to your GitHub fork:
   ```bash
   git push origin fix/issue-description
   ```
3. Open a Pull Request against the `main` branch of the upstream repository (`404Vardan/dbms-pbl`).
4. Fill out the pull request template completely, detailing what was changed and whether any database schemas or triggers were affected.
