# ============================================================
# Student & College Management System (SCMS)
# Attendance Tracking Module (Trigger Demonstration)
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from datetime import date, timedelta
from utils.db import execute_query, execute_update
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info, badge

st.set_page_config(page_title="SCMS - Attendance", page_icon="📋", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_att"):
    logout()
render_project_info()

render_header("Attendance Tracking & Verification", "Class session attendance engine enforced by database triggers", "📋")

st.info("""
💡 **DBMS Trigger Demonstration — `trg_attendance_before_insert`**:
The database trigger enforces:
1. **Valid Active Registration**: Attendance cannot be recorded for dropped or nonexistent registrations.
2. **Date Validity Check**: Rejects any attendance date in the future (`attendance_date > CURRENT_DATE()`).
""")

tab_mark, tab_summary, tab_log, tab_test = st.tabs(["✍️ Record Attendance", "📊 Attendance Summary (SQL View)", "📜 Session Logs", "🧪 Test Attendance Triggers"])

# Fetch Active Registrations
registrations = execute_query("""
    SELECT 
        r.registration_id,
        s.reg_number,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        c.course_code,
        c.course_name,
        sec.section_name,
        r.status AS reg_status
    FROM registration r
    JOIN student s ON r.student_id = s.student_id
    JOIN course c ON r.course_id = c.course_id
    JOIN section sec ON r.section_id = sec.section_id
    ORDER BY c.course_code, s.reg_number
""")

# ------------------------------------------------------------
# TAB 1: RECORD ATTENDANCE
# ------------------------------------------------------------
with tab_mark:
    st.subheader("Record Session Attendance")
    if registrations:
        reg_map = {
            f"Reg #{r['registration_id']} | {r['reg_number']} - {r['student_name']} | {r['course_code']} ({r['section_name']}) [{r['reg_status']}]": r['registration_id']
            for r in registrations
        }
        with st.form("form_record_att", clear_on_submit=True):
            sel_reg = st.selectbox("Select Student & Course Enrollment *", list(reg_map.keys()))
            col1, col2 = st.columns(2)
            with col1:
                att_date = st.date_input("Session Date *", value=date.today())
                att_status = st.selectbox("Attendance Status *", ["Present", "Absent", "Excused"])
            with col2:
                remarks = st.text_input("Session Remarks", placeholder="e.g. Regular lecture, Practical lab, etc.")

            if st.form_submit_button("💾 Save Attendance Record", use_container_width=True):
                try:
                    execute_update("""
                        INSERT INTO attendance (registration_id, attendance_date, status, remarks)
                        VALUES (%s, %s, %s, %s)
                    """, (reg_map[sel_reg], str(att_date), att_status, remarks.strip() if remarks else None))
                    st.success(f"✅ Attendance recorded: {att_status} on {att_date}.")
                    st.rerun()
                except ValueError as e:
                    st.error(f"🛑 {e}")
                except Exception as e:
                    st.error(f"🛑 Database error: {e}")
    else:
        st.warning("No active registrations found. Please register students in courses first.")

# ------------------------------------------------------------
# TAB 2: ATTENDANCE SUMMARY (VIEW: v_attendance_summary)
# ------------------------------------------------------------
with tab_summary:
    st.subheader("Aggregated Student Attendance (`v_attendance_summary`)")
    st.caption("Calculated dynamically through SQL View aggregating total sessions, present counts, and attendance percentage.")
    try:
        summary_data = execute_query("SELECT * FROM v_attendance_summary ORDER BY course_code, attendance_pct DESC")
        if summary_data:
            df_sum = pd.DataFrame(summary_data).rename(columns={
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
            st.dataframe(df_sum.drop(columns=["registration_id", "student_id"]), use_container_width=True, hide_index=True)
        else:
            st.info("No attendance data recorded yet.")
    except Exception as e:
        st.error(f"Failed to query v_attendance_summary: {e}")

# ------------------------------------------------------------
# TAB 3: LOGS
# ------------------------------------------------------------
with tab_log:
    st.subheader("Detailed Session Records")
    logs = execute_query("""
        SELECT 
            a.attendance_id,
            s.reg_number,
            CONCAT(s.first_name, ' ', s.last_name) AS student_name,
            c.course_code,
            a.attendance_date,
            a.status,
            a.remarks,
            a.recorded_at
        FROM attendance a
        JOIN registration r ON a.registration_id = r.registration_id
        JOIN student s ON r.student_id = s.student_id
        JOIN course c ON r.course_id = c.course_id
        ORDER BY a.attendance_date DESC, a.attendance_id DESC
    """)
    if logs:
        df_l = pd.DataFrame(logs).rename(columns={
            "reg_number": "Reg No",
            "student_name": "Student",
            "course_code": "Course",
            "attendance_date": "Date",
            "status": "Status",
            "remarks": "Remarks",
            "recorded_at": "Timestamp"
        })
        st.dataframe(df_l.drop(columns=["attendance_id"]), use_container_width=True, hide_index=True)
    else:
        st.info("No logs found.")

# ------------------------------------------------------------
# TAB 4: TRIGGER TEST LAB
# ------------------------------------------------------------
with tab_test:
    st.subheader("🧪 Live Trigger Validation Lab (PBL Viva Demo)")
    col1, col2 = st.columns(2)
    with col1:
        st.markdown("### Test 1: Future Attendance Date")
        st.markdown("Attempts to insert attendance with date `CURRENT_DATE + 5 days`.")
        if st.button("Run Future Date Test", key="test_future_att"):
            try:
                future_date = date.today() + timedelta(days=5)
                execute_update("""
                    INSERT INTO attendance (registration_id, attendance_date, status, remarks)
                    VALUES (1, %s, 'Present', 'Trigger Test')
                """, (str(future_date),))
                st.error("Unexpected: Future date allowed!")
            except ValueError as e:
                st.success(f"✅ Trigger fired as expected:\n\n**{e}**")

    with col2:
        st.markdown("### Test 2: Dropped Registration Attendance")
        st.markdown("Attempts to record attendance on a registration marked as **Dropped**.")
        if st.button("Run Dropped Registration Test", key="test_dropped_att"):
            try:
                # Find or set a dropped registration
                dropped = execute_query("SELECT registration_id FROM registration WHERE status = 'Dropped' LIMIT 1", fetch="one")
                if not dropped:
                    # Create temporary dropped registration
                    _, reg_id = execute_update("""
                        INSERT INTO registration (student_id, course_id, semester_id, section_id, registration_date, status)
                        VALUES (2, 3, 2, 5, CURDATE(), 'Dropped')
                    """)
                    d_id = reg_id
                else:
                    d_id = dropped["registration_id"]

                execute_update("""
                    INSERT INTO attendance (registration_id, attendance_date, status, remarks)
                    VALUES (%s, CURDATE(), 'Present', 'Test Dropped')
                """, (d_id,))
                st.error("Unexpected: Dropped registration attendance allowed!")
            except ValueError as e:
                st.success(f"✅ Trigger fired as expected:\n\n**{e}**")
