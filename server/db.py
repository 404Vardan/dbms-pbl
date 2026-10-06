import os
from datetime import date, datetime
from decimal import Decimal
import mysql.connector
from dotenv import load_dotenv

load_dotenv()

def get_db():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", 3306)),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "scms_db"),
        autocommit=True
    )

def sanitize_value(val):
    if isinstance(val, (date, datetime)):
        return val.isoformat()
    if isinstance(val, Decimal):
        return float(val)
    return val

def sanitize(data):
    if isinstance(data, list):
        return [sanitize(item) for item in data]
    if isinstance(data, dict):
        return {k: sanitize(v) for k, v in data.items()}
    return sanitize_value(data)

def query(sql, params=None, fetchone=False, commit=False):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(sql, params or ())
        if commit:
            conn.commit()
            return cursor.lastrowid
        if fetchone:
            res = cursor.fetchone()
        else:
            res = cursor.fetchall()
        return sanitize(res)
    finally:
        cursor.close()
        conn.close()
