# ============================================================
# Student & College Management System (SCMS)
# Main Application Entry Point & Authentication Portal
# Author: Vardan Desai (25WU0104029) | Woxsen University
# Program: B.Tech CSE – AIML | Team: Rhinos
# ============================================================

import streamlit as st
from utils.auth import init_session, is_authenticated, authenticate_user, login, logout, get_current_user
from utils.helpers import render_project_info

st.set_page_config(
    page_title="SCMS - Student & College Management System",
    page_icon="🎓",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Initialize Session
init_session()

# Custom CSS for polished academic look
st.markdown("""
<style>
    .main-title {
        font-size: 2.2rem;
        font-weight: 800;
        color: #0f172a;
        margin-bottom: 0.2rem;
    }
    .sub-title {
        font-size: 1.1rem;
        color: #475569;
        margin-bottom: 1.5rem;
    }
    .academic-card {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        padding: 20px;
        margin-bottom: 15px;
    }
    .demo-pill {
        background: #e2e8f0;
        color: #1e293b;
        padding: 4px 10px;
        border-radius: 6px;
        font-size: 0.85rem;
        font-weight: 600;
        cursor: pointer;
    }
</style>
""", unsafe_allow_html=True)

# Sidebar Branding
st.sidebar.markdown("""
<div style="text-align: center; padding: 10px 0;">
    <h2 style="margin: 0; color: #1e3a8a;">🎓 SCMS</h2>
    <p style="margin: 0; font-size: 0.85rem; color: #64748b;">Woxsen University Portal</p>
</div>
<hr style="margin: 10px 0;">
""", unsafe_allow_html=True)

render_project_info()

# ------------------------------------------------------------
# 1. AUTHENTICATED STATE
# ------------------------------------------------------------
if is_authenticated():
    current_user = get_current_user()
    st.sidebar.markdown(f"### 👤 Logged in: **{current_user['username']}**")
    st.sidebar.markdown(f"**Role:** `{current_user['role']}`")
    if st.sidebar.button("🚪 Logout", key="logout_main", use_container_width=True):
        logout()

    # Welcome Banner
    st.markdown('<div class="main-title">🎓 Student & College Management System</div>', unsafe_allow_html=True)
    st.markdown(f'<div class="sub-title">Welcome back, <b>{current_user["username"]}</b>! Access your academic modules below or from the sidebar.</div>', unsafe_allow_html=True)

    # Academic & University Metadata Card
    st.markdown(f"""
    <div class="academic-card">
        <h4 style="margin: 0 0 10px 0; color: #1e293b;">📌 Academic Project Information</h4>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 10px; font-size: 0.95rem; color: #334155;">
            <div><b>Student:</b> Vardan Desai</div>
            <div><b>Roll No:</b> 25WU0104029</div>
            <div><b>Programme:</b> B.Tech CSE – AIML</div>
            <div><b>Section / Cohort:</b> Rhinos</div>
            <div><b>Institution:</b> Woxsen University</div>
            <div><b>Active Role:</b> <span style="background: #2563eb; color: white; padding: 2px 8px; border-radius: 4px;">{current_user['role']}</span></div>
        </div>
    </div>
    """, unsafe_allow_html=True)

    st.subheader("🚀 Quick Navigation to Academic Modules")

    col1, col2, col3 = st.columns(3)

    with col1:
        st.markdown("### 📊 Metrics & Directory")
        if st.button("📊 Executive Dashboard", use_container_width=True):
            st.switch_page("pages/dashboard.py")
        if st.button("🎓 Student Registry & Admission", use_container_width=True):
            st.switch_page("pages/students.py")
        if st.button("🏢 Academic Departments", use_container_width=True):
            st.switch_page("pages/departments.py")
        if st.button("📜 Degree Programmes", use_container_width=True):
            st.switch_page("pages/programmes.py")

    with col2:
        st.markdown("### 📚 Academic Operations")
        if st.button("👨‍🏫 Faculty Directory", use_container_width=True):
            st.switch_page("pages/faculty.py")
        if st.button("📖 Course Catalog", use_container_width=True):
            st.switch_page("pages/courses.py")
        if st.button("📅 Academic Semesters", use_container_width=True):
            st.switch_page("pages/semesters.py")
        if st.button("👥 Sections & Occupancy", use_container_width=True):
            st.switch_page("pages/sections.py")

    with col3:
        st.markdown("### ⚙️ Core DBMS Engine")
        if st.button("📝 Course Registration (Triggers)", use_container_width=True):
            st.switch_page("pages/registration.py")
        if st.button("📋 Session Attendance (Triggers)", use_container_width=True):
            st.switch_page("pages/attendance.py")
        if st.button("📝 Examinations & Grades (Auto Triggers)", use_container_width=True):
            st.switch_page("pages/examinations.py")
        if st.button("💳 Fee Billing & Payments (Triggers)", use_container_width=True):
            st.switch_page("pages/fees.py")
        if st.button("📈 SQL Analytical Reports (Views)", use_container_width=True):
            st.switch_page("pages/reports.py")

# ------------------------------------------------------------
# 2. UNAUTHENTICATED STATE: LOGIN PORTAL
# ------------------------------------------------------------
else:
    st.markdown('<div class="main-title">🎓 Student & College Management System</div>', unsafe_allow_html=True)
    st.markdown('<div class="sub-title">Woxsen University — Database Management Systems (DBMS) PBL Prototype</div>', unsafe_allow_html=True)

    col_l1, col_l2 = st.columns([1.2, 1])

    with col_l1:
        st.markdown("""
        <div style="background: #f1f5f9; border-radius: 10px; padding: 20px; border-left: 5px solid #2563eb;">
            <h3 style="margin: 0 0 10px 0; color: #0f172a;">🔐 University Authentication Portal</h3>
            <p style="color: #475569; font-size: 0.95rem; margin-bottom: 12px;">
                Sign in to manage student admissions, section capacities, attendance compliance, examination marks, and fee billing.
            </p>
            <div style="background: white; border-radius: 8px; padding: 12px; border: 1px solid #cbd5e1;">
                <div style="font-weight: 700; color: #1e293b; margin-bottom: 6px;">💡 PBL Evaluation Quick-Login:</div>
                <div style="font-size: 0.88rem; color: #334155;">
                    • <b>Admin:</b> <code>admin</code> / <code>admin123</code> (Full university system privileges)<br>
                    • <b>Faculty:</b> <code>faculty</code> / <code>faculty123</code> (Grading, attendance, courses)<br>
                    • <b>Student:</b> <code>student</code> / <code>student123</code> (Vardan Desai transcript & dues)
                </div>
            </div>
        </div>
        """, unsafe_allow_html=True)

        st.markdown("<div style='margin-top: 15px;'></div>", unsafe_allow_html=True)

        # Quick Fill Buttons
        st.markdown("<b>⚡ One-Click Demo Credentials:</b>", unsafe_allow_html=True)
        col_b1, col_b2, col_b3 = st.columns(3)
        if col_b1.button("🔑 Fill Admin", use_container_width=True):
            st.session_state.demo_user = "admin"
            st.session_state.demo_pass = "admin123"
        if col_b2.button("👨‍🏫 Fill Faculty", use_container_width=True):
            st.session_state.demo_user = "faculty"
            st.session_state.demo_pass = "faculty123"
        if col_b3.button("🎓 Fill Student", use_container_width=True):
            st.session_state.demo_user = "student"
            st.session_state.demo_pass = "student123"

    with col_l2:
        default_user = st.session_state.get("demo_user", "")
        default_pass = st.session_state.get("demo_pass", "")

        with st.form("form_login"):
            st.markdown("### Sign In")
            username = st.text_input("Username", value=default_user, placeholder="Enter username (e.g. admin)")
            password = st.text_input("Password", value=default_pass, type="password", placeholder="Enter password")
            submit_login = st.form_submit_button("🔓 Log In", use_container_width=True, type="primary")

            if submit_login:
                if not (username.strip() and password):
                    st.error("Please enter both username and password.")
                else:
                    try:
                        user_obj = authenticate_user(username, password)
                        if user_obj and "error" not in user_obj:
                            login(user_obj)
                            st.success(f"Login successful! Welcome, {user_obj['username']}.")
                            st.rerun()
                        elif user_obj and "error" in user_obj:
                            st.error(user_obj["error"])
                        else:
                            st.error("Invalid username or password. Check your credentials.")
                    except Exception as e:
                        st.error(f"Database connection error: {e}")
