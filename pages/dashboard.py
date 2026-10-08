# ============================================================
# Student & College Management System (SCMS)
# Dashboard Module - Live Real-Time Academic Metrics
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from utils.db import execute_query
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info, format_currency, badge

st.set_page_config(page_title="SCMS - Dashboard", page_icon="📊", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in from the main portal.")
    if st.button("Go to Login Portal"):
        st.switch_page("app.py")
    st.stop()

# Sidebar
user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_dash"):
    logout()
render_project_info()

# Header
render_header("Executive Academic Dashboard", "Live operational indicators directly computed by MySQL database", "📊")

# 1. Fetch live metrics from MySQL
try:
    total_students = execute_query("SELECT COUNT(*) AS cnt FROM student", fetch="one")["cnt"]
    active_students = execute_query("SELECT COUNT(*) AS cnt FROM student WHERE status = 'Active'", fetch="one")["cnt"]
    total_faculty = execute_query("SELECT COUNT(*) AS cnt FROM faculty WHERE is_active = TRUE", fetch="one")["cnt"]
    total_courses = execute_query("SELECT COUNT(*) AS cnt FROM course", fetch="one")["cnt"]
    total_departments = execute_query("SELECT COUNT(*) AS cnt FROM department", fetch="one")["cnt"]

    active_sem = execute_query(
        "SELECT semester_name, academic_year FROM semester WHERE is_active = TRUE LIMIT 1", 
        fetch="one"
    )
    current_semester_str = f"{active_sem['semester_name']} ({active_sem['academic_year']})" if active_sem else "None"

    fee_metrics = execute_query("""
        SELECT 
            IFNULL(SUM(amount), 0.00) AS total_billed,
            IFNULL((SELECT SUM(amount_paid) FROM payment), 0.00) AS total_paid
        FROM fee_bill
    """, fetch="one")

    total_billed = float(fee_metrics["total_billed"])
    total_paid = float(fee_metrics["total_paid"])
    outstanding_fees = max(0.0, total_billed - total_paid)

except Exception as e:
    st.error(f"Error fetching metrics from database: {e}")
    st.stop()

# 2. Render Metric Cards (Row 1)
col1, col2, col3, col4 = st.columns(4)
with col1:
    st.metric("Total Students", f"{total_students}", f"{active_students} Active")
with col2:
    st.metric("Faculty Members", f"{total_faculty}", "Full-time Active")
with col3:
    st.metric("Offered Courses", f"{total_courses}", f"{total_departments} Departments")
with col4:
    st.metric("Current Semester", current_semester_str)

st.markdown("<div style='margin-top: 15px;'></div>", unsafe_allow_html=True)

# Row 2 Metrics: Financial & Academic
col5, col6, col7 = st.columns(3)
with col5:
    st.metric("Total Billed Dues", format_currency(total_billed))
with col6:
    st.metric("Total Fees Collected", format_currency(total_paid))
with col7:
    st.metric("Outstanding Fees", format_currency(outstanding_fees), delta=f"-{format_currency(outstanding_fees)}", delta_color="inverse")

st.divider()

# 3. Live Section Occupancy (from SQL View: v_section_occupancy)
st.subheader("🏫 Real-Time Section Capacity & Occupancy (View: `v_section_occupancy`)")
try:
    occupancy_data = execute_query("SELECT * FROM v_section_occupancy ORDER BY course_code, section_name")
    if occupancy_data:
        df_occ = pd.DataFrame(occupancy_data)
        df_display = df_occ[[
            "course_code", "course_name", "section_name", "semester_name", 
            "faculty_name", "room_no", "capacity", "enrolled_count", "available_seats", "occupancy_pct"
        ]].rename(columns={
            "course_code": "Course Code",
            "course_name": "Course Title",
            "section_name": "Section",
            "semester_name": "Semester",
            "faculty_name": "Faculty In-Charge",
            "room_no": "Room",
            "capacity": "Capacity",
            "enrolled_count": "Enrolled",
            "available_seats": "Seats Left",
            "occupancy_pct": "Occupancy %"
        })
        st.dataframe(df_display, use_container_width=True, hide_index=True)
    else:
        st.info("No active sections recorded.")
except Exception as e:
    st.error(f"Failed to query v_section_occupancy: {e}")

st.markdown("<div style='margin-top: 20px;'></div>", unsafe_allow_html=True)

# 4. Attendance & Academic Snapshot
col_att, col_fee = st.columns(2)

with col_att:
    st.subheader("📋 Attendance Snapshot (View: `v_attendance_summary`)")
    try:
        att_data = execute_query("""
            SELECT reg_number, student_name, course_code, total_sessions, present_count, attendance_pct 
            FROM v_attendance_summary 
            LIMIT 6
        """)
        if att_data:
            df_att = pd.DataFrame(att_data).rename(columns={
                "reg_number": "Reg No",
                "student_name": "Student",
                "course_code": "Course",
                "total_sessions": "Sessions",
                "present_count": "Attended",
                "attendance_pct": "Attendance %"
            })
            st.dataframe(df_att, use_container_width=True, hide_index=True)
        else:
            st.info("No attendance records recorded yet.")
    except Exception as e:
        st.error(f"Error loading attendance snapshot: {e}")

with col_fee:
    st.subheader("💳 Pending Fee Bills (View: `v_fee_dues`)")
    try:
        fee_data = execute_query("""
            SELECT bill_number, reg_number, student_name, fee_type, bill_amount, balance_due, status
            FROM v_fee_dues
            WHERE status <> 'Paid'
            LIMIT 6
        """)
        if fee_data:
            df_fees = pd.DataFrame(fee_data).rename(columns={
                "bill_number": "Bill No",
                "reg_number": "Reg No",
                "student_name": "Student",
                "fee_type": "Fee Type",
                "bill_amount": "Total (₹)",
                "balance_due": "Balance (₹)",
                "status": "Status"
            })
            st.dataframe(df_fees, use_container_width=True, hide_index=True)
        else:
            st.success("🎉 All issued fee bills have been cleared.")
    except Exception as e:
        st.error(f"Error loading fee snapshot: {e}")
