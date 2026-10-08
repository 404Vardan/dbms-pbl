# ============================================================
# Student & College Management System (SCMS)
# UI Components, Formatters & Academic Helpers
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import streamlit as st
import pandas as pd


def render_header(title: str, subtitle: str = "", icon: str = "🎓"):
    """Render a clean, professional academic page header."""
    st.markdown(
        f"""
        <div style="padding: 0.8rem 0; border-bottom: 2px solid #e2e8f0; margin-bottom: 1.5rem;">
            <div style="display: flex; align-items: center; gap: 12px;">
                <span style="font-size: 2rem;">{icon}</span>
                <div>
                    <h2 style="margin: 0; font-weight: 700; color: #1e293b; font-size: 1.6rem;">{title}</h2>
                    {f'<p style="margin: 2px 0 0 0; color: #64748b; font-size: 0.95rem;">{subtitle}</p>' if subtitle else ''}
                </div>
            </div>
        </div>
        """,
        unsafe_allow_html=True
    )


def render_project_info():
    """Render Woxsen University PBL Project Metadata in sidebar."""
    st.sidebar.markdown(
        """
        <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; margin-top: 15px;">
            <div style="font-weight: 700; color: #0f172a; font-size: 0.88rem; margin-bottom: 4px;">🎓 DBMS PBL Prototype</div>
            <div style="font-size: 0.8rem; color: #475569; line-height: 1.4;">
                <b>Student:</b> Vardan Desai<br>
                <b>Roll No:</b> 25WU0104029<br>
                <b>Program:</b> B.Tech CSE (AI & ML)<br>
                <b>Team:</b> Rhinos<br>
                <b>Institution:</b> Woxsen University
            </div>
        </div>
        """,
        unsafe_allow_html=True
    )


def format_currency(val) -> str:
    """Format numerical value as Indian Rupee string."""
    try:
        val = float(val)
        return f"₹{val:,.2f}"
    except (ValueError, TypeError):
        return "₹0.00"


def format_pct(val) -> str:
    """Format numerical percentage."""
    try:
        return f"{float(val):.1f}%"
    except (ValueError, TypeError):
        return "0.0%"


def badge(status: str) -> str:
    """Return colored badge HTML string for various entity statuses."""
    colors = {
        "Active": ("#10b981", "#ecfdf5"),
        "Enrolled": ("#0ea5e9", "#f0f9ff"),
        "Paid": ("#059669", "#ecfdf5"),
        "Partially Paid": ("#d97706", "#fffbeb"),
        "Unpaid": ("#dc2626", "#fef2f2"),
        "Dropped": ("#ef4444", "#fef2f2"),
        "Completed": ("#6366f1", "#eef2ff"),
        "Present": ("#10b981", "#ecfdf5"),
        "Absent": ("#ef4444", "#fef2f2"),
        "Excused": ("#f59e0b", "#fffbeb"),
        "A+": ("#10b981", "#ecfdf5"),
        "A": ("#059669", "#ecfdf5"),
        "B+": ("#0284c7", "#f0f9ff"),
        "B": ("#2563eb", "#eff6ff"),
        "C": ("#d97706", "#fffbeb"),
        "D": ("#ea580c", "#fff7ed"),
        "F": ("#dc2626", "#fef2f2")
    }
    fg, bg = colors.get(status, ("#475569", "#f1f5f9"))
    return f"""<span style="background-color: {bg}; color: {fg}; padding: 3px 10px; border-radius: 9999px; font-weight: 600; font-size: 0.8rem; border: 1px solid {fg}33;">{status}</span>"""


def to_dataframe(records: list) -> pd.DataFrame:
    """Convert list of dictionaries to pandas DataFrame safely."""
    if not records:
        return pd.DataFrame()
    return pd.DataFrame(records)
