# ============================================================
# Student & College Management System (SCMS)
# Comprehensive SQL Views & Analytics Reports Module
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from utils.db import execute_query
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info, format_currency

st.set_page_config(page_title="SCMS - Analytical Reports", page_icon="📈", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_reports"):
    logout()
render_project_info()

render_header("Comprehensive Academic SQL Reports", "Analytical business intelligence computed strictly via database views", "📈")

st.info("""
💡 **DBMS Views Demonstration**:
Every table and aggregation shown in this module is queried directly from predefined MySQL Views:
- `v_student_academic_history`
- `v_attendance_summary`
- `v_result_analysis` & `v_exam_details`
- `v_fee_dues` & `v_student_dues`
- `v_department_summary` & `v_section_occupancy`
No business aggregations are calculated in application Python code.
""")

tab_acad, tab_att, tab_exam, tab_fee, tab_dept = st.tabs([
    "🎓 Academic History",
    "📋 Attendance Summary",
    "📝 Examination Analysis",
    "💳 Fee & Dues Ledger",
    "🏢 Department Summary"
])

# ------------------------------------------------------------
# 1. ACADEMIC TAB (View: v_student_academic_history)
# ------------------------------------------------------------
with tab_acad:
    st.subheader("Student Academic History Transcript (`v_student_academic_history`)")
    try:
        students = execute_query("SELECT DISTINCT reg_number, student_name FROM v_student_academic_history ORDER BY reg_number")
        if students:
            stu_options = ["All Students"] + [f"{s['reg_number']} - {s['student_name']}" for s in students]
            chosen_stu = st.selectbox("Filter by Student", stu_options, key="acad_filter")

            query = "SELECT * FROM v_student_academic_history WHERE 1=1"
            params = []
            if chosen_stu != "All Students":
                selected_reg = chosen_stu.split(" - ")[0]
                query += " AND reg_number = %s"
                params.append(selected_reg)
            query += " ORDER BY reg_number, course_code"

            hist_data = execute_query(query, params)
            if hist_data:
                df_h = pd.DataFrame(hist_data).rename(columns={
                    "reg_number": "Reg Number",
                    "student_name": "Student Name",
                    "prog_name": "Programme",
                    "semester_name": "Semester",
                    "course_code": "Course Code",
                    "course_name": "Course Title",
                    "credits": "Credits",
                    "reg_status": "Status",
                    "exam_type": "Exam Type",
                    "marks_obtained": "Marks",
                    "max_marks": "Max",
                    "letter_grade": "Grade",
                    "grade_point": "Grade Point"
                })
                st.dataframe(df_h.drop(columns=["student_id"]), use_container_width=True, hide_index=True)
            else:
                st.info("No academic history records found.")
        else:
            st.info("No records in view.")
    except Exception as e:
        st.error(f"Error querying v_student_academic_history: {e}")

# ------------------------------------------------------------
# 2. ATTENDANCE TAB (View: v_attendance_summary)
# ------------------------------------------------------------
with tab_att:
    st.subheader("Attendance Compliance & Shortage Analysis (`v_attendance_summary`)")
    try:
        att_data = execute_query("SELECT * FROM v_attendance_summary ORDER BY attendance_pct ASC")
        if att_data:
            df_att = pd.DataFrame(att_data).rename(columns={
                "reg_number": "Reg Number",
                "student_name": "Student Name",
                "course_code": "Course Code",
                "course_name": "Course Title",
                "semester_name": "Semester",
                "section_name": "Section",
                "total_sessions": "Total Sessions",
                "present_count": "Present",
                "absent_count": "Absent",
                "excused_count": "Excused",
                "attendance_pct": "Attendance %"
            })
            st.dataframe(df_att.drop(columns=["registration_id", "student_id"]), use_container_width=True, hide_index=True)
        else:
            st.info("No attendance records found.")
    except Exception as e:
        st.error(f"Error querying v_attendance_summary: {e}")

# ------------------------------------------------------------
# 3. EXAMINATION TAB (Views: v_result_analysis & v_exam_details)
# ------------------------------------------------------------
with tab_exam:
    st.subheader("Statistical Result Analysis (`v_result_analysis`)")
    try:
        res_data = execute_query("SELECT * FROM v_result_analysis ORDER BY course_code, exam_type")
        if res_data:
            df_res = pd.DataFrame(res_data).rename(columns={
                "course_code": "Course Code",
                "course_name": "Course Title",
                "semester_name": "Semester",
                "exam_type": "Exam Type",
                "total_candidates": "Candidates",
                "avg_marks": "Average",
                "highest_marks": "Highest",
                "lowest_marks": "Lowest",
                "pass_pct": "Pass Rate %"
            })
            st.dataframe(df_res, use_container_width=True, hide_index=True)
        else:
            st.info("No result analysis data.")
    except Exception as e:
        st.error(f"Error querying v_result_analysis: {e}")

    st.divider()
    st.subheader("Detailed Exam Scores (`v_exam_details`)")
    try:
        details_data = execute_query("SELECT * FROM v_exam_details ORDER BY exam_date DESC")
        if details_data:
            df_det = pd.DataFrame(details_data).rename(columns={
                "reg_number": "Reg Number",
                "student_name": "Student Name",
                "course_code": "Course Code",
                "course_name": "Course Title",
                "semester_name": "Semester",
                "exam_type": "Exam Type",
                "exam_date": "Exam Date",
                "max_marks": "Max",
                "marks_obtained": "Marks",
                "percentage": "Pct %",
                "letter_grade": "Grade",
                "grade_point": "GP",
                "remarks": "Evaluation"
            })
            st.dataframe(df_det.drop(columns=["exam_id"]), use_container_width=True, hide_index=True)
        else:
            st.info("No exam details.")
    except Exception as e:
        st.error(f"Error querying v_exam_details: {e}")

# ------------------------------------------------------------
# 4. FEES TAB (Views: v_fee_dues & v_student_dues)
# ------------------------------------------------------------
with tab_fee:
    st.subheader("Aggregated Student Dues (`v_student_dues`)")
    try:
        stu_dues = execute_query("SELECT * FROM v_student_dues ORDER BY total_outstanding_due DESC")
        if stu_dues:
            df_sd = pd.DataFrame(stu_dues).rename(columns={
                "reg_number": "Reg Number",
                "student_name": "Student Name",
                "prog_name": "Programme",
                "total_billed": "Total Invoiced (₹)",
                "total_paid": "Total Cleared (₹)",
                "total_outstanding_due": "Outstanding Dues (₹)",
                "active_bills_count": "Pending Bills"
            })
            st.dataframe(df_sd.drop(columns=["student_id"]), use_container_width=True, hide_index=True)
        else:
            st.info("No student dues data.")
    except Exception as e:
        st.error(f"Error querying v_student_dues: {e}")

    st.divider()
    st.subheader("Individual Fee Bills Ledger (`v_fee_dues`)")
    try:
        fee_dues = execute_query("SELECT * FROM v_fee_dues ORDER BY bill_id DESC")
        if fee_dues:
            df_fd = pd.DataFrame(fee_dues).rename(columns={
                "bill_number": "Bill No",
                "reg_number": "Reg Number",
                "student_name": "Student Name",
                "semester_name": "Semester",
                "fee_type": "Fee Type",
                "bill_amount": "Total (₹)",
                "paid_amount": "Paid (₹)",
                "balance_due": "Balance (₹)",
                "due_date": "Due Date",
                "status": "Status"
            })
            st.dataframe(df_fd.drop(columns=["bill_id"]), use_container_width=True, hide_index=True)
        else:
            st.info("No bills found.")
    except Exception as e:
        st.error(f"Error querying v_fee_dues: {e}")

# ------------------------------------------------------------
# 5. DEPARTMENT TAB (Views: v_department_summary & v_section_occupancy)
# ------------------------------------------------------------
with tab_dept:
    st.subheader("Department Workload & Entity Summary (`v_department_summary`)")
    try:
        dept_sum = execute_query("SELECT * FROM v_department_summary ORDER BY dept_code")
        if dept_sum:
            df_ds = pd.DataFrame(dept_sum).rename(columns={
                "dept_code": "Dept Code",
                "dept_name": "Department Name",
                "total_faculty": "Faculty Count",
                "total_programmes": "Programmes Offered",
                "total_courses": "Courses Offered",
                "total_students": "Enrolled Students"
            })
            st.dataframe(df_ds.drop(columns=["department_id"]), use_container_width=True, hide_index=True)
        else:
            st.info("No department summary available.")
    except Exception as e:
        st.error(f"Error querying v_department_summary: {e}")

    st.divider()
    st.subheader("Section Capacities & Enrolments (`v_section_occupancy`)")
    try:
        sec_occ = execute_query("SELECT * FROM v_section_occupancy ORDER BY course_code")
        if sec_occ:
            df_so = pd.DataFrame(sec_occ).rename(columns={
                "course_code": "Course Code",
                "course_name": "Course Title",
                "section_name": "Section",
                "semester_name": "Semester",
                "faculty_name": "Faculty",
                "room_no": "Room",
                "capacity": "Capacity",
                "enrolled_count": "Enrolled",
                "available_seats": "Seats Left",
                "occupancy_pct": "Occupancy %"
            })
            st.dataframe(df_so.drop(columns=["section_id"]), use_container_width=True, hide_index=True)
        else:
            st.info("No section occupancy data.")
    except Exception as e:
        st.error(f"Error querying v_section_occupancy: {e}")
