# Installation & Local Setup Guide

Follow this guide to configure and launch the **Student & College Management System (SCMS)** in your local development environment.

---

## 1. Prerequisites

Before starting, ensure the following software is installed on your computer:

| Dependency | Minimum Version | Notes |
|---|---|---|
| **Node.js** | `v18.0.0` or higher | Recommended LTS (`v20+`). Includes `npm`. |
| **Python** | `v3.10` or higher | Required for the Flask backend. Includes `pip`. |
| **MySQL Server** | `8.0` or higher | Must be running locally on port `3306` with the `InnoDB` engine enabled. |
| **Git** | `v2.30+` | For repository version control. |

---

## 2. Step-by-Step Setup

### Step 1: Clone the Repository
```bash
git clone https://github.com/404Vardan/dbms-pbl.git
cd dbms-pbl
```

---

### Step 2: Initialize the MySQL Database
Open your terminal (or MySQL Workbench) and run the SQL migration scripts **in exact sequential order**:

```bash
# 1. Create database and 15 relational tables with constraints
mysql -u root -p < database/schema.sql

# 2. Apply business rule triggers
mysql -u root -p < database/triggers.sql

# 3. Apply stored procedures
mysql -u root -p < database/procedures.sql

# 4. Apply analytical SQL views
mysql -u root -p < database/views.sql

# 5. Populate sample university seed data & demo accounts
mysql -u root -p < database/seed.sql
```

> **MySQL Workbench / GUI Alternative**:
> You can open each script in MySQL Workbench or DBeaver and execute them sequentially:
> `SOURCE database/schema.sql;`
> `SOURCE database/triggers.sql;`
> `SOURCE database/procedures.sql;`
> `SOURCE database/views.sql;`
> `SOURCE database/seed.sql;`

---

### Step 3: Configure Environment Variables
Copy the `.env.example` file to create your local `.env` file in the root directory:

```bash
# On Windows PowerShell:
Copy-Item .env.example .env

# On Linux / macOS:
cp .env.example .env
```

Edit `.env` to match your local MySQL root password:
```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_actual_mysql_password
DB_NAME=scms_db

# Flask Server Configuration
PORT=5000
JWT_SECRET=scms_jwt_secret_university_erp_2026
```

---

### Step 4: Install Backend Dependencies
It is recommended to use a Python virtual environment:

```bash
# Create virtual environment (optional but recommended)
python -m venv venv

# Activate virtual environment
# Windows:
.\venv\Scripts\Activate.ps1
# Linux / macOS:
source venv/bin/activate

# Install required Python packages
pip install -r server/requirements.txt
```

---

### Step 5: Install Frontend Dependencies
```bash
npm install
```

---

## 3. Running the Application

### Option A: Run Both Tiers Concurrently (Recommended)
You can start both the Flask backend server and the Vite React frontend using the single `package.json` script:
```bash
npm start
```

### Option B: Run in Separate Terminals

#### Terminal 1 — Flask API Server
```bash
python server/app.py
```
*The Flask REST API will start listening at `http://localhost:5000`.*

#### Terminal 2 — React Frontend (Vite)
```bash
npm run dev
```
*The Vite development server will start at `http://localhost:5173`.*

---

## 4. Accessing the Application

1. Open your web browser and navigate to:
   ```
   http://localhost:5173
   ```
2. Log in using one of the pre-seeded demo accounts:

| Role | Email | Password | Access Scope |
|---|---|---|---|
| **Admin** | `registrar@scms.edu.in` | `Demo@12345` | Complete administrative operations across all modules |
| **Faculty** | `priya.raghavan@scms.edu.in` | `Demo@12345` | Course rosters, attendance marking, examination grading |
| **Accounts** | `accounts@scms.edu.in` | `Demo@12345` | Fee billing, payment collection, recovery reports |
| **Student** | `meera.nair@students.scms.edu.in` | `Demo@12345` | Student profile, course history, fee balances |

---

## 5. Troubleshooting & FAQ

### Issue: `Can't connect to MySQL server on 'localhost:3306'`
- **Cause**: MySQL service is not running.
- **Resolution**:
  - Windows: Open Services (`services.msc`) and start `MySQL80`. Or run `net start MySQL80` as administrator.
  - Linux: Run `sudo systemctl start mysql`.
  - macOS: Run `brew services start mysql`.

### Issue: `Access denied for user 'root'@'localhost'`
- **Cause**: Incorrect MySQL password in `.env`.
- **Resolution**: Check the `DB_PASSWORD` value in `.env` and ensure it matches the password set during your MySQL Server installation.

### Issue: Port 5000 or 5173 is already in use
- **Cause**: Another background process is occupying the default port.
- **Resolution**: Update the `PORT` variable in `.env` for Flask, or run Vite on another port with `npm run dev -- --port 5174`.
