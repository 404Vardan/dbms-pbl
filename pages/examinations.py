# ============================================================
# Student & College Management System (SCMS)
# Examinations & Grading Module (Trigger & Stored Procedure)
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from datetime import date
from utils.db import execute_query, execute_update, call_procedure
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info, badge

st.set_page_config(page_title="SCMS - Examinations & Grading", page_icon="📝", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_exam"):
    logout()
render_project_info()

render_header("Examinations & Automated Database Grading", "Evaluation engine powered by triggers and stored procedures", "📝")

st.info("""
💡 **DBMS Trigger Demonstration — `trg_exam_after_insert` & `trg_exam_after_update`**:
Whenever marks are inserted or updated in MySQL:
- The database trigger automatically calculates the percentage.
- It computes the letter grade (`A+`, `A`, `B+`, `B`, `C`, `D`, `F`) and grade point (10.0 to 0.0).
- It inserts/updates the `grade` table directly in MySQL without relying on Python logic!
""")

tab_enter, tab_update, tab_results, tab_stats = st.tabs([
    "✍️ Enter Exam Marks (Procedure/Trigger)", 
    "🔄 Update Marks & Verify Recalculation", 
    "📋 Exam Grades (View: `v_exam_details`)", 
    "📊 Result Analysis (View: `v_result_analysis`)"
])

# Fetch Registrations
registrations = execute_query("""
    SELECT 
        r.registration_id,
        s.reg_number,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        c.course_code,
        c.course_name,
        sem.semester_name,
        r.status
    FROM registration r
    JOIN student s ON r.student_id = s.student_id
    JOIN course c ON r.course_id = c.course_id
    JOIN semester sem ON r.semester_id = sem.semester_id
    WHERE r.status = 'Enrolled'
    ORDER BY c.course_code, s.reg_number
""")

# ------------------------------------------------------------
# TAB 1: ENTER EXAM MARKS
# ------------------------------------------------------------
with tab_enter:
    st.subheader("Record Examination Result")
    if registrations:
        reg_map = {
            f"Reg #{r['registration_id']} | {r['reg_number']} - {r['student_name']} | {r['course_code']} ({r['semester_name']})": r['registration_id']
            for r in registrations
        }
        with st.form("form_record_exam", clear_on_submit=False):
            sel_reg = st.selectbox("Select Student & Course *", list(reg_map.keys()))
            col1, col2 = st.columns(2)
            with col1:
                exam_type = st.selectbox("Exam Type *", ["Mid-Term", "End-Term", "Quiz", "Assignment", "Lab-Exam"])
                exam_date = st.date_input("Examination Date *", value=date.today())
            with col2:
                max_marks = st.number_input("Maximum Marks *", min_value=1.0, max_value=200.0, value=100.0, step=5.0)
                marks_obtained = st.number_input("Marks Obtained *", min_value=0.0, max_value=200.0, value=75.0, step=0.5)

            submitted = st.form_submit_button("🚀 Submit Marks via Stored Procedure (`sp_record_exam_result`)", use_container_width=True)

            if submitted:
                if marks_obtained > max_marks:
                    st.error("Constraint Violation: Marks obtained cannot exceed maximum marks.")
                else:
                    try:
                        args = (
                            reg_map[sel_reg],
                            exam_type,
                            str(exam_date),
                            float(max_marks),
                            float(marks_obtained),
                            0,   # OUT p_exam_id
                            "",  # OUT p_letter_grade
                            0.0, # OUT p_grade_point
                            0.0, # OUT p_percentage
                            ""   # OUT p_status_message
                        )
                        res = call_procedure("sp_record_exam_result", args)
                        new_exam_id = res[5]
                        letter_grade = res[6]
                        grade_point = res[7]
                        pct = res[8]
                        msg = res[9]

                        if new_exam_id and "SUCCESS" in msg:
                            st.success(f"✅ {msg}")
                            st.markdown(f"""
                            <div style="background: #f0fdf4; border: 2px solid #22c55e; border-radius: 8px; padding: 15px; margin-top: 10px;">
                                <h4 style="margin: 0; color: #15803d;">🎉 Database Trigger Computed Result:</h4>
                                <ul style="margin: 8px 0 0 0; color: #166534; font-size: 1.05rem;">
                                    <li><b>Percentage:</b> {pct:.2f}%</li>
                                    <li><b>Letter Grade:</b> <code>{letter_grade}</code></li>
                                    <li><b>Grade Point:</b> <code>{grade_point} / 10.0</code></li>
                                </ul>
                            </div>
                            """, unsafe_allow_html=True)
                        else:
                            st.error(f"❌ Failed: {msg}")
                    except Exception as e:
                        st.error(f"Error executing procedure: {e}")
    else:
        st.warning("No active course enrollments found.")

# ------------------------------------------------------------
# TAB 2: UPDATE MARKS & VERIFY RECALCULATION
# ------------------------------------------------------------
with tab_update:
    st.subheader("Update Existing Marks (Verify Trigger `trg_exam_after_update`)")
    exams = execute_query("""
        SELECT e.exam_id, s.reg_number, s.first_name, s.last_name, c.course_code, e.exam_type, e.marks_obtained, e.max_marks, g.letter_grade, g.grade_point
        FROM examination e
        JOIN registration r ON e.registration_id = r.registration_id
        JOIN student s ON r.student_id = s.student_id
        JOIN course c ON r.course_id = c.course_id
        LEFT JOIN grade g ON e.exam_id = g.exam_id
        ORDER BY e.exam_id DESC
    """)
    if exams:
        exam_map = {
            f"Exam #{ex['exam_id']}: {ex['reg_number']} ({ex['first_name']} {ex['last_name']}) - {ex['course_code']} {ex['exam_type']} | Current Marks: {ex['marks_obtained']}/{ex['max_marks']} [Grade: {ex['letter_grade']}]": ex
            for ex in exams
        }
        sel_update = st.selectbox("Select Examination Record to Update", list(exam_map.keys()))
        target_exam = exam_map[sel_update]

        with st.form("form_update_marks"):
            new_obtained = st.number_input("New Marks Obtained", min_value=0.0, max_value=float(target_exam['max_marks']), value=float(target_exam['marks_obtained']), step=1.0)
            if st.form_submit_button("⚡ Update Marks & Trigger Recalculation", use_container_width=True):
                try:
                    execute_update("UPDATE examination SET marks_obtained = %s WHERE exam_id = %s", (new_obtained, target_exam['exam_id']))
                    # Fetch updated grade directly from database
                    updated_grade = execute_query("SELECT percentage, letter_grade, grade_point, remarks FROM grade WHERE exam_id = %s", (target_exam['exam_id'],), fetch="one")
                    st.success(f"✅ Marks updated to {new_obtained}/{target_exam['max_marks']}.")
                    st.info(f"🔄 Trigger recalculated grade: **{updated_grade['letter_grade']}** (Grade Point: **{updated_grade['grade_point']}**, Percentage: **{updated_grade['percentage']}%** - {updated_grade['remarks']})")
                except Exception as e:
                    st.error(f"Update failed: {e}")
    else:
        st.info("No exam records to update.")

# ------------------------------------------------------------
# TAB 3: VIEW ALL GRADES (VIEW: v_exam_details)
# ------------------------------------------------------------
with tab_results:
    st.subheader("Official Exam Grades Registry (`v_exam_details`)")
    try:
        exam_details = execute_query("SELECT * FROM v_exam_details ORDER BY exam_id DESC")
        if exam_details:
            df_ex = pd.DataFrame(exam_details).rename(columns={
                "reg_number": "Reg Number",
                "student_name": "Student",
                "course_code": "Course Code",
                "course_name": "Course Title",
                "semester_name": "Semester",
                "exam_type": "Exam Type",
                "exam_date": "Exam Date",
                "max_marks": "Max",
                "marks_obtained": "Obtained",
                "percentage": "Pct %",
                "letter_grade": "Grade",
                "grade_point": "GP",
                "remarks": "Evaluation"
            })
            st.dataframe(df_ex.drop(columns=["exam_id"]), use_container_width=True, hide_index=True)
        else:
            st.info("No examination records found.")
    except Exception as e:
        st.error(f"Error reading view v_exam_details: {e}")

# ------------------------------------------------------------
# TAB 4: RESULT ANALYSIS (VIEW: v_result_analysis)
# ------------------------------------------------------------
with tab_stats:
    st.subheader("Course-wise Performance Statistics (`v_result_analysis`)")
    st.caption("Aggregated analytics calculated directly by MySQL: average marks, highest, lowest, and pass percentages.")
    try:
        stats = execute_query("SELECT * FROM v_result_analysis ORDER BY course_code, exam_type")
        if stats:
            df_st = pd.DataFrame(stats).rename(columns={
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
            st.dataframe(df_st, use_container_width=True, hide_index=True)
        else:
            st.info("No result analysis data available.")
    except Exception as e:
        st.error(f"Error querying v_result_analysis: {e}")
