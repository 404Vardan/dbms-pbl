# ============================================================
# Student & College Management System (SCMS)
# Database Connection & Query Management Layer
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import os
import mysql.connector
from mysql.connector import Error, errorcode
from dotenv import load_dotenv

# Load environment configuration
load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "scms_db")


def get_connection():
    """
    Establish a connection to the MySQL database.
    Returns a mysql.connector.connection.MySQLConnection instance.
    """
    try:
        connection = mysql.connector.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            charset="utf8mb4",
            autocommit=True
        )
        return connection
    except mysql.connector.Error as err:
        friendly_error = parse_db_error(err)
        raise ConnectionError(friendly_error) from err


def parse_db_error(err: mysql.connector.Error) -> str:
    """
    Translate raw MySQL errors, trigger SIGNAL exceptions (1644),
    and foreign key constraints into clean, user-friendly messages.
    """
    err_msg = getattr(err, "msg", str(err))
    err_no = getattr(err, "errno", None)

    # Trigger custom business errors (SQLSTATE 45000 / Error 1644)
    if err_no == 1644 or "SIGNAL" in err_msg or "Registration rejected" in err_msg or "Attendance rejected" in err_msg or "Payment rejected" in err_msg:
        return err_msg

    # Duplicate entry
    if err_no == 1062:
        if "reg_number" in err_msg:
            return "Registration number already exists in the system."
        if "uq_student_course_semester" in err_msg:
            return "Student is already registered for this course in the selected semester."
        if "uq_reg_date" in err_msg:
            return "Attendance has already been recorded for this student on this date."
        if "email" in err_msg:
            return "Email address is already in use by another record."
        if "course_code" in err_msg:
            return "Course code already exists."
        if "dept_code" in err_msg:
            return "Department code already exists."
        if "bill_number" in err_msg:
            return "Bill number must be unique."
        return f"Duplicate record conflict: {err_msg}"

    # Foreign Key Failure
    if err_no in (1451, 1452):
        if err_no == 1451:
            return "Cannot delete or alter this record because active dependent records reference it."
        return "Invalid reference: Associated related entity does not exist."

    # Access Denied
    if err_no == 1045:
        return "Database authentication failed. Please verify DB credentials in .env file."

    # Unknown Database
    if err_no == 1049:
        return f"Database '{DB_NAME}' does not exist. Please initialize scms_db using schema.sql."

    # General Connection Refused
    if err_no == 2003:
        return f"Cannot connect to MySQL server at {DB_HOST}:{DB_PORT}. Is MySQL running?"

    return err_msg


def execute_query(query: str, params=None, fetch="all"):
    """
    Execute a parameterized SELECT query and return rows as dictionaries.
    fetch options: 'all', 'one', or 'none'
    """
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(query, params or ())
        if fetch == "all":
            result = cursor.fetchall()
        elif fetch == "one":
            result = cursor.fetchone()
        else:
            result = None
        return result
    except mysql.connector.Error as err:
        raise ValueError(parse_db_error(err)) from err
    finally:
        cursor.close()
        conn.close()


def execute_update(query: str, params=None):
    """
    Execute a parameterized INSERT, UPDATE, or DELETE statement.
    Returns: (rowcount, last_insert_id)
    """
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(query, params or ())
        rowcount = cursor.rowcount
        last_id = cursor.lastrowid
        conn.commit()
        return rowcount, last_id
    except mysql.connector.Error as err:
        conn.rollback()
        raise ValueError(parse_db_error(err)) from err
    finally:
        cursor.close()
        conn.close()


def call_procedure(proc_name: str, args=()):
    """
    Call a MySQL stored procedure and return the modified argument list.
    """
    conn = get_connection()
    cursor = conn.cursor()
    try:
        result_args = cursor.callproc(proc_name, list(args))
        conn.commit()
        return result_args
    except mysql.connector.Error as err:
        conn.rollback()
        raise ValueError(parse_db_error(err)) from err
    finally:
        cursor.close()
        conn.close()
