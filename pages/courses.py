# ============================================================
# Student & College Management System (SCMS)
# Courses Catalog Management Module
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from utils.db import execute_query, execute_update
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info

st.set_page_config(page_title="SCMS - Courses", page_icon="📖", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_courses"):
    logout()
render_project_info()

render_header("Course Curriculum & Catalog", "Manage academic courses, syllabus credits, and offering departments", "📖")

tab_list, tab_add = st.tabs(["📋 Course Catalog", "➕ Add Course"])

# ------------------------------------------------------------
# TAB 1: LIST COURSES
# ------------------------------------------------------------
with tab_list:
    courses = execute_query("""
        SELECT 
            c.course_id,
            c.course_code,
            c.course_name,
            c.credits,
            c.course_level,
            d.dept_code,
            d.dept_name,
            c.description,
            COUNT(DISTINCT sec.section_id) AS sections_count,
            COUNT(DISTINCT r.registration_id) AS total_enrolled
        FROM course c
        JOIN department d ON c.department_id = d.department_id
        LEFT JOIN section sec ON c.course_id = sec.course_id
        LEFT JOIN registration r ON c.course_id = r.course_id AND r.status = 'Enrolled'
        GROUP BY c.course_id, c.course_code, c.course_name, c.credits, c.course_level, d.dept_code, d.dept_name, c.description
        ORDER BY d.dept_code, c.course_code
    """)
    if courses:
        df = pd.DataFrame(courses).rename(columns={
            "course_code": "Course Code",
            "course_name": "Course Title",
            "credits": "Credits",
            "course_level": "Level",
            "dept_name": "Department",
            "sections_count": "Active Sections",
            "total_enrolled": "Enrolled Students",
            "description": "Syllabus Overview"
        })
        st.dataframe(df.drop(columns=["course_id", "dept_code"]), use_container_width=True, hide_index=True)
    else:
        st.info("No courses found.")

# ------------------------------------------------------------
# TAB 2: ADD COURSE
# ------------------------------------------------------------
with tab_add:
    st.subheader("Add Course to University Curriculum")
    depts = execute_query("SELECT department_id, dept_code, dept_name FROM department ORDER BY dept_code")
    if depts:
        dept_map = {f"{d['dept_code']} - {d['dept_name']}": d['department_id'] for d in depts}
        with st.form("form_add_course", clear_on_submit=True):
            col1, col2 = st.columns(2)
            with col1:
                ccode = st.text_input("Course Code *", placeholder="e.g. CSE305").upper()
                cname = st.text_input("Course Title *", placeholder="e.g. Cloud Computing & Distributed Systems")
                selected_dept = st.selectbox("Offering Department *", list(dept_map.keys()))
            with col2:
                credits = st.number_input("Credits *", min_value=1, max_value=8, value=3)
                level = st.selectbox("Course Level", ["Undergraduate", "Postgraduate", "Doctoral"])
                desc = st.text_area("Syllabus & Course Objectives", placeholder="Core topics and competencies covered...")

            if st.form_submit_button("➕ Register Course", use_container_width=True):
                if not (ccode.strip() and cname.strip()):
                    st.error("Course Code and Title are mandatory.")
                else:
                    try:
                        execute_update("""
                            INSERT INTO course (department_id, course_code, course_name, credits, course_level, description)
                            VALUES (%s, %s, %s, %s, %s, %s)
                        """, (dept_map[selected_dept], ccode.strip(), cname.strip(), credits, level, desc.strip() if desc else None))
                        st.success(f"✅ Course '{ccode}: {cname}' successfully registered.")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Error registering course: {e}")
    else:
        st.warning("Please create departments first.")
