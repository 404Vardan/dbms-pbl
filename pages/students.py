# ============================================================
# Student & College Management System (SCMS)
# Students Management Module
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from datetime import date
from utils.db import execute_query, execute_update, call_procedure
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info, badge, format_currency

st.set_page_config(page_title="SCMS - Students", page_icon="🎓", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

# Sidebar
user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_students"):
    logout()
render_project_info()

render_header("Student Directory & Admission", "Manage student profiles, guardian information, and academic lifecycle", "🎓")

tab_list, tab_add, tab_edit, tab_details = st.tabs(["📋 View & Search Students", "➕ Admit New Student (Stored Procedure)", "✏️ Edit Student", "🔍 Detailed Profile"])

# ------------------------------------------------------------
# TAB 1: VIEW & SEARCH STUDENTS
# ------------------------------------------------------------
with tab_list:
    st.subheader("Enrolled Student Registry")
    
    col_search1, col_search2, col_filter = st.columns([2, 1, 1])
    with col_search1:
        search_query = st.text_input("Search by Name or Registration Number", placeholder="e.g. Vardan or 25WU0104029")
    with col_search2:
        programmes = execute_query("SELECT programme_id, prog_code, prog_name FROM programme")
        prog_options = {"All Programmes": None}
        for p in programmes:
            prog_options[f"{p['prog_code']} - {p['prog_name']}"] = p['programme_id']
        selected_prog_label = st.selectbox("Filter Programme", list(prog_options.keys()))
        selected_prog_id = prog_options[selected_prog_label]
    with col_filter:
        status_filter = st.selectbox("Filter Status", ["All Statuses", "Active", "Inactive", "Suspended", "Graduated"])

    query = """
        SELECT 
            s.student_id,
            s.reg_number,
            CONCAT(s.first_name, ' ', s.last_name) AS full_name,
            s.email,
            s.phone,
            p.prog_code,
            s.current_semester,
            s.gender,
            s.admission_date,
            s.status
        FROM student s
        JOIN programme p ON s.programme_id = p.programme_id
        WHERE 1=1
    """
    params = []
    if search_query.strip():
        query += " AND (s.reg_number LIKE %s OR s.first_name LIKE %s OR s.last_name LIKE %s OR s.email LIKE %s)"
        pattern = f"%{search_query.strip()}%"
        params.extend([pattern, pattern, pattern, pattern])
    if selected_prog_id:
        query += " AND s.programme_id = %s"
        params.append(selected_prog_id)
    if status_filter != "All Statuses":
        query += " AND s.status = %s"
        params.append(status_filter)
        
    query += " ORDER BY s.student_id DESC"

    try:
        students = execute_query(query, params)
        if students:
            df = pd.DataFrame(students).rename(columns={
                "reg_number": "Reg Number",
                "full_name": "Full Name",
                "email": "Email",
                "phone": "Phone",
                "prog_code": "Programme",
                "current_semester": "Sem",
                "gender": "Gender",
                "admission_date": "Admission Date",
                "status": "Status"
            })
            st.dataframe(df.drop(columns=["student_id"]), use_container_width=True, hide_index=True)
            st.caption(f"Showing {len(students)} student record(s).")
        else:
            st.info("No matching student records found.")
    except Exception as e:
        st.error(f"Error loading students: {e}")

# ------------------------------------------------------------
# TAB 2: ADMIT NEW STUDENT (via sp_admit_student)
# ------------------------------------------------------------
with tab_add:
    st.subheader("Admit New Student via Stored Procedure (`sp_admit_student`)")
    st.info("💡 **DBMS Demonstration**: This form invokes MySQL Stored Procedure `sp_admit_student`, which executes an **atomic ACID transaction** to insert the student and guardian records simultaneously with rollback protection on failure.")

    with st.form("form_admit_student", clear_on_submit=True):
        st.markdown("#### 1. Student Personal & Academic Details")
        col_a1, col_a2 = st.columns(2)
        with col_a1:
            in_reg_no = st.text_input("Registration Number *", placeholder="e.g. 25WU0104030")
            in_first_name = st.text_input("First Name *", placeholder="e.g. Aarohan")
            in_last_name = st.text_input("Last Name *", placeholder="e.g. Roy")
            in_email = st.text_input("Email *", placeholder="e.g. aarohan.roy@woxsen.edu.in")
            in_phone = st.text_input("Phone Number *", placeholder="e.g. 9848011030")
        with col_a2:
            prog_dict = {f"{p['prog_code']} - {p['prog_name']}": p['programme_id'] for p in programmes}
            selected_prog = st.selectbox("Programme *", list(prog_dict.keys()), key="admit_prog")
            in_dob = st.date_input("Date of Birth *", min_value=date(1990, 1, 1), max_value=date(2010, 12, 31), value=date(2004, 5, 10))
            in_gender = st.selectbox("Gender *", ["Male", "Female", "Other"])
            in_admission_date = st.date_input("Admission Date *", value=date.today())
            in_sem = st.number_input("Starting Semester", min_value=1, max_value=10, value=1)

        st.markdown("#### 2. Guardian & Emergency Contact Information")
        col_g1, col_g2 = st.columns(2)
        with col_g1:
            g_name = st.text_input("Guardian Full Name *", placeholder="e.g. Sandeep Roy")
            g_rel = st.selectbox("Relationship *", ["Father", "Mother", "Guardian", "Sibling", "Other"])
            g_phone = st.text_input("Guardian Phone *", placeholder="e.g. 9988001030")
        with col_g2:
            g_email = st.text_input("Guardian Email", placeholder="e.g. sandeep.roy@gmail.com")
            g_address = st.text_area("Residential Address", placeholder="Street, City, Postal Code")

        submitted = st.form_submit_button("🚀 Submit Admission via sp_admit_student", use_container_width=True)

        if submitted:
            if not (in_reg_no.strip() and in_first_name.strip() and in_last_name.strip() and in_email.strip() and in_phone.strip() and g_name.strip() and g_phone.strip()):
                st.error("Please fill in all mandatory fields marked with *.")
            else:
                try:
                    prog_id = prog_dict[selected_prog]
                    proc_args = (
                        in_reg_no.strip(),
                        prog_id,
                        in_first_name.strip(),
                        in_last_name.strip(),
                        in_email.strip(),
                        in_phone.strip(),
                        str(in_dob),
                        in_gender,
                        str(in_admission_date),
                        int(in_sem),
                        g_name.strip(),
                        g_rel,
                        g_phone.strip(),
                        g_email.strip() if g_email else None,
                        g_address.strip() if g_address else None,
                        0,  # OUT p_student_id
                        ""  # OUT p_status_message
                    )
                    res = call_procedure("sp_admit_student", proc_args)
                    new_id = res[-2]
                    status_msg = res[-1]

                    if new_id and "SUCCESS" in status_msg:
                        st.success(f"✅ {status_msg} (Generated Student ID: {new_id})")
                    else:
                        st.error(f"❌ Admission Failed: {status_msg}")
                except Exception as e:
                    st.error(f"❌ Database Transaction Error: {e}")

# ------------------------------------------------------------
# TAB 3: EDIT STUDENT
# ------------------------------------------------------------
with tab_edit:
    st.subheader("Update Student Information")
    all_students = execute_query("SELECT student_id, reg_number, first_name, last_name FROM student ORDER BY reg_number")
    if all_students:
        student_map = {f"{s['reg_number']} - {s['first_name']} {s['last_name']}": s['student_id'] for s in all_students}
        selected_stu = st.selectbox("Select Student to Edit", list(student_map.keys()))
        s_id = student_map[selected_stu]

        current_data = execute_query("SELECT * FROM student WHERE student_id = %s", (s_id,), fetch="one")

        with st.form("form_edit_student"):
            col_e1, col_e2 = st.columns(2)
            with col_e1:
                e_first = st.text_input("First Name", value=current_data["first_name"])
                e_last = st.text_input("Last Name", value=current_data["last_name"])
                e_email = st.text_input("Email", value=current_data["email"])
                e_phone = st.text_input("Phone", value=current_data["phone"] or "")
            with col_e2:
                e_sem = st.number_input("Current Semester", min_value=1, max_value=10, value=current_data["current_semester"])
                status_opts = ["Active", "Inactive", "Suspended", "Graduated"]
                e_status = st.selectbox("Status", status_opts, index=status_opts.index(current_data["status"]))

            btn_update = st.form_submit_button("💾 Save Changes", use_container_width=True)
            if btn_update:
                try:
                    execute_update("""
                        UPDATE student 
                        SET first_name = %s, last_name = %s, email = %s, phone = %s, current_semester = %s, status = %s
                        WHERE student_id = %s
                    """, (e_first.strip(), e_last.strip(), e_email.strip(), e_phone.strip(), e_sem, e_status, s_id))
                    st.success("✅ Student details updated successfully.")
                    st.rerun()
                except Exception as e:
                    st.error(f"Update failed: {e}")

# ------------------------------------------------------------
# TAB 4: DETAILED PROFILE
# ------------------------------------------------------------
with tab_details:
    st.subheader("360° Academic & Profile View")
    if all_students:
        chosen_profile = st.selectbox("Select Student Profile", list(student_map.keys()), key="sel_profile")
        pid = student_map[chosen_profile]

        stu = execute_query("""
            SELECT s.*, p.prog_name, p.prog_code, d.dept_name
            FROM student s
            JOIN programme p ON s.programme_id = p.programme_id
            JOIN department d ON p.department_id = d.department_id
            WHERE s.student_id = %s
        """, (pid,), fetch="one")

        guardian = execute_query("SELECT * FROM guardian WHERE student_id = %s", (pid,), fetch="one")
        registrations = execute_query("""
            SELECT r.registration_id, c.course_code, c.course_name, c.credits, sem.semester_name, sec.section_name, r.status
            FROM registration r
            JOIN course c ON r.course_id = c.course_id
            JOIN semester sem ON r.semester_id = sem.semester_id
            JOIN section sec ON r.section_id = sec.section_id
            WHERE r.student_id = %s
        """, (pid,))

        col_p1, col_p2 = st.columns(2)
        with col_p1:
            st.markdown(f"**Registration No:** `{stu['reg_number']}`")
            st.markdown(f"**Full Name:** {stu['first_name']} {stu['last_name']}")
            st.markdown(f"**Email:** {stu['email']}")
            st.markdown(f"**Phone:** {stu['phone']}")
            st.markdown(f"**Gender:** {stu['gender']} | **DOB:** {stu['dob']}")
        with col_p2:
            st.markdown(f"**Department:** {stu['dept_name']}")
            st.markdown(f"**Programme:** {stu['prog_name']} ({stu['prog_code']})")
            st.markdown(f"**Current Semester:** Semester {stu['current_semester']}")
            st.markdown(f"**Admission Date:** {stu['admission_date']}")
            st.markdown(f"**Status:** {badge(stu['status'])}", unsafe_allow_html=True)

        st.divider()
        st.markdown("#### 👨‍👩‍👦 Guardian Details")
        if guardian:
            st.markdown(f"**Name:** {guardian['guardian_name']} ({guardian['relationship']}) | **Phone:** {guardian['phone']} | **Email:** {guardian['email'] or 'N/A'}")
            st.markdown(f"**Address:** {guardian['address'] or 'N/A'}")
        else:
            st.info("No guardian record associated.")

        st.markdown("#### 📚 Enrolled Courses & Registrations")
        if registrations:
            st.dataframe(pd.DataFrame(registrations).rename(columns={
                "course_code": "Course Code",
                "course_name": "Course Title",
                "credits": "Credits",
                "semester_name": "Semester",
                "section_name": "Section",
                "status": "Status"
            }).drop(columns=["registration_id"]), use_container_width=True, hide_index=True)
        else:
            st.info("No courses registered for this student.")
