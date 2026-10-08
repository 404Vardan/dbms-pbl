# ============================================================
# Student & College Management System (SCMS)
# Semesters Management Module
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd
from datetime import date
from utils.db import execute_query, execute_update
from utils.auth import init_session, is_authenticated, get_current_user, logout
from utils.helpers import render_header, render_project_info, badge

st.set_page_config(page_title="SCMS - Semesters", page_icon="📅", layout="wide")
init_session()

if not is_authenticated():
    st.warning("⚠️ Access restricted. Please log in.")
    st.stop()

user = get_current_user()
st.sidebar.markdown(f"### 👤 Logged in as: **{user['username']}**")
st.sidebar.markdown(f"**Role:** `{user['role']}`")
if st.sidebar.button("🚪 Logout", key="logout_sems"):
    logout()
render_project_info()

render_header("Academic Semesters & Terms", "Manage university academic calendars and set active operational semester", "📅")

tab_list, tab_add, tab_active = st.tabs(["📋 Semesters List", "➕ Add Semester", "⚡ Set Active Semester"])

# ------------------------------------------------------------
# TAB 1: LIST SEMESTERS
# ------------------------------------------------------------
with tab_list:
    sems = execute_query("""
        SELECT 
            semester_id,
            semester_code,
            semester_name,
            academic_year,
            start_date,
            end_date,
            CASE WHEN is_active THEN 'ACTIVE TERM' ELSE 'Inactive' END AS term_status
        FROM semester
        ORDER BY start_date DESC
    """)
    if sems:
        df = pd.DataFrame(sems).rename(columns={
            "semester_code": "Semester Code",
            "semester_name": "Semester Name",
            "academic_year": "Academic Year",
            "start_date": "Start Date",
            "end_date": "End Date",
            "term_status": "Status"
        })
        st.dataframe(df.drop(columns=["semester_id"]), use_container_width=True, hide_index=True)
    else:
        st.info("No semesters configured.")

# ------------------------------------------------------------
# TAB 2: ADD SEMESTER
# ------------------------------------------------------------
with tab_add:
    st.subheader("Define New Academic Semester")
    with st.form("form_add_sem", clear_on_submit=True):
        col1, col2 = st.columns(2)
        with col1:
            scode = st.text_input("Semester Code *", placeholder="e.g. SP2027").upper()
            sname = st.text_input("Semester Title *", placeholder="e.g. Spring 2027")
            ayear = st.text_input("Academic Year *", placeholder="e.g. 2026-2027")
        with col2:
            sdate = st.date_input("Start Date", value=date(2027, 1, 4))
            edate = st.date_input("End Date", value=date(2027, 5, 20))
            is_active = st.checkbox("Set as currently active semester")

        if st.form_submit_button("➕ Create Semester", use_container_width=True):
            if not (scode.strip() and sname.strip() and ayear.strip()):
                st.error("Please fill in code, name, and academic year.")
            elif sdate >= edate:
                st.error("Constraint Violation: Start date must be earlier than end date.")
            else:
                try:
                    if is_active:
                        execute_update("UPDATE semester SET is_active = FALSE")
                    execute_update("""
                        INSERT INTO semester (semester_code, semester_name, academic_year, start_date, end_date, is_active)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, (scode.strip(), sname.strip(), ayear.strip(), str(sdate), str(edate), is_active))
                    st.success(f"✅ Semester '{sname}' added successfully.")
                    st.rerun()
                except Exception as e:
                    st.error(f"Failed to create semester: {e}")

# ------------------------------------------------------------
# TAB 3: SET ACTIVE SEMESTER
# ------------------------------------------------------------
with tab_active:
    st.subheader("Select University Active Academic Term")
    all_sems = execute_query("SELECT semester_id, semester_code, semester_name, is_active FROM semester ORDER BY start_date DESC")
    if all_sems:
        current_active = [s for s in all_sems if s['is_active']]
        active_label = f"{current_active[0]['semester_name']} ({current_active[0]['semester_code']})" if current_active else "None"
        st.info(f"📍 Currently Active Semester: **{active_label}**")

        sem_map = {f"{s['semester_name']} ({s['semester_code']})": s['semester_id'] for s in all_sems}
        chosen = st.selectbox("Choose Semester to Activate", list(sem_map.keys()))
        if st.button("🚀 Set as Active Semester", type="primary"):
            try:
                execute_update("UPDATE semester SET is_active = FALSE")
                execute_update("UPDATE semester SET is_active = TRUE WHERE semester_id = %s", (sem_map[chosen],))
                st.success(f"✅ '{chosen}' is now marked as the active semester.")
                st.rerun()
            except Exception as e:
                st.error(f"Error updating active semester: {e}")
