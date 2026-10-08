# ============================================================
# Student & College Management System (SCMS)
# Programmes Management Module
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from utils.db import execute_query, execute_update
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info

st.set_page_config(page_title="SCMS - Programmes", page_icon="📜", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_prog"):
    logout()
render_project_info()

render_header("Academic Programmes", "Manage degree curricula, duration, and departmental affiliations", "📜")

tab_list, tab_add = st.tabs(["📋 Programmes Directory", "➕ Add Programme"])

# ------------------------------------------------------------
# TAB 1: LIST PROGRAMMES
# ------------------------------------------------------------
with tab_list:
    progs = execute_query("""
        SELECT 
            p.programme_id,
            p.prog_code,
            p.prog_name,
            p.degree_type,
            p.duration_years,
            p.total_semesters,
            d.dept_code,
            d.dept_name,
            COUNT(s.student_id) AS enrolled_students
        FROM programme p
        JOIN department d ON p.department_id = d.department_id
        LEFT JOIN student s ON p.programme_id = s.programme_id
        GROUP BY p.programme_id, p.prog_code, p.prog_name, p.degree_type, p.duration_years, p.total_semesters, d.dept_code, d.dept_name
        ORDER BY d.dept_code, p.prog_code
    """)
    if progs:
        df = pd.DataFrame(progs).rename(columns={
            "prog_code": "Programme Code",
            "prog_name": "Programme Title",
            "degree_type": "Degree",
            "duration_years": "Duration (Yrs)",
            "total_semesters": "Total Sems",
            "dept_name": "Department",
            "enrolled_students": "Students Enrolled"
        })
        st.dataframe(df[["Programme Code", "Programme Title", "Degree", "Duration (Yrs)", "Total Sems", "Department", "Students Enrolled"]], use_container_width=True, hide_index=True)
    else:
        st.info("No programmes registered.")

# ------------------------------------------------------------
# TAB 2: ADD PROGRAMME
# ------------------------------------------------------------
with tab_add:
    st.subheader("Add New Academic Programme")
    depts = execute_query("SELECT department_id, dept_code, dept_name FROM department ORDER BY dept_code")
    if depts:
        dept_map = {f"{d['dept_code']} - {d['dept_name']}": d['department_id'] for d in depts}
        with st.form("form_add_prog", clear_on_submit=True):
            col1, col2 = st.columns(2)
            with col1:
                prog_code = st.text_input("Programme Code *", placeholder="e.g. BTECH-CSBS").upper()
                prog_name = st.text_input("Programme Name *", placeholder="e.g. B.Tech Computer Science & Business Systems")
                selected_dept = st.selectbox("Department *", list(dept_map.keys()))
            with col2:
                degree = st.selectbox("Degree Type", ["B.Tech", "M.Tech", "BBA", "MBA", "B.Des", "B.Arch", "Ph.D"])
                duration = st.number_input("Duration (Years)", min_value=1, max_value=5, value=4)
                semesters = st.number_input("Total Semesters", min_value=2, max_value=10, value=8)

            if st.form_submit_button("➕ Register Programme", use_container_width=True):
                if not (prog_code.strip() and prog_name.strip()):
                    st.error("Programme Code and Name are required.")
                else:
                    try:
                        execute_update("""
                            INSERT INTO programme (department_id, prog_code, prog_name, degree_type, duration_years, total_semesters)
                            VALUES (%s, %s, %s, %s, %s, %s)
                        """, (dept_map[selected_dept], prog_code.strip(), prog_name.strip(), degree, duration, semesters))
                        st.success(f"✅ Programme '{prog_name}' registered successfully.")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Error registering programme: {e}")
    else:
        st.warning("Please create a department first before registering programmes.")
