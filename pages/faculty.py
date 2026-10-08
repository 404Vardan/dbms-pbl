# ============================================================
# Student & College Management System (SCMS)
# Faculty Management Module
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from datetime import date
from utils.db import execute_query, execute_update
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info, badge

st.set_page_config(page_title="SCMS - Faculty", page_icon="👨‍🏫", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_faculty"):
    logout()
render_project_info()

render_header("Faculty Directory", "Manage professors, lecturers, and departmental academic appointments", "👨‍🏫")

tab_list, tab_add = st.tabs(["📋 Faculty Directory", "➕ Add Faculty Member"])

# ------------------------------------------------------------
# TAB 1: LIST FACULTY
# ------------------------------------------------------------
with tab_list:
    faculty_list = execute_query("""
        SELECT 
            f.faculty_id,
            f.employee_id,
            CONCAT(f.first_name, ' ', f.last_name) AS full_name,
            f.designation,
            d.dept_name,
            f.email,
            f.phone,
            f.joining_date,
            f.is_active
        FROM faculty f
        JOIN department d ON f.department_id = d.department_id
        ORDER BY d.dept_name, f.first_name
    """)
    if faculty_list:
        df = pd.DataFrame(faculty_list).rename(columns={
            "employee_id": "Employee ID",
            "full_name": "Faculty Name",
            "designation": "Designation",
            "dept_name": "Department",
            "email": "Email",
            "phone": "Contact No",
            "joining_date": "Joining Date",
            "is_active": "Active Status"
        })
        st.dataframe(df.drop(columns=["faculty_id"]), use_container_width=True, hide_index=True)
    else:
        st.info("No faculty members registered.")

# ------------------------------------------------------------
# TAB 2: ADD FACULTY
# ------------------------------------------------------------
with tab_add:
    st.subheader("Register Faculty Member")
    depts = execute_query("SELECT department_id, dept_code, dept_name FROM department ORDER BY dept_code")
    if depts:
        dept_map = {f"{d['dept_code']} - {d['dept_name']}": d['department_id'] for d in depts}
        with st.form("form_add_faculty", clear_on_submit=True):
            col1, col2 = st.columns(2)
            with col1:
                emp_id = st.text_input("Employee ID *", placeholder="e.g. EMP0105").upper()
                fname = st.text_input("First Name *", placeholder="e.g. Deepa")
                lname = st.text_input("Last Name *", placeholder="e.g. Krishnan")
                selected_dept = st.selectbox("Department *", list(dept_map.keys()))
            with col2:
                designation = st.selectbox("Designation *", [
                    "Professor", "Associate Professor", "Assistant Professor", 
                    "Lecturer", "Head of Department"
                ])
                email = st.text_input("Official Email *", placeholder="e.g. deepa.k@woxsen.edu.in")
                phone = st.text_input("Phone Number", placeholder="e.g. 9848011999")
                join_date = st.date_input("Joining Date", value=date.today())

            if st.form_submit_button("➕ Save Faculty Member", use_container_width=True):
                if not (emp_id.strip() and fname.strip() and lname.strip() and email.strip()):
                    st.error("Please fill all mandatory fields.")
                else:
                    try:
                        execute_update("""
                            INSERT INTO faculty (employee_id, department_id, first_name, last_name, email, phone, designation, joining_date, is_active)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, TRUE)
                        """, (emp_id.strip(), dept_map[selected_dept], fname.strip(), lname.strip(), email.strip(), phone.strip() if phone else None, designation, str(join_date)))
                        st.success(f"✅ Faculty member Prof. {fname} {lname} registered.")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Failed to register faculty: {e}")
    else:
        st.warning("Please create departments first.")
