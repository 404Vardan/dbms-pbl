# ============================================================
# Student & College Management System (SCMS)
# Authentication & Role Management Layer
# Author: Vardan Desai (25WU0104029) | Woxsen University
# ============================================================

import bcrypt
import streamlit as st
from utils.db import execute_query, execute_update


def hash_password(plain_password: str) -> str:
    """Hash a plaintext password using bcrypt."""
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(plain_password.encode("utf-8"), salt).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plaintext password against a bcrypt hash."""
    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    except Exception:
        return False


def authenticate_user(username: str, password: str):
    """
    Look up user account in MySQL database, verify bcrypt hash,
    and update last_login timestamp.
    Returns user dict on success, None on failure.
    """
    query = """
        SELECT user_id, username, password_hash, role, reference_id, email, is_active
        FROM user_account
        WHERE username = %s
    """
    user = execute_query(query, (username.strip(),), fetch="one")
    if not user:
        return None

    if not user.get("is_active"):
        return {"error": "Account is disabled. Please contact system administration."}

    if verify_password(password, user["password_hash"]):
        # Update last login
        try:
            execute_update(
                "UPDATE user_account SET last_login = CURRENT_TIMESTAMP WHERE user_id = %s",
                (user["user_id"],)
            )
        except Exception:
            pass
        return user

    return None


def init_session():
    """Initialize session state keys."""
    if "authenticated" not in st.session_state:
        st.session_state.authenticated = False
    if "user" not in st.session_state:
        st.session_state.user = None
    if "role" not in st.session_state:
        st.session_state.role = None


def login(user_dict: dict):
    """Set authenticated user session."""
    st.session_state.authenticated = True
    st.session_state.user = user_dict
    st.session_state.role = user_dict.get("role")


def logout():
    """Clear session and log user out."""
    st.session_state.authenticated = False
    st.session_state.user = None
    st.session_state.role = None
    st.rerun()


def get_current_user():
    """Get currently logged-in user dictionary."""
    return st.session_state.get("user")


def is_authenticated() -> bool:
    """Check if a session is currently authenticated."""
    return st.session_state.get("authenticated", False)
