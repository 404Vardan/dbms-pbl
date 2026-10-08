# ============================================================
# Student & College Management System (SCMS)
# Sections & Classroom Allocations Module
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from utils.db import execute_query, execute_update
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info

st.set_page_config(page_title="SCMS - Sections", page_icon="👥", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_sections"):
    logout()
render_project_info()

render_header("Course Sections & Occupancy", "Manage course sections, class cohorts, and monitor capacity utilization", "👥")

tab_occ, tab_add = st.tabs(["📊 Section Occupancy (SQL View)", "➕ Add Section"])

# ------------------------------------------------------------
# TAB 1: VIEW OCCUPANCY
# ------------------------------------------------------------
with tab_occ:
    st.subheader("Live Section Occupancy Tracking (`v_section_occupancy`)")
    st.caption("Demonstrating SQL View combining section capacities, student registrations, course codes, and instructor assignments.")
    try:
        occ = execute_query("SELECT * FROM v_section_occupancy ORDER BY course_code, section_name")
        if occ:
            df = pd.DataFrame(occ).rename(columns={
                "course_code": "Course Code",
                "course_name": "Course Title",
                "section_name": "Section",
                "semester_name": "Semester",
                "faculty_name": "Faculty Instructor",
                "room_no": "Room",
                "capacity": "Capacity",
                "enrolled_count": "Enrolled",
                "available_seats": "Seats Remaining",
                "occupancy_pct": "Occupancy %"
            })
            st.dataframe(df.drop(columns=["section_id"]), use_container_width=True, hide_index=True)
        else:
            st.info("No section records available.")
    except Exception as e:
        st.error(f"Error reading view v_section_occupancy: {e}")

# ------------------------------------------------------------
# TAB 2: ADD SECTION
# ------------------------------------------------------------
with tab_add:
    st.subheader("Define New Course Section")
    courses = execute_query("SELECT course_id, course_code, course_name FROM course ORDER BY course_code")
    semesters = execute_query("SELECT semester_id, semester_name, academic_year FROM semester ORDER BY start_date DESC")
    faculties = execute_query("SELECT faculty_id, first_name, last_name, designation FROM faculty WHERE is_active = TRUE ORDER BY first_name")

    if courses and semesters:
        course_map = {f"{c['course_code']} - {c['course_name']}": c['course_id'] for c in courses}
        sem_map = {f"{s['semester_name']} ({s['academic_year']})": s['semester_id'] for s in semesters}
        fac_map = {"Unassigned / TBA": None}
        for f in faculties:
            fac_map[f"{f['first_name']} {f['last_name']} ({f['designation']})"] = f['faculty_id']

        with st.form("form_add_sec", clear_on_submit=True):
            col1, col2 = st.columns(2)
            with col1:
                sel_course = st.selectbox("Course *", list(course_map.keys()))
                sel_sem = st.selectbox("Semester *", list(sem_map.keys()))
                sec_name = st.text_input("Section Cohort Name *", placeholder="e.g. Rhinos, Tigers, Section-A")
            with col2:
                sel_fac = st.selectbox("Faculty Instructor", list(fac_map.keys()))
                capacity = st.number_input("Seat Capacity *", min_value=1, max_value=200, value=30)
                room = st.text_input("Assigned Classroom / Lab", placeholder="e.g. LH-105")

            if st.form_submit_button("➕ Create Section", use_container_width=True):
                if not sec_name.strip():
                    st.error("Section Name is required.")
                else:
                    try:
                        execute_update("""
                            INSERT INTO section (course_id, semester_id, faculty_id, section_name, capacity, room_no)
                            VALUES (%s, %s, %s, %s, %s, %s)
                        """, (course_map[sel_course], sem_map[sel_sem], fac_map[sel_fac], sec_name.strip(), capacity, room.strip() if room else None))
                        st.success(f"✅ Section '{sec_name}' created successfully.")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Failed to create section: {e}")
    else:
        st.warning("Please configure courses and semesters first.")
