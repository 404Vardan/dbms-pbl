# ============================================================
# Student & College Management System (SCMS)
# Course Registration Module (Database Trigger Demonstration)
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from datetime import date
from utils.db import execute_query, execute_update
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info, badge

st.set_page_config(page_title="SCMS - Course Registration", page_icon="📝", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_reg"):
    logout()
render_project_info()

render_header("Course Registration & Enrollment", "Student enrollment engine backed by MySQL validation triggers", "📝")

# Academic Highlights Box
st.info("""
💡 **DBMS Trigger Demonstration — `trg_registration_before_insert`**:
Before any registration is inserted, the database trigger strictly enforces:
1. **Active Student Check**: Rejects inactive/suspended students.
2. **Duplicate Prevention**: Prevents registering for the same course within the same semester.
3. **Capacity Enforcement**: Prevents exceeding section capacity.
Any violation immediately triggers a custom MySQL `SIGNAL SQLSTATE '45000'`!
""")

tab_reg, tab_view, tab_test = st.tabs(["📝 New Course Registration", "📋 Enrolled Registrations", "🧪 Test Trigger Validation"])

# Fetch Active Entities
students = execute_query("SELECT student_id, reg_number, first_name, last_name, status FROM student ORDER BY reg_number")
semesters = execute_query("SELECT semester_id, semester_name, academic_year, is_active FROM semester ORDER BY start_date DESC")
courses = execute_query("SELECT course_id, course_code, course_name FROM course ORDER BY course_code")

student_map = {f"{s['reg_number']} - {s['first_name']} {s['last_name']} ({s['status']})": s['student_id'] for s in students}
sem_map = {f"{s['semester_name']} ({s['academic_year']}){' [ACTIVE]' if s['is_active'] else ''}": s['semester_id'] for s in semesters}
course_map = {f"{c['course_code']} - {c['course_name']}": c['course_id'] for c in courses}

# ------------------------------------------------------------
# TAB 1: NEW COURSE REGISTRATION FORM
# ------------------------------------------------------------
with tab_reg:
    st.subheader("Register Student for Course")

    col1, col2 = st.columns(2)
    with col1:
        sel_student_label = st.selectbox("Select Student *", list(student_map.keys()), key="reg_sel_student")
        selected_student_id = student_map[sel_student_label]

        sel_sem_label = st.selectbox("Select Semester *", list(sem_map.keys()), key="reg_sel_sem")
        selected_sem_id = sem_map[sel_sem_label]

    with col2:
        sel_course_label = st.selectbox("Select Course *", list(course_map.keys()), key="reg_sel_course")
        selected_course_id = course_map[sel_course_label]

        # Fetch sections for this course & semester
        available_sections = execute_query("""
            SELECT sec.section_id, sec.section_name, sec.capacity, 
                   COUNT(CASE WHEN r.status = 'Enrolled' THEN 1 END) AS enrolled
            FROM section sec
            LEFT JOIN registration r ON sec.section_id = r.section_id
            WHERE sec.course_id = %s AND sec.semester_id = %s
            GROUP BY sec.section_id, sec.section_name, sec.capacity
        """, (selected_course_id, selected_sem_id))

        if available_sections:
            sec_options = {
                f"Section {s['section_name']} ({s['enrolled']}/{s['capacity']} enrolled)": s['section_id'] 
                for s in available_sections
            }
            sel_sec_label = st.selectbox("Select Section *", list(sec_options.keys()), key="reg_sel_sec")
            selected_section_id = sec_options[sel_sec_label]
        else:
            st.warning("⚠️ No sections defined for this course in the selected semester.")
            selected_section_id = None

    reg_date = st.date_input("Registration Date", value=date.today())

    if st.button("🚀 Submit Course Registration", type="primary", use_container_width=True):
        if not selected_section_id:
            st.error("Cannot proceed: Please choose a valid course section.")
        else:
            try:
                execute_update("""
                    INSERT INTO registration (student_id, course_id, semester_id, section_id, registration_date, status)
                    VALUES (%s, %s, %s, %s, %s, 'Enrolled')
                """, (selected_student_id, selected_course_id, selected_sem_id, selected_section_id, str(reg_date)))
                st.success("✅ Course registration successful! Record confirmed by MySQL.")
                st.rerun()
            except ValueError as e:
                # Clean error message originating from trigger or constraint
                st.error(f"🛑 {e}")
            except Exception as e:
                st.error(f"🛑 Error: {e}")

# ------------------------------------------------------------
# TAB 2: CURRENT REGISTRATIONS LIST
# ------------------------------------------------------------
with tab_view:
    st.subheader("Active Student Registrations")
    regs = execute_query("""
        SELECT 
            r.registration_id,
            s.reg_number,
            CONCAT(s.first_name, ' ', s.last_name) AS student_name,
            c.course_code,
            c.course_name,
            sem.semester_name,
            sec.section_name,
            r.registration_date,
            r.status
        FROM registration r
        JOIN student s ON r.student_id = s.student_id
        JOIN course c ON r.course_id = c.course_id
        JOIN semester sem ON r.semester_id = sem.semester_id
        JOIN section sec ON r.section_id = sec.section_id
        ORDER BY r.registration_id DESC
    """)
    if regs:
        df_r = pd.DataFrame(regs)
        st.dataframe(df_r[[
            "reg_number", "student_name", "course_code", "course_name", 
            "semester_name", "section_name", "registration_date", "status"
        ]].rename(columns={
            "reg_number": "Reg Number",
            "student_name": "Student",
            "course_code": "Course Code",
            "course_name": "Course Title",
            "semester_name": "Semester",
            "section_name": "Section",
            "registration_date": "Registered On",
            "status": "Status"
        }), use_container_width=True, hide_index=True)

        st.divider()
        st.markdown("#### Drop a Registration")
        reg_drop_map = {
            f"Reg #{r['registration_id']}: {r['student_name']} ({r['reg_number']}) - {r['course_code']} [{r['status']}]": r['registration_id']
            for r in regs if r['status'] == 'Enrolled'
        }
        if reg_drop_map:
            sel_drop = st.selectbox("Select Enrolled Registration to Drop", list(reg_drop_map.keys()))
            if st.button("⚠️ Drop Selected Registration", type="secondary"):
                try:
                    execute_update("UPDATE registration SET status = 'Dropped' WHERE registration_id = %s", (reg_drop_map[sel_drop],))
                    st.success("✅ Registration marked as 'Dropped'.")
                    st.rerun()
                except Exception as e:
                    st.error(f"Failed to drop registration: {e}")
    else:
        st.info("No registration records found.")

# ------------------------------------------------------------
# TAB 3: TRIGGER VIVA TEST LAB
# ------------------------------------------------------------
with tab_test:
    st.subheader("🧪 Live Trigger Validation Lab (PBL Viva Demo)")
    st.markdown("Easily demonstrate DBMS trigger business rules live in front of the evaluator:")

    col_t1, col_t2 = st.columns(2)

    with col_t1:
        st.markdown("### Test 1: Duplicate Registration")
        st.markdown("Attempts to register **Vardan Desai** for **CSE201** in **Spring 2026** again.")
        if st.button("Run Duplicate Registration Test", key="btn_test_dup"):
            try:
                execute_update("""
                    INSERT INTO registration (student_id, course_id, semester_id, section_id, registration_date, status)
                    VALUES (1, 1, 2, 1, CURDATE(), 'Enrolled')
                """)
                st.error("Unexpected: Duplicate insert allowed!")
            except ValueError as e:
                st.success(f"✅ Trigger fired as expected:\n\n**{e}**")

    with col_t2:
        st.markdown("### Test 2: Section Capacity Exceeded")
        st.markdown("Tests trigger when a section's registered students reaches capacity.")
        if st.button("Run Section Capacity Test", key="btn_test_cap"):
            try:
                # Temporarily create a dummy section with capacity 1 and fill it
                sec_info = execute_query("SELECT section_id FROM section WHERE capacity <= (SELECT COUNT(*) FROM registration WHERE section_id = section.section_id AND status = 'Enrolled') LIMIT 1", fetch="one")
                if not sec_info:
                    # Create a test section with capacity 1
                    _, new_sec = execute_update("INSERT INTO section (course_id, semester_id, section_name, capacity) VALUES (1, 2, 'TEST_FULL', 1)")
                    execute_update("INSERT INTO registration (student_id, course_id, semester_id, section_id, registration_date, status) VALUES (2, 1, 2, %s, CURDATE(), 'Enrolled')", (new_sec,))
                    full_sec_id = new_sec
                else:
                    full_sec_id = sec_info["section_id"]

                # Try registering another student into this full section
                execute_update("""
                    INSERT INTO registration (student_id, course_id, semester_id, section_id, registration_date, status)
                    VALUES (12, 1, 2, %s, CURDATE(), 'Enrolled')
                """, (full_sec_id,))
                st.error("Unexpected: Exceeded capacity allowed!")
            except ValueError as e:
                st.success(f"✅ Trigger fired as expected:\n\n**{e}**")
