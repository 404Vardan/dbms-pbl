# ============================================================
# Student & College Management System (SCMS)
# Departments Management Module
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from utils.db import execute_query, execute_update
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info

st.set_page_config(page_title="SCMS - Departments", page_icon="🏢", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_dept"):
    logout()
render_project_info()

render_header("Academic Departments", "Manage university faculties, schools, and academic departmental divisions", "🏢")

tab_view, tab_add, tab_manage = st.tabs(["📋 Department Directory", "➕ Add Department", "⚙️ Manage & Delete"])

# ------------------------------------------------------------
# TAB 1: DIRECTORY
# ------------------------------------------------------------
with tab_view:
    depts = execute_query("""
        SELECT 
            d.department_id,
            d.dept_code,
            d.dept_name,
            d.building,
            d.established_year,
            COUNT(DISTINCT p.programme_id) AS programmes_count,
            COUNT(DISTINCT c.course_id) AS courses_count,
            COUNT(DISTINCT f.faculty_id) AS faculty_count
        FROM department d
        LEFT JOIN programme p ON d.department_id = p.department_id
        LEFT JOIN course c ON d.department_id = c.department_id
        LEFT JOIN faculty f ON d.department_id = f.department_id
        GROUP BY d.department_id, d.dept_code, d.dept_name, d.building, d.established_year
        ORDER BY d.dept_code
    """)
    if depts:
        df = pd.DataFrame(depts).rename(columns={
            "dept_code": "Code",
            "dept_name": "Department Name",
            "building": "Campus Building",
            "established_year": "Established",
            "programmes_count": "Programmes",
            "courses_count": "Courses",
            "faculty_count": "Faculty"
        })
        st.dataframe(df.drop(columns=["department_id"]), use_container_width=True, hide_index=True)
    else:
        st.info("No departments registered.")

# ------------------------------------------------------------
# TAB 2: ADD DEPARTMENT
# ------------------------------------------------------------
with tab_add:
    st.subheader("Register New Department")
    with st.form("form_add_dept", clear_on_submit=True):
        col1, col2 = st.columns(2)
        with col1:
            code = st.text_input("Department Code *", placeholder="e.g. AI-DS").upper()
            name = st.text_input("Department Name *", placeholder="e.g. Artificial Intelligence & Data Sciences")
        with col2:
            building = st.text_input("Building / Wing", placeholder="e.g. Turing Academic Complex")
            est_year = st.number_input("Established Year", min_value=1900, max_value=2030, value=2024)

        submitted = st.form_submit_button("➕ Save Department", use_container_width=True)
        if submitted:
            if not (code.strip() and name.strip()):
                st.error("Department Code and Name are mandatory.")
            else:
                try:
                    execute_update(
                        "INSERT INTO department (dept_code, dept_name, building, established_year) VALUES (%s, %s, %s, %s)",
                        (code.strip(), name.strip(), building.strip() if building else None, est_year)
                    )
                    st.success(f"✅ Department '{name}' ({code}) registered successfully.")
                    st.rerun()
                except Exception as e:
                    st.error(f"Failed to add department: {e}")

# ------------------------------------------------------------
# TAB 3: MANAGE & DELETE
# ------------------------------------------------------------
with tab_manage:
    st.subheader("Edit or Delete Department")
    if depts:
        dept_map = {f"{d['dept_code']} - {d['dept_name']}": d for d in depts}
        selected = st.selectbox("Select Department to Modify", list(dept_map.keys()))
        d_data = dept_map[selected]

        col_e, col_d = st.columns([2, 1])
        with col_e:
            with st.form("form_edit_dept"):
                new_name = st.text_input("Department Name", value=d_data["dept_name"])
                new_bldg = st.text_input("Campus Building", value=d_data["building"] or "")
                new_year = st.number_input("Established Year", min_value=1900, max_value=2030, value=d_data["established_year"] or 2020)
                if st.form_submit_button("💾 Update Department", use_container_width=True):
                    try:
                        execute_update(
                            "UPDATE department SET dept_name = %s, building = %s, established_year = %s WHERE department_id = %s",
                            (new_name.strip(), new_bldg.strip(), new_year, d_data["department_id"])
                        )
                        st.success("✅ Department updated successfully.")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Update failed: {e}")

        with col_d:
            st.markdown("#### Referential Integrity Deletion")
            st.caption("Demonstrating `RESTRICT` foreign key integrity: A department cannot be deleted if referenced by programmes or faculty.")
            if st.button("🗑️ Attempt Delete", type="primary"):
                try:
                    execute_update("DELETE FROM department WHERE department_id = %s", (d_data["department_id"],))
                    st.success("✅ Department deleted successfully.")
                    st.rerun()
                except Exception as e:
                    st.error(f"❌ Referential Integrity Action: {e}")
